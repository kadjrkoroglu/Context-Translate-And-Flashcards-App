import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';
import 'package:translate_app/presentation/viewmodels/history_viewmodel.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/data/constants/ml_languages.dart';

class GeminiTranslateViewModel extends ChangeNotifier {
  final TranslateUsecase _translateUsecase;
  final SpeechToText _speechToText = SpeechToText();
  final SettingsService _settingsService;
  final HistoryViewModel _historyViewModel;

  bool _isLoading = false;
  String? _error;
  AppException? _lastException;
  late String _sourceLanguage;
  late String _targetLanguage;
  bool _speechEnabled = false;
  final TextEditingController _textController = TextEditingController();
  List<String> _results = [];
  int _selectedToneIndex = 0;
  String _lastTranslateKey = '';
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppException? get lastException => _lastException;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  bool get speechEnabled => _speechEnabled;
  bool get isListening => _speechToText.isListening;
  TextEditingController get textController => _textController;
  List<String> get recentLanguages => _settingsService.recentLanguages;
  int get selectedToneIndex => _selectedToneIndex;
  List<String> get results => List.unmodifiable(_results);

  GeminiTranslateViewModel(
    this._translateUsecase,
    this._settingsService,
    this._historyViewModel,
  ) {
    _sourceLanguage = _settingsService.geminiSourceLang;
    _targetLanguage = _settingsService.geminiTargetLang;
    _initSpeech();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _lastException = null;
    notifyListeners();
  }

  void setSourceLanguage(
    String language, [
    TextEditingController? outputController,
  ]) {
    if (language == _targetLanguage) {
      if (outputController != null) {
        swapLanguages(outputController);
      } else {
        final temp = _sourceLanguage;
        _sourceLanguage = _targetLanguage;
        _targetLanguage = temp;
        _settingsService.setGeminiSourceLang(_sourceLanguage);
        _settingsService.setGeminiTargetLang(_targetLanguage);
        _settingsService.addRecentLanguage(_sourceLanguage);
        _settingsService.addRecentLanguage(_targetLanguage);
        notifyListeners();
      }
    } else {
      _sourceLanguage = language;
      _settingsService.setGeminiSourceLang(language);
      _settingsService.addRecentLanguage(language);
      notifyListeners();
    }
  }

  void setTargetLanguage(
    String language, [
    TextEditingController? outputController,
  ]) {
    if (language == _sourceLanguage) {
      if (outputController != null) {
        swapLanguages(outputController);
      } else {
        final temp = _sourceLanguage;
        _sourceLanguage = _targetLanguage;
        _targetLanguage = temp;
        _settingsService.setGeminiSourceLang(_sourceLanguage);
        _settingsService.setGeminiTargetLang(_targetLanguage);
        _settingsService.addRecentLanguage(_sourceLanguage);
        _settingsService.addRecentLanguage(_targetLanguage);
        notifyListeners();
      }
    } else {
      _targetLanguage = language;
      _settingsService.setGeminiTargetLang(language);
      _settingsService.addRecentLanguage(language);
      notifyListeners();
    }
  }

  void swapLanguages(TextEditingController outputController) {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;

    _settingsService.setGeminiSourceLang(_sourceLanguage);
    _settingsService.setGeminiTargetLang(_targetLanguage);
    _settingsService.addRecentLanguage(_sourceLanguage);
    _settingsService.addRecentLanguage(_targetLanguage);

    if (_textController.text.isNotEmpty && outputController.text.isNotEmpty) {
      final inputTemp = _textController.text;
      _textController.text = outputController.text;
      outputController.text = inputTemp;
    }

    notifyListeners();
  }

  void setSelectedToneIndex(int index, TextEditingController outputController) {
    _selectedToneIndex = index;
    _updateOutputText(outputController);
    notifyListeners();
  }

  void _updateOutputText(TextEditingController outputController) {
    if (_results.isEmpty) return;

    if (_results.length > _selectedToneIndex) {
      outputController.text = _results[_selectedToneIndex];
    } else {
      outputController.text = _results[0];
    }
  }

  bool _isInitializingSpeech = false;

  Future<void> _initSpeech() async {
    if (_speechEnabled || _isInitializingSpeech) return;

    _isInitializingSpeech = true;
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
          _speechEnabled = false;
          _isInitializingSpeech = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Speech recognition initialization failed: $e');
      _speechEnabled = false;
    } finally {
      _isInitializingSpeech = false;
      notifyListeners();
    }
  }

  Future<void> startListening() async {
    final languageCode = MlLanguages.mapNameToBCP(_sourceLanguage);
    await _speechToText.listen(
      localeId: languageCode,
      onResult: (result) {
        _textController.text = result.recognizedWords;
      },
    );
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    notifyListeners();
  }

  Future<void> translate(TextEditingController outputController) async {
    // Stop the mic first so it never conflicts with the translation call.
    if (isListening) {
      await _speechToText.stop();
    }

    if (_textController.text.isEmpty || _targetLanguage == '-') {
      if (_textController.text.isEmpty) {
        outputController.text = '';
      }
      return;
    }

    final translateKey =
        '${_textController.text.trim()}|$_sourceLanguage|$_targetLanguage';
    if (translateKey == _lastTranslateKey) return;

    _setLoading(true);
    clearError();

    try {
      final entity = await _translateUsecase.execute(
        _textController.text,
        _sourceLanguage,
        _targetLanguage,
      );
      _results = entity.translatedText.split('|').map((t) => t.trim()).toList();
      _updateOutputText(outputController);

      if (outputController.text.isNotEmpty) {
        final trimmedWord = _textController.text.trim();
        final trimmedTranslation = outputController.text.trim();

        if (trimmedWord.isNotEmpty) {
          _historyViewModel.addHistoryItem(
            word: trimmedWord,
            translation: trimmedTranslation,
            translations: List.of(_results),
            isGemini: true,
          );
        }
      }

      _lastTranslateKey = translateKey;
    } catch (e) {
      _lastException = e is AppException ? e : null;
      _setError(_handleError(e));
      _results = [];
    } finally {
      _setLoading(false);
    }
  }

  String _handleError(dynamic e) {
    if (e is NetworkException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (e is QuotaExceededException) {
      return e.isDailyLimit
          ? 'Daily AI limit reached. Try offline mode or upgrade for unlimited translations.'
          : 'Too many requests! Please wait a few seconds and try again.';
    }

    final String raw = e is AppException
        ? '${e.message} ${e.details ?? ''}'
        : e.toString();
    String message = raw.toLowerCase();

    if (message.contains('503') || message.contains('service unavailable')) {
      return 'AI servers are currently overloaded. Please wait a few seconds and try again.';
    }

    return 'An error occurred: ${e is AppException ? e.message : e}';
  }

  /// Restores a saved translation (history/favorites) with its tone variants.
  void restore({
    required String word,
    required String shown,
    required List<String> translations,
  }) {
    _textController.text = word;
    _results = translations.isNotEmpty ? List.of(translations) : [shown];
    _selectedToneIndex = math.max(0, _results.indexOf(shown));
    clearError();
    notifyListeners();
  }

  void clear(TextEditingController outputController) {
    _textController.clear();
    outputController.clear();
    _results = [];
    clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
