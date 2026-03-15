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
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (value.isEmpty) outputController.clear();
          },
        ),
        if (viewModel.textController.text.isNotEmpty)
          Positioned(
            bottom: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  onPressed: () =>
                      viewModel.speakInputText(context.read<TtsService>()),
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
          Positioned(
            bottom: 8,
            left: 16,
            child: Text(
              viewModel.error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        if (viewModel.isListening)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: LanguageDropdown(
              value: geminiVM.sourceLanguage,
              recentLanguages: geminiVM.recentLanguages,
              showIcons: false,
              showHeader: true,
              onChanged: (v) => geminiVM.setSourceLanguage(v!),
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
              showHeader: true,
              onChanged: (v) => geminiVM.setTargetLanguage(v!),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ElevatedButton(
                  onPressed: geminiVM.isLoading
                      ? null
                      : () => geminiVM.translate(outputController),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: geminiVM.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
