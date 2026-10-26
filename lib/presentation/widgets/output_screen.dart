import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:translate_app/core/languages.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/example_sentence.dart';
import 'package:translate_app/presentation/viewmodels/examples_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/favorite_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/widgets/ai_consent_dialog.dart';
import 'package:translate_app/presentation/widgets/deck_selector_sheet.dart';
import 'package:translate_app/presentation/widgets/example_sentences_sheet.dart';
import 'package:translate_app/presentation/widgets/speech_toggle_button.dart';
import 'package:translate_app/presentation/utils/font_size_helper.dart';
import 'package:translate_app/presentation/utils/haptics.dart';
import 'package:translate_app/l10n/l10n.dart';

class OutputTranslationField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;

  const OutputTranslationField({
    super.key,
    required this.controller,
    this.hintText,
  });

  // Card-sized pairs only, and only for the text that was translated.
  bool _examplesFit(
    MainViewModel mainVM,
    GeminiTranslateViewModel ai,
    MLTranslateViewModel ml,
  ) {
    final output = controller.text.trim();
    if (output.isEmpty || output.length > maxCardTranslationLength) {
      return false;
    }
    if (mainVM.isMLPage) {
      return !ml.isLoading && fitsExamples(ml.textController.text);
    }
    return !ai.isLoading &&
        ai.isUpToDate &&
        fitsExamples(ai.textController.text);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);
    final ai = context.read<GeminiTranslateViewModel>();
    final ml = context.read<MLTranslateViewModel>();

    return AnimatedBuilder(
      animation: Listenable.merge([
        viewModel.pageController,
        controller,
        ai,
        ai.textController,
        ml,
        ml.textController,
      ]),
      builder: (context, _) {
        final fontSize = FontSizeHelper.getDynamicFontSize(
          controller.text.length,
        );
        final showExamples = _examplesFit(viewModel, ai, ml);

        return Stack(
          children: [
            TextField(
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
                hintText: hintText ?? l10n.translationHint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  showExamples ? 48 : 20,
                  8,
                ),
                border: InputBorder.none,
              ),
            ),
            if (showExamples)
              Positioned(
                top: 6,
                right: 2,
                child: _ExamplesButton(
                  mainVM: viewModel,
                  translation: controller.text,
                ),
              ),
          ],
        );
      },
    );
  }
}

// The input and languages of whichever page (AI or Basic) is showing;
// auto-detect leaves the word's language unknown.
({String text, String? source, String target}) _pageInput(
  BuildContext context,
  MainViewModel mainVM,
) {
  ({String text, String? source, String target}) input(
    String text,
    String source,
    String target,
  ) => (
    text: text,
    source: source == autoDetect ? null : source,
    target: target,
  );

  if (mainVM.isMLPage) {
    final ml = context.read<MLTranslateViewModel>();
    return input(ml.textController.text, ml.sourceLanguage, ml.targetLanguage);
  }
  final ai = context.read<GeminiTranslateViewModel>();
  return input(ai.textController.text, ai.sourceLanguage, ai.targetLanguage);
}

/// AI example sentences for a short translation.
class _ExamplesButton extends StatelessWidget {
  final MainViewModel mainVM;
  final String translation;

  const _ExamplesButton({required this.mainVM, required this.translation});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: l10n.exampleSentences,
      icon: Icon(
        Icons.info_outline_rounded,
        color: Colors.white.withValues(alpha: 0.6),
      ),
      onPressed: () async {
        final input = _pageInput(context, mainVM);
        final examples = context.read<ExamplesViewModel>();
        if (examples.cached(input.text, translation) == null &&
            !await ensureAiConsent(context)) {
          return;
        }
        if (!context.mounted) return;
        HapticFeedback.lightImpact();
        ExampleSentencesSheet.show(
          context,
          title: input.text.trim(),
          load: () => examples.load(
            text: input.text,
            translation: translation,
            sourceLanguage: input.source,
            targetLanguage: input.target,
          ),
        );
      },
    );
  }
}

class OutputActionButtons extends StatelessWidget {
  final TextEditingController controller;
  
  const OutputActionButtons({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final mainVM = Provider.of<MainViewModel>(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          if (!mainVM.isMLPage) ...[
            _ToneDropdown(controller: controller),
            const SizedBox(width: 6),
            _TranslateAgainButton(controller: controller),
          ],
          const Spacer(),
          SpeechToggleButton(
            text: controller.text,
            language: mainVM.isMLPage
                ? Provider.of<MLTranslateViewModel>(
                    context,
                    listen: false,
                  ).targetLanguage
                : Provider.of<GeminiTranslateViewModel>(
                    context,
                    listen: false,
                  ).targetLanguage,
          ),
          _DeckAddButton(mainVM: mainVM, translation: controller.text),
          _FavoriteButton(mainVM: mainVM, translation: controller.text),
        ],
      ),
    );
  }
}

