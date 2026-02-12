import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/widgets/dropdown.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';

class TranslatePage extends StatelessWidget {
  final TextEditingController outputController;

  const TranslatePage({super.key, required this.outputController});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GeminiTranslateViewModel>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
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
                    if (value.isEmpty) {
                      outputController.clear();
                    }
                  },
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
                      onPressed: () {
                        viewModel.clear(outputController);
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
                  child: Stack(
                    children: [
                      LanguageDropdown(
                        value: viewModel.selectedLanguage,
                        onChanged: (value) {
                          viewModel.setSelectedLanguage(value!);
                        },
                      ),
                      if (viewModel.isListening)
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
                  child: ElevatedButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => viewModel.translate(outputController),
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
                    child: viewModel.isLoading
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
          if (viewModel.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                viewModel.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
