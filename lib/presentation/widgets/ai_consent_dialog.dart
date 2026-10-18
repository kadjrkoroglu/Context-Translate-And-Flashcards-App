import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/core/app_links.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/l10n/l10n.dart';

/// App Store 5.1.2(i): say where the data goes and ask once before sending.
Future<bool> ensureAiConsent(BuildContext context) async {
  final settings = context.read<SettingsService>();
  if (settings.aiConsent) return true;
  final allowed =
      await showDialog<bool>(
        context: context,
        builder: (_) => const _AiConsentDialog(),
      ) ??
      false;
  if (allowed) await settings.setAiConsent(true);
  return allowed;
}

class _AiConsentDialog extends StatelessWidget {
  const _AiConsentDialog();

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(
      color: Colors.white.withValues(alpha: 0.8),
      fontSize: 14,
      height: 1.4,
    );
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: AlertDialog(
        backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: Text(
          l10n.consentTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.consentBody1, style: body),
            const SizedBox(height: 10),
            Text(l10n.consentBody2, style: body),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => AppLinks.open(AppLinks.privacyPolicy),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                l10n.privacyPolicy,
                style: TextStyle(color: Colors.lightBlueAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.notNow, style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.allow,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
