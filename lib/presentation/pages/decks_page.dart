import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/pages/deck_detail_page.dart';
import 'package:translate_app/presentation/pages/study_page.dart';
import 'package:translate_app/presentation/viewmodels/study_viewmodel.dart';
import 'package:translate_app/data/services/local_storage_service.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';

class DecksPage extends StatelessWidget {
  const DecksPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color ip = Colors.white;

    return AppBackground(
      child: Scaffold(
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
                  title: const Text(
                    'Decks',
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDeckDialog(context),
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          label: const Text(
            'New Deck',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add_rounded),
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
            'Create your first deck to start learning!',
            style: TextStyle(color: ip.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showAddDeckDialog(BuildContext context) {
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
          title: const Text(
            'New Deck',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Deck Name',
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await context.read<DecksViewModel>().addDeck(
                    controller.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create'),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${deck.orderIndex ?? (index + 1)}',
                    style: const TextStyle(
                      color: ip,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                deck.name,
                style: const TextStyle(
                  color: ip,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              trailing: _CountBadges(
                counts: vm.getCardCountsByStatus(deck),
                ip: ip,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (ctx) =>
                          StudyViewModel(ctx.read<LocalStorageService>(), deck),
                      child: const StudyPage(),
                    ),
                  ),
                ).then((_) => vm.loadDecks());
              },
              onLongPress: () => _showDeckOptions(context),
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
                'Add Card',
                () {
                  Navigator.pop(ctx);
                  _showAddCardDialog(context);
                },
              ),
              _optionItem(ctx, Icons.style_outlined, 'Browse Cards', () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeckDetailPage(deck: deck)),
                );
              }),
              _optionItem(ctx, Icons.settings_outlined, 'Deck Settings', () {
                Navigator.pop(ctx);
                _showDeckSettingsDialog(context);
              }),
              const Divider(color: Colors.white12, height: 24),
              _optionItem(
                ctx,
                Icons.delete_outline_rounded,
                'Delete Deck',
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
            'Delete Deck?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Delete "${deck.name}" and all its cards?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                vm.deleteDeck(deck.id);
                Navigator.pop(ctx);
              },
              child: const Text(
                'Delete',
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
          title: const Text(
            'Deck Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LimitField(controller: newCtrl, label: 'Daily New Cards Limit'),
              const SizedBox(height: 16),
              _LimitField(controller: revCtrl, label: 'Daily Reviews Limit'),
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
                await vm.updateDeckLimits(
                  deck.id,
                  int.tryParse(newCtrl.text) ?? 20,
                  int.tryParse(revCtrl.text) ?? 200,
                );
                if (context.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
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
              _LimitField(
                controller: frontCtrl,
                label: 'Front',
                autofocus: true,
              ),
              const SizedBox(height: 12),
              _LimitField(controller: backCtrl, label: 'Back'),
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
                  await vm.addCard(
                    deck.id,
                    frontCtrl.text.trim(),
                    backCtrl.text.trim(),
                  );
                  frontCtrl.clear();
                  backCtrl.clear();
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

class _LimitField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  const _LimitField({
    required this.controller,
    required this.label,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: const TextStyle(color: Colors.white),
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
