import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:small_husn_muslim/core/services/shared_prefs_cache.dart';
import 'package:small_husn_muslim/core/storage/app_database.dart';
import 'package:small_husn_muslim/features/todo/controllers/todo_controller.dart';
import 'package:small_husn_muslim/features/todo/data/todo_repository.dart';
import 'package:small_husn_muslim/features/todo/models/todo_filter.dart';
import 'package:small_husn_muslim/features/todo/models/todo_item.dart';
import 'package:small_husn_muslim/features/todo/models/todo_priority.dart';
import 'package:small_husn_muslim/features/todo/models/todo_repeat_rule.dart';
import 'package:small_husn_muslim/features/todo/models/todo_subtask.dart';
import 'package:small_husn_muslim/features/todo/presentation/todo_screen.dart';
import 'package:small_husn_muslim/features/todo/services/todo_predefined_service.dart';
import 'package:small_husn_muslim/features/todo/services/todo_notification_service.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late TodoRepository repo;
  late TodoController controller;
  late String dbPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefsCache.init(await SharedPreferences.getInstance());
    // Fake the native widget bridge (no platform channels under test).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ahmed.hisnelmuslim/prayer_notification'),
      (call) async => true,
    );
    // Skip predefined seeding for the legacy groups (covered separately).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TodoPredefinedService.seedFlag, true);

    dbPath = inMemoryDatabasePath;
    db = await AppDatabase.open(overridePath: dbPath);
    // Clean any prior tables
    await db.db.delete('todo_tasks');
    await db.db.delete('todo_categories');

    repo = TodoRepository(db);
    controller = TodoController(repository: repo);
    Get.put(controller);
    await controller.loadData();
  });

  tearDown(() async {
    if (Get.isRegistered<TodoController>()) {
      Get.delete<TodoController>(force: true);
    }
    await db.close();
  });

  group('Todo Models', () {
    test('TodoItem JSON/DB map roundtrip', () {
      final now = DateTime(2026, 9, 16, 12, 0);
      final item = TodoItem(
        id: 'task_1',
        title: 'Read Surah Al-Baqarah',
        notes: '2 pages per day',
        dueDate: DateTime(2026, 9, 17),
        dueTime: const TimeOfDay(hour: 14, minute: 30),
        priority: TodoPriority.high,
        repeatRule: TodoRepeatRule.custom,
        repeatWeekdays: const [7, 4, 5],
        categoryId: 'worship',
        tags: ['quran', 'daily'],
        subtasks: const [
          TodoSubtask(id: 's1', title: 'Part 1', isCompleted: true),
          TodoSubtask(id: 's2', title: 'Part 2', isCompleted: false),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toDbMap();
      final reconstructed = TodoItem.fromDbMap(map);

      expect(reconstructed.id, item.id);
      expect(reconstructed.title, item.title);
      expect(reconstructed.notes, item.notes);
      expect(reconstructed.priority, TodoPriority.high);
      expect(reconstructed.repeatRule, TodoRepeatRule.custom);
      expect(reconstructed.repeatWeekdays, [7, 4, 5]);
      expect(reconstructed.isImportant, isTrue);
      expect(reconstructed.tags, ['quran', 'daily']);
      expect(reconstructed.hasSubtasks, isTrue);
      expect(reconstructed.totalSubtasksCount, 2);
      expect(reconstructed.completedSubtasksCount, 1);
      expect(reconstructed.dueTime?.hour, 14);
      expect(reconstructed.dueTime?.minute, 30);
    });

    test('isDueToday, isDueTomorrow, and isOverdue logic', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final past = today.subtract(const Duration(days: 2));

      final todayTask = TodoItem(
        id: 'today',
        title: 'Today Task',
        dueDate: today,
        createdAt: now,
        updatedAt: now,
      );
      expect(todayTask.isDueToday, isTrue);
      expect(todayTask.isOverdue, isFalse);

      final tomorrowTask = TodoItem(
        id: 'tomorrow',
        title: 'Tomorrow Task',
        dueDate: tomorrow,
        createdAt: now,
        updatedAt: now,
      );
      expect(tomorrowTask.isDueTomorrow, isTrue);
      expect(tomorrowTask.isDueToday, isFalse);

      final overdueTask = TodoItem(
        id: 'overdue',
        title: 'Overdue Task',
        dueDate: past,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(overdueTask.isOverdue, isTrue);

      final completedOverdue = overdueTask.copyWith(isCompleted: true);
      expect(completedOverdue.isOverdue, isFalse);
    });

    test('TodoRepeatRule next recurrence computation', () {
      final base = DateTime(2026, 9, 16, 10, 0); // Wednesday
      expect(TodoRepeatRule.none.computeNextDue(base), isNull);

      final daily = TodoRepeatRule.daily.computeNextDue(base);
      expect(daily?.day, 17);

      final weekly = TodoRepeatRule.weekly.computeNextDue(base);
      expect(weekly?.day, 23);

      final monthly = TodoRepeatRule.monthly.computeNextDue(base);
      expect(monthly?.month, 10);
      expect(monthly?.day, 16);
    });

    test('TodoRepeatRule custom days computation', () {
      final wednesday = DateTime(2026, 9, 16, 10, 0);
      const sun = DateTime.sunday; // 7
      const thu = DateTime.thursday; // 4
      const fri = DateTime.friday; // 5

      // Sun + Thu + Fri from Wednesday -> Thursday 17th.
      final next = TodoRepeatRule.custom.computeNextDue(
        wednesday,
        customWeekdays: [sun, thu, fri],
      );
      expect(next?.day, 17);
      expect(next?.weekday, thu);
      expect(next?.hour, 10);

      // Same weekday only -> exactly 7 days later.
      final sameDay = TodoRepeatRule.custom.computeNextDue(
        wednesday,
        customWeekdays: [DateTime.wednesday],
      );
      expect(sameDay?.day, 23);

      // Empty / invalid days -> no recurrence.
      expect(
        TodoRepeatRule.custom.computeNextDue(wednesday, customWeekdays: []),
        isNull,
      );
      expect(
        TodoRepeatRule.custom.computeNextDue(wednesday),
        isNull,
      );
    });
  });

  group('TodoRepository SQLite operations', () {
    test('default categories are seeded if empty', () async {
      final cats = await repo.getAllCategories();
      expect(cats.isNotEmpty, isTrue);
      expect(cats.any((c) => c.id == 'worship'), isTrue);
    });

    test('insert, update, and delete task', () async {
      final now = DateTime.now();
      final task = TodoItem(
        id: 't_test',
        title: 'Test SQLite Task',
        createdAt: now,
        updatedAt: now,
      );

      await repo.insertTask(task);
      var all = await repo.getAllTasks();
      expect(all.length, 1);
      expect(all.first.title, 'Test SQLite Task');

      final updated = task.copyWith(title: 'Updated SQLite Task');
      await repo.updateTask(updated);
      all = await repo.getAllTasks();
      expect(all.first.title, 'Updated SQLite Task');

      await repo.deleteTask('t_test');
      all = await repo.getAllTasks();
      expect(all.isEmpty, isTrue);
    });
  });

  group('TodoController state & logic', () {
    test('quickAddTask inserts at beginning and persists', () async {
      await controller.quickAddTask('Buy books');
      expect(controller.tasks.length, 1);
      expect(controller.activeTasks.length, 1);
      expect(controller.activeTasks.first.title, 'Buy books');

      final fromDb = await repo.getAllTasks();
      expect(fromDb.length, 1);
      expect(fromDb.first.title, 'Buy books');
    });

    test('toggleTaskCompletion handles recurring task by creating next occurrence', () async {
      final now = DateTime.now();
      final task = TodoItem(
        id: 'rec_1',
        title: 'Daily Dhikr',
        dueDate: DateTime(now.year, now.month, now.day),
        repeatRule: TodoRepeatRule.daily,
        createdAt: now,
        updatedAt: now,
      );
      await repo.insertTask(task);
      controller.tasks.add(task);

      await controller.toggleTaskCompletion('rec_1');

      // The original task should be completed
      final completed = controller.tasks.firstWhere((t) => t.id == 'rec_1');
      expect(completed.isCompleted, isTrue);

      // A new next occurrence should have been created!
      expect(controller.tasks.length, 2);
      final newOccur = controller.tasks.firstWhere((t) => t.id != 'rec_1');
      expect(newOccur.isCompleted, isFalse);
      expect(newOccur.title, 'Daily Dhikr');
      expect(newOccur.dueDate?.day, DateTime.now().add(const Duration(days: 1)).day);
    });

    test('toggleTaskCompletion carries custom repeat days forward', () async {
      final now = DateTime.now();
      // Last Sunday relative to today.
      final daysSinceSunday = now.weekday % 7;
      final sunday =
          DateTime(now.year, now.month, now.day - daysSinceSunday);
      final task = TodoItem(
        id: 'custom_1',
        title: 'Sunday + Thursday task',
        dueDate: sunday,
        repeatRule: TodoRepeatRule.custom,
        repeatWeekdays: const [7, 4], // Sun + Thu
        createdAt: now,
        updatedAt: now,
      );
      await repo.insertTask(task);
      controller.tasks.add(task);

      await controller.toggleTaskCompletion('custom_1');

      expect(controller.tasks.length, 2);
      final next =
          controller.tasks.firstWhere((t) => t.id != 'custom_1');
      expect(next.isCompleted, isFalse);
      expect(next.repeatRule, TodoRepeatRule.custom);
      expect(next.repeatWeekdays, [7, 4]);
      // Next occurrence lands on Thursday (weekday 4).
      expect(next.dueDate?.weekday, DateTime.thursday);
      expect(next.dueDate!.isAfter(sunday), isTrue);
    });

    test('subtasks checklist addition, toggle, and removal', () async {
      final task = await controller.quickAddTask('Prep presentation');
      await controller.addSubtask(task.id, 'Slide 1');
      await controller.addSubtask(task.id, 'Slide 2');

      final updated = controller.tasks.firstWhere((t) => t.id == task.id);
      expect(updated.subtasks.length, 2);
      expect(updated.completedSubtasksCount, 0);

      final sub1Id = updated.subtasks.first.id;
      await controller.toggleSubtask(task.id, sub1Id);
      final afterToggle = controller.tasks.firstWhere((t) => t.id == task.id);
      expect(afterToggle.completedSubtasksCount, 1);

      await controller.deleteSubtask(task.id, sub1Id);
      final afterDelete = controller.tasks.firstWhere((t) => t.id == task.id);
      expect(afterDelete.subtasks.length, 1);
    });

    test('deleteTask and restore (Undo)', () async {
      final task = await controller.quickAddTask('Undo task');
      expect(controller.tasks.length, 1);

      await controller.deleteTask(task.id);
      expect(controller.tasks.isEmpty, isTrue);
      expect(controller.recentlyDeletedTask?.id, task.id);

      await controller.restoreDeletedTask();
      expect(controller.tasks.length, 1);
      expect(controller.tasks.first.title, 'Undo task');
    });

    test('filtering and search', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tom = today.add(const Duration(days: 2));

      await controller.quickAddTask('Today item', dueDate: today);
      await controller.quickAddTask('Future item', dueDate: tom);
      await controller.quickAddTask('Important item', priority: TodoPriority.high);

      controller.setFilter(TodoFilterType.today);
      expect(controller.activeTasks.any((t) => t.title == 'Today item'), isTrue);

      controller.setFilter(TodoFilterType.important);
      expect(controller.activeTasks.any((t) => t.title == 'Important item'), isTrue);

      controller.setFilter(TodoFilterType.all);
      expect(controller.activeTasks.length, 3);

      controller.updateSearchQuery('Future');
      expect(controller.activeTasks.length, 1);
      expect(controller.activeTasks.first.title, 'Future item');
    });

    test('smart filter and category combine (AND)', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tom = today.add(const Duration(days: 2));

      await controller.quickAddTask(
        'Today personal',
        dueDate: today,
        categoryId: 'personal',
      );
      await controller.quickAddTask(
        'Today work',
        dueDate: today,
        categoryId: 'work',
      );
      await controller.quickAddTask(
        'Future personal',
        dueDate: tom,
        categoryId: 'personal',
      );

      // Today alone shows both tasks due today.
      controller.setFilter(TodoFilterType.today);
      expect(controller.activeTasks.length, 2);

      // Today + Personal narrows to the single personal task due today.
      controller.selectCategory('personal');
      expect(controller.activeTasks.length, 1);
      expect(controller.activeTasks.first.title, 'Today personal');

      // Switching the smart tab keeps the category (independent dimensions).
      controller.setFilter(TodoFilterType.all);
      expect(controller.selectedCategoryId.value, 'personal');
      expect(controller.activeTasks.length, 2);

      // Clearing the category restores the full list.
      controller.selectCategory(null);
      expect(controller.activeTasks.length, 3);
    });
  });

  group('TodoPredefinedService', () {
    test('seeds adhkar + kahf + wird once with fallback times', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TodoPredefinedService.seedFlag, false);
      await controller.loadData();

      // 3 daily adhkar + Friday Kahf + daily wird.
      expect(controller.tasks.length, 5);

      final morning = controller.tasks.firstWhere(
        (t) => t.tags.contains(TodoPredefinedService.tagMorning),
      );
      expect(morning.categoryId, 'worship');
      expect(morning.repeatRule, TodoRepeatRule.daily);
      expect(morning.dueDate, isNotNull);
      // No prayer logic registered in tests -> fallbacks apply.
      expect(morning.dueTime?.hour,
          TodoPredefinedService.fallbackMorning.hour);
      expect(morning.dueTime?.minute,
          TodoPredefinedService.fallbackMorning.minute);

      final evening = controller.tasks.firstWhere(
        (t) => t.tags.contains(TodoPredefinedService.tagEvening),
      );
      expect(evening.repeatRule, TodoRepeatRule.daily);

      final sleep = controller.tasks.firstWhere(
        (t) => t.tags.contains(TodoPredefinedService.tagSleep),
      );
      expect(sleep.repeatRule, TodoRepeatRule.daily);

      final kahf = controller.tasks.firstWhere(
        (t) => t.tags.contains(TodoPredefinedService.tagKahf),
      );
      expect(kahf.categoryId, 'worship');
      expect(kahf.repeatRule, TodoRepeatRule.custom);
      expect(kahf.repeatWeekdays, [DateTime.friday]);
      expect(kahf.dueDate?.weekday, DateTime.friday);

      final wird = controller.tasks.firstWhere(
        (t) => t.tags.contains(TodoPredefinedService.tagWird),
      );
      expect(wird.categoryId, 'worship');
      expect(wird.repeatRule, TodoRepeatRule.daily);
      expect(wird.dueDate, isNotNull);

      // Second load: flag set, no duplicates.
      await controller.loadData();
      expect(controller.tasks.length, 5);
    });

    test('v1 upgrade adds kahf/wird and removes retired starters', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TodoPredefinedService.seedFlag, false);
      await prefs.setBool('todo_predefined_seeded_v1', true);
      final now = DateTime.now();
      final legacy = TodoItem(
        id: 'pre_starter_personal',
        title: 'legacy sample',
        categoryId: 'personal',
        createdAt: now,
        updatedAt: now,
      );
      controller.tasks.add(legacy);
      await controller.repository.insertTask(legacy);

      await controller.loadData();

      // Retired sample removed, new tasks added, adhkar batch skipped.
      expect(
        controller.tasks.any((t) => t.id == 'pre_starter_personal'),
        isFalse,
      );
      expect(controller.tasks.any((t) => t.id == 'pre_kahf'), isTrue);
      expect(controller.tasks.any((t) => t.id == 'pre_wird'), isTrue);
      expect(controller.tasks.length, 2);
    });

    test('syncTodayTimes no-ops without prayer data', () async {
      await TodoPredefinedService.syncTodayTimes(controller);
      expect(TodoPredefinedService.prayerDueTimes(), isNull);
    });

    test('resume reloads tasks (picks up widget-side changes)', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TodoPredefinedService.seedFlag, false);
      expect(controller.tasks.isEmpty, isTrue);

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 300));

      expect(controller.tasks.length, 5);
    });
  });

  group('Todo home-screen widget bridge', () {
    test('reminder notification id mapping persists for native cancel',
        () async {
      final service = TodoNotificationService();
      final now = DateTime.now();
      final task = TodoItem(
        id: 't_notif',
        title: 'Widget mapping task',
        reminderDateTime: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );
      await service.scheduleReminder(task);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(TodoNotificationService.notifIdKey('t_notif')),
        TodoNotificationService.notificationIdFor('t_notif'),
      );

      await service.cancelReminder('t_notif');
      expect(
        prefs.containsKey(TodoNotificationService.notifIdKey('t_notif')),
        isFalse,
      );
    });
  });

  group('TodoScreen Widget Tests', () {
    testWidgets('renders TodoScreen with quick add bar and adds task', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: const TodoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen title in app bar contains 'المهام'
      expect(find.textContaining('المهام'), findsAtLeast(1));

      // Verify category manager button exists and opens the manage sheet
      expect(find.byIcon(Icons.category_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.category_rounded));
      await tester.pumpAndSettle();
      expect(find.text('القائمة'), findsOneWidget);
      expect(find.text('عبادات'), findsWidgets);
      // Close the sheet to continue the test
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();

      // Verify the Today empty state is displayed initially: Today is
      // the default (first) tab.
      expect(find.text('لا توجد مهام مستحقة اليوم'), findsOneWidget);

      // Enter task in quick add bar
      final inputFinder = find.byType(TextField).last;
      await tester.enterText(inputFinder, 'تلاوة سورة الملك');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify task tile is created and rendered
      expect(find.text('تلاوة سورة الملك'), findsOneWidget);

      // Tap card to open details
      await tester.tap(find.text('تلاوة سورة الملك'));
      await tester.pumpAndSettle();

      // Details bottom sheet opens!
      expect(find.text('تفاصيل المهمة'), findsNothing); // Title in app bar or dialog
      expect(find.text('المهام الفرعية'), findsOneWidget);
    });
  });
}
