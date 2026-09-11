import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';
import '../models/khatma_models.dart';

/// Persistence for reading events and the canonical reading position.
///
/// The [ReadingProgress] row is the **single source of truth** for the current
/// ayah position. `temporaryViewedAyah` is explicitly NOT persisted — it is
/// ephemeral UI state held only by the reader controller.
class ReadingRepository {
  ReadingRepository(this._db);

  final AppDatabase _db;

  Database get _database => _db.db;

  // ---------------------------------------------------------------------
  // Progress (canonical position)
  // ---------------------------------------------------------------------

  Future<void> saveProgress(ReadingProgress p) => _database.insert(
        'reading_progress',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// Wipes every reading event and saved position (full reset).
  Future<void> clearAll() async {
    await _database.delete('reading_events');
    await _database.delete('reading_progress');
  }

  Future<ReadingProgress?> loadProgress() async {
    final rows = await _database.query('reading_progress', limit: 1);
    if (rows.isEmpty) return null;
    return ReadingProgress.fromMap(rows.first);
  }

  // ---------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------

  Future<void> insertEvent(ReadingEvent e) =>
      _database.insert('reading_events', e.toMap());

  Future<List<ReadingEvent>> events({
    String? khatmaId,
    ReadingStatus? status,
    String? source,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (khatmaId != null) {
      where.add('khatma_id = ?');
      args.add(khatmaId);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.code);
    }
    if (source != null) {
      where.add('source = ?');
      args.add(source);
    }
    final rows = await _database.query(
      'reading_events',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'completed_at ASC, started_at ASC',
    );
    return rows.map(ReadingEvent.fromMap).toList();
  }

  /// Completed events between two [DateTime] (inclusive) using the local
  /// calendar dates. [start] and [end] are normalized to local midnight.
  Future<List<ReadingEvent>> completedBetween(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _database.query(
      'reading_events',
      where: 'status = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        ReadingStatus.completed.code,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'completed_at ASC',
    );
    return rows.map(ReadingEvent.fromMap).toList();
  }

  /// Completed events grouped by local day, within [start, end).
  Future<List<DailyCount>> dailyCounts(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _database.rawQuery(
      '''
      SELECT substr(completed_at, 1, 10) AS day, COUNT(*) AS cnt
      FROM reading_events
      WHERE status = ? AND completed_at >= ? AND completed_at < ?
      GROUP BY day
      ORDER BY day ASC
      ''',
      [
        ReadingStatus.completed.code,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );
    return rows.map((r) {
      final d = DateTime.parse('${r['day']}T00:00:00');
      return DailyCount(day: d, count: (r['cnt'] as num).toInt());
    }).toList();
  }

  /// Sum of completed durations grouped by local day, within [start, end).
  Future<List<DailyMinutes>> dailyMinutes(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _database.rawQuery(
      '''
      SELECT substr(completed_at, 1, 10) AS day, SUM(duration_seconds) AS secs
      FROM reading_events
      WHERE status = ? AND completed_at >= ? AND completed_at < ?
        AND duration_seconds IS NOT NULL
      GROUP BY day
      ORDER BY day ASC
      ''',
      [
        ReadingStatus.completed.code,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );
    return rows.map((r) {
      final d = DateTime.parse('${r['day']}T00:00:00');
      final secs = (r['secs'] as num?)?.toDouble() ?? 0;
      return DailyMinutes(day: d, minutes: (secs / 60).round());
    }).toList();
  }

  Future<({int total, int completed, int shown, int later})> totals() async {
    final rows = await _database.rawQuery(
      'SELECT status, COUNT(*) AS cnt FROM reading_events GROUP BY status',
    );
    var total = 0, completed = 0, shown = 0, later = 0;
    for (final r in rows) {
      final c = (r['cnt'] as num).toInt();
      total += c;
      switch (r['status']) {
        case 'completed':
          completed = c;
          break;
        case 'shown':
          shown = c;
          break;
        case 'later':
          later = c;
          break;
      }
    }
    return (total: total, completed: completed, shown: shown, later: later);
  }

  /// The set of distinct local days that have at least one completed event.
  Future<List<DateTime>> activeDays() async {
    final rows = await _database.rawQuery(
      '''
      SELECT DISTINCT substr(completed_at, 1, 10) AS day
      FROM reading_events
      WHERE status = ?
      ORDER BY day ASC
      ''',
      [ReadingStatus.completed.code],
    );
    return rows.map((r) => DateTime.parse('${r['day']}T00:00:00')).toList();
  }

  Future<ReadingEvent?> firstCompleted() async {
    final rows = await _database.query(
      'reading_events',
      where: 'status = ?',
      whereArgs: [ReadingStatus.completed.code],
      orderBy: 'completed_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReadingEvent.fromMap(rows.first);
  }

  Future<bool> hasCompletedOn(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _database.query(
      'reading_events',
      where: 'status = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        ReadingStatus.completed.code,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
