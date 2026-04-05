import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/viewmodels/favorite_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/widgets/deck_selector_sheet.dart';
import 'package:translate_app/data/services/tts_service.dart';

class OutputScreen extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const OutputScreen({
    super.key,
    required this.controller,
    this.hintText = 'Translation',
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);

    return AnimatedBuilder(
      animation: Listenable.merge([viewModel.pageController, controller]),
      builder: (context, _) {
        const double fontSize = 22;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Stack(
            children: [
              _buildTranslationField(fontSize),
              if (controller.text.isNotEmpty)
                _buildActionButtons(context, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTranslationField(double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 48),
      child: TextField(
        controller: controller,
        readOnly: true,
        maxLines: null,
        minLines: 1,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MainViewModel mainVM) {
    return Positioned(
      bottom: 0,
      left: 4,
      right: 4,
      child: Row(
        children: [
          if (!mainVM.isMLPage) ...[
            _ToneDropdown(controller: controller),
            const SizedBox(width: 6),
            _actionIcon(context, Icons.auto_awesome_rounded, "Translate"),
          ],
          const Spacer(),
          _TtsButton(mainVM: mainVM, text: controller.text),
          _DeckAddButton(mainVM: mainVM, translation: controller.text),
          _FavoriteButton(mainVM: mainVM, translation: controller.text),
        ],
      ),
    );
  }

  Widget _actionIcon(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () =>
          context.read<GeminiTranslateViewModel>().translate(controller),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToneDropdown extends StatelessWidget {
  final TextEditingController controller;
  const _ToneDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<GeminiTranslateViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: viewModel.selectedToneIndex,
              onChanged: (value) =>
                  viewModel.setSelectedToneIndex(value!, controller),
              dropdownColor: const Color(0xFF2D3238),
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white70,
                size: 16,
              ),
              items: const [
                DropdownMenuItem(
                  value: 0,
                  child: Text(
                    "Standard",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text(
                    "Formal",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(
                    "Slang",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeckAddButton extends StatelessWidget {
  final MainViewModel mainVM;
  final String translation;
  const _DeckAddButton({required this.mainVM, required this.translation});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40),
      onPressed: () {
        final word = mainVM.isMLPage
            ? Provider.of<MLTranslateViewModel>(
                context,
                listen: false,
              ).textController.text
            : Provider.of<GeminiTranslateViewModel>(
                context,
                listen: false,
              ).textController.text;
        DeckSelectorSheet.show(context, word, translation);
      },
      icon: Icon(
        Icons.library_add_rounded,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final MainViewModel mainVM;
  final String translation;
  const _FavoriteButton({required this.mainVM, required this.translation});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteViewModel>(
      builder: (context, favVM, _) {
        final mlVM = Provider.of<MLTranslateViewModel>(context, listen: false);
        final geminiVM = Provider.of<GeminiTranslateViewModel>(
          context,
          listen: false,
        );
        final word = mainVM.isMLPage
            ? mlVM.textController.text
            : geminiVM.textController.text;
        final isFav = favVM.isFavorite(word);

        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40),
          onPressed: () {
            if (word.isNotEmpty && translation.isNotEmpty) {
              favVM.toggleFavorite(
                word: word,
                translation: translation,
                isGemini: !mainVM.isMLPage,
              );
              if (mainVM.isMLPage) mlVM.saveHistoryNow(translation);
            }
          },
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav
                ? Colors.redAccent
                : Colors.white.withValues(alpha: 0.7),
          ),
        );
      },
    );
  }
}

class _TtsButton extends StatelessWidget {
  final MainViewModel mainVM;
  final String text;
  const _TtsButton({required this.mainVM, required this.text});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40),
      onPressed: () {
        final tts = context.read<TtsService>();
        final language = mainVM.isMLPage
            ? Provider.of<MLTranslateViewModel>(
                context,
                listen: false,
              ).targetLanguage
            : Provider.of<GeminiTranslateViewModel>(
                context,
                listen: false,
              ).targetLanguage;
        tts.speak(text, language);
      },
      icon: Icon(
        Icons.volume_up_rounded,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}
