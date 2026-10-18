import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:translate_app/core/app_links.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/l10n/l10n.dart';

List<(String, String)> get _faq => [
  (l10n.faqQ1, l10n.faqA1),
  (l10n.faqQ2, l10n.faqA2),
  (l10n.faqQ3, l10n.faqA3),
  (l10n.faqQ4, l10n.faqA4),
  (l10n.faqQ5, l10n.faqA5),
  (l10n.faqQ6, l10n.faqA6),
  (l10n.faqQ7, l10n.faqA7),
];

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
          title: Text(
            l10n.helpFaq,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            for (final (question, answer) in _faq)
              _FaqItem(question: question, answer: answer),
            const SizedBox(height: 24),
            Text(
              l10n.stillNeedHelp,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => AppLinks.emailSupport(
                  body:
                      '\n\n---\nUser: '
                      '${FirebaseAuth.instance.currentUser?.uid ?? '-'}',
                ),
                icon: const Icon(Icons.mail_outline_rounded),
                label: Text(l10n.contactUs),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      // Its own Material, so the tap ripple shows over the tinted box.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          // No divider lines when a tile opens.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: Colors.white70,
            collapsedIconColor: Colors.white38,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Text(
                answer,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
