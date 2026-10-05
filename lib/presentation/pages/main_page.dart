import 'package:flutter/gestures.dart' show Drag;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/pages/ml_translate_page.dart';
import 'package:translate_app/presentation/pages/gemini_translate_page.dart';
import 'package:translate_app/presentation/pages/history_page.dart';
import 'package:translate_app/presentation/pages/favorites_page.dart';
import 'package:translate_app/presentation/pages/profile_page.dart';
import 'package:translate_app/presentation/pages/decks_page.dart';
import 'package:translate_app/presentation/widgets/output_screen.dart';
import 'package:translate_app/presentation/widgets/speech_toggle_button.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/presentation/widgets/ai_consent_dialog.dart';
import 'package:translate_app/presentation/widgets/voice_scale.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/pages/photo_translate_page.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/live_translate_viewmodel.dart';
import 'package:translate_app/presentation/widgets/glass_page_selector.dart';
import 'package:translate_app/presentation/widgets/live_translate_body.dart';
import 'package:translate_app/presentation/widgets/upgrade_required_dialog.dart';
import 'package:translate_app/theme/theme.dart';
import 'dart:ui';
import 'dart:math' as math;

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);
    final mlViewModel = Provider.of<MLTranslateViewModel>(context);
    final geminiViewModel = Provider.of<GeminiTranslateViewModel>(context);
    final liveViewModel = Provider.of<LiveTranslateViewModel>(context);
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    const Color inversePrimary = Colors.white;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // viewPadding: padding.bottom is 0 while the keyboard is up (card jumped on close).
    final double safeAreaBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double bottomAreaHeight = 45 + 38;
    final double fixedGap = 15;
    final double totalBottomPadding =
        bottomAreaHeight + fixedGap + safeAreaBottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  // 8 + the ~4 px under the letters = the 12 below the selector.
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: Text(
                      'Context Translate & Flashcards',
                      style: TextStyle(
                        color: inversePrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),

                GlassPageSelector(
                  controller: viewModel.pageController,
                  page: () => viewModel.page,
                  labels: const ['Live', 'AI', 'Basic'],
                  onSelected: viewModel.animateToPage,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: math.max(totalBottomPadding, keyboardHeight + 8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              glassTheme?.baseGlassColor ??
                                  Colors.white.withValues(alpha: 0.12),
                              glassTheme?.backgroundGradient.first ??
                                  (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF2D3436)
                                      : const Color(0xFF7A8386)),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 72,
                                child: PageView(
                                  controller: viewModel.pageController,
                                  onPageChanged: (index) {
                                    // Keep restored text when history/favorites switch pages.
                                    if (!viewModel.isRestoring) {
                                      geminiViewModel.clear(
                                        viewModel.outputController,
                                      );
                                      mlViewModel.clear(
                                        viewModel.outputController,
                                      );
                                    }
                                    if (index != MainViewModel.livePage) {
                                      liveViewModel.stop();
                                    }
                                  },
                                  children: [
                                    const LiveLanguageHeader(),
                                    GeminiLanguageHeader(
                                      outputController:
                                          viewModel.outputController,
                                    ),
                                    MLLanguageHeader(
                                      outputController:
                                          viewModel.outputController,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _PageSwipeArea(
                                  controller: viewModel.pageController,
                                  child: AnimatedBuilder(
                                    animation: viewModel.pageController,
                                    // Fade between the Live and text bodies instead of a hard swap.
                                    builder: (context, _) => AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: viewModel.isLivePage
                                          ? const KeyedSubtree(
                                              key: ValueKey('live'),
                                              child: LiveTranslateBody(),
                                            )
                                          : KeyedSubtree(
                                              key: const ValueKey('text'),
                                              child: LayoutBuilder(
                                                builder: (context, constraints) {
                                                  return SingleChildScrollView(
                                                    physics:
                                                        const BouncingScrollPhysics(),
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                            minHeight:
                                                                constraints
                                                                    .maxHeight,
                                                          ),
                                                      child: IntrinsicHeight(
                                                        child: ValueListenableBuilder<TextEditingValue>(
                                                          valueListenable: viewModel
                                                              .outputController,
                                                          builder: (context, outputValue, _) {
                                                            final bool
                                                            hasOutput =
                                                                outputValue
                                                                    .text
                                                                    .isNotEmpty;

                                                            return Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                AnimatedBuilder(
                                                                  animation:
                                                                      viewModel
                                                                          .pageController,
                                                                  builder: (context, _) {
                                                                    final isML =
                                                                        viewModel
                                                                            .isMLPage;
                                                                    return isML
                                                                        ? MLInputBody(
                                                                            outputController:
                                                                                viewModel.outputController,
                                                                          )
                                                                        : GeminiInputBody(
                                                                            outputController:
                                                                                viewModel.outputController,
                                                                          );
                                                                  },
                                                                ),

                                                                // The empty space under the text opens the keyboard too.
                                                                Expanded(
                                                                  child: GestureDetector(
                                                                    behavior:
                                                                        HitTestBehavior
                                                                            .opaque,
                                                                    onTap: () =>
                                                                        (viewModel.isMLPage
                                                                                ? mlViewModel.inputFocus
                                                                                : geminiViewModel.inputFocus)
                                                                            .requestFocus(),
                                                                    child: const SizedBox(
                                                                      width: double
                                                                          .infinity,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (hasOutput &&
                                                                    !(viewModel
                                                                            .isMLPage
                                                                        ? mlViewModel
                                                                              .isLoading
                                                                        : geminiViewModel
                                                                              .isLoading))
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerRight,
                                                                    child: Transform.translate(
                                                                      offset:
                                                                          const Offset(
                                                                            0,
                                                                            10,
                                                                          ),
                                                                      child: Padding(
                                                                        padding: const EdgeInsets.only(
                                                                          right:
                                                                              8,
                                                                        ),
                                                                        child: Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            SpeechToggleButton(
                                                                              text: viewModel.isMLPage
                                                                                  ? mlViewModel.textController.text
                                                                                  : geminiViewModel.textController.text,
                                                                              language: viewModel.isMLPage
                                                                                  ? mlViewModel.sourceLanguage
                                                                                  : geminiViewModel.sourceLanguage,
                                                                            ),
                                                                            IconButton(
                                                                              icon: Icon(
                                                                                Icons.clear_rounded,
                                                                                color: Colors.white.withValues(
                                                                                  alpha: 0.5,
                                                                                ),
                                                                              ),
                                                                              onPressed: () {
                                                                                if (viewModel.isMLPage) {
                                                                                  mlViewModel.clear(
                                                                                    viewModel.outputController,
                                                                                  );
                                                                                } else {
                                                                                  geminiViewModel.clear(
                                                                                    viewModel.outputController,
                                                                                  );
                                                                                }
                                                                              },
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),

                                                                if (hasOutput)
                                                                  Padding(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8,
                                                                    ),
                                                                    child: Divider(
                                                                      color: Colors
                                                                          .white
                                                                          .withValues(
                                                                            alpha:
                                                                                0.15,
                                                                          ),
                                                                      thickness:
                                                                          0.5,
                                                                    ),
                                                                  ),

                                                                if (hasOutput)
                                                                  OutputTranslationField(
                                                                    controller:
                                                                        viewModel
                                                                            .outputController,
                                                                  ),

                                                                if (hasOutput)
                                                                  const Spacer(),
                                                                if (hasOutput)
                                                                  OutputActionButtons(
                                                                    controller:
                                                                        viewModel
                                                                            .outputController,
                                                                  ),

                                                                if (!hasOutput)
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets.only(
                                                                          top:
                                                                              6,
                                                                          bottom:
                                                                              15,
                                                                        ),
                                                                    child: _buildTranslateButton(
                                                                      viewModel,
                                                                      geminiViewModel,
                                                                    ),
                                                                  ),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildGlassMicrophoneButton(
        context,
        viewModel,
        mlViewModel,
        geminiViewModel,
        liveViewModel,
        inversePrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(context, inversePrimary),
    );
  }

  Widget _buildGlassMicrophoneButton(
    BuildContext context,
    MainViewModel viewModel,
    MLTranslateViewModel mlVM,
    GeminiTranslateViewModel gVM,
    LiveTranslateViewModel liveVM,
    Color inversePrimary,
  ) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    final level = viewModel.isLivePage
        ? liveVM.soundLevel
        : viewModel.isMLPage
        ? mlVM.soundLevel
        : gVM.soundLevel;
    final listening = viewModel.isLivePage
        ? liveVM.isActive
        : viewModel.isMLPage
        ? mlVM.isListening
        : gVM.isListening;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors:
              glassTheme?.micGradient ??
              [
                const Color(0xFF89979D),
                const Color.fromARGB(255, 94, 106, 121),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (viewModel.isLivePage) {
              if (liveVM.isActive) {
                liveVM.stop();
              } else if (await _ensureLiveAccess(context) &&
                  context.mounted &&
                  await ensureAiConsent(context)) {
                liveVM.start();
              }
              return;
            }
            if (viewModel.isMLPage) {
              mlVM.isListening
                  ? mlVM.stopListening()
                  : mlVM.startListening(viewModel.outputController);
            } else {
              gVM.isListening ? gVM.stopListening() : gVM.startListening();
            }
          },
          customBorder: const CircleBorder(),
          child: VoiceScale(
            level: level,
            active: listening,
            child: Icon(
              liveVM.isActive ? Icons.stop_rounded : Icons.mic_rounded,
              color: mlVM.isListening || gVM.isListening || liveVM.isActive
                  ? Colors.redAccent
                  : Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, Color ip) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 45,
      color: glassTheme?.baseGlassColor ?? Colors.white.withValues(alpha: 0.1),
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      notchMargin: 12,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(context, Icons.history_rounded, const HistoryPage()),
            _navIcon(context, Icons.favorite_rounded, const FavoritesPage()),
            const SizedBox(width: 50),
            _navIcon(context, Icons.quiz_rounded, const DecksPage()),
            _navIcon(context, Icons.person_rounded, const ProfilePage()),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, Widget page) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 28),
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }

  Widget _buildTranslateButton(
    MainViewModel viewModel,
    GeminiTranslateViewModel gVM,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        viewModel.pageController,
        gVM,
        gVM.textController,
      ]),
      builder: (context, _) {
        final isMLPage = viewModel.isMLPage;
        final hasText = gVM.textController.text.isNotEmpty;

        return AnimatedOpacity(
          opacity: isMLPage ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: isMLPage || gVM.isLoading,
            // Translate centred; camera and clear 15 px from the sides, like the bottom gap.
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 15,
                    // Hidden as soon as Translate is pressed.
                    child: AnimatedOpacity(
                      opacity: gVM.isLoading ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: _buildCornerButton(
                        Icons.photo_camera_rounded,
                        () => _openPhotoTranslate(context, gVM),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    // Clears what was typed; hidden with no text or while translating.
                    child: AnimatedOpacity(
                      opacity: gVM.isLoading || !hasText ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !hasText,
                        child: _buildCornerButton(
                          Icons.close_rounded,
                          () => gVM.clear(viewModel.outputController),
                        ),
                      ),
                    ),
                  ),
                  _buildTranslateButtonBody(context, viewModel, gVM),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCornerButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 42,
      height: 42,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }

  // Checked on the mic press; non-Premium gets the plans screen (offline passes).
  Future<bool> _ensureLiveAccess(BuildContext context) async {
    final entitlementsVM = context.read<EntitlementsViewModel>();
    if (entitlementsVM.entitlements?.entitlements.live != true) {
      await entitlementsVM.load();
    }
    if (!context.mounted) return false;
    final entitlements = entitlementsVM.entitlements;
    if (entitlements != null && !entitlements.entitlements.live) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpgradePage()),
      );
      return false;
    }
    return true;
  }

  // A cached "not allowed" is re-checked so an upgrade shows up at once.
  Future<void> _openPhotoTranslate(
    BuildContext context,
    GeminiTranslateViewModel gVM,
  ) async {
    final entitlementsVM = context.read<EntitlementsViewModel>();
    if (entitlementsVM.entitlements?.entitlements.photo != true) {
      await entitlementsVM.load();
    }
    if (!context.mounted) return;

    final entitlements = entitlementsVM.entitlements;
    // Unknown (e.g. offline) is let through; the backend enforces the tier.
    if (entitlements != null && !entitlements.entitlements.photo) {
      showUpgradeRequiredDialog(
        context,
        title: 'Photo Translation',
        message:
            'Translating text in photos is available on the Standard and '
            'Premium plans.',
      );
      return;
    }
    if (gVM.targetLanguage == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a target language first.')),
      );
      return;
    }
    if (!await ensureAiConsent(context) || !context.mounted) return;
    await PhotoTranslatePage.open(context);
  }

  Widget _buildTranslateButtonBody(
    BuildContext context,
    MainViewModel viewModel,
    GeminiTranslateViewModel gVM,
  ) {
    return SizedBox(
      height: 42,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton(
            onPressed: () async {
              if (!await ensureAiConsent(context)) return;
              gVM.translate(viewModel.outputController);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: gVM.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Translate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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

/// Swiping anywhere on the card body switches Live / AI / Basic, like the header.
class _PageSwipeArea extends StatefulWidget {
  final PageController controller;
  final Widget child;

  const _PageSwipeArea({required this.controller, required this.child});

  @override
  State<_PageSwipeArea> createState() => _PageSwipeAreaState();
}

class _PageSwipeAreaState extends State<_PageSwipeArea> {
  Drag? _drag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        if (!widget.controller.hasClients) return;
        // Same width as the header's PageView, so the page follows the finger.
        _drag = widget.controller.position.drag(details, () => _drag = null);
      },
      onHorizontalDragUpdate: (details) => _drag?.update(details),
      onHorizontalDragEnd: (details) => _drag?.end(details),
      onHorizontalDragCancel: () => _drag?.cancel(),
      child: widget.child,
    );
  }
}
