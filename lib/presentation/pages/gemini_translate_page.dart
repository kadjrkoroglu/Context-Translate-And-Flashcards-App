import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/widgets/dropdown.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/data/services/tts_service.dart';

class GeminiTranslatePage extends StatelessWidget {
  final TextEditingController outputController;

  const GeminiTranslatePage({super.key, required this.outputController});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GeminiTranslateViewModel>(context);
    final inversePrimary = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: viewModel.textController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: 26,
                        color: inversePrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Enter text',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) outputController.clear();
                      },
                    ),
                    if (viewModel.textController.text.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                viewModel.speakInputText(
                                  context.read<TtsService>(),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              onPressed: () =>
                                  viewModel.clear(outputController),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildActionRow(context, viewModel, outputController),
          if (viewModel.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                viewModel.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    GeminiTranslateViewModel viewModel,
    TextEditingController outputController,
  ) {
    return SizedBox(
      height: 55,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LanguageDropdown(
                  value: viewModel.sourceLanguage,
                  recentLanguages: viewModel.recentLanguages,
                  showIcons: false,
                  showHeader: true,
                  onChanged: (value) => viewModel.setSourceLanguage(value!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: IconButton(
                  onPressed: () => viewModel.swapLanguages(outputController),
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: LanguageDropdown(
                  value: viewModel.targetLanguage,
                  recentLanguages: viewModel.recentLanguages,
                  showIcons: false,
                  showHeader: true,
                  onChanged: (value) => viewModel.setTargetLanguage(value!),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => viewModel.translate(outputController),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (viewModel.isListening)
            Positioned.fill(
              child: _glassOverlay(
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic_none_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Listening...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassOverlay(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
