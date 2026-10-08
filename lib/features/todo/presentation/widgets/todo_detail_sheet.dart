import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:small_husn_muslim/features/todo/controllers/todo_controller.dart';
import 'package:small_husn_muslim/features/todo/utils/todo_date_format.dart';
import 'package:small_husn_muslim/features/todo/models/todo_item.dart';
import 'package:small_husn_muslim/features/todo/models/todo_priority.dart';
import 'package:small_husn_muslim/features/todo/models/todo_repeat_rule.dart';
import 'package:small_husn_muslim/features/todo/models/todo_subtask.dart';
import 'package:small_husn_muslim/features/todo/presentation/widgets/todo_category_dialog.dart';
import 'package:small_husn_muslim/features/todo/presentation/widgets/todo_checkbox.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class TodoDetailSheet extends StatefulWidget {
  final TodoItem task;

  const TodoDetailSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TodoItem task) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E28) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TodoDetailSheet(task: task),
    );
  }

  @override
  State<TodoDetailSheet> createState() => _TodoDetailSheetState();
}

class _TodoDetailSheetState extends State<TodoDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  final TextEditingController _newSubtaskController = TextEditingController();
  final TextEditingController _newTagController = TextEditingController();

  late bool _isCompleted;
  late TodoPriority _priority;
  late TodoRepeatRule _repeatRule;
  late Set<int> _customWeekdays;
  late String _categoryId;
  late List<TodoSubtask> _subtasks;
  late List<String> _tags;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  DateTime? _reminderDateTime;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t.title);
    _notesController = TextEditingController(text: t.notes ?? '');
    _isCompleted = t.isCompleted;
    _priority = t.priority;
    _repeatRule = t.repeatRule;
    _customWeekdays = Set<int>.from(t.repeatWeekdays);
    _categoryId = t.categoryId;
    _subtasks = List<TodoSubtask>.from(t.subtasks);
    _tags = List<String>.from(t.tags);
    _dueDate = t.dueDate;
    _dueTime = t.dueTime;
    _reminderDateTime = t.reminderDateTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _newSubtaskController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  /// Sunday-first day order (DateTime weekday numbers),
  /// matching the regional week (weekend Fri–Sat).
  static const List<int> _weekOrder = [7, 1, 2, 3, 4, 5, 6];

  /// A known Sunday used to derive localized day names.
  static final DateTime _referenceSunday = DateTime(2026, 9, 20);

  String _weekdayLabel(BuildContext context, int weekday) {
    final date = _referenceSunday.add(
      Duration(days: _weekOrder.indexOf(weekday)),
    );
    return DateFormat.E(todoLocaleTag(context)).format(date);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // Custom repeat without any day selected means "no repeat".
    var repeatRule = _repeatRule;
    final repeatDays = _customWeekdays.toList()..sort();
    if (repeatRule == TodoRepeatRule.custom && repeatDays.isEmpty) {
      repeatRule = TodoRepeatRule.none;
    }

    final controller = Get.find<TodoController>();
    final updated = widget.task.copyWith(
      title: title,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isCompleted: _isCompleted,
      dueDate: _dueDate,
      dueTime: _dueTime,
      reminderDateTime: _reminderDateTime,
      repeatRule: repeatRule,
      repeatWeekdays:
          repeatRule == TodoRepeatRule.custom ? repeatDays : const <int>[],
      priority: _priority,
      categoryId: _categoryId,
      subtasks: _subtasks,
      tags: _tags,
      clearDueDate: _dueDate == null,
      clearDueTime: _dueTime == null,
      clearReminder: _reminderDateTime == null,
      clearNotes: _notesController.text.trim().isEmpty,
    );

    controller.updateTask(updated);
    Navigator.of(context).pop();
  }

  void _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
        // If due date wasn't set, default to today
        _dueDate ??= DateTime.now();
      });
    }
  }

  void _setReminderPreset(Duration before) {
    _dueDate ??= DateTime.now();
    final hour = _dueTime?.hour ?? 9;
    final minute = _dueTime?.minute ?? 0;
    final target = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      hour,
      minute,
    );
    setState(() {
      _reminderDateTime = target.subtract(before);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final controller = Get.find<TodoController>();
    const accentColor = Color(0xFF693B42);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          children: [
            // Header Row: Checkbox, Title, Star
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TodoCheckbox(
                  isCompleted: _isCompleted,
                  size: 26,
                  onChanged: (val) => setState(() => _isCompleted = val),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      decoration:
                          _isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.todoTaskTitle,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _priority == TodoPriority.high
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _priority == TodoPriority.high
                        ? const Color(0xFFF59E0B)
                        : (isDark ? Colors.white38 : Colors.black38),
                    size: 26,
                  ),
                  onPressed: () {
                    setState(() {
                      _priority = _priority == TodoPriority.high
                          ? TodoPriority.none
                          : TodoPriority.high;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 16),
            // Scrollable Content
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // Notes input
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    minLines: 1,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                      hintText: loc.todoTaskNotes,
                      hintStyle: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 15,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF252532)
                          : Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // --- SUBTASKS SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.checklist_rounded, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            loc.todoSubtasks,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_subtasks.isNotEmpty)
                        Text(
                          '${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._subtasks.map((sub) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Checkbox(
                              value: sub.isCompleted,
                              activeColor: const Color(0xFF2E6B34),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  final idx = _subtasks.indexOf(sub);
                                  _subtasks[idx] =
                                      sub.copyWith(isCompleted: val ?? false);
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                sub.title,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 15,
                                  decoration: sub.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: sub.isCompleted
                                      ? (isDark
                                          ? Colors.white38
                                          : Colors.black38)
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                setState(() {
                                  _subtasks.remove(sub);
                                });
                              },
                            ),
                          ],
                        ),
                      )),
                  // Add subtask inline
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.add_rounded, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _newSubtaskController,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: loc.todoAddSubtask,
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) {
                              setState(() {
                                _subtasks.add(TodoSubtask(
                                  id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                                  title: text.trim(),
                                ));
                                _newSubtaskController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // --- DUE DATE & TIME ---
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        loc.todoDueDate,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_dueDate != null) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            _dueDate = null;
                            _dueTime = null;
                          }),
                          child: Text(loc.todoClearDate),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        showCheckmark: false,
                        label: Text(loc.todoFilterToday),
                        selected: _dueDate != null &&
                            _dueDate!.day == DateTime.now().day &&
                            _dueDate!.month == DateTime.now().month,
                        onSelected: (selected) {
                          setState(() {
                            final now = DateTime.now();
                            _dueDate = selected
                                ? DateTime(now.year, now.month, now.day)
                                : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        showCheckmark: false,
                        label: Text(loc.todoTomorrow),
                        selected: _dueDate != null &&
                            _dueDate!.day ==
                                DateTime.now().add(const Duration(days: 1)).day,
                        onSelected: (selected) {
                          setState(() {
                            final tom =
                                DateTime.now().add(const Duration(days: 1));
                            _dueDate = selected
                                ? DateTime(tom.year, tom.month, tom.day)
                                : null;
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.event_rounded, size: 16),
                        label: Text(_dueDate == null
                            ? loc.todoPickDate
                            : formatTodoDate(context, _dueDate!)),
                        onPressed: _pickDueDate,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(_dueTime == null
                            ? loc.todoPickTime
                            : formatTodoTimeOfDay(context, _dueTime!)),
                        onPressed: _pickDueTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // --- REMINDER ---
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        loc.todoReminder,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_reminderDateTime != null) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            _reminderDateTime = null;
                          }),
                          child: Text(loc.todoNoReminder),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: Text(loc.todoReminderAtDue),
                        onPressed: () => _setReminderPreset(Duration.zero),
                      ),
                      ActionChip(
                        label: Text(loc.todoReminder15m),
                        onPressed: () =>
                            _setReminderPreset(const Duration(minutes: 15)),
                      ),
                      ActionChip(
                        label: Text(loc.todoReminder1h),
                        onPressed: () =>
                            _setReminderPreset(const Duration(hours: 1)),
                      ),
                      ActionChip(
                        label: Text(loc.todoReminder1d),
                        onPressed: () =>
                            _setReminderPreset(const Duration(days: 1)),
                      ),
                    ],
                  ),
                  if (_reminderDateTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${loc.todoReminderSet}: ${formatTodoDateTime(context, _reminderDateTime!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E6B34),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),

                  // --- REPEAT ---
                  Row(
                    children: [
                      const Icon(Icons.repeat_rounded, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        loc.todoRepeat,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TodoRepeatRule.pickerValues.map((rule) {
                      final isSelected = _repeatRule == rule;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text(rule.label(loc)),
                        selected: isSelected,
                        onSelected: (_) => setState(() {
                          _repeatRule = rule;
                          // Preselect the due weekday for convenience.
                          if (rule == TodoRepeatRule.custom &&
                              _customWeekdays.isEmpty &&
                              _dueDate != null) {
                            _customWeekdays.add(_dueDate!.weekday);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  // Custom days selector (e.g. Sunday + Thursday + Friday).
                  if (_repeatRule == TodoRepeatRule.custom) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final day in _weekOrder)
                          ChoiceChip(
                            showCheckmark: false,
                            label: Text(_weekdayLabel(context, day)),
                            selected: _customWeekdays.contains(day),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _customWeekdays.add(day);
                                } else {
                                  _customWeekdays.remove(day);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),

                  // --- PRIORITY ---
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        loc.todoPriority,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TodoPriority.values.map((p) {
                      final isSelected = _priority == p;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text(p.label(loc)),
                        selected: isSelected,
                        selectedColor: p.color.withValues(alpha: 0.2),
                        avatar: p != TodoPriority.none
                            ? Icon(p.icon, size: 16, color: p.color)
                            : null,
                        onSelected: (_) => setState(() => _priority = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // --- LIST / CATEGORY ---
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        loc.todoCategory,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => TodoCategoryDialog(
                              onSave: (name, iconCode, colorValue) {
                                controller.addCategory(
                                    name, iconCode, colorValue);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Obx(() {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.categories.map((cat) {
                        final isSelected = _categoryId == cat.id;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(cat.localizedName(loc)),
                          selected: isSelected,
                          selectedColor: cat.color.withValues(alpha: 0.2),
                          avatar: Icon(cat.icon, size: 16, color: cat.color),
                          onSelected: (selected) {
                            setState(() {
                              _categoryId = selected ? cat.id : 'all';
                            });
                          },
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 18),

                  // --- TAGS ---
                  Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 20),
                      const SizedBox(width: 6),
                      const Text(
                        'الوسوم / Tags',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._tags.map((tag) => Chip(
                            label: Text('#$tag'),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                          )),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _newTagController,
                          decoration: const InputDecoration(
                            hintText: '+ وسام',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (tag) {
                            final clean = tag.replaceAll('#', '').trim();
                            if (clean.isNotEmpty && !_tags.contains(clean)) {
                              setState(() {
                                _tags.add(clean);
                                _newTagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
            // Footer: Delete Task button & Save button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFF9B2C2C)),
                  tooltip: loc.todoDelete,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(loc.todoDeleteConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(loc.todoCancel),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF9B2C2C),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              controller.deleteTask(widget.task.id);
                              Navigator.of(context).pop();
                            },
                            child: Text(loc.todoDelete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(loc.todoSave),
                  style: FilledButton.styleFrom(
                    // Bright rose on dark surfaces for contrast,
                    // deep burgundy on light surfaces.
                    backgroundColor: isDark
                        ? const Color(0xFFD64463)
                        : accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
