import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local user database (khatmas, reading events, progress, app state).
///
/// Quran assets are NOT stored here — they remain immutable bundled JSON
/// assets imported through [QuranRepository]. This DB holds only user data,
/// so it can be cleared/migrated without touching the Quran.
class AppDatabase {
  AppDatabase._(this._db, this.dbPath);

  final Database _db;

  /// Absolute SQLite file path (published to the home-screen widget
  /// so native code opens the exact same database file).
  final String dbPath;

  static const _version = 3;

  static Future<AppDatabase> open({String? overridePath}) async {
    final path = overridePath ??
        p.join(await getDatabasesPath(), 'khatma_app.db');
    final db = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _onCreate(db, version);
        await _createTodoTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTodoTables(db);
        }
        if (oldVersion < 3) {
          // Custom repeat weekdays (CSV of DateTime weekday numbers).
          await db.execute(
            'ALTER TABLE todo_tasks ADD COLUMN repeat_weekdays TEXT',
          );
        }
      },
    );
    return AppDatabase._(db, path);
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

  static Future<void> _createTodoTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS todo_tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        due_date TEXT,
        due_time TEXT,
        reminder_date_time TEXT,
        repeat_rule TEXT,
        repeat_weekdays TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        category_id TEXT NOT NULL DEFAULT 'all',
        tags TEXT,
        subtasks TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_todo_tasks_due ON todo_tasks (due_date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_todo_tasks_completed ON todo_tasks (is_completed)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_todo_tasks_category ON todo_tasks (category_id)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS todo_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
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
