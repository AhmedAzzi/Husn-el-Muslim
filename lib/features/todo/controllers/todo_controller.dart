import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/storage/app_database.dart';
import 'package:small_husn_muslim/features/todo/data/todo_repository.dart';
import 'package:small_husn_muslim/features/todo/models/todo_category.dart';
import 'package:small_husn_muslim/features/todo/models/todo_filter.dart';
import 'package:small_husn_muslim/features/todo/models/todo_item.dart';
import 'package:small_husn_muslim/features/todo/models/todo_priority.dart';
import 'package:small_husn_muslim/features/todo/models/todo_repeat_rule.dart';
import 'package:small_husn_muslim/features/todo/models/todo_subtask.dart';
import 'package:small_husn_muslim/features/todo/services/todo_notification_service.dart';
import 'package:small_husn_muslim/features/todo/services/todo_predefined_service.dart';
import 'package:small_husn_muslim/features/todo/services/todo_widget_bridge.dart';
import 'package:small_husn_muslim/features/prayer_times/controllers/prayer_times_logic.dart';

class TodoController extends GetxController with WidgetsBindingObserver {
  final TodoRepository repository;
  final TodoNotificationService notificationService;

  TodoController({
    required this.repository,
    TodoNotificationService? notificationService,
  }) : notificationService = notificationService ?? TodoNotificationService();

  static TodoController findOrCreate(AppDatabase database) {
    if (Get.isRegistered<TodoController>()) {
      return Get.find<TodoController>();
    }
    return Get.put(
      TodoController(repository: TodoRepository(database)),
      permanent: true,
    );
  }

  final RxList<TodoItem> tasks = <TodoItem>[].obs;
  final RxList<TodoCategory> categories = <TodoCategory>[].obs;

  // Today is the default tab (first tab): the list opens on what
  // matters now; other filters stay one tap away.
  final Rx<TodoFilterType> activeFilter = TodoFilterType.today.obs;
  final Rx<TodoSortType> activeSort = TodoSortType.manual.obs;
  final RxnString selectedCategoryId = RxnString();
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool showCompletedSection = true.obs;
  final RxBool isLoading = true.obs;

  TodoItem? _recentlyDeletedTask;
  TodoItem? get recentlyDeletedTask => _recentlyDeletedTask;

  bool _predefinedHooked = false;

