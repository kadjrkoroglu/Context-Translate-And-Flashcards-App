import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translate_app/data/services/dictionary_service.dart';
import 'package:translate_app/data/constants/ml_languages.dart';
import 'package:translate_app/presentation/viewmodels/history_viewmodel.dart';
import 'package:translate_app/data/services/settings_service.dart';

class MLTranslateViewModel extends ChangeNotifier {
  final DictionaryService _dictionaryService = DictionaryService();
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final SettingsService _settingsService;
  final HistoryViewModel _historyViewModel;

  OnDeviceTranslator? _onDeviceTranslator;
  late String _sourceLanguage;
  late String _targetLanguage;
  bool _isLoading = false;
  String? _spellingCorrection;
  String? _downloadingLanguage;
  bool _speechEnabled = false;
  Timer? _debounce;
  Timer? _historyTimer;
  Set<String> _downloadedModels = {};
  bool _isDownloading = false;

  TextEditingController get textController => _textController;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  bool get isLoading => _isLoading;
  String? get spellingCorrection => _spellingCorrection;
  String? get downloadingLanguage => _downloadingLanguage;
  bool get speechEnabled => _speechEnabled;
  bool get isListening => _speechToText.isListening;
  List<String> get recentLanguages => _settingsService.recentLanguages;
  Set<String> get downloadedModels => _downloadedModels;

  MLTranslateViewModel(this._settingsService, this._historyViewModel) {
    _sourceLanguage = _settingsService.mlSourceLang;
    _targetLanguage = _settingsService.mlTargetLang;
    _initSpeech();
    fetchDownloadedModels();
  }

  Future<void> fetchDownloadedModels() async {
    final modelManager = OnDeviceTranslatorModelManager();
    final List<String> downloaded = [];

    for (final lang in MlLanguages.languageList) {
      final bcp = MlLanguages.mapNameToBCP(lang);
      if (await modelManager.isModelDownloaded(bcp)) {
        downloaded.add(lang);
      }
    }

    _downloadedModels = downloaded.toSet();
    notifyListeners();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          notifyListeners();
        }
      },
      onError: (error) {
        notifyListeners();
      },
    );
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

    _settingsService.setMlSourceLang(_sourceLanguage);
    _settingsService.setMlTargetLang(_targetLanguage);
    _settingsService.addRecentLanguage(_sourceLanguage);
    _settingsService.addRecentLanguage(_targetLanguage);

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
      _settingsService.addRecentLanguage(language);
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
      _settingsService.addRecentLanguage(language);
      checkAndDownloadModel(language, outputController);
      translate(outputController);
    }
    notifyListeners();
  }

  Future<void> checkAndDownloadModel(
    String languageName,
    TextEditingController outputController,
  ) async {
    if (languageName == '-' || _isDownloading) return;

    final bcpCode = MlLanguages.mapNameToBCP(languageName);
    final modelManager = OnDeviceTranslatorModelManager();
    final isDownloaded = await modelManager.isModelDownloaded(bcpCode);

    if (!isDownloaded) {
      _isDownloading = true;
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
        _isDownloading = false;
        _downloadingLanguage = null;
        await Future.delayed(const Duration(milliseconds: 200));
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
      try {
        _onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );

        final String? response = await _onDeviceTranslator?.translateText(
          correctedText,
        );
        outputController.text = response ?? '';
      } catch (e) {
        debugPrint('OnDeviceTranslator init/translate error: $e');
        outputController.text = 'Error initializing translator';
        return;
      }

      _historyTimer?.cancel();

      if (outputController.text.isNotEmpty) {
        final trimmedWord = originalText.trim();
        final trimmedTranslation = outputController.text.trim();

        if (trimmedWord.isNotEmpty) {
          _historyTimer = Timer(const Duration(seconds: 3), () {
            _historyViewModel.addHistoryItem(
              word: trimmedWord,
              translation: trimmedTranslation,
            );
          });
        }
      }
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

  void saveHistoryNow(String translation) {
    _historyTimer?.cancel();
    final word = _textController.text.trim();
    final trimmedTranslation = translation.trim();

    if (word.isNotEmpty && trimmedTranslation.isNotEmpty) {
      _historyViewModel.addHistoryItem(
        word: word,
        translation: trimmedTranslation,
      );
    }
  }

  void clear(TextEditingController outputController) {
    if (outputController.text.isNotEmpty) {
      saveHistoryNow(outputController.text);
    }

    _textController.clear();
    outputController.clear();
    _spellingCorrection = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _historyTimer?.cancel();
    _onDeviceTranslator?.close();
    _textController.dispose();
    super.dispose();
  }
}
