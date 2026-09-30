import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:translate_app/core/errors/app_exception.dart';
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
  List<PhotoTextBlock> _blocks = [];
  List<PhotoWord> _words = [];
  // Sent so the word list goes photo language → target language.
  String _sourceLanguage = '';
  AppException? _exception;
  bool _showOriginal = false;
  bool _disposed = false;

  PhotoTranslateStatus get status => _status;

  /// Same pixels that were read, so positions match exactly.
  ui.Image? get image => _image;
  List<PhotoTextBlock> get blocks => _blocks;

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
      _blocks = [];
      _fail(
        UnsupportedLanguageException(
          'No text reader for $sourceLanguage',
          language: sourceLanguage,
        ),
      );
      return;
    }

    _blocks = [];
    _sourceLanguage = sourceLanguage;
    _setStatus(PhotoTranslateStatus.reading);
    try {
      final lines = await _textRecognition.recognize(pixels, script);
      if (_disposed) return;
      _blocks = [
        for (final line in lines)
          PhotoTextBlock(
            text: line.text,
            translation: '',
            corners: line.corners,
            background: ui.Color(line.colors.background),
            foreground: ui.Color(line.colors.foreground),
          ),
      ];
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
    if (_blocks.isEmpty) return;
    _setStatus(PhotoTranslateStatus.translating);
    try {
      final count = _countWithinLimits();
      final result = await _translateUsecase.executePhotoLines(
        _blocks.take(count).map((b) => b.text).toList(),
        _sourceLanguage,
        targetLanguage,
      );
      if (_disposed) return;
      final translations = result.translations;
      _words = result.words;
      // Lines past the request limits keep their original text.
      _blocks = [
        for (var i = 0; i < _blocks.length; i++)
          _blocks[i].withTranslation(
            i < translations.length ? translations[i] : '',
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
    return _blocks.isEmpty
        ? readText(sourceLanguage, targetLanguage)
        : translate(targetLanguage);
  }

  int _countWithinLimits() {
    var chars = 0;
    var count = 0;
    for (final block in _blocks) {
      if (count == _maxLines || chars + block.text.length > _maxTotalChars) {
        break;
      }
      chars += block.text.length;
      count++;
    }
    return count;
  }

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
