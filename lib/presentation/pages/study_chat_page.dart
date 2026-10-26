import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/entities/study_session.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import 'package:translate_app/presentation/pages/study_page.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/ai_study_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/study_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/l10n/l10n.dart';

const _correctColor = Color(0xFF7BD88F);
const _secondTryColor = Colors.amberAccent;
const _missedColor = Color(0xFFFF8A80);

/// Opens the flashcard study for [deck] (the regular, non-AI one).
void openFlashcards(BuildContext context, DeckEntity deck) {
  Navigator.push(
    context,
    // Swiping a card right rates it, so going back stays on the edge.
    SwipeablePageRoute(
      canOnlySwipeFromEdge: true,
      builder: (_) => ChangeNotifierProvider(
        create: (ctx) => StudyViewModel(deck, ctx.read<DeckUsecase>()),
        child: const StudyPage(),
      ),
    ),
  );
}

/// Study with AI chat: starts a session with [deck], or resumes the open one.
class StudyChatPage extends StatefulWidget {
  final DeckEntity? deck;

  const StudyChatPage({super.key, this.deck});

  @override
  State<StudyChatPage> createState() => _StudyChatPageState();
}

class _StudyChatPageState extends State<StudyChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AiStudyViewModel>().open(widget.deck);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(AiStudyViewModel vm) async {
    final text = _input.text;
    if (text.trim().isEmpty || vm.isBusy || !vm.hasUnfinishedSession) return;
    _input.clear();
    final before = vm.messages.length + 1;
    await vm.send(text);
    final replies = vm.messages.skip(before);
    // Success for a correct answer or the finish, a light tap for a tutor reply.
    if (vm.session?.completed == true || replies.any((m) => m.correct)) {
      HapticFeedback.successNotification();
    } else if (replies.any((m) => m.kind == StudyMessageKind.tutor)) {
      HapticFeedback.lightImpact();
    }
  }

  // Follows new messages to the bottom.
  void _scrollOnGrowth(int count) {
    if (count == _itemCount) return;
    _itemCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiStudyViewModel>();
    final session = vm.session;
    final messages = vm.messages;
    final finished = session?.completed ?? false;
    final starting = messages.isEmpty;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(vm, session, finished),
        body: Column(
          children: [
            if (session != null) _ProgressSegments(session: session),
            Expanded(
              // Tapping the chat closes the keyboard.
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: starting
                    ? _StartState(vm: vm)
                    : _buildMessages(vm, messages, session, finished),
              ),
            ),
            if (!starting && vm.error != null)
              _ErrorBar(error: vm.error!, onRetry: vm.retry),
            if (!starting && session != null && !finished)
              _InputBar(
                controller: _input,
                busy: vm.isBusy,
                onSend: () => _send(vm),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish(AiStudyViewModel vm) async {
    final hours = (vm.state?.cooldownSeconds ?? 10800) ~/ 3600;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: Text(
            l10n.finishSessionTitle,
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            l10n.finishSessionBody(hours),
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel, style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                l10n.endSession,
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
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (await vm.finishSession()) {
      HapticFeedback.mediumImpact();
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotEndSession)));
    }
  }

  PreferredSizeWidget _buildAppBar(
    AiStudyViewModel vm,
    StudySession? session,
    bool finished,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session?.deckName ?? widget.deck?.name ?? l10n.studyWithAi,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            l10n.studyWithAi,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      actions: [
        if (session != null && !finished)
          IconButton(
            tooltip: l10n.endSession,
            onPressed: vm.isBusy ? null : () => _finish(vm),
            icon: const Icon(Icons.flag_outlined),
          ),
        if (session != null)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${session.answeredCount}/${session.total}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessages(
    AiStudyViewModel vm,
    List<StudyMessage> messages,
    StudySession? session,
    bool finished,
  ) {
    final count = messages.length + (vm.isBusy || finished ? 1 : 0);
    _scrollOnGrowth(count);
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      itemCount: count,
      itemBuilder: (context, i) {
        if (i < messages.length) return _Bubble(message: messages[i]);
        if (finished && session != null) return _Summary(session: session);
        return const _TypingBubble();
      },
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  final StudySession session;

  const _ProgressSegments({required this.session});

  @override
  Widget build(BuildContext context) {
    Color colorOf(int i) {
      final item = session.items[i];
      if (item.done) return item.misses == 0 ? _correctColor : _secondTryColor;
      if (i < session.answeredCount) return _missedColor;
      if (i == session.current) return Colors.white;
      return Colors.white.withValues(alpha: 0.15);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          for (var i = 0; i < session.total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: colorOf(i),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final StudyMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.kind == StudyMessageKind.note) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      );
    }

    final mine = message.kind == StudyMessageKind.learner;
    const text = TextStyle(color: Colors.white, fontSize: 15, height: 1.35);
    final dim = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 15,
      height: 1.35,
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * (mine ? 0.72 : 0.84),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: mine ? 0.24 : 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: SelectableText.rich(
          TextSpan(
            style: text,
            children: [
              if (message.correct)
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: _correctColor,
                      size: 16,
                    ),
                  ),
                ),
              if (message.label != null)
                TextSpan(text: '${message.label} · ', style: dim),
              TextSpan(text: message.text),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  /// Left in the chat; centered on the loading screen.
  final AlignmentGeometry alignment;

  const _TypingBubble({this.alignment = Alignment.centerLeft});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(
                      alpha: 0.25 + 0.6 * _pulse(_controller.value, i),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Each dot lights up a third of a cycle after the previous one.
  static double _pulse(double t, int dot) {
    final phase = (t - dot / 3) % 1;
    return phase < 0.5 ? 1 - (phase * 2 - 0.5).abs() * 2 : 0;
  }
}

class _Summary extends StatelessWidget {
  final StudySession session;

  const _Summary({required this.session});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AiStudyViewModel>();
    final firstTry = session.items.where((i) => i.done && i.misses == 0).length;
    final secondTry = session.items.where((i) => i.done && i.misses > 0).length;
    final missed = session.items.where((i) => !i.done).length;
    final left = vm.cooldownLeft;
    final deck = context
        .read<DecksViewModel>()
        .decks
        .where((d) => d.syncId == session.deckId)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: _correctColor,
            size: 34,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.sessionComplete,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: l10n.firstTryCount(firstTry),
                  style: const TextStyle(color: _correctColor),
                ),
                if (secondTry > 0) ...[
                  const TextSpan(text: '  ·  '),
                  TextSpan(
                    text: l10n.secondTryCount(secondTry),
                    style: const TextStyle(color: _secondTryColor),
                  ),
                ],
                if (missed > 0) ...[
                  const TextSpan(text: '  ·  '),
                  TextSpan(
                    text: l10n.missedCount(missed),
                    style: const TextStyle(color: _missedColor),
                  ),
                ],
              ],
            ),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in session.items)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.word,
                    style: TextStyle(
                      fontSize: 13,
                      color: !item.done
                          ? _missedColor
                          : item.misses == 0
                          ? _correctColor
                          : _secondTryColor,
                    ),
                  ),
                ),
            ],
          ),
          if (left != null) ...[
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: l10n.nextSessionIn,
                children: [
                  TextSpan(
                    text: formatCountdown(left),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (deck != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => openFlashcards(context, deck),
                    style: _outlined,
                    child: Text(l10n.reviewWithFlashcardsShort),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: _outlined,
                  child: Text(l10n.done),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final _outlined = OutlinedButton.styleFrom(
  foregroundColor: Colors.white,
  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  padding: const EdgeInsets.symmetric(vertical: 12),
);

/// Before the first message: waiting for the tutor, or why it can't start.
class _StartState extends StatelessWidget {
  final AiStudyViewModel vm;

  const _StartState({required this.vm});

  @override
  Widget build(BuildContext context) {
    final error = vm.error;
    if (error == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TypingBubble(alignment: Alignment.center),
            const SizedBox(height: 10),
            Text(
              l10n.gettingWordsReady,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    final left = vm.cooldownLeft;
    final String message;
    if (error is FeatureNotAvailableException) {
      message = l10n.studyNeedsPlan;
    } else if (left != null) {
      message = l10n.nextSessionStartsIn(formatCountdown(left));
    } else {
      message = studyErrorText(error);
    }
    final canRetry = error is! FeatureNotAvailableException && left == null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              left != null
                  ? Icons.hourglass_bottom_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white54,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 18),
            if (error is FeatureNotAvailableException)
              OutlinedButton(
                style: _outlined,
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UpgradePage()),
                ),
                child: Text('  ${l10n.seePlans}  '),
              )
            else if (canRetry)
              OutlinedButton(
                style: _outlined,
                onPressed: vm.retry,
                child: Text('  ${l10n.tryAgain}  '),
              ),
          ],
        ),
      ),
    );
  }
}

String studyErrorText(AppException error) {
  if (error is NetworkException) return l10n.noInternet;
  if (error is QuotaExceededException) {
    return l10n.tooManyMessages;
  }
  if (error is AiServiceException) {
    switch (error.kind) {
      case AiFailure.busy:
        return l10n.aiBusy;
      case AiFailure.unavailable:
        return l10n.studyUnavailable;
      case AiFailure.timeout:
        return l10n.replyTooLong;
      default:
        break;
    }
  }
  return l10n.couldNotGetReply;
}

class _ErrorBar extends StatelessWidget {
  final AppException error;
  final VoidCallback onRetry;

  const _ErrorBar({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              studyErrorText(error),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retry,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: 300,
                minLines: 1,
                maxLines: 4,
                // The answer is compared letter by letter; autocorrect would change it.
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: l10n.typeAnswer,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final enabled = !busy && value.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: enabled ? onSend : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: enabled ? 0.25 : 0.08,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white.withValues(alpha: enabled ? 1 : 0.35),
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
