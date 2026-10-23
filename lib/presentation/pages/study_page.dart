import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../viewmodels/study_viewmodel.dart';
import '../viewmodels/decks_viewmodel.dart';
import '../widgets/add_card_dialog.dart';
import '../../data/services/srs_service.dart';
import '../widgets/app_background.dart';
import 'package:translate_app/l10n/l10n.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

/// A rated card on its way off the screen.
typedef _Leaving = ({dynamic card, StudyRating rating, Offset from, Offset to});

class _StudyPageState extends State<StudyPage> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  int? _previousCardId;

  // The rated card flies off, the next one grows into place, a dropped one slides back.
  late final AnimationController _leave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  late final AnimationController _snapBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  _Leaving? _leaving;
  Offset _snapFrom = Offset.zero;

  Offset get _snapOffset => Offset.lerp(
    _snapFrom,
    Offset.zero,
    Curves.easeOutCubic.transform(_snapBack.value),
  )!;

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
    _leave.dispose();
    _enter.dispose();
    _snapBack.dispose();
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

  void _release(StudyViewModel vm, dynamic card, StudyRating? rating) {
    if (rating != null && vm.isAnswerVisible) {
      final direction = _dragOffset / _dragOffset.distance;
      _leaving = (
        card: card,
        rating: rating,
        from: _dragOffset,
        to: _dragOffset + direction * 480,
      );
      _leave.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        // Same card again (e.g. the last one rated Again): bring it back in.
        if (_leaving?.card.id == _previousCardId) _enter.forward(from: 0);
        setState(() => _leaving = null);
      });
      _rate(vm, rating);
    } else {
      _snapFrom = _dragOffset;
      _snapBack.forward(from: 0);
    }
    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });
  }

  Future<void> _rate(StudyViewModel vm, StudyRating rating) async {
    await vm.rateCard(rating);
    vm.isFinished
        ? HapticFeedback.successNotification()
        : HapticFeedback.lightImpact();
  }

  // An empty deck starts its session with the cards added here.
  Future<void> _addFirstCards(StudyViewModel vm) async {
    final decks = context.read<DecksViewModel>();
    await AddCardDialog.show(context, vm.deck);
    final updated = decks.decks.where((d) => d.id == vm.deck.id).firstOrNull;
    if (updated != null) vm.cardsAdded(updated);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StudyViewModel>(context);
    const Color ip = Colors.white;

    if (vm.isLoading) return _LoadingView();
    if (vm.error != null) return _ErrorView(message: vm.error!);
    if (vm.deckIsEmpty) return _EmptyDeckView(onAdd: () => _addFirstCards(vm));
    if (vm.isFinished) return _FinishedView();

    final card = vm.currentCard;
    if (card == null) return _NoCardsView();

    if (_previousCardId != card.id) {
      _flipController.animateTo(0, duration: Duration.zero);
      if (_previousCardId != null) _enter.forward(from: 0);
      _previousCardId = card.id;
    }
    if (vm.isAnswerVisible && _flipController.value == 0) {
      _flipController.forward();
    } else if (!vm.isAnswerVisible && _flipController.value == 1) {
      _flipController.reverse();
    }

    final activeRating = _isDragging ? _getRatingFromOffset(_dragOffset) : null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // The add card dialog's keyboard must not push the card around.
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            vm.deck.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: ip,
          actions: [
            // Added cards wait for the next session.
            IconButton(
              tooltip: l10n.addCard,
              icon: const Icon(Icons.add_rounded),
              onPressed: () => AddCardDialog.show(context, vm.deck),
            ),
          ],
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
                  onPanStart: (_) => setState(() {
                    // Catch a card that is still sliding back.
                    if (_snapBack.isAnimating) {
                      _dragOffset = _snapOffset;
                      _snapBack.value = 1;
                    }
                    _isDragging = true;
                  }),
                  onPanUpdate: (d) => setState(() {
                    if (!vm.isAnswerVisible) return;
                    final before = _getRatingFromOffset(_dragOffset);
                    _dragOffset += d.delta;
                    final after = _getRatingFromOffset(_dragOffset);
                    if (after != null && after != before) {
                      HapticFeedback.selectionClick();
                    }
                  }),
                  onPanEnd: (_) => _release(vm, card, activeRating),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_leave, _enter, _snapBack]),
                    builder: (context, _) => _FlashcardStack(
                      activeRating: activeRating,
                      flipAnimation: _flipAnimation,
                      offset: _isDragging && vm.isAnswerVisible
                          ? _dragOffset
                          : _snapOffset,
                      enter: Curves.easeOutCubic.transform(_enter.value),
                      hidden: _leaving?.card.id == card.id,
                      leaving: _leaving,
                      leaveProgress: _leave.value,
                      card: card,
                    ),
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

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => AppBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
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
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Text(
                l10n.backToDecks,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
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
            Text(
              l10n.sessionFinished,
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
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Text(
                l10n.backToDecks,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A deck without cards: add the first ones right here.
class _EmptyDeckView extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyDeckView({required this.onAdd});

  @override
  Widget build(BuildContext context) => AppBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noCardsAdded,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                l10n.addCard,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
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
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          l10n.noCardsAvailable,
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
              l10n.cardProgress(index + 1, total),
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
  final Offset offset;

  /// 0 → 1 while the card grows into place.
  final double enter;
  final bool hidden;
  final _Leaving? leaving;
  final double leaveProgress;
  final dynamic card;
  const _FlashcardStack({
    required this.activeRating,
    required this.flipAnimation,
    required this.offset,
    required this.enter,
    required this.hidden,
    required this.leaving,
    required this.leaveProgress,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final leaving = this.leaving;
    final fade = 1 - leaveProgress;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (activeRating != null) _RatingFeedback(rating: activeRating!),
        if (leaving != null)
          Opacity(
            opacity: fade,
            child: _RatingFeedback(rating: leaving.rating),
          ),
        Opacity(
          opacity: hidden ? 0 : enter,
          child: Transform.scale(
            scale: 0.9 + 0.1 * enter,
            child: Transform.translate(offset: offset, child: _flippingCard()),
          ),
        ),
        if (leaving != null)
          Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset.lerp(
                leaving.from,
                leaving.to,
                Curves.easeOutCubic.transform(leaveProgress),
              )!,
              child: _CardSide(text: leaving.card.translation, isBack: true),
            ),
          ),
      ],
    );
  }

  Widget _flippingCard() => AnimatedBuilder(
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
        return l10n.rateAgain;
      case StudyRating.good:
        return l10n.rateGood;
      case StudyRating.easy:
        return l10n.rateEasy;
      case StudyRating.hard:
        return l10n.rateHard;
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
            onPressed: () {
              HapticFeedback.lightImpact();
              vm.showAnswer();
            },
            icon: const Icon(Icons.flip_rounded),
            label: Text(
              l10n.showAnswer,
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
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.swipeToRate,
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                l10n.rateLegend,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
  );
}
