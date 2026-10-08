import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/widgets/app_feedback.dart';
import 'package:small_husn_muslim/features/todo/controllers/todo_controller.dart';
import 'package:small_husn_muslim/features/todo/models/todo_category.dart';
import 'package:small_husn_muslim/features/todo/models/todo_item.dart';
import 'package:small_husn_muslim/features/todo/models/todo_priority.dart';
import 'package:small_husn_muslim/features/todo/utils/todo_date_format.dart';
import 'package:small_husn_muslim/features/todo/presentation/widgets/todo_checkbox.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class TodoTaskTile extends StatelessWidget {
  final TodoItem task;
  final VoidCallback onTap;
  final bool isReorderable;

  const TodoTaskTile({
    super.key,
    required this.task,
    required this.onTap,
    this.isReorderable = false,
  });

  String _formatDueDate(BuildContext context, DateTime due) {
    final loc = AppLocalizations.of(context)!;
    if (task.isDueToday) {
      return loc.todoFilterToday;
    }
    if (task.isDueTomorrow) {
      return loc.todoTomorrow;
    }
    return formatTodoShortDate(context, due);
  }

  String _formatDueTime(BuildContext context, TimeOfDay time) {
    return formatTodoTimeOfDay(context, time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final controller = Get.find<TodoController>();

    final cardColor = isDark ? const Color(0xFF242432) : Colors.white;

    final TodoCategory? category = controller.categories.firstWhereOrNull(
      (c) => c.id == task.categoryId,
    );

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? const Color(0xFF3B82F6)
              : const Color(0xFF2E6B34),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          task.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF9B2C2C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Quick complete / uncomplete
          controller.toggleTaskCompletion(task.id);
          return false;
        } else {
          // Delete with Undo snackbar
          final deleted = await controller.deleteTask(task.id);
          if (deleted != null && context.mounted) {
            AppFeedback.snack(
              context,
              loc.todoTaskDeleted,
              type: AppFeedbackType.info,
              action: SnackBarAction(
                label: loc.todoUndo,
                onPressed: () => controller.restoreDeletedTask(),
              ),
            );
          }
          return true;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isOverdue && !task.isCompleted
                ? const Color(0xFFD64463).withValues(alpha: 0.5)
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            width: task.isOverdue && !task.isCompleted ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox
                  TodoCheckbox(
                    isCompleted: task.isCompleted,
                    activeColor: const Color(0xFF2E6B34),
                    onChanged: (_) => controller.toggleTaskCompletion(task.id),
                  ),
                  const SizedBox(width: 8),
                  // Title + compact single-line meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            fontWeight: task.isCompleted
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: task.isCompleted
                                ? (isDark ? Colors.white38 : Colors.black38)
                                : (isDark ? Colors.white : Colors.black87),
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor:
                                isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        // One compact meta line (no pill badges).
                        if (!task.isCompleted && _hasMeta(task, category)) ...[
                          const SizedBox(height: 2),
                          _buildMetaRow(context, isDark, loc, category),
                        ],
                      ],
                    ),
                  ),
                  // Trailing: fav (star) button is always visible;
                  // the drag handle is added beside it in manual-sort mode.
                  _buildFavButton(context, isDark, controller),
                  if (isReorderable)
                    ReorderableDragStartListener(
                      index: task.sortOrder,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: 20,
                          color: isDark ? Colors.white38 : Colors.black26,
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

  /// Star button toggling the task as favourite (high priority).
  Widget _buildFavButton(
    BuildContext context,
    bool isDark,
    TodoController controller,
  ) {
    return IconButton(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        task.isImportant ? Icons.star_rounded : Icons.star_outline_rounded,
        color: task.isImportant
            ? const Color(0xFFF59E0B)
            : (isDark ? Colors.white24 : Colors.black26),
        size: 20,
      ),
      onPressed: () {
        final nextPriority =
            task.isImportant ? TodoPriority.none : TodoPriority.high;
        controller.updateTask(task.copyWith(priority: nextPriority));
      },
    );
  }

  bool _hasMeta(TodoItem task, TodoCategory? category) {
    return task.isOverdue ||
        task.dueDate != null ||
        task.hasSubtasks ||
        task.reminderDateTime != null ||
        task.repeatRule.value != 'none' ||
        (task.notes != null && task.notes!.trim().isNotEmpty) ||
        (category != null && category.id != 'all');
  }

  /// Single compact meta line: tinted due info (red when overdue),
  /// subtask progress, tiny status icons, and a category dot + name.
  Widget _buildMetaRow(
    BuildContext context,
    bool isDark,
    AppLocalizations loc,
    TodoCategory? category,
  ) {
    const dangerColor = Color(0xFFD64463);
    final metaColor = isDark ? Colors.white60 : Colors.black45;
    final dueColor = task.isOverdue ? dangerColor : metaColor;

    String dueText = '';
    if (task.dueDate != null) {
      dueText = _formatDueDate(context, task.dueDate!);
      if (task.dueTime != null) {
        dueText += ' • ${_formatDueTime(context, task.dueTime!)}';
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Due info (red + warning icon when overdue, no separate badge)
        if (task.dueDate != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                task.isOverdue
                    ? Icons.warning_amber_rounded
                    : Icons.calendar_today_rounded,
                size: 12,
                color: dueColor,
              ),
              const SizedBox(width: 3),
              Text(
                dueText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      task.isOverdue ? FontWeight.bold : FontWeight.normal,
                  color: dueColor,
                ),
              ),
            ],
          ),
        // Subtask progress
        if (task.hasSubtasks)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 12,
                color: metaColor,
              ),
              const SizedBox(width: 3),
              Text(
                '${task.completedSubtasksCount}/${task.totalSubtasksCount}',
                style: TextStyle(fontSize: 11, color: metaColor),
              ),
            ],
          ),
        // Status icons
        if (task.reminderDateTime != null)
          Icon(
            Icons.notifications_active_outlined,
            size: 12,
            color: metaColor,
          ),
        if (task.repeatRule.value != 'none')
          Icon(Icons.repeat_rounded, size: 12, color: metaColor),
        if (task.notes != null && task.notes!.trim().isNotEmpty)
          Icon(Icons.notes_rounded, size: 12, color: metaColor),
        // Category dot + name
        if (category != null && category.id != 'all')
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                category.localizedName(loc),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: category.color,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
