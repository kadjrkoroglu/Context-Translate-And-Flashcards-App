import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/widgets/dropdown.dart';
import 'package:translate_app/presentation/widgets/speech_toggle_button.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';

class GeminiTranslatePage extends StatelessWidget {
  final TextEditingController outputController;

  const GeminiTranslatePage({super.key, required this.outputController});

  static bool _errorDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GeminiTranslateViewModel>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: _buildLanguageRow(context, viewModel),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            color: Colors.white.withValues(alpha: 0.1),
            thickness: 0.5,
            height: 12,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              TextField(
                controller: viewModel.textController,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Enter text',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  if (value.isEmpty) outputController.clear();
                },
              ),
              if (outputController.text.isNotEmpty && !viewModel.isLoading)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpeechToggleButton(
                        text: viewModel.textController.text,
                        language: viewModel.sourceLanguage,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        onPressed: () => viewModel.clear(outputController),
                      ),
                    ],
                  ),
                ),
              if (viewModel.error != null)
                Builder(
                  builder: (_) {
                    _showTranslationErrorDialog(context);
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageRow(
    BuildContext context,
    GeminiTranslateViewModel geminiVM,
  ) {
    return Stack(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: LanguageDropdown(
                  value: geminiVM.sourceLanguage,
                  recentLanguages: geminiVM.recentLanguages,
                  showIcons: false,
                  onChanged: (v) =>
                      geminiVM.setSourceLanguage(v!, outputController),
                ),
              ),
              IconButton(
                onPressed: () => geminiVM.swapLanguages(outputController),
                icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
              ),
              Expanded(
                child: LanguageDropdown(
                  value: geminiVM.targetLanguage,
                  recentLanguages: geminiVM.recentLanguages,
                  showIcons: false,
                  onChanged: (v) =>
                      geminiVM.setTargetLanguage(v!, outputController),
                ),
              ),
            ],
          ),
        ),
        if (geminiVM.isListening)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
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
              ),
            ),
          ),
      ],
    );
  }

  void _showTranslationErrorDialog(BuildContext context) {
    if (_errorDialogOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || _errorDialogOpen) return;
      _errorDialogOpen = true;
      context.read<GeminiTranslateViewModel>().clearError();
      showDialog<void>(
        context: context,
        builder: (dialogContext) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: const Text(
              'Connection Error',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  'Translation could not be completed. Try again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ).whenComplete(() => _errorDialogOpen = false);
    });
  }
}
