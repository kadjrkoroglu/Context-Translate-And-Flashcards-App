import 'package:flutter/material.dart';
import 'package:translate_app/components/dropdown.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translate_app/gemini_service.dart';

class TranslatePage extends StatefulWidget {
  final String? initialText;
  final TextEditingController outputController;
  const TranslatePage({
    super.key,
    this.initialText,
    required this.outputController,
  });

  @override
  State<TranslatePage> createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _textController = TextEditingController();
  late final TextEditingController _outputController;
  String _selectedLanguage = '-';
  bool _isLoading = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

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

  Future<void> _handleTranslate() async {
    if (_textController.text.isEmpty || _selectedLanguage == '-') {
      setState(() {
        if (_textController.text.isEmpty) {
          _outputController.text = '';
        }
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _geminiService.translateText(
        _textController.text,
        _selectedLanguage,
      );
      setState(() {
        _outputController.text = response.join('\n\n');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = e.toString();
      if (errorMessage.contains('429')) {
        errorMessage =
            'Çok hızlı gittiniz! Lütfen 1 dakika bekleyip tekrar deneyin (Kota Sınırı).';
      } else {
        errorMessage = 'Bir hata oluştu: $e';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color.fromARGB(255, 201, 64, 64),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Ferah düzen
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                TextField(
                  controller: _textController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontSize: 26,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.primary,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    hintText: 'Enter text',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _outputController.clear();
                      }
                    });
                  },
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
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 55,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: !_speechEnabled || _isLoading
                        ? null
                        : () {
                            if (_speechToText.isListening) {
                              _stopListening();
                            } else {
                              _startListening();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
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
                  flex: 2,
                  child: Stack(
                    children: [
                      LanguageDropdown(
                        value: _selectedLanguage,
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value!;
                          });
                        },
                      ),
                      if (_speechToText.isListening)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mic,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inversePrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Listening...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleTranslate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Theme.of(
                                  context,
                                ).colorScheme.inversePrimary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const Icon(Icons.translate, size: 26),
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
