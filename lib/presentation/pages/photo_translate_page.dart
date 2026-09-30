import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/services/text_recognition_service.dart';
import 'package:translate_app/domain/entities/photo_text_block.dart';
import 'package:translate_app/domain/entities/photo_translation.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/photo_translate_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/presentation/widgets/deck_selector_sheet.dart';
import 'package:translate_app/presentation/widgets/dropdown.dart';
import 'package:translate_app/presentation/widgets/restart_required_dialog.dart';
import 'package:translate_app/presentation/widgets/upgrade_required_dialog.dart';
import 'package:translate_app/theme/theme.dart';

/// Camera/gallery photo → text read on the device → only the text is translated
/// → translations drawn over their lines, plus a word list for decks.
class PhotoTranslatePage extends StatefulWidget {
  const PhotoTranslatePage({super.key});

  static Future<void> open(BuildContext context) {
    final usecase = context.read<TranslateUsecase>();
    final textRecognition = context.read<TextRecognitionService>();
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => PhotoTranslateViewModel(usecase, textRecognition),
          child: const PhotoTranslatePage(),
        ),
      ),
    );
  }

  @override
  State<PhotoTranslatePage> createState() => _PhotoTranslatePageState();
}

enum _CameraState { starting, ready, denied, unavailable }

const Set<String> _rightToLeftLanguages = {
  'Arabic',
  'Hebrew',
  'Persian',
  'Urdu',
};