  @override
  void onInit() {
    super.onInit();
    // Push widget re-renders on any task/category change. Workers are
    // auto-disposed with the controller; the native call no-ops when
    // no todo widget is pinned.
    ever(tasks, (_) => TodoWidgetBridge.refresh());
    ever(categories, (_) => TodoWidgetBridge.refresh());
    WidgetsBinding.instance.addObserver(this);
    loadData();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Picks up widget-side toggles made while the app was away.
  /// Silent: no loading flash, seeds/sync are idempotent.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadData(silent: true);
    }
  }

  Future<void> loadData({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final loadedCategories = await repository.getAllCategories();
      categories.assignAll(loadedCategories);

      final loadedTasks = await repository.getAllTasks();
      tasks.assignAll(loadedTasks);

      // Seed predefined tasks once, then anchor today's instances to
      // the live prayer times (fallbacks until prayer data is ready).
      await TodoPredefinedService.ensureSeeded(this);
      await TodoPredefinedService.syncTodayTimes(this);
      _hookPrayerUpdates();

      // Publish the DB path for the native widget + self-heal reminders
      // (covers recurrences spawned from the widget, which bypass Dart).
      await TodoWidgetBridge.rememberDbPath(repository.database.dbPath);
      await _rescheduleDueReminders();
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-arms alarms for uncompleted tasks with future reminders.
  /// Idempotent (same notification ids) — heals anything the native
  /// widget toggle created or restored behind Dart's back.
  Future<void> _rescheduleDueReminders() async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (!task.isCompleted &&
          task.reminderDateTime != null &&
          task.reminderDateTime!.isAfter(now)) {
        await notificationService.scheduleReminder(task);
      }
    }
  }

  /// Re-anchors predefined tasks whenever prayer times (re)load.
  /// Skipped in contexts without prayer logic (e.g. unit tests).
  void _hookPrayerUpdates() {
    if (_predefinedHooked || !Get.isRegistered<PrayerTimesLogic>()) return;
    _predefinedHooked = true;
    final logic = Get.find<PrayerTimesLogic>();
    ever(
      logic.prayerTimesRx,
      (_) => TodoPredefinedService.syncTodayTimes(this),
    );
  }

  /// Smart filter and category are independent dimensions that combine
  /// (AND): e.g. Today + Personal shows only personal tasks due today.
  /// Changing one never clears the other.
  void setFilter(TodoFilterType filter) {
    activeFilter.value = filter;
  }

  void selectCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  void setSort(TodoSortType sort) {
    activeSort.value = sort;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query.trim();
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchQuery.value = '';
    }
  }

  // --- Filtered and Sorted Tasks ---

  List<TodoItem> get filteredTasks {
    final query = searchQuery.value.toLowerCase();
    final catId = selectedCategoryId.value;
    final filter = activeFilter.value;

    return tasks.where((task) {
      // 1. Search Query
      if (query.isNotEmpty) {
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesNotes = task.notes?.toLowerCase().contains(query) ?? false;
        final matchesTags = task.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchesTitle && !matchesNotes && !matchesTags) return false;
      }

      // 2. Category Filter (combines with the smart filter below)
      if (catId != null && task.categoryId != catId) {
        return false;
      }

      // 3. Smart Filter (applies on top of any selected category)
      switch (filter) {
        case TodoFilterType.all:
          return true;
        case TodoFilterType.today:
          return task.isDueToday || task.isOverdue;
        case TodoFilterType.upcoming:
          if (task.dueDate == null) return false;
          final startOfTomorrow = DateTime.now().add(const Duration(days: 1));
          final cleanTomorrow = DateTime(
            startOfTomorrow.year,
            startOfTomorrow.month,
            startOfTomorrow.day,
          );
          return task.dueDate!.isAfter(cleanTomorrow) ||
              task.isDueTomorrow;
        case TodoFilterType.important:
          return task.isImportant;
        case TodoFilterType.overdue:
          return task.isOverdue;
        case TodoFilterType.completed:
          return task.isCompleted;
      }
    }).toList();
  }

  List<TodoItem> _sortTasks(List<TodoItem> list) {
    final sorted = List<TodoItem>.from(list);
    switch (activeSort.value) {
      case TodoSortType.manual:
        sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
      case TodoSortType.dueDate:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TodoSortType.priority:
        sorted.sort((a, b) => b.priority.value.compareTo(a.priority.value));
        break;
      case TodoSortType.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case TodoSortType.createdAt:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return sorted;
  }

  List<TodoItem> get activeTasks {
    if (activeFilter.value == TodoFilterType.completed && selectedCategoryId.value == null) {
      return [];
    }
    final active = filteredTasks.where((t) => !t.isCompleted).toList();
    return _sortTasks(active);
  }

  List<TodoItem> get completedTasks {
    final comp = filteredTasks.where((t) => t.isCompleted).toList();
    comp.sort((a, b) {
      final aTime = a.completedAt ?? a.updatedAt;
      final bTime = b.completedAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });
    return comp;
  }

  int get overdueCount => tasks.where((t) => t.isOverdue).length;
  int get todayCount => tasks.where((t) => !t.isCompleted && (t.isDueToday || t.isOverdue)).length;
  int get upcomingCount => tasks.where((t) => !t.isCompleted && (t.isDueTomorrow || (t.dueDate != null && t.dueDate!.isAfter(DateTime.now())))).length;
  int get importantCount => tasks.where((t) => !t.isCompleted && t.isImportant).length;
  int get completedCount => tasks.where((t) => t.isCompleted).length;

  // --- Task CRUD ---

  Future<TodoItem> quickAddTask(
    String title, {
    DateTime? dueDate,
    TimeOfDay? dueTime,
    String? categoryId,
    TodoPriority priority = TodoPriority.none,
  }) async {
    final now = DateTime.now();
    DateTime? effectiveDueDate = dueDate;
    if (effectiveDueDate == null && activeFilter.value == TodoFilterType.today) {
      effectiveDueDate = DateTime(now.year, now.month, now.day);
    } else if (effectiveDueDate == null && activeFilter.value == TodoFilterType.upcoming) {
      final tom = now.add(const Duration(days: 1));
      effectiveDueDate = DateTime(tom.year, tom.month, tom.day);
    }

    final effectivePriority =
        activeFilter.value == TodoFilterType.important ? TodoPriority.high : priority;

    final effectiveCat = selectedCategoryId.value ?? categoryId ?? 'all';

    final task = TodoItem(
      id: 'task_${now.millisecondsSinceEpoch}_${tasks.length}',
      title: title.trim(),
      dueDate: effectiveDueDate,
      dueTime: dueTime,
      priority: effectivePriority,
      categoryId: effectiveCat,
      sortOrder: tasks.isEmpty ? 0 : (tasks.map((t) => t.sortOrder).reduce((a, b) => a < b ? a : b) - 1),
      createdAt: now,
      updatedAt: now,
    );

    tasks.insert(0, task);
    await repository.insertTask(task);
    return task;
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final current = tasks[index];
    final willComplete = !current.isCompleted;
    final now = DateTime.now();

    final updated = current.copyWith(
      isCompleted: willComplete,
      completedAt: willComplete ? now : null,
      updatedAt: now,
    );

    tasks[index] = updated;
    await repository.updateTask(updated);

    if (willComplete) {
      await notificationService.cancelReminder(current.id);

      // Handle Recurring tasks: create next recurrence automatically!
      if (current.repeatRule != TodoRepeatRule.none && current.dueDate != null) {
        final nextDue = current.repeatRule.computeNextDue(
          current.dueDate!,
          customWeekdays: current.repeatWeekdays,
        );
        if (nextDue != null) {
          DateTime? nextReminder;
          if (current.reminderDateTime != null) {
            final diff = current.dueDate!.difference(current.reminderDateTime!);
            nextReminder = nextDue.subtract(diff);
          }

          final recurringTask = TodoItem(
            id: 'task_${now.millisecondsSinceEpoch}_rec',
            title: current.title,
            notes: current.notes,
            dueDate: nextDue,
            dueTime: current.dueTime,
            reminderDateTime: nextReminder,
            repeatRule: current.repeatRule,
            repeatWeekdays: current.repeatWeekdays,
            priority: current.priority,
            categoryId: current.categoryId,
            tags: current.tags,
            subtasks: current.subtasks.map((s) => s.copyWith(isCompleted: false)).toList(),
            sortOrder: current.sortOrder,
            createdAt: now,
            updatedAt: now,
          );

          tasks.insert(0, recurringTask);
          await repository.insertTask(recurringTask);
          if (nextReminder != null) {
            await notificationService.scheduleReminder(recurringTask);
          }
        }
      }
    } else {
      if (updated.reminderDateTime != null) {
        await notificationService.scheduleReminder(updated);
      }
    }
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = tasks[taskIndex];
    final subtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    final updated = task.copyWith(
      subtasks: subtasks,
      updatedAt: DateTime.now(),
    );
    tasks[taskIndex] = updated;
    await repository.updateTask(updated);
  }

  Future<void> addSubtask(String taskId, String title) async {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = tasks[taskIndex];
    // Microseconds + count suffix: two rapid adds must never share an id,
    // or toggle/delete would hit both subtasks at once.
    final newSubtask = TodoSubtask(
      id: 'sub_${DateTime.now().microsecondsSinceEpoch}_${task.subtasks.length}',
      title: title.trim(),
    );

    final updated = task.copyWith(
      subtasks: [...task.subtasks, newSubtask],
      updatedAt: DateTime.now(),
    );
    tasks[taskIndex] = updated;
    await repository.updateTask(updated);
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = tasks[taskIndex];
    final subtasks = task.subtasks.where((s) => s.id != subtaskId).toList();

    final updated = task.copyWith(
      subtasks: subtasks,
      updatedAt: DateTime.now(),
    );
    tasks[taskIndex] = updated;
    await repository.updateTask(updated);
  }

  Future<void> updateTask(TodoItem task) async {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final updated = task.copyWith(updatedAt: DateTime.now());
    tasks[index] = updated;
    await repository.updateTask(updated);

    if (updated.reminderDateTime != null && !updated.isCompleted) {
      await notificationService.scheduleReminder(updated);
    } else {
      await notificationService.cancelReminder(updated.id);
    }
  }

  Future<TodoItem?> deleteTask(String taskId) async {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return null;

    final taskToDelete = tasks[index];
    _recentlyDeletedTask = taskToDelete;

    tasks.removeAt(index);
    await repository.deleteTask(taskId);
    await notificationService.cancelReminder(taskId);
    return taskToDelete;
  }

  Future<void> restoreDeletedTask() async {
    if (_recentlyDeletedTask == null) return;
    final task = _recentlyDeletedTask!;
    _recentlyDeletedTask = null;

    tasks.insert(0, task);
    await repository.insertTask(task);
    if (task.reminderDateTime != null && !task.isCompleted) {
      await notificationService.scheduleReminder(task);
    }
  }

  Future<void> rescheduleOverdueToToday(String taskId) async {
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = tasks[index];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final updated = task.copyWith(
      dueDate: today,
      updatedAt: now,
    );
    tasks[index] = updated;
    await repository.updateTask(updated);
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final active = activeTasks;
    if (oldIndex < 0 || oldIndex >= active.length) return;
    if (newIndex < 0 || newIndex > active.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = active.removeAt(oldIndex);
    active.insert(newIndex, item);

    // Reassign sort orders
    for (int i = 0; i < active.length; i++) {
      final task = active[i];
      final originalIndex = tasks.indexWhere((t) => t.id == task.id);
      if (originalIndex != -1) {
        tasks[originalIndex] = tasks[originalIndex].copyWith(sortOrder: i);
      }
    }

    await repository.reorderTasks(active);
  }

  Future<void> clearCompleted() async {
    final completed = tasks.where((t) => t.isCompleted).toList();
    for (final task in completed) {
      await notificationService.cancelReminder(task.id);
    }
    tasks.removeWhere((t) => t.isCompleted);
    await repository.clearCompletedTasks();
  }

  Future<void> addCategory(String name, int iconCode, int colorValue) async {
    final cat = TodoCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      iconCode: iconCode,
      colorValue: colorValue,
      sortOrder: categories.length,
    );
    categories.add(cat);
    await repository.insertCategory(cat);
  }

  Future<void> deleteCategory(String id) async {
    categories.removeWhere((c) => c.id == id);
    if (selectedCategoryId.value == id) {
      selectedCategoryId.value = null;
    }
    // Set tasks in this category to 'all'
    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].categoryId == id) {
        tasks[i] = tasks[i].copyWith(categoryId: 'all');
        await repository.updateTask(tasks[i]);
      }
    }
    await repository.deleteCategory(id);
  }
}
