import 'package:flutter/material.dart';
import 'package:translate_app/data/services/gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translate_app/presentation/viewmodels/history_viewmodel.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/data/services/tts_service.dart';
import 'package:translate_app/data/constants/ml_languages.dart';

class GeminiTranslateViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final SpeechToText _speechToText = SpeechToText();
  final SettingsService _settingsService;
  final HistoryViewModel _historyViewModel;

  bool _isLoading = false;
  String? _error;
  late String _sourceLanguage;
  late String _targetLanguage;
  bool _speechEnabled = false;
  final TextEditingController _textController = TextEditingController();
  List<String> _results = [];
  int _selectedToneIndex = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get sourceLanguage => _sourceLanguage;
  String get targetLanguage => _targetLanguage;
  bool get speechEnabled => _speechEnabled;
  bool get isListening => _speechToText.isListening;
  TextEditingController get textController => _textController;
  List<String> get recentLanguages => _settingsService.recentLanguages;
  int get selectedToneIndex => _selectedToneIndex;

  GeminiTranslateViewModel(this._settingsService, this._historyViewModel) {
    _sourceLanguage = 'Turkish'; // Varsayılan kaynak dil
    _targetLanguage = _settingsService.geminiTargetLang;
    _initSpeech();
  }

  void setSourceLanguage(String language) {
    _sourceLanguage = language;
    _settingsService.addRecentLanguage(language);
    notifyListeners();
  }

  void setTargetLanguage(String language) {
    _targetLanguage = language;
    _settingsService.setGeminiTargetLang(language);
    _settingsService.addRecentLanguage(language);
    notifyListeners();
  }

  void swapLanguages(TextEditingController outputController) {
    final temp = _sourceLanguage;
    _sourceLanguage = _targetLanguage;
    _targetLanguage = temp;

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
    if (_textController.text.isEmpty || _targetLanguage == '-') {
      if (_textController.text.isEmpty) {
        outputController.text = '';
      }
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _geminiService.translateText(
        _textController.text,
        _targetLanguage,
      );
      _results = response;
      _updateOutputText(outputController);

      if (outputController.text.isNotEmpty) {
        final trimmedWord = _textController.text.trim();
        final trimmedTranslation = outputController.text.trim();

        if (trimmedWord.isNotEmpty) {
          _historyViewModel.addHistoryItem(
            word: trimmedWord,
            translation: trimmedTranslation,
            isGemini: true,
          );
        }
      }
    } catch (e) {
      _error = _handleError(e);
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _handleError(dynamic e) {
    String message = e.toString().toLowerCase();

    if (message.contains('503') || message.contains('service unavailable')) {
      return 'AI servers are currently overloaded. Please wait a few seconds and try again.';
    }
    if (message.contains('429') || message.contains('too many requests')) {
      return 'Too many requests! Please wait 1 minute and try again (Quota Limit).';
    }
    if (message.contains('quota') || message.contains('exhausted')) {
      return 'Daily AI limit reached. Please try again tomorrow or use Basic mode.';
    }

    return 'An error occurred: $e';
  }

  void clear(TextEditingController outputController) {
    _textController.clear();
    outputController.clear();
    _results = [];
    notifyListeners();
  }

  Future<void> speakInputText(TtsService tts) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      await tts.speak(text, _sourceLanguage);
    } catch (e) {
      debugPrint('Speak error: $e');
      await tts.speak(text, 'English');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
