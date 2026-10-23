import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/ocr/line_grouping.dart';
import 'package:translate_app/data/ocr/ocr_core.dart';
import 'package:translate_app/data/services/text_recognition_service.dart';
import 'package:translate_app/domain/entities/photo_text_block.dart';
import 'package:translate_app/domain/entities/photo_translation.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';

enum PhotoTranslateStatus { camera, reading, translating, done, noText, error }

/// The photo is read on the device; only the text lines are sent.
class PhotoTranslateViewModel extends ChangeNotifier {
  // Same limits as the backend's POST /translate/photo.
  static const int _maxLines = 100;
  static const int _maxTotalChars = 5000;

  final TranslateUsecase _translateUsecase;
  final TextRecognitionService _textRecognition;

  PhotoTranslateViewModel(this._translateUsecase, this._textRecognition);

  PhotoTranslateStatus _status = PhotoTranslateStatus.camera;
  ui.Image? _image;
  RgbaImage? _pixels;
  // As read, one per line; [_blocks] is what's drawn (joined text as one box).
  List<PhotoTextBlock> _lines = [];
  List<List<int>> _groups = [];
  List<PhotoTextBlock> _blocks = [];
  List<PhotoWord> _words = [];
  AppException? _exception;
  bool _showOriginal = false;
  bool _disposed = false;

  PhotoTranslateStatus get status => _status;

  /// Same pixels that were read, so positions match exactly.
  ui.Image? get image => _image;
  List<PhotoTextBlock> get blocks => _blocks;
  int get lineCount => _lines.length;

  List<PhotoWord> get words => _words;
  AppException? get exception => _exception;
  bool get showOriginal => _showOriginal;
  bool get hasPhoto => _image != null;
  bool get isBusy =>
      _status == PhotoTranslateStatus.reading ||
      _status == PhotoTranslateStatus.translating;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> processCapture(
    String capturePath,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    _setStatus(PhotoTranslateStatus.reading);
    try {
      final bytes = await File(capturePath).readAsBytes();
      File(capturePath).delete().ignore();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (_disposed) {
        frame.image.dispose();
        return;
      }
      _image?.dispose();
      _image = frame.image;
      _pixels = RgbaImage(
        data!.buffer.asUint8List(),
        frame.image.width,
        frame.image.height,
      );
      _notify();
    } catch (e) {
      _fail(GeneralException('Could not open the photo', details: '$e'));
      return;
    }
    await readText(sourceLanguage, targetLanguage);
  }

  Future<void> readText(String sourceLanguage, String targetLanguage) async {
    final pixels = _pixels;
    if (pixels == null) return;
    final script = TextRecognitionService.scriptFor(sourceLanguage);
    if (script == null) {
      _lines = [];
      _blocks = [];
      _fail(
        UnsupportedLanguageException(
          'No text reader for $sourceLanguage',
          language: sourceLanguage,
        ),
      );
      return;
    }

    _lines = [];
    _blocks = [];
    _setStatus(PhotoTranslateStatus.reading);
    try {
      final lines = await _textRecognition.recognize(pixels, script);
      if (_disposed) return;
      _lines = [
        for (final line in lines)
          PhotoTextBlock(
            text: line.text,
            translation: '',
            corners: line.corners,
            background: ui.Color(line.colors.background),
            foreground: ui.Color(line.colors.foreground),
          ),
      ];
      _groups = groupLines([
        for (final line in lines)
          LineBox(_toPixels(line.corners, pixels), line.colors),
      ]);
      _blocks = _lines;
    } catch (e) {
      _fail(e is AppException ? e : GeneralException('$e'));
      return;
    }

    if (_blocks.isEmpty) {
      _setStatus(PhotoTranslateStatus.noText);
      return;
    }
    await translate(targetLanguage);
  }

  Future<void> translate(String targetLanguage) async {
    if (_lines.isEmpty) return;
    _blocks = _lines;
    _setStatus(PhotoTranslateStatus.translating);
    try {
      final count = _groupsWithinLimits();
      final result = await _translateUsecase.executePhotoBlocks([
        for (final group in _groups.take(count))
          [for (final i in group) _lines[i].text],
      ], targetLanguage);
      if (_disposed) return;
      _words = result.words;
      // Groups past the request limits keep their original text.
      _blocks = [
        for (var g = 0; g < _groups.length; g++)
          ..._drawn(
            _groups[g],
            g < result.translations.length ? result.translations[g] : null,
          ),
      ];
      _setStatus(PhotoTranslateStatus.done);
    } catch (e) {
      _fail(
        e is AppException
            ? e
            : GeneralException('Photo translation failed', details: '$e'),
      );
    }
  }

  Future<void> retry(String sourceLanguage, String targetLanguage) {
    return _lines.isEmpty
        ? readText(sourceLanguage, targetLanguage)
        : translate(targetLanguage);
  }

  /// One text over its whole group, or each line with its own translation.
  List<PhotoTextBlock> _drawn(List<int> group, List<String>? translation) {
    final lines = [for (final i in group) _lines[i]];
    if (translation == null) return lines;
    if (translation.length == 1 && lines.length > 1) {
      final pixels = _pixels!;
      final boxes = [
        for (final line in lines)
          LineBox(_toPixels(line.corners, pixels), LabelColors(0, 0)),
      ];
      return [
        PhotoTextBlock(
          text: lines.map((l) => l.text).join(' '),
          translation: translation.single,
          corners: _toUnit(enclosingCorners(boxes), pixels),
          background: lines.first.background,
          foreground: lines.first.foreground,
          lines: lines.length,
          centered: isCentered(boxes),
        ),
      ];
    }
    return [
      for (var i = 0; i < lines.length; i++)
        lines[i].withTranslation(i < translation.length ? translation[i] : ''),
    ];
  }

  // Whole groups only, within the backend's limits.
  int _groupsWithinLimits() {
    var lines = 0;
    var chars = 0;
    var count = 0;
    for (final group in _groups) {
      final length = group.fold(0, (sum, i) => sum + _lines[i].text.length);
      if (lines + group.length > _maxLines || chars + length > _maxTotalChars) {
        break;
      }
      lines += group.length;
      chars += length;
      count++;
    }
    return count;
  }

  // Grouping needs real pixels: the photo isn't square.
  static List<Offset> _toPixels(List<Offset> corners, RgbaImage image) => [
    for (final c in corners) Offset(c.dx * image.width, c.dy * image.height),
  ];

  static List<Offset> _toUnit(List<Offset> corners, RgbaImage image) => [
    for (final c in corners) Offset(c.dx / image.width, c.dy / image.height),
  ];

  void _setStatus(PhotoTranslateStatus status) {
    _status = status;
    if (status != PhotoTranslateStatus.done) _words = [];
    _exception = null;
    if (status != PhotoTranslateStatus.done) _showOriginal = false;
    _notify();
  }

  void _fail(AppException exception) {
    _status = PhotoTranslateStatus.error;
    _exception = exception;
    _notify();
  }

  void reset() {
    _image?.dispose();
    _image = null;
    _pixels = null;
    _lines = [];
    _groups = [];
    _blocks = [];
    _setStatus(PhotoTranslateStatus.camera);
  }

  void toggleOriginal() {
    _showOriginal = !_showOriginal;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _image?.dispose();
    super.dispose();
  }
}
