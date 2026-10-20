/// A card in a Study with AI session; [done] once answered correctly.
class StudyItem {
  final String id;
  final String word;
  final String translation;

  /// The AI's sentence with the word as "___"; null asks the word alone.
  final String? sentence;
  final bool done;
  final int misses;

  const StudyItem({
    required this.id,
    required this.word,
    required this.translation,
    this.sentence,
    this.done = false,
    this.misses = 0,
  });

  factory StudyItem.fromJson(Map<String, dynamic> json) => StudyItem(
    id: json['id'] as String,
    word: json['word'] as String,
    translation: json['translation'] as String,
    sentence: json['sentence'] as String?,
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
  final bool completed;

  const StudySession({
    required this.id,
    required this.deckId,
    required this.deckName,
    required this.items,
    this.current,
    this.completed = false,
  });

  int get total => items.length;

  /// Cards go in order, so the ones before [current] are behind.
  int get answeredCount => current ?? total;
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

class StudyReply {
  final bool correct;

  /// Missed twice: the answer is shown and the next card comes.
  final bool revealed;
  final StudyState state;

  const StudyReply({
    required this.correct,
    required this.state,
    this.revealed = false,
  });

  factory StudyReply.fromJson(Map<String, dynamic> json) => StudyReply(
    correct: json['verdict'] == 'correct',
    revealed: json['revealed'] as bool? ?? false,
    state: StudyState.fromJson(json),
  );
}

class StudyStart {
  final StudyState state;

  /// An unfinished session was open already (e.g. from another device).
  final bool resumed;

  const StudyStart({required this.state, this.resumed = false});

  factory StudyStart.fromJson(Map<String, dynamic> json) => StudyStart(
    state: StudyState.fromJson(json),
    resumed: json['resumed'] as bool? ?? false,
  );
}
