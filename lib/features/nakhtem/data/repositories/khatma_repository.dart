import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';
import '../models/khatma_models.dart';

/// Persistence for khatmas. The active khatma is selected by a simple
/// `app_kv` flag so a new khatma can be started without losing history.
class KhatmaRepository {
  KhatmaRepository(this._db);

  final AppDatabase _db;

  Database get _database => _db.db;

  Future<Khatma> create({
    required String name,
    required String edition,
    required int startingGlobalAyah,
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    final khatma = Khatma(
      id: 'k${t.microsecondsSinceEpoch}',
      name: name,
      edition: edition,
      startedAt: t,
      startingGlobalAyah: startingGlobalAyah,
      currentGlobalAyah: startingGlobalAyah,
      versesRead: 0,
      status: KhatmaStatus.active,
      createdAt: t,
      updatedAt: t,
    );
    await _database.insert('khatmas', khatma.toMap());
    await _db.putKV('active_khatma_id', khatma.id);
    return khatma;
  }

  Future<Khatma?> update(Khatma k) async {
    await _database.update(
      'khatmas',
      k.copyWith().toMap(),
      where: 'id = ?',
      whereArgs: [k.id],
    );
    return findById(k.id);
  }

  Future<Khatma?> findById(String id) async {
    final rows = await _database.query(
      'khatmas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Khatma.fromMap(rows.first);
  }

  /// The currently-active khatma (most recent selected via `active_khatma_id`,
  /// falling back to the newest non-completed one).
  Future<Khatma?> activeKhatma() async {
    final id = await _db.getKV('active_khatma_id');
    if (id != null) {
      final k = await findById(id);
      if (k != null && !k.isCompleted) return k;
    }
    final rows = await _database.query(
      'khatmas',
      where: 'status != ?',
      whereArgs: [KhatmaStatus.completed.code],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Khatma.fromMap(rows.first);
  }

  Future<void> setActive(String id) => _db.putKV('active_khatma_id', id);

  /// Wipes every khatma and the active-khatma pointer (full reset).
  /// Khatma *settings* (reciter, edition) live in the KV settings blob and
  /// are deliberately kept.
  Future<void> clearAll() async {
    await _database.delete('khatmas');
    await _db.deleteKV('active_khatma_id');
  }

  Future<void> markCompleted(Khatma k, DateTime? now) async {
    final t = now ?? DateTime.now();
    await update(
      k.copyWith(status: KhatmaStatus.completed, completedAt: t),
    );
    await _db.deleteKV('active_khatma_id');
  }

  Future<void> setStatus(Khatma k, KhatmaStatus status) async {
    await update(k.copyWith(status: status));
  }

  Future<List<Khatma>> all() async {
    final rows = await _database.query(
      'khatmas',
      orderBy: 'started_at DESC',
    );
    return rows.map(Khatma.fromMap).toList();
  }

  Future<List<Khatma>> previous() async {
    final rows = await _database.query(
      'khatmas',
      where: 'status = ? OR status = ?',
      whereArgs: [KhatmaStatus.completed.code, KhatmaStatus.paused.code],
      orderBy: 'started_at DESC',
    );
    return rows.map(Khatma.fromMap).toList();
  }
}
