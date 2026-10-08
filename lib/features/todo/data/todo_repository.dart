import 'package:sqflite/sqflite.dart';
import 'package:small_husn_muslim/core/storage/app_database.dart';
import 'package:small_husn_muslim/features/todo/models/todo_category.dart';
import 'package:small_husn_muslim/features/todo/models/todo_item.dart';

class TodoRepository {
  final AppDatabase database;

  TodoRepository(this.database);

  Database get _db => database.db;

  Future<List<TodoItem>> getAllTasks() async {
    final rows = await _db.query(
      'todo_tasks',
      orderBy: 'sort_order ASC, created_at DESC',
    );
    return rows.map((r) => TodoItem.fromDbMap(r)).toList();
  }

  Future<void> insertTask(TodoItem task) async {
    await _db.insert(
      'todo_tasks',
      task.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(TodoItem task) async {
    await _db.update(
      'todo_tasks',
      task.toDbMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    await _db.delete(
      'todo_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearCompletedTasks() async {
    await _db.delete(
      'todo_tasks',
      where: 'is_completed = 1',
    );
  }

  Future<void> reorderTasks(List<TodoItem> tasks) async {
    final batch = _db.batch();
    for (int i = 0; i < tasks.length; i++) {
      batch.update(
        'todo_tasks',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [tasks[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<TodoCategory>> getAllCategories() async {
    final rows = await _db.query(
      'todo_categories',
      orderBy: 'sort_order ASC',
    );
    if (rows.isEmpty) {
      final defaults = TodoCategory.defaultCategories();
      final batch = _db.batch();
      for (final cat in defaults) {
        batch.insert(
          'todo_categories',
          cat.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return defaults;
    }
    return rows.map((r) => TodoCategory.fromDbMap(r)).toList();
  }

  Future<void> insertCategory(TodoCategory category) async {
    await _db.insert(
      'todo_categories',
      category.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategory(String id) async {
    await _db.delete(
      'todo_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
