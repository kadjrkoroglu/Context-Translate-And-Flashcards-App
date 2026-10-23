import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/widgets/upgrade_required_dialog.dart';
import 'package:translate_app/l10n/l10n.dart';

class AddCardDialog {
  /// Done when the dialog closes.
  static Future<void> show(BuildContext context, dynamic deck) async {
    final vm = context.read<DecksViewModel>();
    if (!vm.canAddCard(deck)) {
      showCardLimitDialog(context, vm.maxCardsPerDeck);
      return;
    }
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    final frontFocus = FocusNode();

    await showDialog<void>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            l10n.addCard,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: frontCtrl,
                focusNode: frontFocus,
                label: l10n.cardFront,
                maxLength: maxCardWordLength,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              _DialogField(
                controller: backCtrl,
                label: l10n.cardBack,
                maxLength: maxCardTranslationLength,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (frontCtrl.text.isNotEmpty && backCtrl.text.isNotEmpty) {
                  // The dialog stays open for adding several cards in a row,
                  // so the limit can be reached from inside it.
                  final added = await vm.addCard(
                    deck.id,
                    frontCtrl.text.trim(),
                    backCtrl.text.trim(),
                  );
                  if (!added) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      showCardLimitDialog(context, vm.maxCardsPerDeck);
                    }
                    return;
                  }
                  HapticFeedback.lightImpact();
                  frontCtrl.clear();
                  backCtrl.clear();
                  frontFocus.requestFocus();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same fields as adding a card, filled with the card's two sides.
class EditCardDialog {
  static void show(
    BuildContext context,
    CardEntity card, {
    VoidCallback? onSaved,
  }) {
    final vm = context.read<DecksViewModel>();
    final frontCtrl = TextEditingController(text: card.word);
    final backCtrl = TextEditingController(text: card.translation);

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            l10n.editCard,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: frontCtrl,
                label: l10n.cardFront,
                maxLength: maxCardWordLength,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              _DialogField(
                controller: backCtrl,
                label: l10n.cardBack,
                maxLength: maxCardTranslationLength,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final front = frontCtrl.text.trim();
                final back = backCtrl.text.trim();
                if (front.isEmpty || back.isEmpty) return;
                Navigator.pop(ctx);
                await vm.editCard(card, front, back);
                HapticFeedback.lightImpact();
                onSaved?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final bool autofocus;
  final FocusNode? focusNode;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      maxLength: maxLength,
      // The keyboard starts with a capital (and knows Turkish "İ").
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        counterStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
