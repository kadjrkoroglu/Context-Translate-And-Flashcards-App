import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/widgets/dropdown.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';

class MLTranslatePage extends StatelessWidget {
  final TextEditingController outputController;

  const MLTranslatePage({super.key, required this.outputController});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MLTranslateViewModel>(context);
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
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: viewModel.textController,
                            maxLines: null,
                            minLines: 1,
                            textAlignVertical: TextAlignVertical.top,
                            style: TextStyle(
                              color: inversePrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter text',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                8,
                              ),
                              border: InputBorder.none,
                            ),
                            onChanged: (text) =>
                                viewModel.onTextChanged(text, outputController),
                          ),
                          if (viewModel.spellingCorrection != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => viewModel.applyCorrection(
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
                                              text: 'Did you mean: ',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                                fontSize: 13,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: viewModel
                                                      .spellingCorrection,
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
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          onPressed: () => viewModel.clear(outputController),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildControlRow(context, viewModel, outputController),
        ],
      ),
    );
  }

  Widget _buildControlRow(
    BuildContext context,
    MLTranslateViewModel viewModel,
    TextEditingController outputController,
  ) {
    return SizedBox(
      height: 55,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: LanguageDropdown(
                  value: viewModel.sourceLanguage,
                  recentLanguages: viewModel.recentLanguages,
                  downloadedModels: viewModel.downloadedModels,
                  isLoading:
                      viewModel.downloadingLanguage == viewModel.sourceLanguage,
                  onChanged: (v) =>
                      viewModel.setSourceLanguage(v!, outputController),
                  showIcons: true,
                  showHeader: false,
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
                  downloadedModels: viewModel.downloadedModels,
                  isLoading:
                      viewModel.downloadingLanguage == viewModel.targetLanguage,
                  onChanged: (v) =>
                      viewModel.setTargetLanguage(v!, outputController),
                  showIcons: true,
                  showHeader: false,
                ),
              ),
            ],
          ),
          if (viewModel.isListening)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Listening...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