/// Faded once this text and these languages are translated; spinner while busy.
class _TranslateAgainButton extends StatelessWidget {
  final TextEditingController controller;

  const _TranslateAgainButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GeminiTranslateViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([vm, vm.textController]),
      builder: (context, _) {
        final loading = vm.isLoading;
        return AnimatedOpacity(
          opacity: vm.isUpToDate && !loading ? 0.4 : 1,
          duration: const Duration(milliseconds: 200),
          child: InkWell(
            onTap: loading
                ? null
                : () async {
                    if (await ensureAiConsent(context)) {
                      translateWithHaptics(vm, controller);
                    }
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              // The label stays (invisible) under the spinner so the width holds.
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: loading ? 0 : 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          l10n.translate,
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToneDropdown extends StatefulWidget {
  final TextEditingController controller;
  const _ToneDropdown({required this.controller});

  @override
  State<_ToneDropdown> createState() => _ToneDropdownState();
}

class _ToneDropdownState extends State<_ToneDropdown> {
  OverlayEntry? _menuEntry;

  static List<String> get _tones => [
    l10n.toneStandard,
    l10n.toneFormal,
    l10n.toneSlang,
  ];

  @override
  void dispose() {
    _menuEntry?.remove();
    super.dispose();
  }

  void _openMenu(int selectedIndex, GeminiTranslateViewModel viewModel) {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    const double gap = 4;
    final double keyboardTop = screenSize.height - media.viewInsets.bottom;

    final double menuHeight = _tones.length * 42.0 + 12.0;
    final double belowAvail =
        keyboardTop - anchor.dy - box.size.height - 2 * gap;
    final double aboveAvail = anchor.dy - gap;
    final bool openDown = belowAvail >= aboveAvail && belowAvail >= menuHeight;
    final double maxMenuHeight = math.min(
      openDown ? belowAvail : aboveAvail,
      240,
    );

    _closeMenu();
    _menuEntry = OverlayEntry(
      builder: (ctx) {
        final double actualHeight = math.min(menuHeight, maxMenuHeight);
        final double top = openDown
            ? anchor.dy + box.size.height + gap
            : anchor.dy - actualHeight - gap;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeMenu,
              ),
            ),
            Positioned(
              left: anchor.dx,
              top: top,
              width: box.size.width,
              child: _buildMenuCard(actualHeight, selectedIndex, viewModel),
            ),
          ],
        );
      },
    );
    overlay.insert(_menuEntry!);
  }

  void _closeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  Widget _buildMenuCard(
    double menuHeight,
    int selectedIndex,
    GeminiTranslateViewModel viewModel,
  ) {
    final BorderRadius radius = BorderRadius.circular(16);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3238).withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _tones.length; i++)
                      _buildMenuItem(
                        i,
                        _tones[i],
                        selectedIndex == i,
                        viewModel,
                      ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    int index,
    String label,
    bool isSelected,
    GeminiTranslateViewModel viewModel,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isSelected) HapticFeedback.selectionClick();
        viewModel.setSelectedToneIndex(index, widget.controller);
        _closeMenu();
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        color: isSelected ? Colors.white.withValues(alpha: 0.08) : null,
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeminiTranslateViewModel>(
      builder: (context, viewModel, child) {
        final int index = viewModel.selectedToneIndex;
        final String label = (index >= 0 && index < _tones.length)
            ? _tones[index]
            : l10n.toneLabel;

        return InkWell(
          onTap: () => _openMenu(index, viewModel),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                SizedBox(
                  width: 58,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
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
      constraints: const BoxConstraints(minWidth: 36),
      onPressed: () {
        final input = _pageInput(context, mainVM);
        DeckSelectorSheet.show(
          context,
          input.text,
          translation,
          wordLanguage: input.source,
          translationLanguage: input.target,
          // Looked up already: the card keeps them.
          examples: context.read<ExamplesViewModel>().cached(
            input.text,
            translation,
          ),
        );
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
          constraints: const BoxConstraints(minWidth: 36),
          onPressed: () {
            if (word.isNotEmpty && translation.isNotEmpty) {
              HapticFeedback.lightImpact();
              favVM.toggleFavorite(
                word: word,
                translation: translation,
                translations: mainVM.isMLPage ? const [] : geminiVM.results,
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
