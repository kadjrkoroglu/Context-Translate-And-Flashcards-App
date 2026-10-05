import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/data/services/study_card_picker.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/presentation/pages/study_chat_page.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/ai_study_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/widgets/ai_consent_dialog.dart';

/// Decks screen, bottom left: Study with AI, Continue 4/10, or the countdown.
class StudyWithAiButton extends StatefulWidget {
  const StudyWithAiButton({super.key});

  @override
  State<StudyWithAiButton> createState() => _StudyWithAiButtonState();
}

class _StudyWithAiButtonState extends State<StudyWithAiButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AiStudyViewModel>().refresh();
    });
  }

  Future<void> _openChat(DeckEntity? deck) async {
    if (!await ensureAiConsent(context) || !mounted) return;
    final study = context.read<AiStudyViewModel>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudyChatPage(deck: deck)),
    );
    await study.refresh();
  }

  Future<void> _showCooldown() async {
    final deck = await _CooldownSheet.show(context);
    if (deck != null && mounted) openFlashcards(context, deck);
  }

  // Same gate as the Live tab: reload the plan before sending anyone to it.
  Future<void> _start(List<DeckEntity> decks) async {
    final entitlementsVM = context.read<EntitlementsViewModel>();
    if (entitlementsVM.entitlements?.entitlements.chat != true) {
      await entitlementsVM.load();
    }
    if (!mounted) return;
    final entitlements = entitlementsVM.entitlements;
    if (entitlements != null && !entitlements.entitlements.chat) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpgradePage()),
      );
      return;
    }
    final ready = decks
        .where((d) => studyCardCount(d.cards) >= studySessionCards)
        .toList();
    if (ready.length == 1) {
      _openChat(ready.single);
      return;
    }
    final deck = await _DeckPickerSheet.show(context, decks);
    if (deck != null && mounted) _openChat(deck);
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<AiStudyViewModel>();
    final decks = context.watch<DecksViewModel>().decks;
    final hasChat =
        context
            .watch<EntitlementsViewModel>()
            .entitlements
            ?.entitlements
            .chat ??
        false;
    final session = study.session;
    final cooldown = study.cooldownLeft;
    final mostCards = decks.fold(
      0,
      (most, d) => max(most, studyCardCount(d.cards)),
    );

    if (hasChat && study.hasUnfinishedSession) {
      return _Pill(
        icon: Icons.auto_awesome,
        label: 'Continue · ${session!.doneCount}/${session.total}',
        progress: session.doneCount / session.total,
        onTap: () => _openChat(null),
      );
    }
    if (hasChat && cooldown != null) {
      return _Pill(
        faded: true,
        icon: Icons.hourglass_bottom_rounded,
        label: formatCountdown(cooldown),
        tabular: true,
        onTap: _showCooldown,
      );
    }
    if (hasChat && mostCards < studySessionCards) {
      final missing = studySessionCards - mostCards;
      return _Pill(
        faded: true,
        label: 'Add $missing more ${missing == 1 ? 'word' : 'words'}',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study with AI needs a deck with at least 10 words.'),
          ),
        ),
      );
    }
    return _Pill(
      icon: Icons.auto_awesome,
      label: 'Study with AI',
      onTap: () => _start(decks),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool faded;
  final bool tabular;
  final double? progress;

  const _Pill({
    required this.label,
    required this.onTap,
    this.icon,
    this.faded = false,
    this.tabular = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Faded: the button steps back, the label (the countdown) stays bright.
    return Material(
      color: Colors.white.withValues(alpha: faded ? 0.05 : 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withValues(alpha: faded ? 0.08 : 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          // Same height as the extended FAB next to it.
          height: 56,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 20,
                        color: faded
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.amberAccent,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: faded && !tabular
                            ? Colors.white.withValues(alpha: 0.45)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: tabular ? 15 : 14,
                        fontFeatures: tabular
                            ? const [FontFeature.tabularFigures()]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (progress != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress!.clamp(0.0, 1.0),
                      child: Container(height: 3, color: Colors.amberAccent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D3238).withValues(alpha: 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Picks the deck to study; decks without enough words say how many to add.
class _DeckPickerSheet extends StatelessWidget {
  final List<DeckEntity> decks;

  const _DeckPickerSheet({required this.decks});

  static Future<DeckEntity?> show(
    BuildContext context,
    List<DeckEntity> decks,
  ) => showModalBottomSheet<DeckEntity>(
    context: context,
    barrierColor: Colors.black54,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DeckPickerSheet(decks: decks),
  );

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      title: 'Study with AI',
      child: Flexible(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(
                'Pick a deck. Each session practises 10 of its words.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
            for (final deck in decks) _row(context, deck),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, DeckEntity deck) {
    final count = studyCardCount(deck.cards);
    final ready = count >= studySessionCards;
    final missing = studySessionCards - count;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.white.withValues(alpha: ready ? 0.08 : 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          enabled: ready,
          onTap: () => Navigator.pop(context, deck),
          title: Text(
            deck.name,
            style: TextStyle(
              color: Colors.white.withValues(alpha: ready ? 1 : 0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            ready
                ? '$count words'
                : 'Add $missing more ${missing == 1 ? 'word' : 'words'}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
          ),
          trailing: ready
              ? const Icon(Icons.auto_awesome, color: Colors.amberAccent)
              : null,
        ),
      ),
    );
  }
}

/// Countdown to the next session; returns a deck to review meanwhile.
class _CooldownSheet extends StatelessWidget {
  const _CooldownSheet();

  static Future<DeckEntity?> show(BuildContext context) =>
      showModalBottomSheet<DeckEntity>(
        context: context,
        barrierColor: Colors.black54,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => const _CooldownSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final study = context.watch<AiStudyViewModel>();
    final left = study.cooldownLeft;
    final lastDeckId = study.state?.lastDeckId;
    final deck = context
        .watch<DecksViewModel>()
        .decks
        .where((d) => d.syncId == lastDeckId)
        .firstOrNull;

    return _GlassSheet(
      title: 'Next session',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          children: [
            Text(
              left == null ? 'Ready now' : formatCountdown(left),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Words stick better with a break between sessions. '
              'Meanwhile you can review them with flashcards.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            if (deck != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, deck),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text('Review ${deck.name} with flashcards'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
