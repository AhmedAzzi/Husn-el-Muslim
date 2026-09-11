/// Domain models for the khatma / reading engine.
///
/// These models are deliberately independent of Flutter and of any storage
/// backend so they can be unit-tested in isolation and reused across layers.
library;

enum KhatmaStatus {
  active,
  paused,
  completed;

  static KhatmaStatus from(String? raw) {
    switch (raw) {
      case 'completed':
        return KhatmaStatus.completed;
      case 'paused':
        return KhatmaStatus.paused;
      default:
        return KhatmaStatus.active;
    }
  }

  String get code {
    switch (this) {
      case KhatmaStatus.active:
        return 'active';
      case KhatmaStatus.paused:
        return 'paused';
      case KhatmaStatus.completed:
        return 'completed';
    }
  }
}

/// One complete pass over the Quran (a "khatma").
///
/// [currentGlobalAyah] is the canonical 1-based global ayah index the user is
/// *currently reading* (not yet completed). [versesRead] counts completed
/// ayahs. [edition] records the narration used for this pass.
class Khatma {
  const Khatma({
    required this.id,
    required this.name,
    required this.edition,
    required this.startedAt,
    required this.startingGlobalAyah,
    required this.currentGlobalAyah,
    required this.versesRead,
    required this.status,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String edition; // QuranEdition.id
  final DateTime startedAt;
  final int startingGlobalAyah;
  final int currentGlobalAyah;
  final int versesRead;
  final KhatmaStatus status;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => status == KhatmaStatus.completed;

  Khatma copyWith({
    String? name,
    String? edition,
    DateTime? startedAt,
    int? startingGlobalAyah,
    int? currentGlobalAyah,
    int? versesRead,
    KhatmaStatus? status,
    DateTime? completedAt,
  }) =>
      Khatma(
        id: id,
        name: name ?? this.name,
        edition: edition ?? this.edition,
        startedAt: startedAt ?? this.startedAt,
        startingGlobalAyah: startingGlobalAyah ?? this.startingGlobalAyah,
        currentGlobalAyah: currentGlobalAyah ?? this.currentGlobalAyah,
        versesRead: versesRead ?? this.versesRead,
        status: status ?? this.status,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'edition': edition,
        'started_at': startedAt.toIso8601String(),
        'starting_global_ayah': startingGlobalAyah,
        'current_global_ayah': currentGlobalAyah,
        'verses_read': versesRead,
        'status': status.code,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Khatma.fromMap(Map<String, Object?> m) => Khatma(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        edition: m['edition'] as String? ?? 'hafs',
        startedAt: DateTime.parse(m['started_at'] as String),
        startingGlobalAyah: (m['starting_global_ayah'] as num).toInt(),
        currentGlobalAyah: (m['current_global_ayah'] as num).toInt(),
        versesRead: (m['verses_read'] as num?)?.toInt() ?? 0,
        status: KhatmaStatus.from(m['status'] as String?),
        completedAt: m['completed_at'] == null
            ? null
            : DateTime.parse(m['completed_at'] as String),
        createdAt: m['created_at'] == null
            ? null
            : DateTime.tryParse(m['created_at'] as String),
        updatedAt: m['updated_at'] == null
            ? null
            : DateTime.tryParse(m['updated_at'] as String),
      );
}

/// A single reading event — the only thing that drives accurate statistics.
///
/// An ayah must NOT be counted merely because it was displayed. Only a
/// [ReadingStatus.completed] event contributes to progress and statistics.
enum ReadingStatus {
  /// The ayah was shown to the user.
  shown,

  /// The user explicitly completed reading it ("تمت القراءة").
  completed,

  /// The user postponed it ("Later"); no progress.
  later;

  static ReadingStatus from(String? raw) {
    switch (raw) {
      case 'completed':
        return ReadingStatus.completed;
      case 'later':
        return ReadingStatus.later;
      default:
        return ReadingStatus.shown;
    }
  }

  String get code {
    switch (this) {
      case ReadingStatus.shown:
        return 'shown';
      case ReadingStatus.completed:
        return 'completed';
      case ReadingStatus.later:
        return 'later';
    }
  }
}

class ReadingEvent {
  const ReadingEvent({
    required this.id,
    required this.khatmaId,
    required this.globalAyahIndex,
    required this.surah,
    required this.ayah,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.durationSeconds,
    this.source,
  });

  final String id;
  final String khatmaId;
  final int globalAyahIndex;
  final int surah;
  final int ayah;
  final ReadingStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Duration of the reading in seconds (when known).
  final int? durationSeconds;

  /// Origin: 'reader', 'notification', 'widget', 'onboarding', ...
  final String? source;

  /// Local-day date of the completion/start, used for daily stats.
  DateTime? get day => (completedAt ?? startedAt);

  Map<String, Object?> toMap() => {
        'id': id,
        'khatma_id': khatmaId,
        'global_ayah_index': globalAyahIndex,
        'surah': surah,
        'ayah': ayah,
        'status': status.code,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'duration_seconds': durationSeconds,
        'source': source,
      };

  factory ReadingEvent.fromMap(Map<String, Object?> m) => ReadingEvent(
        id: m['id'] as String,
        khatmaId: m['khatma_id'] as String? ?? '',
        globalAyahIndex: (m['global_ayah_index'] as num).toInt(),
        surah: (m['surah'] as num).toInt(),
        ayah: (m['ayah'] as num).toInt(),
        status: ReadingStatus.from(m['status'] as String?),
        startedAt: m['started_at'] == null
            ? null
            : DateTime.tryParse(m['started_at'] as String),
        completedAt: m['completed_at'] == null
            ? null
            : DateTime.tryParse(m['completed_at'] as String),
        durationSeconds: (m['duration_seconds'] as num?)?.toInt(),
        source: m['source'] as String?,
      );
}

/// The canonical reading position for the app (single source of truth).
class ReadingProgress {
  const ReadingProgress({
    required this.khatmaId,
    required this.currentGlobalAyah,
    this.versesRead = 0,
    this.lastShownAt,
    this.lastCompletedAt,
    this.lastSummaryDate,
  });

  final String khatmaId;
  final int currentGlobalAyah;
  final int versesRead;
  final DateTime? lastShownAt;
  final DateTime? lastCompletedAt;

  /// The (local) date on which the daily summary was last shown, so we do not
  /// nag the user every time the app opens.
  final DateTime? lastSummaryDate;

  ReadingProgress copyWith({
    String? khatmaId,
    int? currentGlobalAyah,
    int? versesRead,
    DateTime? lastShownAt,
    DateTime? lastCompletedAt,
    DateTime? lastSummaryDate,
  }) =>
      ReadingProgress(
        khatmaId: khatmaId ?? this.khatmaId,
        currentGlobalAyah: currentGlobalAyah ?? this.currentGlobalAyah,
        versesRead: versesRead ?? this.versesRead,
        lastShownAt: lastShownAt ?? this.lastShownAt,
        lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
        lastSummaryDate: lastSummaryDate ?? this.lastSummaryDate,
      );

  Map<String, Object?> toMap() => {
        'khatma_id': khatmaId,
        'current_global_ayah': currentGlobalAyah,
        'verses_read': versesRead,
        'last_shown_at': lastShownAt?.toIso8601String(),
        'last_completed_at': lastCompletedAt?.toIso8601String(),
        'last_summary_date': lastSummaryDate?.toIso8601String(),
      };

  factory ReadingProgress.fromMap(Map<String, Object?> m) => ReadingProgress(
        khatmaId: m['khatma_id'] as String? ?? '',
        currentGlobalAyah: (m['current_global_ayah'] as num).toInt(),
        versesRead: (m['verses_read'] as num?)?.toInt() ?? 0,
        lastShownAt: m['last_shown_at'] == null
            ? null
            : DateTime.tryParse(m['last_shown_at'] as String),
        lastCompletedAt: m['last_completed_at'] == null
            ? null
            : DateTime.tryParse(m['last_completed_at'] as String),
        lastSummaryDate: m['last_summary_date'] == null
            ? null
            : DateTime.tryParse(m['last_summary_date'] as String),
      );
}

/// An aggregate count of completed ayahs per local calendar day.
class DailyCount {
  const DailyCount({required this.day, required this.count});
  final DateTime day; // normalized to local midnight
  final int count;
}

/// Aggregated reading time (in minutes) per local calendar day.
class DailyMinutes {
  const DailyMinutes({required this.day, required this.minutes});
  final DateTime day;
  final int minutes;
}
