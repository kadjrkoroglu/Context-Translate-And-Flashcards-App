import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/pages/deck_detail_page.dart';
import 'package:translate_app/presentation/pages/study_page.dart';
import 'package:translate_app/presentation/viewmodels/study_viewmodel.dart';
import 'package:translate_app/data/services/local_storage_service.dart';

class DecksPage extends StatelessWidget {
  const DecksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inversePrimary = colorScheme.inversePrimary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Decks'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: inversePrimary,
      ),
      body: Consumer<DecksViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.decks.isEmpty) {
            return _buildEmptyState(inversePrimary);
          }

          return ListView.builder(
            itemCount: viewModel.decks.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final deck = viewModel.decks[index];

              return Card(
                color: colorScheme.primary,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: inversePrimary.withValues(alpha: 0.1),
                    child: Text(
                      '${deck.orderIndex ?? (index + 1)}.',
                      style: TextStyle(
                        color: inversePrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    deck.name,
                    style: TextStyle(
                      color: inversePrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: _buildCountBadges(
                    viewModel.getCardCountsByStatus(deck),
                    inversePrimary,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (context) => StudyViewModel(
                            context.read<LocalStorageService>(),
                            deck,
                          ),
                          child: const StudyPage(),
                        ),
                      ),
                    ).then((_) => viewModel.loadDecks());
                  },
                  onLongPress: () => _showDeckOptions(context, deck, viewModel),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDeckDialog(context),
        backgroundColor: inversePrimary,
        label: const Text('New Deck'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showDeckOptions(
    BuildContext context,
    dynamic deck,
    DecksViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final inversePrimary = colorScheme.inversePrimary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          deck.name,
          textAlign: TextAlign.center,
          style: TextStyle(color: inversePrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionItem(
              context,
              icon: Icons.add_circle_outline,
              title: 'Add Card',
              onTap: () {
                Navigator.pop(context);
                _showAddCardDialog(context, deck, viewModel);
              },
            ),
            _buildOptionItem(
              context,
              icon: Icons.style_outlined,
              title: 'Browse Cards',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeckDetailPage(deck: deck),
                  ),
                );
              },
            ),
            _buildOptionItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Deck Settings',
              onTap: () {
                Navigator.pop(context);
                _showDeckSettingsDialog(context, deck, viewModel);
              },
            ),
            const Divider(),
            _buildOptionItem(
              context,
              icon: Icons.delete_outline,
              title: 'Delete Deck',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, deck, viewModel);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final inversePrimary = Theme.of(context).colorScheme.inversePrimary;
    return ListTile(
      leading: Icon(icon, color: color ?? inversePrimary),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? inversePrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    dynamic deck,
    DecksViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck?'),
        content: Text(
          'Are you sure you want to delete "${deck.name}" and all its cards?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.inversePrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteDeck(deck.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color inversePrimary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 64,
            color: inversePrimary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Create your first deck to start learning!',
            style: TextStyle(color: inversePrimary.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  void _showAddDeckDialog(BuildContext context) {
    final controller = TextEditingController();
    final viewModel = context.read<DecksViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final inversePrimary = colorScheme.inversePrimary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'New Deck',
          style: TextStyle(color: inversePrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: inversePrimary),
          decoration: InputDecoration(
            labelText: 'Deck Name',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: TextStyle(color: inversePrimary.withValues(alpha: 0.7)),
            filled: true,
            fillColor: colorScheme.primary.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: inversePrimary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await viewModel.addDeck(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: inversePrimary,
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeckSettingsDialog(
    BuildContext context,
    dynamic deck,
    DecksViewModel viewModel,
  ) {
    final newLimitController = TextEditingController(
      text: deck.newCardsLimit.toString(),
    );
    final reviewLimitController = TextEditingController(
      text: deck.reviewsLimit.toString(),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final inversePrimary = colorScheme.inversePrimary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Deck Settings',
          style: TextStyle(color: inversePrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newLimitController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: inversePrimary),
              decoration: InputDecoration(
                labelText: 'Daily New Cards Limit',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(
                  color: inversePrimary.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: colorScheme.primary.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewLimitController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: inversePrimary),
              decoration: InputDecoration(
                labelText: 'Daily Reviews Limit',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(
                  color: inversePrimary.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: colorScheme.primary.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: inversePrimary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newLimit = int.tryParse(newLimitController.text) ?? 20;
              final reviewLimit =
                  int.tryParse(reviewLimitController.text) ?? 200;

              await viewModel.updateDeckLimits(deck.id, newLimit, reviewLimit);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: inversePrimary,
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog(
    BuildContext context,
    dynamic deck,
    DecksViewModel viewModel,
  ) {
    final wordController = TextEditingController();
    final translationController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final inversePrimary = colorScheme.inversePrimary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Card',
          style: TextStyle(color: inversePrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordController,
              autofocus: true,
              style: TextStyle(color: inversePrimary),
              decoration: InputDecoration(
                labelText: 'Front',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(
                  color: inversePrimary.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: colorScheme.primary.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: translationController,
              style: TextStyle(color: inversePrimary),
              decoration: InputDecoration(
                labelText: 'Back',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: TextStyle(
                  color: inversePrimary.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: colorScheme.primary.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: inversePrimary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (wordController.text.isNotEmpty &&
                  translationController.text.isNotEmpty) {
                await viewModel.addCard(
                  deck.id,
                  wordController.text.trim(),
                  translationController.text.trim(),
                );
                wordController.clear();
                translationController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: inversePrimary,
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadges(Map<String, int> counts, Color inversePrimary) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _countBadge(counts['new'] ?? 0, Colors.grey.shade400, Colors.black87),
        const SizedBox(width: 3),
        _countBadge(counts['again'] ?? 0, Colors.red, Colors.white),
        const SizedBox(width: 3),
        _countBadge(counts['hard'] ?? 0, Colors.orange, Colors.white),
        const SizedBox(width: 3),
        _countBadge(counts['good'] ?? 0, Colors.green, Colors.white),
        const SizedBox(width: 3),
        _countBadge(counts['easy'] ?? 0, Colors.blue, Colors.white),
      ],
    );
  }

  Widget _countBadge(int count, Color color, Color textColor) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
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
