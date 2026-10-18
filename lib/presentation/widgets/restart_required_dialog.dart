import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:translate_app/l10n/l10n.dart';

/// Shown after sign-out, and whenever a translate is attempted with no
/// Firebase session at all (a guest session is only granted on app launch).
Future<void> showRestartRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: AlertDialog(
        backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: Text(l10n.restartTitle, style: TextStyle(color: Colors.white)),
        content: Text(
          l10n.restartBody,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.ok, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
