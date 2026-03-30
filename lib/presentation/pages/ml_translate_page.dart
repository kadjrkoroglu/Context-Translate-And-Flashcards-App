import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/widgets/dropdown.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/data/services/tts_service.dart';

class MLTranslatePage extends StatelessWidget {
  final TextEditingController outputController;

  const MLTranslatePage({super.key, required this.outputController});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MLTranslateViewModel>(context);

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
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: viewModel.textController,
                      maxLines: null,
                      minLines: 1,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Enter text',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          8,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (text) =>
                          viewModel.onTextChanged(text, outputController),
                    ),
                    if (viewModel.spellingCorrection != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                viewModel.applyCorrection(outputController),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_fix_high,
                                    size: 16,
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'Did you mean: ',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 13,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: viewModel.spellingCorrection,
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
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
                    if (viewModel.detectedLanguage != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => viewModel.applyDetectedLanguage(
                              outputController,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_fix_high,
                                    size: 16,
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'Translate from: ',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 13,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: viewModel.detectedLanguage,
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
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
                        onPressed: () {
                          context.read<TtsService>().speak(
                            viewModel.textController.text,
                            viewModel.sourceLanguage,
                          );
                        },
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageRow(BuildContext context, MLTranslateViewModel mlVM) {
    return Stack(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: LanguageDropdown(
                  value: mlVM.sourceLanguage,
                  recentLanguages: mlVM.recentLanguages,
                  downloadedModels: mlVM.downloadedModels,
                  isLoading: mlVM.downloadingLanguage == mlVM.sourceLanguage,
                  onChanged: (v) =>
                      mlVM.setSourceLanguage(v!, outputController),
                  showIcons: true,
                ),
              ),
              IconButton(
                onPressed: () => mlVM.swapLanguages(outputController),
                icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
              ),
              Expanded(
                child: LanguageDropdown(
                  value: mlVM.targetLanguage,
                  recentLanguages: mlVM.recentLanguages,
                  downloadedModels: mlVM.downloadedModels,
                  isLoading: mlVM.downloadingLanguage == mlVM.targetLanguage,
                  onChanged: (v) =>
                      mlVM.setTargetLanguage(v!, outputController),
                  showIcons: true,
                ),
              ),
            ],
          ),
        ),
        if (mlVM.isListening)
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
}
