import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:small_husn_muslim/features/todo/models/todo_priority.dart';
import 'package:small_husn_muslim/features/todo/models/todo_repeat_rule.dart';
import 'package:small_husn_muslim/features/todo/models/todo_subtask.dart';

class TodoItem {
  final String id;
  final String title;
  final String? notes;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final DateTime? reminderDateTime;
  final TodoRepeatRule repeatRule;
  /// Custom repeat days as DateTime weekday numbers (Mon=1 … Sun=7).
  /// Only meaningful when [repeatRule] is [TodoRepeatRule.custom].
  final List<int> repeatWeekdays;
  final TodoPriority priority;
  final String categoryId;
  final List<String> tags;
  final List<TodoSubtask> subtasks;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
    this.dueDate,
    this.dueTime,
    this.reminderDateTime,
    this.repeatRule = TodoRepeatRule.none,
    this.repeatWeekdays = const [],
    this.priority = TodoPriority.none,
    this.categoryId = 'all',
    this.tags = const [],
    this.subtasks = const [],
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isImportant => priority == TodoPriority.high;
  bool get hasSubtasks => subtasks.isNotEmpty;
  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;
  int get totalSubtasksCount => subtasks.length;

  bool isDueOn(DateTime date) {
    if (dueDate == null) return false;
    return dueDate!.year == date.year &&
        dueDate!.month == date.month &&
        dueDate!.day == date.day;
  }

  bool get isDueToday {
    final now = DateTime.now();
    return isDueOn(now);
  }

  bool get isDueTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isDueOn(tomorrow);
  }

  DateTime? get fullDueDateTime {
    if (dueDate == null) return null;
    if (dueTime == null) {
      return DateTime(dueDate!.year, dueDate!.month, dueDate!.day, 23, 59, 59);
    }
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTime!.hour,
      dueTime!.minute,
    );
  }

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    if (dueTime != null) {
      final deadline = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        dueTime!.hour,
        dueTime!.minute,
      );
      return now.isAfter(deadline);
    } else {
      final startOfToday = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
      return dueDay.isBefore(startOfToday);
    }
  }

  TodoItem copyWith({
    String? id,
    String? title,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    DateTime? reminderDateTime,
    TodoRepeatRule? repeatRule,
    List<int>? repeatWeekdays,
    TodoPriority? priority,
    String? categoryId,
    List<String>? tags,
    List<TodoSubtask>? subtasks,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDueDate = false,
    bool clearDueTime = false,
    bool clearReminder = false,
    bool clearNotes = false,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: isCompleted == false ? null : (completedAt ?? this.completedAt),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueTime: clearDueTime ? null : (dueTime ?? this.dueTime),
      reminderDateTime:
          clearReminder ? null : (reminderDateTime ?? this.reminderDateTime),
      repeatRule: repeatRule ?? this.repeatRule,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDbMap() {
    String? timeString;
    if (dueTime != null) {
      final h = dueTime!.hour.toString().padLeft(2, '0');
      final m = dueTime!.minute.toString().padLeft(2, '0');
      timeString = '$h:$m';
    }

    return {
      'id': id,
      'title': title,
      'notes': notes,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'due_time': timeString,
      'reminder_date_time': reminderDateTime?.toIso8601String(),
      'repeat_rule': repeatRule.value,
      'repeat_weekdays':
          repeatWeekdays.isEmpty ? null : repeatWeekdays.join(','),
      'priority': priority.value,
      'category_id': categoryId,
      'tags': tags.isEmpty ? null : jsonEncode(tags),
      'subtasks':
          subtasks.isEmpty ? null : jsonEncode(subtasks.map((s) => s.toJson()).toList()),
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TodoItem.fromDbMap(Map<String, dynamic> map) {
    TimeOfDay? parsedTime;
    final timeStr = map['due_time'] as String?;
    if (timeStr != null && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      parsedTime = TimeOfDay(hour: h, minute: m);
    }

    List<String> parsedTags = [];
    final tagsRaw = map['tags'] as String?;
    if (tagsRaw != null && tagsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(tagsRaw);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    List<TodoSubtask> parsedSubtasks = [];
    final subtasksRaw = map['subtasks'] as String?;
    if (subtasksRaw != null && subtasksRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(subtasksRaw);
        if (decoded is List) {
          parsedSubtasks = decoded
              .map((e) => TodoSubtask.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return TodoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'] as String)
          : null,
      dueTime: parsedTime,
      reminderDateTime: map['reminder_date_time'] != null
          ? DateTime.tryParse(map['reminder_date_time'] as String)
          : null,
      repeatRule: TodoRepeatRule.fromValue(map['repeat_rule'] as String?),
      repeatWeekdays: _parseWeekdays(map['repeat_weekdays'] as String?),
      priority: TodoPriority.fromValue(map['priority'] as int?),
      categoryId: (map['category_id'] as String?) ?? 'all',
      tags: parsedTags,
      subtasks: parsedSubtasks,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Parses the `repeat_weekdays` CSV column (e.g. `"7,4,5"`) into
  /// DateTime weekday numbers. Corrupt/missing values yield `[]`.
  static List<int> _parseWeekdays(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final days = <int>[];
    for (final part in raw.split(',')) {
      final day = int.tryParse(part.trim());
      if (day != null &&
          day >= DateTime.monday &&
          day <= DateTime.sunday &&
          !days.contains(day)) {
        days.add(day);
      }
    }
    return days;
  }
}
