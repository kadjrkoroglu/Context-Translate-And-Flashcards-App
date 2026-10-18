import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/l10n/l10n.dart';

/// Shown when a free-tier limit is hit.
Future<void> showUpgradeRequiredDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  HapticFeedback.warningNotification();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: AlertDialog(
        backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel, style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpgradePage()),
              );
            },
            child: Text(
              l10n.upgrade,
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showDeckLimitDialog(BuildContext context, int? maxDecks) {
  return showUpgradeRequiredDialog(
    context,
    title: l10n.deckLimitTitle,
    message: l10n.deckLimitBody(maxDecks ?? 0),
  );
}

Future<void> showCardLimitDialog(BuildContext context, int? maxCardsPerDeck) {
  return showUpgradeRequiredDialog(
    context,
    title: l10n.cardLimitTitle,
    message: l10n.cardLimitBody(maxCardsPerDeck ?? 0),
  );
}
