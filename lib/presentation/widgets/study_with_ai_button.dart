import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/data/services/study_card_picker.dart';
import 'package:translate_app/data/services/sync_service.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/entities/study_session.dart';
import 'package:translate_app/presentation/pages/study_chat_page.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/ai_study_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/favorite_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/history_viewmodel.dart';
import 'package:translate_app/presentation/widgets/ai_consent_dialog.dart';
import 'package:translate_app/l10n/l10n.dart';

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
    HapticFeedback.lightImpact();
    final study = context.read<AiStudyViewModel>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudyChatPage(deck: deck)),
    );
    await study.refresh();
  }

  // The session lives on the server, its deck only on the phone.
  Future<void> _continue(StudySession session) async {
    bool hasDeck() => context.read<DecksViewModel>().decks.any(
      (d) => d.syncId == session.deckId,
    );
    if (hasDeck()) return _openChat(null);

    final choice = await _MissingDeckSheet.show(
      context,
      session.deckName,
      canSync: context.read<AuthViewModel>().isAuthenticated,
    );
    if (choice == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (choice == _MissingDeckChoice.end) {
      if (!await context.read<AiStudyViewModel>().endSession()) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.couldNotEndSession)),
        );
      }
      return;
    }

    final sync = context.read<SyncService>();
    final decksVM = context.read<DecksViewModel>();
    final favorites = context.read<FavoriteViewModel>();
    final history = context.read<HistoryViewModel>();
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
    final error = await sync.syncAll() ?? sync.syncError;
    await decksVM.loadDecks();
    favorites.loadFavorites();
    history.loadHistory();
    navigator.pop();
    if (!mounted) return;
    if (hasDeck()) return _openChat(null);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? l10n.deckNotFoundEnd)),
    );
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
      HapticFeedback.warningNotification();
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
        label: l10n.continueProgress(session!.doneCount, session.total),
        progress: session.doneCount / session.total,
        onTap: () => _continue(session),
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
        label: l10n.addMoreWords(missing),
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.needsTenWords))),
      );
    }
    return _Pill(
      icon: Icons.auto_awesome,
      label: l10n.studyWithAi,
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
      title: l10n.studyWithAi,
      child: Flexible(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(
                l10n.pickDeck,
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
            ready ? l10n.wordCount(count) : l10n.addMoreWords(missing),
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

enum _MissingDeckChoice { sync, end }

/// The unfinished session's deck isn't on this phone: sync it back or end.
class _MissingDeckSheet extends StatelessWidget {
  final String deckName;
  final bool canSync;

  const _MissingDeckSheet({required this.deckName, required this.canSync});

  static Future<_MissingDeckChoice?> show(
    BuildContext context,
    String deckName, {
    required bool canSync,
  }) => showModalBottomSheet<_MissingDeckChoice>(
    context: context,
    barrierColor: Colors.black54,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _MissingDeckSheet(deckName: deckName, canSync: canSync),
  );

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const padding = EdgeInsets.symmetric(vertical: 13);
    return _GlassSheet(
      title: l10n.deckNotOnPhone,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          children: [
            Text(
              l10n.missingDeckIntro(deckName) +
                  (canSync ? l10n.missingDeckSync : '') +
                  l10n.missingDeckEndNote,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 18),
            if (canSync) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, _MissingDeckChoice.sync),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: shape,
                    padding: padding,
                  ),
                  child: Text(l10n.syncNowLower),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, _MissingDeckChoice.end),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  shape: shape,
                  padding: padding,
                ),
                child: Text(l10n.endSession),
              ),
            ),
          ],
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
      title: l10n.nextSession,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          children: [
            Text(
              left == null ? l10n.readyNow : formatCountdown(left),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.breakNote,
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
                  child: Text(l10n.reviewWithFlashcards(deck.name)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
