import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translate_app/data/services/dictionary_service.dart';
import 'package:translate_app/data/constants/ml_languages.dart';

class MLTranslateViewModel extends ChangeNotifier {
  final DictionaryService _dictionaryService = DictionaryService();
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _textController = TextEditingController();

  OnDeviceTranslator? _onDeviceTranslator;
  String _sourceLanguage = 'English';
  String _targetLanguage = '-';
  bool _isLoading = false;
  String? _spellingCorrection;
  String? _downloadingLanguage;
  bool _speechEnabled = false;
  Timer? _debounce;

  TextEditingController get textController => _textController;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  bool get isLoading => _isLoading;
  String? get spellingCorrection => _spellingCorrection;
  String? get downloadingLanguage => _downloadingLanguage;
  bool get speechEnabled => _speechEnabled;
  bool get isListening => _speechToText.isListening;

  MLTranslateViewModel() {
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  void onTextChanged(String text, TextEditingController outputController) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (text.isEmpty) {
        outputController.text = '';
        _spellingCorrection = null;
        notifyListeners();
      } else {
        translate(outputController);
      }
    });
  }

  void swapLanguages(TextEditingController outputController) {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;
    if (_textController.text.isNotEmpty) {
      translate(outputController);
    }
    notifyListeners();
  }

  void setSourceLanguage(
    String language,
    TextEditingController outputController,
  ) {
    if (language == _targetLanguage) {
      swapLanguages(outputController);
    } else {
      _sourceLanguage = language;
      checkAndDownloadModel(language, outputController);
      translate(outputController);
    }
    notifyListeners();
  }

  void setTargetLanguage(
    String language,
    TextEditingController outputController,
  ) {
    if (language == _sourceLanguage) {
      swapLanguages(outputController);
    } else {
      _targetLanguage = language;
      checkAndDownloadModel(language, outputController);
      translate(outputController);
    }
    notifyListeners();
  }

  Future<void> checkAndDownloadModel(
    String languageName,
    TextEditingController outputController,
  ) async {
    if (languageName == '-') return;

    final bcpCode = MlLanguages.mapNameToBCP(languageName);
    final modelManager = OnDeviceTranslatorModelManager();
    final isDownloaded = await modelManager.isModelDownloaded(bcpCode);

    if (!isDownloaded) {
      _downloadingLanguage = languageName;
      notifyListeners();

      try {
        if (!(await _dictionaryService.isDictionaryDownloaded(bcpCode))) {
          await _dictionaryService.downloadDictionary(bcpCode);
        }
        await modelManager.downloadModel(bcpCode);
      } catch (e) {
        debugPrint('Download error: $e');
      } finally {
        _downloadingLanguage = null;
        translate(outputController);
        notifyListeners();
      }
    }
  }

  Future<void> translate(TextEditingController outputController) async {
    if (_textController.text.isEmpty ||
        _targetLanguage == '-' ||
        _sourceLanguage == '-') {
      if (_textController.text.isEmpty) {
        outputController.text = '';
        _spellingCorrection = null;
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final sourceLang = MlLanguages.mapStringToLanguage(_sourceLanguage);
      final targetLang = MlLanguages.mapStringToLanguage(_targetLanguage);
      final sourceBcp = MlLanguages.mapNameToBCP(_sourceLanguage);

      await _dictionaryService.loadDictionary(sourceBcp);

      final originalText = _textController.text;
      final correctedText = _dictionaryService.correctSentence(
        originalText,
        sourceBcp,
      );

      _spellingCorrection = (correctedText != originalText.toLowerCase())
          ? correctedText
          : null;

      _onDeviceTranslator?.close();
      _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      final String? response = await _onDeviceTranslator?.translateText(
        correctedText,
      );
      outputController.text = response ?? '';
    } catch (e) {
      debugPrint('Translation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startListening(TextEditingController outputController) async {
    await _speechToText.listen(
      onResult: (result) {
        _textController.text = result.recognizedWords;
        translate(outputController);
      },
    );
    notifyListeners();
  }

  void stopListening() async {
    await _speechToText.stop();
    notifyListeners();
  }

  void applyCorrection(TextEditingController outputController) {
    if (_spellingCorrection != null) {
      _textController.text = _spellingCorrection!;
      _spellingCorrection = null;
      translate(outputController);
      notifyListeners();
    }
  }

  void clear(TextEditingController outputController) {
    _textController.clear();
    outputController.clear();
    _spellingCorrection = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _onDeviceTranslator?.close();
    _textController.dispose();
    super.dispose();
  }
}
