import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/storage/app_database.dart';
import 'package:small_husn_muslim/core/widgets/app_drawer.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
import 'package:small_husn_muslim/features/todo/controllers/todo_controller.dart';
import 'package:small_husn_muslim/features/todo/data/todo_repository.dart';
import 'package:small_husn_muslim/features/todo/models/todo_filter.dart';
import 'package:small_husn_muslim/features/todo/presentation/widgets/todo_category_dialog.dart';
import 'package:small_husn_muslim/features/todo/presentation/widgets/todo_detail_sheet.dart';
import 'package:small_husn_muslim/features/todo/presentation/widgets/todo_quick_add_bar.dart';
import 'package:small_husn_muslim/features/todo/presentation/widgets/todo_task_tile.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late final TodoController _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _completedExpanded = true;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<TodoController>()) {
      _controller = Get.find<TodoController>();
    } else {
      // Fallback if not registered yet
      AppDatabase.open().then((db) {
        if (!Get.isRegistered<TodoController>()) {
          Get.put(TodoController(repository: TodoRepository(db)),
              permanent: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    const accentColor = Color(0xFFD64463);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const AppDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() {
          final isSearching = _controller.isSearching.value;

          return HusnAppBar(
            title: isSearching ? null : loc.navTodo,
            titleWidget: isSearching
                ? Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      autofocus: true,
                      onChanged: (val) => _controller.updateSearchQuery(val),
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: loc.todoSearchTasks,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: 'Amiri',
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white70, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                : null,
            actions: [
              // Manage categories (lists)
              IconButton(
                icon: const Icon(
                  Icons.category_rounded,
                  color: Colors.white,
                ),
                tooltip: loc.todoCategory,
                onPressed: _showManageCategories,
              ),
              // Search toggle
              IconButton(
                icon: Icon(
                  isSearching ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  _controller.toggleSearch();
                  if (_controller.isSearching.value) {
                    _searchFocus.requestFocus();
                  } else {
                    _searchController.clear();
                  }
                },
              ),
              // More Options Menu (Sorting, Completed Toggle)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (action) {
                  switch (action) {
                    case 'sort_manual':
                      _controller.setSort(TodoSortType.manual);
                      break;
                    case 'sort_due':
                      _controller.setSort(TodoSortType.dueDate);
                      break;
                    case 'sort_priority':
                      _controller.setSort(TodoSortType.priority);
                      break;
                    case 'sort_title':
                      _controller.setSort(TodoSortType.title);
                      break;
                    case 'sort_created':
                      _controller.setSort(TodoSortType.createdAt);
                      break;
                    case 'toggle_completed':
                      _controller.showCompletedSection.value =
                          !_controller.showCompletedSection.value;
                      break;
                    case 'clear_completed':
                      _controller.clearCompleted();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      loc.todoSortBy,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_manual',
                    checked:
                        _controller.activeSort.value == TodoSortType.manual,
                    child: Text(loc.todoSortManual),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_due',
                    checked:
                        _controller.activeSort.value == TodoSortType.dueDate,
                    child: Text(loc.todoSortDueDate),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_priority',
                    checked:
                        _controller.activeSort.value == TodoSortType.priority,
                    child: Text(loc.todoSortPriority),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_title',
                    checked: _controller.activeSort.value == TodoSortType.title,
                    child: Text(loc.todoSortTitle),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_created',
                    checked:
                        _controller.activeSort.value == TodoSortType.createdAt,
                    child: Text(loc.todoSortCreatedAt),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'toggle_completed',
                    child: Text(_controller.showCompletedSection.value
                        ? loc.todoHideCompleted
                        : loc.todoShowCompleted),
                  ),
                  PopupMenuItem(
                    value: 'clear_completed',
                    child: Text(
                      loc.todoClearCompleted,
                      style: const TextStyle(color: Color(0xFF9B2C2C)),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: accentColor),
          );
        }

        final active = _controller.activeTasks;
        final completed = _controller.completedTasks;
        final isManualSort =
            _controller.activeSort.value == TodoSortType.manual;

        return Column(
          children: [
            // Super filter tabs — fixed, fits screen width, no scrolling
            _buildFilterTabs(context),
            // Category filter chips (worship / personal / work / general…)
            _buildCategoryRow(context),
            // Task List + Completed Section
            Expanded(
              child: active.isEmpty && completed.isEmpty
                  ? _buildEmptyState(context)
                  : ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      children: [
                        // Active Tasks
                        if (isManualSort)
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: active.length,
                            onReorder: _controller.reorderTasks,
                            itemBuilder: (ctx, index) {
                              final task = active[index];
                              return TodoTaskTile(
                                key: ValueKey('active_${task.id}'),
                                task: task,
                                isReorderable: true,
                                onTap: () =>
                                    TodoDetailSheet.show(context, task),
                              );
                            },
                          )
                        else
                          ...active.map((task) => TodoTaskTile(
                                key: ValueKey('active_${task.id}'),
                                task: task,
                                isReorderable: false,
                                onTap: () =>
                                    TodoDetailSheet.show(context, task),
                              )),

                        // Completed Tasks Collapsible Section
                        if (completed.isNotEmpty &&
                            _controller.showCompletedSection.value) ...[
                          const SizedBox(height: 16),
                          _buildCompletedHeader(context, completed.length),
                          if (_completedExpanded)
                            ...completed.map((task) => TodoTaskTile(
                                  key: ValueKey('comp_${task.id}'),
                                  task: task,
                                  isReorderable: false,
                                  onTap: () =>
                                      TodoDetailSheet.show(context, task),
                                )),
                        ],
                      ],
                    ),
            ),
            // Docked Quick-Add Bar right at the bottom of the Column
            const TodoQuickAddBar(),
          ],
        );
      }),
    );
  }

  /// Super filter tabs: all 6 filters visible at once in a fixed row.
  /// No horizontal scroll — each tab takes equal width via [Expanded].
  Widget _buildFilterTabs(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    const accentColor = Color(0xFFD64463);

    return Obx(() {
      final activeFilter = _controller.activeFilter.value;

      // Today is first and selected on entry; the rest keep their order.
      final tabs = <_FilterTabData>[
        _FilterTabData(
          type: TodoFilterType.today,
          icon: Icons.today_rounded,
          label: TodoFilterType.today.label(loc),
        ),
        _FilterTabData(
          type: TodoFilterType.all,
          icon: Icons.list_rounded,
          label: TodoFilterType.all.label(loc),
        ),
        _FilterTabData(
          type: TodoFilterType.upcoming,
          icon: Icons.event_rounded,
          label: TodoFilterType.upcoming.label(loc),
        ),
        _FilterTabData(
          type: TodoFilterType.important,
          icon: Icons.star_rounded,
          label: TodoFilterType.important.label(loc),
        ),
        _FilterTabData(
          type: TodoFilterType.overdue,
          icon: Icons.warning_amber_rounded,
          label: TodoFilterType.overdue.label(loc),
        ),
        _FilterTabData(
          type: TodoFilterType.completed,
          icon: Icons.check_circle_rounded,
          label: TodoFilterType.completed.label(loc),
        ),
      ];

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final tab in tabs)
              Expanded(
                child: _FilterTab(
                  data: tab,
                  // Smart tab and category chip highlight independently:
                  // both can be active at once (combined filter).
                  selected: activeFilter == tab.type,
                  accentColor: accentColor,
                  isDark: isDark,
                  onTap: () => _controller.setFilter(tab.type),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (_) => TodoCategoryDialog(
        onSave: (name, iconCode, colorValue) {
          _controller.addCategory(name, iconCode, colorValue);
        },
      ),
    );
  }

  /// Categories manager: pick a list to filter, add new lists,
  /// delete custom lists (defaults are protected).
  void _showManageCategories() {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1E1E28) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Obx(() {
        final cats = _controller.categories;
        final selectedId = _controller.selectedCategoryId.value;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 8,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.todoCategory,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      tooltip: loc.todoNewCategory,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showAddCategoryDialog();
                      },
                    ),
                  ],
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final cat = cats[i];
                      final selected = selectedId == cat.id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat.icon, size: 18, color: cat.color),
                        ),
                        title: Text(
                          cat.localizedName(loc),
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected)
                              const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF2E6B34),
                              ),
                            if (!cat.isDefault)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFF9B2C2C),
                                ),
                                tooltip: loc.todoDelete,
                                onPressed: () =>
                                    _controller.deleteCategory(cat.id),
                              ),
                          ],
                        ),
                        onTap: () {
                          _controller.selectCategory(
                            selected ? null : cat.id,
                          );
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Category filter chips (worship / personal / work / general + custom)
  /// in a single horizontal row. The Add button is pinned outside the
  /// scrollable area so it never scrolls away; the chips scroll
  /// horizontally, so even 20 categories fit without growing the page.
  /// Tapping a chip toggles it; it combines with the active smart tab
  /// (e.g. Today + Personal shows only personal tasks due today).
  Widget _buildCategoryRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Obx(() {
      final cats = _controller.categories;
      final selectedId = _controller.selectedCategoryId.value;

      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 0, 0),
        child: Row(
          children: [
            // Add-new-category button, always visible.
            _ActionChip(
              icon: Icons.add_rounded,
              label: loc.todoNewCategory,
              isDark: isDark,
              onTap: _showAddCategoryDialog,
            ),
            const SizedBox(width: 8),
            // Scrollable single row with every category chip.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < cats.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Builder(
                        builder: (_) {
                          final cat = cats[i];
                          return _CategoryChip(
                            label: cat.localizedName(loc),
                            icon: cat.icon,
                            color: cat.color,
                            selected: selectedId == cat.id,
                            isDark: isDark,
                            onTap: () => _controller.selectCategory(
                              selectedId == cat.id ? null : cat.id,
                            ),
                          );
                        },
                      ),
                    ],
                    // End padding inside the scroll area.
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCompletedHeader(BuildContext context, int count) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => setState(() => _completedExpanded = !_completedExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            Icon(
              _completedExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              color: isDark ? Colors.white54 : Colors.black45,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              loc.todoCompletedCount(count),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    String title;
    String subtitle;
    IconData icon;

    // When a category chip is selected and nothing matches, name the
    // category — combined with the smart filter label when one is active
    // (e.g. "Personal • Today").
    final selectedCatId = _controller.selectedCategoryId.value;
    if (selectedCatId != null) {
      final match = _controller.categories
          .where((c) => c.id == selectedCatId)
          .toList(growable: false);
      if (match.isNotEmpty) {
        final catName = match.first.localizedName(loc);
        final filter = _controller.activeFilter.value;
        final title = filter == TodoFilterType.all
            ? catName
            : '$catName • ${filter.label(loc)}';
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  match.first.icon,
                  size: 72,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.todoEmptyAllSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    switch (_controller.activeFilter.value) {
      case TodoFilterType.today:
        title = loc.todoEmptyToday;
        subtitle = loc.todoEmptyTodaySub;
        icon = Icons.wb_sunny_rounded;
        break;
      case TodoFilterType.upcoming:
        title = loc.todoEmptyUpcoming;
        subtitle = loc.todoEmptyUpcomingSub;
        icon = Icons.event_available_rounded;
        break;
      case TodoFilterType.important:
        title = loc.todoEmptyImportant;
        subtitle = loc.todoEmptyImportantSub;
        icon = Icons.star_rounded;
        break;
      case TodoFilterType.overdue:
        title = loc.todoFilterOverdue;
        subtitle = loc.todoEmptyAllSub;
        icon = Icons.warning_amber_rounded;
        break;
      case TodoFilterType.completed:
        title = loc.todoCompletedSection;
        subtitle = loc.todoEmptyAllSub;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        title = loc.todoEmptyAll;
        subtitle = loc.todoEmptyAllSub;
        icon = Icons.task_alt_rounded;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data for a single super-filter tab.
class _FilterTabData {
  final TodoFilterType type;
  final IconData icon;
  final String label;

  const _FilterTabData({
    required this.type,
    required this.icon,
    required this.label,
  });
}

/// One fixed-width tab: icon on top, short label below.
/// Fits 6 tabs in a single row with no scrolling.
class _FilterTab extends StatelessWidget {
  final _FilterTabData data;
  final bool selected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterTab({
    required this.data,
    required this.selected,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedFg = isDark ? Colors.white70 : Colors.black87;
    final fg = selected ? Colors.white : unselectedFg;

    return Material(
      color: selected ? accentColor : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          label: data.label,
          child: Tooltip(
            message: data.label,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.icon, size: 20, color: fg),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A neutral action chip (Add category).
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFD64463);
    final fg = isDark ? Colors.white70 : Colors.black54;

    return Material(
      color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Semantics(
          button: true,
          label: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }
}

/// One category filter chip: icon + label in a pill.
/// Selected chip is filled with the category color.
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg =
        selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87);

    return Material(
      color: selected ? color : color.withValues(alpha: isDark ? 0.15 : 0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
