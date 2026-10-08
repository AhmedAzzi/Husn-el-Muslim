import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/todo/controllers/todo_controller.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class TodoQuickAddBar extends StatefulWidget {
  const TodoQuickAddBar({super.key});

  @override
  State<TodoQuickAddBar> createState() => _TodoQuickAddBarState();
}

class _TodoQuickAddBarState extends State<TodoQuickAddBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DateTime? _quickDueDate;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    final controller = Get.find<TodoController>();
    controller.quickAddTask(text, dueDate: _quickDueDate);

    _textController.clear();
    setState(() {
      _quickDueDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    const accentColor = Color(0xFF693B42);

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? 8
            : MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E28) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_quickDueDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          _quickDueDate!.day == DateTime.now().day
                              ? loc.todoFilterToday
                              : loc.todoTomorrow,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _quickDueDate = null),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: accentColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Calendar quick toggle
              IconButton(
                icon: Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: _quickDueDate != null
                      ? accentColor
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
                tooltip: loc.todoDueDate,
                onPressed: () {
                  final now = DateTime.now();
                  setState(() {
                    if (_quickDueDate == null) {
                      _quickDueDate = DateTime(now.year, now.month, now.day);
                    } else if (_quickDueDate!.day == now.day) {
                      final tom = now.add(const Duration(days: 1));
                      _quickDueDate = DateTime(tom.year, tom.month, tom.day);
                    } else {
                      _quickDueDate = null;
                    }
                  });
                },
              ),
              // Input text field
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 17,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: loc.todoQuickAddHint,
                    hintStyle: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              // Add button
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  padding: const EdgeInsets.all(12),
                  elevation: 2,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
