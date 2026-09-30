import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/widgets/upgrade_required_dialog.dart';

class AddCardDialog {
  static void show(BuildContext context, dynamic deck) {
    final vm = context.read<DecksViewModel>();
    if (!vm.canAddCard(deck)) {
      showCardLimitDialog(context, vm.maxCardsPerDeck);
      return;
    }
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    final frontFocus = FocusNode();

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
          title: const Text(
            'Add Card',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: frontCtrl,
                focusNode: frontFocus,
                label: 'Front',
                autofocus: true,
              ),
              const SizedBox(height: 12),
              _DialogField(controller: backCtrl, label: 'Back'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
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
              child: const Text('Add'),
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
  final bool autofocus;
  final FocusNode? focusNode;

  const _DialogField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
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
