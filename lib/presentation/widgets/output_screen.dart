import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/viewmodels/favorite_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/widgets/deck_selector_sheet.dart';

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

    return SizedBox(
      height: 210,
      child: AnimatedBuilder(
        animation: Listenable.merge([viewModel.pageController, controller]),
        builder: (context, _) {
          final page = viewModel.pageController.hasClients
              ? (viewModel.pageController.page ?? 0)
              : 0.0;
          final fontSize = 26 - (page * 8);

          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Stack(
                  children: [
                    _buildTranslationField(fontSize),
                    if (controller.text.isNotEmpty)
                      _buildActionButtons(context, viewModel),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranslationField(double fontSize) {
    return TextField(
      controller: controller,
      readOnly: true,
      expands: true,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        contentPadding: const EdgeInsets.all(20),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MainViewModel mainVM) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Row(
        children: [
          _DeckAddButton(mainVM: mainVM, translation: controller.text),
          _FavoriteButton(mainVM: mainVM, translation: controller.text),
        ],
      ),
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
          onPressed: () {
            if (word.isNotEmpty && translation.isNotEmpty) {
              favVM.toggleFavorite(word: word, translation: translation);
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
