import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/data/models/deck_model.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/widgets/add_card_dialog.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'dart:ui';

class DeckDetailPage extends StatefulWidget {
  final DeckItem deck;

  const DeckDetailPage({super.key, required this.deck});

  @override
  State<DeckDetailPage> createState() => _DeckDetailPageState();
}

class _DeckDetailPageState extends State<DeckDetailPage> {
  final Set<int> _selectedCardIds = {};
  bool get _isSelectionMode => _selectedCardIds.isNotEmpty;

  void _toggleSelection(int cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else {
        _selectedCardIds.add(cardId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCardIds.clear();
    });
  }

  Future<void> _deleteSelectedCards(DecksViewModel viewModel) async {
    final count = _selectedCardIds.length;
    final confirmed = await showDialog<bool>(
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
            'Delete $count Cards?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
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

    if (confirmed == true) {
      await viewModel.deleteMultipleCards(_selectedCardIds.toList());
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color ip = Colors.white;

    return AppBackground(
      child: PopScope(
        canPop: !_isSelectionMode,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isSelectionMode) {
            _clearSelection();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Consumer<DecksViewModel>(
            builder: (context, viewModel, child) {
              final currentDeck = viewModel.decks.firstWhere(
                (d) => d.id == widget.deck.id,
                orElse: () => widget.deck,
              );
              final cardsList = currentDeck.cards
                  .where((c) => !c.isDeleted)
                  .toList();
              cardsList.sort((a, b) => a.createdAt.compareTo(b.createdAt));

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    leading: _isSelectionMode
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _clearSelection,
                          )
                        : const BackButton(),
                    title: Text(
                      _isSelectionMode
                          ? '${_selectedCardIds.length} Selected'
                          : currentDeck.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                    actions: [
                      if (_isSelectionMode)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteSelectedCards(viewModel),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: Center(
                            child: Text(
                              '${currentDeck.cards.where((c) => !c.isDeleted).length} cards',
                              style: TextStyle(
                                color: ip.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (cardsList.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState(context, ip))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final card = cardsList[index];
                          final isSelected = _selectedCardIds.contains(card.id);
                          final dateStr = DateFormat(
                            'dd.MM.yyyy',
                          ).format(card.createdAt);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: GestureDetector(
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  _toggleSelection(card.id);
                                }
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(card.id);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.white.withValues(alpha: 0.05),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5,
                                      sigmaY: 5,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                      child: Row(
                                        children: [
                                          if (_isSelectionMode)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 12,
                                              ),
                                              child: Icon(
                                                isSelected
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                          .radio_button_unchecked_rounded,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.white30,
                                                size: 20,
                                              ),
                                            ),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: card.word,
                                                    style: const TextStyle(
                                                      color: ip,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '  /  ',
                                                    style: TextStyle(
                                                      color: ip.withValues(
                                                        alpha: 0.3,
                                                      ),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: card.translation,
                                                    style: TextStyle(
                                                      color: ip.withValues(
                                                        alpha: 0.6,
                                                      ),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              color: ip.withValues(alpha: 0.3),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }, childCount: cardsList.length),
                      ),
                    ),
                ],
              );
            },
          ),
          floatingActionButton: _isSelectionMode
              ? null
              : Consumer<DecksViewModel>(
                  builder: (context, viewModel, child) {
                    final currentDeck = viewModel.decks.firstWhere(
                      (d) => d.id == widget.deck.id,
                      orElse: () => widget.deck,
                    );
                    return FloatingActionButton(
                      onPressed: () => AddCardDialog.show(context, currentDeck),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(Icons.add_rounded),
                    );
                  },
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
          Icon(Icons.style_rounded, size: 64, color: ip.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'No cards yet',
            style: TextStyle(color: ip.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
