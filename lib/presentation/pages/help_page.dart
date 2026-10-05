import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:translate_app/core/app_links.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';

const _faq = [
  (
    'How many translations can I make?',
    'Free: 10 AI translations a day. Standard and Premium: unlimited. Basic '
        'translation runs on your phone and is always free.',
  ),
  (
    'Do my photos leave my phone?',
    'No. The text is read on your phone and only that text is sent to be '
        'translated.',
  ),
  (
    'What is Live translation?',
    'Premium translates speech as it is spoken, with captions: 60 minutes a '
        'month (5 minutes in the free trial). The minutes renew every month.',
  ),
  (
    'How does Study with AI work?',
    'Premium: an AI tutor quizzes you on 10 words from a deck. A word counts '
        'once you answer it correctly. After a session there is a 3-hour '
        'break.',
  ),
  (
    'How do I sync my decks between devices?',
    'Sign in on the Profile page, then tap Sync Now.',
  ),
  (
    'Can I translate without internet?',
    'Yes, on the Basic page. Each language downloads once (about 30 MB) and '
        'then works offline.',
  ),
  (
    'How do I cancel my subscription?',
    'On your iPhone: Settings > your name > Subscriptions. Deleting the app '
        'or your account does not cancel it.',
  ),
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
          title: const Text(
            'Help & FAQ',
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
              'Still need help?',
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
                label: const Text('Contact us'),
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
