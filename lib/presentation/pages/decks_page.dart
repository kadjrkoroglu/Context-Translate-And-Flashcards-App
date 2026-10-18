import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:translate_app/presentation/widgets/add_card_dialog.dart';
import 'dart:ui';
import 'package:translate_app/presentation/viewmodels/ai_study_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/pages/deck_detail_page.dart';
import 'package:translate_app/presentation/pages/study_page.dart';
import 'package:translate_app/presentation/viewmodels/study_viewmodel.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/presentation/widgets/study_with_ai_button.dart';
import 'package:translate_app/presentation/widgets/upgrade_required_dialog.dart';
import 'package:translate_app/presentation/utils/haptics.dart';
import 'package:translate_app/l10n/l10n.dart';

class DecksPage extends StatefulWidget {
  const DecksPage({super.key});

  @override
  State<DecksPage> createState() => _DecksPageState();
}

class _DecksPageState extends State<DecksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DecksViewModel>().loadDecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color ip = Colors.white;

    return AppBackground(
      child: Scaffold(
        // Dialogs bring the keyboard; the buttons stay at the bottom.
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Consumer<DecksViewModel>(
          builder: (context, vm, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  title: Text(
                    l10n.decksTitle,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  foregroundColor: ip,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (vm.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (vm.error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          vm.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  )
                else if (vm.decks.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState(context, ip))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _DeckCard(
                          deck: vm.decks[index],
                          index: index,
                          vm: vm,
                        ),
                        childCount: vm.decks.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButtonLocation: const _EdgeGapFabLocation(),
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StudyWithAiButton(),
              FloatingActionButton.extended(
                onPressed: () => _showAddDeckDialog(context),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                label: Text(
                  l10n.newDeck,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color ip) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_rounded, size: 64, color: ip.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            l10n.createFirstDeck,
            style: TextStyle(color: ip.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showAddDeckDialog(BuildContext context) {
    final vm = context.read<DecksViewModel>();
    if (!vm.canAddDeck) {
      showDeckLimitDialog(context, vm.maxDecks);
      return;
    }
    final controller = TextEditingController();
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
            l10n.newDeck,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              labelText: l10n.deckName,
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final added = await vm.addDeck(controller.text.trim());
                  if (context.mounted) Navigator.pop(ctx);
                  if (!added && context.mounted) {
                    showDeckLimitDialog(context, vm.maxDecks);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final dynamic deck;
  final int index;
  final DecksViewModel vm;
  const _DeckCard({required this.deck, required this.index, required this.vm});

  @override
  Widget build(BuildContext context) {
    const Color ip = Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    deck.name,
                    style: const TextStyle(
                      color: ip,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (vm.getTotalCardCount(deck) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l10n.cardCount(vm.getTotalCardCount(deck)),
                        style: TextStyle(
                          color: ip.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: _CountBadges(
                counts: vm.getCardCountsByStatus(deck),
                ip: ip,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  // Swiping a card right rates it, so going back stays on the edge.
                  SwipeablePageRoute(
                    canOnlySwipeFromEdge: true,
                    builder: (_) => ChangeNotifierProvider(
                      create: (ctx) =>
                          StudyViewModel(deck, ctx.read<DeckUsecase>()),
                      child: const StudyPage(),
                    ),
                  ),
                ).then((_) => vm.loadDecks());
              },
              onLongPress: () {
                longPressHaptic();
                _showDeckOptions(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showDeckOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            deck.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _optionItem(
                ctx,
                Icons.add_circle_outline_rounded,
                l10n.addCard,
                () {
                  Navigator.pop(ctx);
                  AddCardDialog.show(context, deck);
                },
              ),
              _optionItem(ctx, Icons.style_outlined, l10n.browseCards, () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeckDetailPage(deck: deck)),
                );
              }),
              _optionItem(ctx, Icons.settings_outlined, l10n.deckSettings, () {
                Navigator.pop(ctx);
                _showDeckSettingsDialog(context);
              }),
              const Divider(color: Colors.white12, height: 24),
              _optionItem(
                ctx,
                Icons.delete_outline_rounded,
                l10n.deleteDeck,
                () {
                  Navigator.pop(ctx);
                  _showDeleteConfirm(context);
                },
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    final study = context.read<AiStudyViewModel>();
    final endsSession =
        study.hasUnfinishedSession && study.session!.deckId == deck.syncId;
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: Text(
            l10n.deleteDeckTitle,
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            l10n.deleteDeckBody(deck.name) +
                (endsSession ? l10n.deleteDeckEndsSession : ''),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () {
                vm.deleteDeck(deck.id);
                if (endsSession) study.endSession();
                Navigator.pop(ctx);
              },
              child: Text(
                l10n.delete,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeckSettingsDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: deck.name);
    final newCtrl = TextEditingController(text: deck.newCardsLimit.toString());
    final revCtrl = TextEditingController(text: deck.reviewsLimit.toString());
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
            l10n.deckSettings,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NameField(controller: nameCtrl),
              const SizedBox(height: 16),
              _LimitField(controller: newCtrl, label: l10n.dailyNewLimit),
              const SizedBox(height: 16),
              _LimitField(controller: revCtrl, label: l10n.dailyReviewLimit),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                vm.updateDeckSettings(
                  deck.id,
                  nameCtrl.text,
                  int.tryParse(newCtrl.text) ?? 20,
                  int.tryParse(revCtrl.text) ?? 200,
                );
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

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: l10n.deckName,
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

class _LimitField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _LimitField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
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

class _CountBadges extends StatelessWidget {
  final Map<String, int> counts;
  final Color ip;
  const _CountBadges({required this.counts, required this.ip});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (counts['new']! > 0) _badge(counts['new']!, Colors.white),
        const SizedBox(width: 4),
        if (counts['again']! > 0) _badge(counts['again']!, Colors.redAccent),
        const SizedBox(width: 4),
        if (counts['hard']! > 0) _badge(counts['hard']!, Colors.orangeAccent),
        const SizedBox(width: 4),
        if (counts['good']! > 0) _badge(counts['good']!, Colors.greenAccent),
        const SizedBox(width: 4),
        if (counts['easy']! > 0) _badge(counts['easy']!, Colors.blueAccent),
      ],
    );
  }

  Widget _badge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// The buttons sit as far from the bottom edge as from the sides.
class _EdgeGapFabLocation extends FloatingActionButtonLocation {
  const _EdgeGapFabLocation();

  static const double gap = 16;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) => Offset(
    (geometry.scaffoldSize.width - geometry.floatingActionButtonSize.width) / 2,
    geometry.scaffoldSize.height -
        geometry.floatingActionButtonSize.height -
        gap,
  );
}