class _PhotoTranslatePageState extends State<PhotoTranslatePage>
    with WidgetsBindingObserver {
  late final PhotoTranslateViewModel _vm;
  late final GeminiTranslateViewModel _languages;
  late String _sourceLanguage;
  late String _targetLanguage;
  AppException? _handledException;

  CameraController? _camera;
  _CameraState _cameraState = _CameraState.starting;
  FlashMode _flashMode = FlashMode.off;
  bool _capturing = false;
  bool _picking = false;

  static const double _zoomCap = 8;
  double _zoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoomAtPinchStart = 1;

  /// Tap-to-focus point (0-1 in the preview), shown briefly.
  Offset? _focusPoint;
  Timer? _focusRingTimer;

  bool _showHint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm = context.read<PhotoTranslateViewModel>();
    _vm.addListener(_showDialogForException);
    // Shares the AI page's language pair.
    _languages = context.read<GeminiTranslateViewModel>();
    _sourceLanguage = _languages.sourceLanguage;
    _targetLanguage = _languages.targetLanguage;
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm.removeListener(_showDialogForException);
    _focusRingTimer?.cancel();
    _hintTimer?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  // `inactive` is ignored: iOS fires it for the permission alert too.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final camera = _camera;
      _camera = null;
      camera?.dispose();
      if (mounted) setState(() => _cameraState = _CameraState.starting);
    } else if (state == AppLifecycleState.resumed &&
        _camera == null &&
        _cameraState == _CameraState.starting) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    setState(() => _cameraState = _CameraState.starting);
    try {
      final cameras = await availableCameras();
      final back =
          cameras
              .where((c) => c.lensDirection == CameraLensDirection.back)
              .firstOrNull ??
          cameras.firstOrNull;
      if (back == null) {
        if (mounted) setState(() => _cameraState = _CameraState.unavailable);
        return;
      }

      // 4K so small text stays readable.
      final camera = CameraController(
        back,
        ResolutionPreset.ultraHigh,
        enableAudio: false,
      );
      await camera.initialize();
      if (!mounted) {
        camera.dispose();
        return;
      }
      await camera
          .lockCaptureOrientation(DeviceOrientation.portraitUp)
          .catchError((_) {});
      await camera.setFlashMode(_flashMode).catchError((_) {});
      await camera.setFocusMode(FocusMode.auto).catchError((_) {});
      await camera.setExposureMode(ExposureMode.auto).catchError((_) {});
      final minZoom = await camera.getMinZoomLevel().catchError((_) => 1.0);
      final maxZoom = await camera.getMaxZoomLevel().catchError((_) => 1.0);
      final zoom = _zoom.clamp(minZoom, math.min(maxZoom, _zoomCap)).toDouble();
      if (zoom != 1) await camera.setZoomLevel(zoom).catchError((_) {});
      // Returned while a result is shown: keep the preview paused.
      if (_vm.status != PhotoTranslateStatus.camera) {
        await camera.pausePreview();
      }
      if (!mounted) {
        camera.dispose();
        return;
      }
      setState(() {
        _camera = camera;
        _cameraState = _CameraState.ready;
        _minZoom = minZoom;
        _maxZoom = math.max(minZoom, math.min(maxZoom, _zoomCap));
        _zoom = zoom;
      });
      _hintTimer ??= Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showHint = false);
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      const deniedCodes = {
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
      };
      setState(
        () => _cameraState = deniedCodes.contains(e.code)
            ? _CameraState.denied
            : _CameraState.unavailable,
      );
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final photo = await camera.takePicture();
      await camera.pausePreview();
      _vm.processCapture(photo.path, _sourceLanguage, _targetLanguage);
    } on CameraException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not take the photo. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_picking || _capturing) return;
    setState(() => _picking = true);
    try {
      // Capped near the camera's 4K size to keep reading fast.
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 95,
      );
      if (photo == null || !mounted) return;
      await _camera?.pausePreview().catchError((_) {});
      _vm.processCapture(photo.path, _sourceLanguage, _targetLanguage);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your photos.')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _retake() {
    _vm.reset();
    _camera?.resumePreview().catchError((_) {});
  }

  Future<void> _setZoom(double zoom) async {
    final camera = _camera;
    if (camera == null) return;
    final clamped = zoom.clamp(_minZoom, _maxZoom).toDouble();
    if (clamped == _zoom) return;
    setState(() => _zoom = clamped);
    await camera.setZoomLevel(clamped).catchError((_) {});
  }

  Future<void> _focusAt(Offset point) async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    _focusRingTimer?.cancel();
    setState(() => _focusPoint = point);
    _focusRingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _focusPoint = null);
    });
    if (camera.value.focusPointSupported) {
      await camera.setFocusPoint(point).catchError((_) {});
    }
    if (camera.value.exposurePointSupported) {
      await camera.setExposurePoint(point).catchError((_) {});
    }
  }

  Future<void> _toggleFlash() async {
    final next = _flashMode == FlashMode.off ? FlashMode.auto : FlashMode.off;
    setState(() => _flashMode = next);
    await _camera?.setFlashMode(next).catchError((_) {});
  }

  // Source change → read again; target change → translate again.
  void _applyLanguages(void Function() change) {
    final oldSource = _sourceLanguage;
    final oldTarget = _targetLanguage;
    change();
    setState(() {
      _sourceLanguage = _languages.sourceLanguage;
      _targetLanguage = _languages.targetLanguage;
    });
    if (!_vm.hasPhoto || _vm.isBusy) return;
    if (_sourceLanguage != oldSource) {
      _vm.readText(_sourceLanguage, _targetLanguage);
    } else if (_targetLanguage != oldTarget) {
      _vm.translate(_targetLanguage);
    }
  }

  void _changeSourceLanguage(String? language) {
    if (language == null || language == _sourceLanguage) return;
    _applyLanguages(() => _languages.setSourceLanguage(language));
  }

  void _changeTargetLanguage(String? language) {
    if (language == null || language == _targetLanguage) return;
    _applyLanguages(() => _languages.setTargetLanguage(language));
  }

  void _swapLanguages() {
    _applyLanguages(() => _languages.setSourceLanguage(_targetLanguage));
  }

  // Plan/session errors get dialogs; the rest show in the status bar.
  void _showDialogForException() {
    final exception = _vm.exception;
    if (exception == null || identical(exception, _handledException)) return;
    _handledException = exception;
    if (exception is! FeatureNotAvailableException &&
        exception is! AuthException) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (exception is FeatureNotAvailableException) {
        showUpgradeRequiredDialog(
          context,
          title: 'Photo Translation',
          message:
              'Translating text in photos is available on the Standard and '
              'Premium plans.',
        );
      } else {
        showRestartRequiredDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhotoTranslateViewModel>();
    final inCameraMode = vm.status == PhotoTranslateStatus.camera;
    final done = vm.status == PhotoTranslateStatus.done;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Same gap above the buttons and below them.
    final bottomGap = math.max(20.0, bottomInset);
    final drawerPeek = _WordsDrawer.peekContentHeight + bottomInset;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: _Card(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: vm.hasPhoto
                                    ? _PhotoCanvas(
                                        vm: vm,
                                        rightToLeft: _rightToLeftLanguages
                                            .contains(_targetLanguage),
                                      )
                                    : _Viewfinder(
                                        camera: _camera,
                                        state: _cameraState,
                                        focusPoint: _focusPoint,
                                        onFocus: _focusAt,
                                        onPinchStart: () =>
                                            _zoomAtPinchStart = _zoom,
                                        onPinchUpdate: (scale) =>
                                            _setZoom(_zoomAtPinchStart * scale),
                                      ),
                              ),
                              Positioned(
                                top: 10,
                                left: 8,
                                right: 8,
                                child: _TopBar(
                                  sourceLanguage: _sourceLanguage,
                                  targetLanguage: _targetLanguage,
                                  recentLanguages: _languages.recentLanguages,
                                  locked: vm.isBusy,
                                  onBack: () => Navigator.maybePop(context),
                                  onSourceChanged: _changeSourceLanguage,
                                  onTargetChanged: _changeTargetLanguage,
                                  onSwap: _swapLanguages,
                                ),
                              ),
                              if (inCameraMode &&
                                  _cameraState == _CameraState.ready)
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  top: 62,
                                  child: IgnorePointer(
                                    child: AnimatedOpacity(
                                      opacity: _showHint ? 1 : 0,
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      child: const _AlignmentHint(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (done)
                      SizedBox(height: drawerPeek)
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          bottomGap,
                          16,
                          bottomGap,
                        ),
                        child: inCameraMode
                            ? _CameraControls(
                                enabled: _cameraState == _CameraState.ready,
                                capturing: _capturing,
                                galleryEnabled: !_picking && !_capturing,
                                flashMode: _flashMode,
                                onToggleFlash: _toggleFlash,
                                onCapture: _capture,
                                onPickFromGallery: _pickFromGallery,
                              )
                            : _StatusBar(
                                vm: vm,
                                targetLanguage: _targetLanguage,
                                onRetry: () =>
                                    vm.retry(_sourceLanguage, _targetLanguage),
                                onRetake: _retake,
                              ),
                      ),
                  ],
                ),
                if (done)
                  Positioned.fill(
                    child: _WordsDrawer(
                      vm: vm,
                      targetLanguage: _targetLanguage,
                      peekHeight: drawerPeek,
                      availableHeight: constraints.maxHeight,
                      onRetake: _retake,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred language dropdowns with back on the left (room kept free on the
/// right so they stay centred).
class _TopBar extends StatelessWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final List<String> recentLanguages;
  final bool locked;
  final VoidCallback onBack;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<String?> onTargetChanged;
  final VoidCallback onSwap;

  const _TopBar({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.recentLanguages,
    required this.locked,
    required this.onBack,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSwap,
  });

  static const double _height = 40;
  static const double _swapWidth = 32;
  static const double _maxDropdownWidth = 132;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = _height + 8;
        final dropdownWidth = math.min(
          _maxDropdownWidth,
          (constraints.maxWidth - 2 * side - _swapWidth) / 2,
        );
        return SizedBox(
          height: _height,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: _GlassCircleButton(
                  tooltip: 'Back',
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: onBack,
                  size: _height,
                  iconSize: 18,
                ),
              ),
              Center(
                child: IgnorePointer(
                  ignoring: locked,
                  child: Opacity(
                    opacity: locked ? 0.6 : 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: dropdownWidth,
                          child: LanguageDropdown(
                            value: sourceLanguage,
                            recentLanguages: recentLanguages,
                            showIcons: false,
                            dense: true,
                            onChanged: onSourceChanged,
                          ),
                        ),
                        SizedBox(
                          width: _swapWidth,
                          child: IconButton(
                            tooltip: 'Swap languages',
                            onPressed: onSwap,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: dropdownWidth,
                          child: LanguageDropdown(
                            value: targetLanguage,
                            recentLanguages: recentLanguages,
                            showIcons: false,
                            dense: true,
                            onChanged: onTargetChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const _GlassPanel({
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassThemeExtension>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glass?.baseGlassColor ?? Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color:
                  glass?.borderGlassColor ??
                  Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    // Border drawn on top so the camera fills the card edge to edge.
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

/// Camera preview filling the card; tap to focus, pinch to zoom.
class _Viewfinder extends StatelessWidget {
  final CameraController? camera;
  final _CameraState state;
  final Offset? focusPoint;
  final ValueChanged<Offset> onFocus;
  final VoidCallback onPinchStart;
  final ValueChanged<double> onPinchUpdate;

  const _Viewfinder({
    required this.camera,
    required this.state,
    required this.focusPoint,
    required this.onFocus,
    required this.onPinchStart,
    required this.onPinchUpdate,
  });

  static const double _focusRingSize = 68;

  @override
  Widget build(BuildContext context) {
    final camera = this.camera;
    if (state == _CameraState.denied) {
      return const _CameraMessage(
        icon: Icons.no_photography_rounded,
        title: 'Camera access is off',
        message:
            'Allow camera access for Translate App in Settings > Privacy > '
            'Camera, or pick a photo from your gallery.',
      );
    }
    if (state == _CameraState.unavailable) {
      return const _CameraMessage(
        icon: Icons.no_photography_rounded,
        title: 'Camera unavailable',
        message:
            'The camera could not be started on this device. You can still '
            'pick a photo from your gallery.',
      );
    }
    if (camera == null || state == _CameraState.starting) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    final focusPoint = this.focusPoint;
    return LayoutBuilder(
      builder: (context, constraints) {
        // previewSize is landscape; the preview is shown portrait.
        final previewSize = camera.value.previewSize;
        final aspect = previewSize == null
            ? 9 / 16
            : previewSize.height / previewSize.width;
        final box = constraints.biggest;
        final width = box.width / box.height > aspect
            ? box.width
            : box.height * aspect;
        final size = Size(width, width / aspect);

        return ClipRect(
          child: OverflowBox(
            minWidth: size.width,
            maxWidth: size.width,
            minHeight: size.height,
            maxHeight: size.height,
            child: CameraPreview(
              camera,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => onFocus(
                        Offset(
                          (details.localPosition.dx / size.width).clamp(0, 1),
                          (details.localPosition.dy / size.height).clamp(0, 1),
                        ),
                      ),
                      onScaleStart: (_) => onPinchStart(),
                      onScaleUpdate: (details) {
                        if (details.pointerCount >= 2) {
                          onPinchUpdate(details.scale);
                        }
                      },
                    ),
                  ),
                  if (focusPoint != null)
                    Positioned(
                      left: focusPoint.dx * size.width - _focusRingSize / 2,
                      top: focusPoint.dy * size.height - _focusRingSize / 2,
                      width: _focusRingSize,
                      height: _focusRingSize,
                      child: const IgnorePointer(child: _FocusRing()),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FocusRing extends StatelessWidget {
  const _FocusRing();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.25, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CameraMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlignmentHint extends StatelessWidget {
  const _AlignmentHint();

  @override
  Widget build(BuildContext context) {
    return const _GlassPanel(
      child: Row(
        children: [
          Icon(Icons.crop_free_rounded, color: Colors.white70, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hold the phone straight and parallel to the text for the best fit.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraControls extends StatelessWidget {
  final bool enabled;
  final bool capturing;
  final bool galleryEnabled;
  final FlashMode flashMode;
  final VoidCallback onToggleFlash;
  final VoidCallback onCapture;
  final VoidCallback onPickFromGallery;

  const _CameraControls({
    required this.enabled,
    required this.capturing,
    required this.galleryEnabled,
    required this.flashMode,
    required this.onToggleFlash,
    required this.onCapture,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassThemeExtension>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GlassCircleButton(
          tooltip: flashMode == FlashMode.off ? 'Flash off' : 'Flash auto',
          icon: flashMode == FlashMode.off
              ? Icons.flash_off_rounded
              : Icons.flash_auto_rounded,
          onPressed: enabled ? onToggleFlash : null,
        ),
        const SizedBox(width: 36),
        Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors:
                    glass?.micGradient ??
                    const [
                      Color(0xFF89979D),
                      Color.fromARGB(255, 94, 106, 121),
                    ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enabled && !capturing ? onCapture : null,
                child: Center(
                  child: capturing
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 36),
        _GlassCircleButton(
          tooltip: 'Choose from gallery',
          icon: Icons.photo_library_rounded,
          onPressed: galleryEnabled ? onPickFromGallery : null,
        ),
      ],
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  const _GlassCircleButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _GlassPanel(
        radius: size / 2,
        padding: EdgeInsets.zero,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

/// Frozen photo with each translation drawn over its line at its angle.
/// Labels are laid out in screen points: at photo scale the selection
/// handles and Copy menu came out tiny and far from the text.
class _PhotoCanvas extends StatelessWidget {
  final PhotoTranslateViewModel vm;
  final bool rightToLeft;

  const _PhotoCanvas({required this.vm, required this.rightToLeft});

  @override
  Widget build(BuildContext context) {
    final image = vm.image;
    if (image == null) return const SizedBox.expand();
    final showLabels =
        vm.status == PhotoTranslateStatus.done && !vm.showOriginal;

    return SelectionArea(
      child: InteractiveViewer(
        maxScale: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final area = Offset.zero & constraints.biggest;
            final imageSize = Size(
              image.width.toDouble(),
              image.height.toDouble(),
            );
            // Camera shots fill the card like the preview; other photos are shown whole.
            final photoAspect = imageSize.width / imageSize.height;
            final cardAspect = area.width / area.height;
            final fitted = applyBoxFit(
              (photoAspect / cardAspect - 1).abs() < 0.08
                  ? BoxFit.cover
                  : BoxFit.contain,
              imageSize,
              constraints.biggest,
            );
            final photo = Alignment.center.inscribe(fitted.destination, area);

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned.fromRect(
                    rect: photo,
                    child: RawImage(image: image, fit: BoxFit.fill),
                  ),
                  if (vm.status == PhotoTranslateStatus.translating)
                    Positioned.fromRect(
                      rect: photo,
                      child: CustomPaint(
                        painter: _LineOutlinePainter(
                          blocks: vm.blocks,
                          strokeWidth: 1.5,
                        ),
                      ),
                    ),
                  if (showLabels)
                    for (final block in vm.blocks)
                      if (block.translation.isNotEmpty)
                        _placeLabel(block, photo),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _placeLabel(PhotoTextBlock block, Rect photo) {
    final points = [
      for (final c in block.corners)
        Offset(
          photo.left + c.dx * photo.width,
          photo.top + c.dy * photo.height,
        ),
    ];
    final along = points[1] - points[0];
    final across = points[3] - points[0];
    final center = (points[0] + points[2]) / 2;
    final labelWidth = along.distance;
    final labelHeight = across.distance;

    return Positioned(
      left: center.dx - labelWidth / 2,
      top: center.dy - labelHeight / 2,
      width: labelWidth,
      height: labelHeight,
      child: Transform.rotate(
        angle: math.atan2(along.dy, along.dx),
        child: _TranslationLabel(
          text: block.translation,
          background: block.background,
          foreground: block.foreground,
          width: labelWidth,
          height: labelHeight,
          rightToLeft: rightToLeft,
        ),
      ),
    );
  }
}

class _LineOutlinePainter extends CustomPainter {
  final List<PhotoTextBlock> blocks;
  final double strokeWidth;

  const _LineOutlinePainter({required this.blocks, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final block in blocks) {
      final points = [
        for (final c in block.corners)
          Offset(c.dx * size.width, c.dy * size.height),
      ];
      canvas.drawPath(Path()..addPolygon(points, true), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineOutlinePainter oldDelegate) =>
      !identical(oldDelegate.blocks, blocks) ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Translation over its line in the photo's own colors, at the largest
/// font size that fits.
class _TranslationLabel extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final double width;
  final double height;
  final bool rightToLeft;

  const _TranslationLabel({
    required this.text,
    required this.background,
    required this.foreground,
    required this.width,
    required this.height,
    required this.rightToLeft,
  });

  static const double _lineHeight = 1.15;

  @override
  Widget build(BuildContext context) {
    final padding = height * 0.08;
    final direction = rightToLeft ? TextDirection.rtl : TextDirection.ltr;
    final style = TextStyle(
      color: foreground,
      fontSize: _fittingFontSize(
        width - 2 * padding,
        height - 2 * padding,
        direction,
      ),
      height: _lineHeight,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: EdgeInsets.all(padding),
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(height * 0.12),
      ),
      child: Text(
        text,
        textDirection: direction,
        textScaler: TextScaler.noScaling,
        overflow: TextOverflow.clip,
        style: style,
      ),
    );
  }

  // Largest size that fits without breaking a word.
  double _fittingFontSize(
    double maxWidth,
    double maxHeight,
    TextDirection direction,
  ) {
    if (maxWidth <= 0 || maxHeight <= 0) return 1;
    var low = 1.0;
    var high = maxHeight / _lineHeight;
    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: mid,
            height: _lineHeight,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: direction,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: maxWidth);
      final fits =
          painter.height <= maxHeight && painter.minIntrinsicWidth <= maxWidth;
      painter.dispose();
      if (fits) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

/// Word list drawer: peeks under the photo, drags up to full screen.
class _WordsDrawer extends StatelessWidget {
  final PhotoTranslateViewModel vm;
  final String targetLanguage;

  /// Includes the home indicator area.
  final double peekHeight;
  final double availableHeight;
  final VoidCallback onRetake;

  const _WordsDrawer({
    required this.vm,
    required this.targetLanguage,
    required this.peekHeight,
    required this.availableHeight,
    required this.onRetake,
  });

  /// Header plus the top of the first word.
  static const double peekContentHeight = 132;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassThemeExtension>();
    final peek = (peekHeight / availableHeight).clamp(0.1, 0.5).toDouble();
    final words = vm.words;
    final lineCount = vm.blocks.length;

    return DraggableScrollableSheet(
      initialChildSize: peek,
      minChildSize: peek,
      maxChildSize: 1,
      snap: true,
      builder: (context, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D3238).withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color:
                    glass?.borderGlassColor ??
                    Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: CustomScrollView(
              controller: controller,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$lineCount '
                                '${lineCount == 1 ? 'line' : 'lines'} '
                                'translated to $targetLanguage',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            _StatusIconButton(
                              tooltip: vm.showOriginal
                                  ? 'Show translation'
                                  : 'Show original',
                              icon: vm.showOriginal
                                  ? Icons.translate_rounded
                                  : Icons.visibility_rounded,
                              onPressed: vm.toggleOriginal,
                            ),
                            _StatusIconButton(
                              tooltip: 'Retake',
                              icon: Icons.photo_camera_rounded,
                              onPressed: onRetake,
                            ),
                            _StatusIconButton(
                              tooltip: 'Close',
                              icon: Icons.close_rounded,
                              onPressed: () => Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Row(
                          children: [
                            const Text(
                              'Words',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${words.length}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (words.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
                      child: Text(
                        'No words to add were found in this photo.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: words.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, i) => _WordRow(word: words[i]),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final PhotoWord word;

  const _WordRow({required this.word});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: word.word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '  →  ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  TextSpan(
                    text: word.translation,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          IconButton(
            tooltip: 'Add to deck',
            onPressed: () =>
                DeckSelectorSheet.show(context, word.word, word.translation),
            icon: Icon(
              Icons.library_add_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final PhotoTranslateViewModel vm;
  final String targetLanguage;
  final VoidCallback onRetry;
  final VoidCallback onRetake;

  const _StatusBar({
    required this.vm,
    required this.targetLanguage,
    required this.onRetry,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final exception = vm.exception;
    final done = vm.status == PhotoTranslateStatus.done;
    final (
      IconData? icon,
      String message,
      Widget? action,
    ) = switch (vm.status) {
      PhotoTranslateStatus.camera => (null, '', null),
      PhotoTranslateStatus.reading => (null, 'Reading text…', null),
      PhotoTranslateStatus.translating => (
        null,
        'Translating ${vm.blocks.length} '
            '${vm.blocks.length == 1 ? 'line' : 'lines'}…',
        null,
      ),
      PhotoTranslateStatus.done => (
        Icons.check_circle_rounded,
        '${vm.blocks.length} '
            '${vm.blocks.length == 1 ? 'line' : 'lines'} translated to '
            '$targetLanguage',
        null,
      ),
      PhotoTranslateStatus.noText => (
        Icons.search_off_rounded,
        'No text found. Try a closer, sharper photo, or check the source '
            'language.',
        _ActionButton(label: 'Retake', onPressed: onRetake),
      ),
      PhotoTranslateStatus.error => (
        Icons.error_outline_rounded,
        _errorMessage(vm, exception),
        !vm.hasPhoto
            ? _ActionButton(label: 'Retake', onPressed: onRetake)
            : _canRetry(exception)
            ? _ActionButton(label: 'Retry', onPressed: onRetry)
            : null,
      ),
    };

    return _GlassPanel(
      child: Row(
        children: [
          if (vm.isBusy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else if (icon != null)
            Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          ?action,
          if (done)
            _StatusIconButton(
              tooltip: vm.showOriginal ? 'Show translation' : 'Show original',
              icon: vm.showOriginal
                  ? Icons.translate_rounded
                  : Icons.visibility_rounded,
              onPressed: vm.toggleOriginal,
            ),
          if (!vm.isBusy &&
              (action is! _ActionButton || action.label != 'Retake'))
            _StatusIconButton(
              tooltip: 'Retake',
              icon: Icons.photo_camera_rounded,
              onPressed: onRetake,
            ),
        ],
      ),
    );
  }

  static bool _canRetry(AppException? e) =>
      e is! FeatureNotAvailableException &&
      e is! AuthException &&
      e is! UnsupportedLanguageException;

  static String _errorMessage(PhotoTranslateViewModel vm, AppException? e) {
    if (!vm.hasPhoto) return 'Could not open the photo. Please retake it.';
    if (e is UnsupportedLanguageException) {
      return "Text in ${e.language ?? 'this language'} can't be read from "
          'photos yet. Choose another source language.';
    }
    // No lines: reading failed, not the translation.
    if (vm.blocks.isEmpty) return 'Could not read the text. Please try again.';
    if (e is NetworkException) return 'No internet connection.';
    if (e is QuotaExceededException) {
      return 'Too many photo translations. Wait a few seconds and retry.';
    }
    if (e is FeatureNotAvailableException) {
      return 'Photo translation is available on the Standard plan.';
    }
    if (e is AuthException) return 'Restart the app or sign in to continue.';
    return 'Translation failed. Please try again.';
  }
}

class _StatusIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _StatusIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
