import 'package:flutter/material.dart';
import 'package:translate_app/components/dropdown.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:translate_app/components/ml_languages.dart';
import 'package:translate_app/services/dictionary_service.dart';
import 'dart:async';

class MLTranslatePage extends StatefulWidget {
  final String? initialText;
  final TextEditingController outputController;

  const MLTranslatePage({
    super.key,
    this.initialText,
    required this.outputController,
  });

  @override
  State<MLTranslatePage> createState() => _MLTranslatePageState();
}

class _MLTranslatePageState extends State<MLTranslatePage> {
  final DictionaryService _dictionaryService = DictionaryService();
  final TextEditingController _textController = TextEditingController();
  late final TextEditingController _outputController;
  OnDeviceTranslator? _onDeviceTranslator;

  String _sourceLanguage = 'English';
  String _targetLanguage = '-';
  bool _isLoading = false;
  String? _spellingCorrection;
  String? _downloadingLanguage;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _outputController = widget.outputController;
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
      _handleTranslate();
    }
    _initSpeech();
  }

  void _onTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (text.isEmpty) {
        setState(() {
          _outputController.text = '';
          _spellingCorrection = null;
        });
      } else {
        _handleTranslate();
      }
    });
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
      if (_textController.text.isNotEmpty) {
        _handleTranslate();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _onDeviceTranslator?.close();
    super.dispose();
  }

  Future<void> _checkAndDownloadModel(String languageName) async {
    if (languageName == '-') return;

    final bcpCode = MlLanguages.mapNameToBCP(languageName);
    final modelManager = OnDeviceTranslatorModelManager();
    final isDownloaded = await modelManager.isModelDownloaded(bcpCode);

    if (!isDownloaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$languageName package downloading...',
              textAlign: TextAlign.center,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() => _downloadingLanguage = languageName);

      try {
        if (!(await _dictionaryService.isDictionaryDownloaded(bcpCode))) {
          await _dictionaryService.downloadDictionary(bcpCode);
        }
        await modelManager.downloadModel(bcpCode);
      } catch (e) {
        // Hata durumunda sessizce devam et veya logla
        debugPrint('Download error: $e');
      } finally {
        if (mounted) {
          setState(() => _downloadingLanguage = null);
          _handleTranslate();
        }
      }
    }
  }

  Future<void> _handleTranslate() async {
    if (_textController.text.isEmpty ||
        _targetLanguage == '-' ||
        _sourceLanguage == '-') {
      setState(() {
        if (_textController.text.isEmpty) {
          _outputController.text = '';
          _spellingCorrection = null;
        }
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

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

      setState(
        () =>
            _spellingCorrection = (correctedText != originalText.toLowerCase())
            ? correctedText
            : null,
      );

      _onDeviceTranslator?.close();
      _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: targetLang,
      );

      final String? response = await _onDeviceTranslator?.translateText(
        correctedText, // Orijinal metin yerine düzeltilmiş halini çeviriyoruz
      );
      setState(() {
        _outputController.text = response ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
          _handleTranslate();
        });
      },
    );
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        minLines: 1,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 26,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter text',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            8,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: _onTextChanged,
                      ),
                      if (_spellingCorrection != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Material(
                            color: Theme.of(context).colorScheme.inversePrimary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _textController.text = _spellingCorrection!;
                                  _spellingCorrection = null;
                                  _handleTranslate();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text.rich(
                                        TextSpan(
                                          text: 'Did you mean: ',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .inversePrimary
                                                .withValues(alpha: 0.7),
                                            fontSize: 13,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: _spellingCorrection,
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (_textController.text.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(
                          context,
                        ).colorScheme.inversePrimary.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _textController.clear();
                          _outputController.clear();
                          _spellingCorrection = null;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildControlRow(),
        ],
      ),
    );
  }

  Widget _buildControlRow() {
    return SizedBox(
      height: 55,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: !_speechEnabled || _isLoading
                  ? null
                  : (_speechToText.isListening
                        ? _stopListening
                        : _startListening),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              child: Icon(
                _speechToText.isListening ? Icons.stop : Icons.mic_none,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 7,
            child: Row(
              children: [
                Expanded(
                  child: LanguageDropdown(
                    value: _sourceLanguage,
                    isLoading: _downloadingLanguage == _sourceLanguage,
                    onChanged: (v) {
                      if (v == _targetLanguage) {
                        _swapLanguages();
                      } else {
                        setState(() {
                          _sourceLanguage = v!;
                        });
                        _checkAndDownloadModel(v!);
                        _handleTranslate();
                      }
                    },
                    showIcon: false,
                  ),
                ),

                SizedBox(
                  width: 40,
                  child: IconButton(
                    onPressed: _swapLanguages,
                    icon: Icon(
                      Icons.swap_horiz,
                      color: Theme.of(
                        context,
                      ).colorScheme.inversePrimary.withValues(alpha: 0.6),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),

                Expanded(
                  child: LanguageDropdown(
                    value: _targetLanguage,
                    isLoading: _downloadingLanguage == _targetLanguage,
                    onChanged: (v) {
                      if (v == _sourceLanguage) {
                        _swapLanguages();
                      } else {
                        setState(() {
                          _targetLanguage = v!;
                        });
                        _checkAndDownloadModel(v!);
                        _handleTranslate();
                      }
                    },
                    showIcon: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
