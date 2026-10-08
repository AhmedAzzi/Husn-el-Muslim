import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';
import 'package:small_husn_muslim/features/todo/controllers/todo_controller.dart';
import 'package:small_husn_muslim/features/todo/models/todo_item.dart';
import 'package:small_husn_muslim/features/todo/models/todo_repeat_rule.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Predefined (seeded) todo tasks.
///
/// Prayer-linked worship tasks (all daily-repeating):
/// - Morning adhkar → due 1h after Fajr (same anchor as the morning alarm).
/// - Evening adhkar → due 1h after Asr (same anchor as the evening alarm).
/// - Sleep adhkar → due at the first third of the night (bedtime).
///
/// Uncompleted instances due today track the live prayer times, so a task
/// left undone past its deadline automatically flips to overdue (متأخرة)
/// through the standard [TodoItem.isOverdue] check. Recurrences inherit the
/// same tags, so they keep tracking day after day; deleting one breaks its
/// chain, which is respected (nothing is ever resurrected).
class TodoPredefinedService {
  static const seedFlag = 'todo_predefined_seeded_v2';
  static const _legacySeedFlagV1 = 'todo_predefined_seeded_v1';

  static const tagPredefined = 'predefined';
  static const tagMorning = 'pre_morning';
  static const tagEvening = 'pre_evening';
  static const tagSleep = 'pre_sleep';
  static const tagKahf = 'pre_kahf';
  static const tagWird = 'pre_wird';

  /// Sample tasks from the first version, removed on upgrade.
  static const _removedStarterIds = [
    'pre_starter_personal',
    'pre_starter_work',
    'pre_starter_general',
  ];

  /// Fallback clock times used when prayer data isn't ready yet.
  /// Corrected by [syncTodayTimes] as soon as times load.
  static const fallbackMorning = TimeOfDay(hour: 6, minute: 0);
  static const fallbackEvening = TimeOfDay(hour: 16, minute: 30);
  static const fallbackSleep = TimeOfDay(hour: 22, minute: 0);

  /// Prayer-derived due times, or null when prayer data isn't ready.
  static ({TimeOfDay morning, TimeOfDay evening, TimeOfDay sleep})?
      prayerDueTimes() {
    if (!Get.isRegistered<PrayerTimesLogic>()) return null;
    final times = Get.find<PrayerTimesLogic>().prayerTimes;
    if (times == null || times.isEmpty) return null;

    DateTime? named(String name) =>
        times.firstWhereOrNull((p) => p.name == name)?.time;

    final fajr = named('Fajr');
    final asr = named('Asr');
    final firstThird = named('First Third');
    if (fajr == null || asr == null || firstThird == null) return null;

    TimeOfDay tod(DateTime dt) =>
        TimeOfDay(hour: dt.hour, minute: dt.minute);
    return (
      morning: tod(fajr.add(const Duration(hours: 1))),
      evening: tod(asr.add(const Duration(hours: 1))),
      sleep: tod(firstThird),
    );
  }

  /// Seeds the predefined tasks (flag-guarded, never duplicates).
  /// v1 users keep their adhkar; only the missing pieces are added and
  /// the retired starter samples are removed.
  static Future<void> ensureSeeded(TodoController controller) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(seedFlag) ?? false) return;

    final loc = lookupAppLocalizations(
      Locale(Get.locale?.languageCode ?? 'ar'),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final times = prayerDueTimes();
    bool has(String id) => controller.tasks.any((t) => t.id == id);

    var order = controller.tasks.isEmpty
        ? 0
        : controller.tasks
                .map((t) => t.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1;
    Future<void> add(TodoItem task) async {
      if (has(task.id)) return;
      final withOrder = task.copyWith(sortOrder: order++);
      controller.tasks.add(withOrder);
      await controller.repository.insertTask(withOrder);
    }

    // --- Prayer-linked daily adhkar (worship, v1 batch) ---
    if (!(prefs.getBool(_legacySeedFlagV1) ?? false)) {
      await add(TodoItem(
        id: 'pre_morning',
        title: loc.todoPreMorning,
        dueDate: today,
        dueTime: times?.morning ?? fallbackMorning,
        repeatRule: TodoRepeatRule.daily,
        categoryId: 'worship',
        tags: const [tagPredefined, tagMorning],
        createdAt: now,
        updatedAt: now,
      ));
      await add(TodoItem(
        id: 'pre_evening',
        title: loc.todoPreEvening,
        dueDate: today,
        dueTime: times?.evening ?? fallbackEvening,
        repeatRule: TodoRepeatRule.daily,
        categoryId: 'worship',
        tags: const [tagPredefined, tagEvening],
        createdAt: now,
        updatedAt: now,
      ));
      await add(TodoItem(
        id: 'pre_sleep',
        title: loc.todoPreSleep,
        dueDate: today,
        dueTime: times?.sleep ?? fallbackSleep,
        repeatRule: TodoRepeatRule.daily,
        categoryId: 'worship',
        tags: const [tagPredefined, tagSleep],
        createdAt: now,
        updatedAt: now,
      ));
    }

    // --- Retired v1 starter samples are removed ---
    for (final id in _removedStarterIds) {
      if (has(id)) {
        controller.tasks.removeWhere((t) => t.id == id);
        await controller.repository.deleteTask(id);
      }
    }

    // --- Surah Al-Kahf every Friday (v2 batch) ---
    final daysUntilFriday = (DateTime.friday - today.weekday) % 7;
    await add(TodoItem(
      id: 'pre_kahf',
      title: loc.todoPreKahf,
      dueDate: today.add(Duration(days: daysUntilFriday)),
      repeatRule: TodoRepeatRule.custom,
      repeatWeekdays: const [DateTime.friday],
      categoryId: 'worship',
      tags: const [tagPredefined, tagKahf],
      createdAt: now,
      updatedAt: now,
    ));

    // --- Daily Quran wird (v2 batch) ---
    await add(TodoItem(
      id: 'pre_wird',
      title: loc.todoPreWird,
      dueDate: today,
      repeatRule: TodoRepeatRule.daily,
      categoryId: 'worship',
      tags: const [tagPredefined, tagWird],
      createdAt: now,
      updatedAt: now,
    ));

    await prefs.setBool(_legacySeedFlagV1, true);
    await prefs.setBool(seedFlag, true);
  }

  /// Re-anchors today's uncompleted predefined instances to the current
  /// prayer times. No-ops when prayer data isn't ready or nothing changed.
  static Future<void> syncTodayTimes(TodoController controller) async {
    final times = prayerDueTimes();
    if (times == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < controller.tasks.length; i++) {
      final task = controller.tasks[i];
      if (task.isCompleted ||
          task.dueDate == null ||
          !task.isDueOn(today)) {
        continue;
      }

      TimeOfDay? target;
      if (task.tags.contains(tagMorning)) {
        target = times.morning;
      } else if (task.tags.contains(tagEvening)) {
        target = times.evening;
      } else if (task.tags.contains(tagSleep)) {
        target = times.sleep;
      } else {
        continue;
      }

      if (task.dueTime?.hour != target.hour ||
          task.dueTime?.minute != target.minute) {
        final updated = task.copyWith(dueTime: target, updatedAt: now);
        controller.tasks[i] = updated;
        await controller.repository.updateTask(updated);
      }
    }
  }
}
