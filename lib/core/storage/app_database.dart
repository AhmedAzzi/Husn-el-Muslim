import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local user database (khatmas, reading events, progress, app state).
///
/// Quran assets are NOT stored here — they remain immutable bundled JSON
/// assets imported through [QuranRepository]. This DB holds only user data,
/// so it can be cleared/migrated without touching the Quran.
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static const _version = 1;

  static Future<AppDatabase> open({String? overridePath}) async {
    final path = overridePath ??
        p.join(await getDatabasesPath(), 'khatma_app.db');
    final db = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE khatmas (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        edition TEXT NOT NULL DEFAULT 'hafs',
        started_at TEXT NOT NULL,
        starting_global_ayah INTEGER NOT NULL,
        current_global_ayah INTEGER NOT NULL,
        verses_read INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        completed_at TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reading_events (
        id TEXT PRIMARY KEY,
        khatma_id TEXT NOT NULL,
        global_ayah_index INTEGER NOT NULL,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        status TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        duration_seconds INTEGER,
        source TEXT
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_events_completed ON reading_events (completed_at)
    ''');
    await db.execute('''
      CREATE INDEX idx_events_khatma ON reading_events (khatma_id)
    ''');
    await db.execute('''
      CREATE TABLE reading_progress (
        khatma_id TEXT PRIMARY KEY,
        current_global_ayah INTEGER NOT NULL,
        verses_read INTEGER NOT NULL DEFAULT 0,
        last_shown_at TEXT,
        last_completed_at TEXT,
        last_summary_date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE app_kv (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Database get db => _db;

  /// Generic key-value store for lightweight app state (incl. onboarding
  /// completion, last shown summary date, etc.).
  Future<void> putKV(String key, String value) async {
    await _db.insert(
      'app_kv',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getKV(String key) async {
    final rows = await _db.query(
      'app_kv',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> deleteKV(String key) async =>
      _db.delete('app_kv', where: 'key = ?', whereArgs: [key]);

  Future<void> close() => _db.close();
}
