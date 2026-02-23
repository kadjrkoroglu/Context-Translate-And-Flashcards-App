import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';

class DeckSelectorSheet extends StatelessWidget {
  final String word;
  final String translation;

  const DeckSelectorSheet({
    super.key,
    required this.word,
    required this.translation,
  });

  static Future<void> show(
    BuildContext context,
    String word,
    String translation,
  ) {
    return showModalBottomSheet(
      context: context,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DeckSelectorSheet(word: word, translation: translation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decksVM = Provider.of<DecksViewModel>(context);
    final Color ip = Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.0,
      maxChildSize: 0.7,
      expand: false,
      builder: (ctx, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D3238).withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(36),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: CustomScrollView(
              controller: scrollCtrl,
              slivers: [
                _buildAppBar(ctx, ip),
                if (decksVM.decks.isEmpty)
                  _buildEmptyState(ip)
                else
                  _buildDeckList(ctx, decksVM, ip),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color ip) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 80,
      titleSpacing: 0,
      title: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: ip.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Save to Deck',
                  style: TextStyle(
                    color: ip,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: ip),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white12, height: 1),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color ip) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          'No decks found.\nCreate a deck first.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ip.withValues(alpha: 0.5), height: 1.5),
        ),
      ),
    );
  }

  Widget _buildDeckList(
    BuildContext context,
    DecksViewModel decksVM,
    Color ip,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final deck = decksVM.decks[i];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.style_rounded,
                color: Colors.blueAccent,
              ),
              title: Text(
                deck.name,
                style: TextStyle(color: ip, fontWeight: FontWeight.w600),
              ),
              onTap: () => _handleSave(context, decksVM, deck),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }, childCount: decksVM.decks.length),
      ),
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    DecksViewModel decksVM,
    dynamic deck,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Save Flashcard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Save word to ${deck.name}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

    if (confirmed == true) {
      await decksVM.addCard(deck.id, word, translation);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
