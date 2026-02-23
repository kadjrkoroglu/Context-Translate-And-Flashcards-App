import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../viewmodels/study_viewmodel.dart';
import '../../data/services/srs_service.dart';
import '../widgets/app_background.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  int? _previousCardId;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  StudyRating? _getRatingFromOffset(Offset offset) {
    if (offset.dx.abs() < 30 && offset.dy.abs() < 30) return null;
    if (offset.dx.abs() > offset.dy.abs()) {
      return offset.dx < -30 ? StudyRating.again : StudyRating.good;
    } else {
      return offset.dy < -30 ? StudyRating.easy : StudyRating.hard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StudyViewModel>(context);
    const Color ip = Colors.white;

    if (vm.isLoading) return _LoadingView();
    if (vm.isFinished) return _FinishedView();

    final card = vm.currentCard;
    if (card == null) return _NoCardsView();

    if (_previousCardId != card.id) {
      _flipController.animateTo(0, duration: Duration.zero);
      _previousCardId = card.id;
    }
    if (vm.isAnswerVisible && _flipController.value == 0)
      _flipController.forward();
    else if (!vm.isAnswerVisible && _flipController.value == 1)
      _flipController.reverse();

    final activeRating = _isDragging ? _getRatingFromOffset(_dragOffset) : null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            vm.deck.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            _StudyProgressBar(
              progress: vm.progress,
              index: vm.currentIndex,
              total: vm.dueCards.length,
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _isDragging = true),
                  onPanUpdate: (d) => setState(() {
                    if (vm.isAnswerVisible) _dragOffset += d.delta;
                  }),
                  onPanEnd: (_) {
                    if (activeRating != null && vm.isAnswerVisible)
                      vm.rateCard(activeRating);
                    setState(() {
                      _isDragging = false;
                      _dragOffset = Offset.zero;
                    });
                  },
                  child: _FlashcardStack(
                    activeRating: activeRating,
                    flipAnimation: _flipAnimation,
                    dragOffset: _dragOffset,
                    isDragging: _isDragging && vm.isAnswerVisible,
                    card: card,
                  ),
                ),
              ),
            ),
            _StudyActionArea(vm: vm),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppBackground(
    child: const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    ),
  );
}

class _FinishedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration_rounded,
              size: 80,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Finished!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: const Text(
                'Back to Decks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NoCardsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppBackground(
    child: const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          'No cards available',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    ),
  );
}

class _StudyProgressBar extends StatelessWidget {
  final double progress;
  final int index;
  final int total;
  const _StudyProgressBar({
    required this.progress,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Card ${index + 1} / $total',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 10,
          ),
        ),
      ],
    ),
  );
}

class _FlashcardStack extends StatelessWidget {
  final StudyRating? activeRating;
  final Animation<double> flipAnimation;
  final Offset dragOffset;
  final bool isDragging;
  final dynamic card;
  const _FlashcardStack({
    required this.activeRating,
    required this.flipAnimation,
    required this.dragOffset,
    required this.isDragging,
    required this.card,
  });

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      if (activeRating != null) _RatingFeedback(rating: activeRating!),
      Transform.translate(
        offset: isDragging ? dragOffset : Offset.zero,
        child: AnimatedBuilder(
          animation: flipAnimation,
          builder: (context, _) {
            final angle = flipAnimation.value;
            final isBack = angle > pi / 2;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isBack
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _CardSide(text: card.translation, isBack: true),
                    )
                  : _CardSide(text: card.word, isBack: false),
            );
          },
        ),
      ),
    ],
  );
}

class _RatingFeedback extends StatelessWidget {
  final StudyRating rating;
  const _RatingFeedback({required this.rating});

  Color _getColor() {
    switch (rating) {
      case StudyRating.again:
        return Colors.redAccent;
      case StudyRating.good:
        return Colors.greenAccent;
      case StudyRating.easy:
        return Colors.blueAccent;
      case StudyRating.hard:
        return Colors.orangeAccent;
    }
  }

  String _getText() {
    switch (rating) {
      case StudyRating.again:
        return '🔴 ← AGAIN';
      case StudyRating.good:
        return '🟢 GOOD →';
      case StudyRating.easy:
        return '🔵 ↑ EASY';
      case StudyRating.hard:
        return '🟠 ↓ HARD';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 320,
    height: 320,
    decoration: BoxDecoration(
      color: _getColor().withValues(alpha: 0.1),
      border: Border.all(color: _getColor(), width: 3),
      borderRadius: BorderRadius.circular(40),
    ),
    child: Center(
      child: Text(
        _getText(),
        style: TextStyle(
          color: _getColor(),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    ),
  );
}

class _CardSide extends StatelessWidget {
  final String text;
  final bool isBack;
  const _CardSide({required this.text, required this.isBack});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(40),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        width: 310,
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: SingleChildScrollView(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isBack ? 28 : 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StudyActionArea extends StatelessWidget {
  final StudyViewModel vm;
  const _StudyActionArea({required this.vm});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 80.0),
    child: !vm.isAnswerVisible
        ? ElevatedButton.icon(
            onPressed: () => vm.showAnswer(),
            icon: const Icon(Icons.flip_rounded),
            label: const Text(
              'SHOW ANSWER',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Colors.white24),
              ),
              elevation: 0,
            ),
          )
        : const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Swipe to Rate',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '🔴 Again  •  🟠 Hard  •  🟢 Good  •  🔵 Easy',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
  );
}
