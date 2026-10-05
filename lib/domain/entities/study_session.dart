/// A card in a Study with AI session; it counts only once [done].
class StudyItem {
  final String id;
  final String word;
  final String translation;
  final bool done;
  final int misses;

  const StudyItem({
    required this.id,
    required this.word,
    required this.translation,
    this.done = false,
    this.misses = 0,
  });

  factory StudyItem.fromJson(Map<String, dynamic> json) => StudyItem(
    id: json['id'] as String,
    word: json['word'] as String,
    translation: json['translation'] as String,
    done: json['done'] as bool? ?? false,
    misses: json['misses'] as int? ?? 0,
  );
}

class StudySession {
  final String id;
  final String deckId;
  final String deckName;
  final List<StudyItem> items;

  /// Index in [items] of the card being practised; null once completed.
  final int? current;
  final String? task;
  final bool completed;

  const StudySession({
    required this.id,
    required this.deckId,
    required this.deckName,
    required this.items,
    this.current,
    this.task,
    this.completed = false,
  });

  int get total => items.length;
  int get doneCount => items.where((i) => i.done).length;
  StudyItem? get currentItem => current == null ? null : items[current!];

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'] as String,
    deckId: json['deckId'] as String,
    deckName: json['deckName'] as String,
    items: [
      for (final item in json['items'] as List<dynamic>)
        StudyItem.fromJson(item as Map<String, dynamic>),
    ],
    current: json['current'] as int?,
    task: json['task'] as String?,
    completed: json['completed'] as bool? ?? false,
  );
}

class StudyState {
  /// The unfinished session; after an answer, also the one that just ended.
  final StudySession? session;

  /// When the next session can start; null if it can start now.
  final DateTime? nextAvailableAt;
  final String? lastDeckId;
  final int cooldownSeconds;

  const StudyState({
    this.session,
    this.nextAvailableAt,
    this.lastDeckId,
    this.cooldownSeconds = 10800,
  });

  factory StudyState.fromJson(Map<String, dynamic> json) => StudyState(
    session: json['session'] is Map<String, dynamic>
        ? StudySession.fromJson(json['session'] as Map<String, dynamic>)
        : null,
    nextAvailableAt: json['nextAvailableAt'] is String
        ? DateTime.tryParse(json['nextAvailableAt'] as String)
        : null,
    lastDeckId: json['lastDeckId'] as String?,
    cooldownSeconds: json['cooldownSeconds'] as int? ?? 10800,
  );
}

/// rejected: the tutor said correct but the word wasn't in the answer.
enum StudyVerdict { correct, wrong, question, offTopic, rejected }

class StudyReply {
  final StudyVerdict verdict;

  /// The tutor's words; null for offTopic and rejected (no reply then).
  final String? feedback;

  /// Missed twice: the answer was shown and the card went to the back.
  final bool revealed;
  final bool limitReached;
  final StudyState state;

  const StudyReply({
    required this.verdict,
    required this.state,
    this.feedback,
    this.revealed = false,
    this.limitReached = false,
  });

  factory StudyReply.fromJson(Map<String, dynamic> json) => StudyReply(
    verdict: switch (json['verdict']) {
      'correct' => StudyVerdict.correct,
      'wrong' => StudyVerdict.wrong,
      'question' => StudyVerdict.question,
      'rejected' => StudyVerdict.rejected,
      _ => StudyVerdict.offTopic,
    },
    feedback: json['feedback'] as String?,
    revealed: json['revealed'] as bool? ?? false,
    limitReached: json['limitReached'] as bool? ?? false,
    state: StudyState.fromJson(json),
  );
}

class StudyStart {
  final StudyState state;

  /// The tutor's opening line; null when an unfinished session was resumed.
  final String? greeting;

  const StudyStart({required this.state, this.greeting});

  factory StudyStart.fromJson(Map<String, dynamic> json) => StudyStart(
    state: StudyState.fromJson(json),
    greeting: json['greeting'] as String?,
  );
}
