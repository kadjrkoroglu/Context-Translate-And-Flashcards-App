import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/widgets/dropdown.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';

class MLTranslatePage extends StatelessWidget {
  final TextEditingController outputController;

  const MLTranslatePage({super.key, required this.outputController});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MLTranslateViewModel>(context);

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
                        controller: viewModel.textController,
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
                        onChanged: (text) =>
                            viewModel.onTextChanged(text, outputController),
                      ),
                      if (viewModel.spellingCorrection != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Material(
                            color: Theme.of(context).colorScheme.inversePrimary
                                .withValues(alpha: 0.08),
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
                                              text:
                                                  viewModel.spellingCorrection,
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
                if (viewModel.textController.text.isNotEmpty)
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
                      onPressed: () => viewModel.clear(outputController),
                    ),
                  ),
              ],
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: !viewModel.speechEnabled || viewModel.isLoading
                  ? null
                  : () {
                      if (viewModel.isListening) {
                        viewModel.stopListening();
                      } else {
                        viewModel.startListening(outputController);
                      }
                    },
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
                viewModel.isListening ? Icons.stop : Icons.mic_none,
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
                    value: viewModel.sourceLanguage,
                    isLoading:
                        viewModel.downloadingLanguage ==
                        viewModel.sourceLanguage,
                    onChanged: (v) =>
                        viewModel.setSourceLanguage(v!, outputController),
                    showIcon: false,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    onPressed: () => viewModel.swapLanguages(outputController),
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
                    value: viewModel.targetLanguage,
                    isLoading:
                        viewModel.downloadingLanguage ==
                        viewModel.targetLanguage,
                    onChanged: (v) =>
                        viewModel.setTargetLanguage(v!, outputController),
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
