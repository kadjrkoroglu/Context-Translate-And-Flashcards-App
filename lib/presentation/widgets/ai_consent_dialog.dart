import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/core/app_links.dart';
import 'package:translate_app/data/services/settings_service.dart';

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
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text(
          'Before you use AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI translation, photo translation, Live and Study with AI '
              'send the text you enter, the text read from your photo, your '
              'voice in Live and your answers to Google Gemini to be '
              'processed.',
              style: body,
            ),
            const SizedBox(height: 10),
            Text(
              'Your photos never leave your phone. Basic translation works '
              'on your phone without this.',
              style: body,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => AppLinks.open(AppLinks.privacyPolicy),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                'Privacy Policy',
                style: TextStyle(color: Colors.lightBlueAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Not now',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Allow',
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
