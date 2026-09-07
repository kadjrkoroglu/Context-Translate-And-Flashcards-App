import 'dart:math' as math;
import 'dart:ui';
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
        padding: const EdgeInsets.symmetric(horizontal: 7),
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

class _ToneDropdown extends StatefulWidget {
  final TextEditingController controller;
  const _ToneDropdown({required this.controller});

  @override
  State<_ToneDropdown> createState() => _ToneDropdownState();
}

class _ToneDropdownState extends State<_ToneDropdown> {
  OverlayEntry? _menuEntry;

  static const List<String> _tones = ['Standard', 'Formal', 'Slang'];

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
            : 'Tone';

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
                const Icon(
                  Icons.tune_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
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
          constraints: const BoxConstraints(minWidth: 36),
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
      constraints: const BoxConstraints(minWidth: 36),
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
