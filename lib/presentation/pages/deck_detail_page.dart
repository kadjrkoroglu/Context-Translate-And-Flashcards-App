import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/data/models/deck_model.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'dart:ui';

class DeckDetailPage extends StatelessWidget {
  final DeckItem deck;

  const DeckDetailPage({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    const Color ip = Colors.white;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
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
          title: Text(
            deck.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: ip,
          actions: [
            Consumer<DecksViewModel>(
              builder: (context, viewModel, child) {
                final currentDeck = viewModel.decks.firstWhere(
                  (d) => d.id == deck.id,
                  orElse: () => deck,
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Center(
                    child: Text(
                      '${currentDeck.cards.length} cards',
                      style: TextStyle(
                        color: ip.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<DecksViewModel>(
          builder: (context, viewModel, child) {
            final currentDeck = viewModel.decks.firstWhere(
              (d) => d.id == deck.id,
              orElse: () => deck,
            );
            final cardsList = currentDeck.cards.toList();
            cardsList.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            if (cardsList.isEmpty) return _buildEmptyState(context, ip);

            return ListView.builder(
              itemCount: cardsList.length,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                bottom: 8,
              ),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                // ... (rest of the itemBuilder content remains the same)
                final card = cardsList[index];
                final dateStr = DateFormat('dd.MM.yy').format(card.createdAt);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            card.word,
                            style: const TextStyle(
                              color: ip,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            card.translation,
                            style: TextStyle(
                              color: ip.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                          trailing: Text(
                            dateStr,
                            style: TextStyle(
                              color: ip.withValues(alpha: 0.3),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color ip) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
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
