import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/data/services/study_card_picker.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/entities/study_session.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';

enum StudyMessageKind { tutor, task, learner, note }

class StudyMessage {
  final StudyMessageKind kind;
  final String text;

  /// Card number on a task, e.g. "3/10".
  final String? label;
  final bool correct;

  const StudyMessage(this.kind, this.text, {this.label, this.correct = false});

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'text': text,
    if (label != null) 'label': label,
    if (correct) 'correct': true,
  };

  factory StudyMessage.fromJson(Map<String, dynamic> json) => StudyMessage(
    StudyMessageKind.values.byName(json['kind'] as String),
    json['text'] as String,
    label: json['label'] as String?,
    correct: json['correct'] as bool? ?? false,
  );
}

/// Study with AI: the decks button's state and the chat (kept to resume it).
class AiStudyViewModel extends ChangeNotifier {
  final TranslateUsecase _translate;
  final DeckUsecase _decks;
  final SettingsService _settings;
  final VoidCallback? onCardsChanged;
  final DateTime Function() _now;

  AiStudyViewModel(
    this._translate,
    this._decks,
    this._settings, {
    this.onCardsChanged,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const offTopicNote = 'Only answers to the exercise get a reply.';
  static const rejectedNote = 'Write the word exactly as it is on your card.';
  static const limitNote = 'This session reached its message limit.';

  StudyState? _state;
  final List<StudyMessage> _messages = [];
  bool _busy = false;
  AppException? _error;
  String? _unsent;
  DeckEntity? _startingDeck;
  Timer? _ticker;

  StudyState? get state => _state;
  StudySession? get session => _state?.session;
  List<StudyMessage> get messages => List.unmodifiable(_messages);
  bool get isBusy => _busy;
  AppException? get error => _error;
  bool get hasUnfinishedSession => session != null && !session!.completed;

  /// Time until the next session can start; null when it can start now.
  Duration? get cooldownLeft {
    final at = _state?.nextAvailableAt;
    if (at == null) return null;
    final left = at.difference(_now());
    return left > Duration.zero ? left : null;
  }

  Future<void> refresh() async {
    try {
      _setState(await _translate.fetchStudyState());
    } catch (e) {
      debugPrint('[STUDY] state failed: $e');
    }
  }

  /// Resumes the unfinished session, or starts one with [deck].
  Future<void> open(DeckEntity? deck) async {
    if (_busy) return;
    if (hasUnfinishedSession) {
      _resume();
    } else if (deck != null) {
      await _start(deck);
    }
  }

  Future<void> send(String text) async {
    final answer = text.trim();
    if (answer.isEmpty || _busy || !hasUnfinishedSession) return;
    _messages.add(StudyMessage(StudyMessageKind.learner, answer));
    _saveChat();
    await _answer(answer);
  }

  Future<void> retry() async {
    if (_unsent != null) {
      await _answer(_unsent!);
    } else if (_startingDeck != null) {
      await _start(_startingDeck!);
    }
  }

  Future<void> _start(DeckEntity deck) async {
    final cards = pickStudyCards(deck.cards);
    if (cards.isEmpty) {
      _error = const GeneralException('Not enough words in this deck');
      notifyListeners();
      return;
    }
    _startingDeck = deck;
    _messages.clear();
    _setBusy(true);
    try {
      final result = await _translate.startStudy(
        deckId: deck.syncId,
        deckName: deck.name,
        cards: [
          for (final c in cards)
            (
              id: c.syncId,
              word: c.word.trim(),
              translation: c.translation.trim(),
            ),
        ],
      );
      _startingDeck = null;
      _setState(result.state);
      final greeting = result.greeting;
      if (greeting == null) {
        // Another session was still open (e.g. from another device).
        _resume();
      } else {
        _messages.add(StudyMessage(StudyMessageKind.tutor, greeting));
        _addTask();
        _saveChat();
        final now = _now();
        await _updateCards({
          for (final c in cards) c.syncId: (card) => card.aiStudiedAt = now,
        });
      }
    } on QuotaExceededException catch (e) {
      // Usually the cooldown: the state tells how long.
      _startingDeck = null;
      _error = e;
      await refresh();
    } on AppException catch (e) {
      _error = e;
    } catch (e) {
      _error = GeneralException('Could not start', details: e.toString());
    } finally {
      _setBusy(false);
    }
  }

  void _resume() {
    final current = session;
    if (current == null) return;
    _messages
      ..clear()
      ..addAll(_storedChat(current.id));
    final lastTask = _messages
        .lastWhere(
          (m) => m.kind == StudyMessageKind.task,
          orElse: () => const StudyMessage(StudyMessageKind.task, ''),
        )
        .text;
    // No chat saved here, or the session moved on without it.
    if (lastTask != current.task) {
      final left = current.total - current.doneCount;
      _messages.add(
        StudyMessage(
          StudyMessageKind.note,
          'Welcome back, $left ${left == 1 ? 'word' : 'words'} to go.',
        ),
      );
      _addTask();
      _saveChat();
    }
    notifyListeners();
  }

  Future<void> _answer(String answer) async {
    final id = session?.id;
    if (id == null) return;
    _unsent = answer;
    _setBusy(true);
    try {
      final reply = await _translate.answerStudy(id, answer);
      _unsent = null;
      await _applyReply(reply);
    } on AiServiceException catch (e) {
      if (e.code == 'session_not_found' || e.code == 'conflict') {
        // Finished or answered elsewhere: show the server's view.
        _unsent = null;
        await refresh();
        if (hasUnfinishedSession) _resume();
      } else {
        _error = e;
      }
    } on AppException catch (e) {
      _error = e;
    } catch (e) {
      _error = GeneralException('Could not send', details: e.toString());
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _applyReply(StudyReply reply) async {
    final feedback = reply.feedback;
    switch (reply.verdict) {
      case StudyVerdict.offTopic:
        _messages.add(const StudyMessage(StudyMessageKind.note, offTopicNote));
      case StudyVerdict.rejected:
        _messages.add(const StudyMessage(StudyMessageKind.note, rejectedNote));
      case StudyVerdict.correct:
        _messages.add(
          StudyMessage(StudyMessageKind.tutor, feedback ?? '', correct: true),
        );
      case StudyVerdict.wrong || StudyVerdict.question:
        if (feedback != null && feedback.isNotEmpty) {
          _messages.add(StudyMessage(StudyMessageKind.tutor, feedback));
        }
    }
    _setState(reply.state);
    final finished = session?.completed ?? true;
    if (reply.limitReached) {
      _messages.add(const StudyMessage(StudyMessageKind.note, limitNote));
    }
    final newTask = reply.verdict == StudyVerdict.correct || reply.revealed;
    if (!finished && newTask) _addTask();

    if (finished) {
      _settings.setAiStudyChat(null);
      final items = session?.items ?? const <StudyItem>[];
      await _updateCards({
        for (final item in items)
          item.id: (card) => card.aiNeedsReview = item.misses > 0,
      });
    } else {
      _saveChat();
    }
  }

  void _addTask() {
    final current = session;
    final task = current?.task;
    if (current == null || task == null) return;
    _messages.add(
      StudyMessage(
        StudyMessageKind.task,
        task,
        label: '${current.doneCount + 1}/${current.total}',
      ),
    );
  }

  Future<void> _updateCards(
    Map<String, void Function(CardEntity card)> changes,
  ) async {
    try {
      final decks = await _decks.executeGetAllDecks();
      for (final card in decks.expand((d) => d.cards)) {
        final change = changes[card.syncId];
        if (change == null) continue;
        change(card);
        await _decks.executeUpdateCard(card);
      }
      onCardsChanged?.call();
    } catch (e) {
      debugPrint('[STUDY] card update failed: $e');
    }
  }

  List<StudyMessage> _storedChat(String sessionId) {
    final raw = _settings.aiStudyChat;
    if (raw == null) return const [];
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['sessionId'] != sessionId) return const [];
      return [
        for (final m in json['messages'] as List<dynamic>)
          StudyMessage.fromJson(m as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _saveChat() {
    final id = session?.id;
    if (id == null) return;
    _settings.setAiStudyChat(
      jsonEncode({
        'sessionId': id,
        'messages': [for (final m in _messages) m.toJson()],
      }),
    );
  }

  void _setBusy(bool value) {
    _busy = value;
    if (value) _error = null;
    notifyListeners();
  }

  void _setState(StudyState value) {
    _state = value;
    _ticker?.cancel();
    _ticker = null;
    if (cooldownLeft != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (cooldownLeft == null) {
          timer.cancel();
          _ticker = null;
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// "2:41:07" above an hour, "41:07" below.
String formatCountdown(Duration left) {
  final h = left.inHours;
  final m = left.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
