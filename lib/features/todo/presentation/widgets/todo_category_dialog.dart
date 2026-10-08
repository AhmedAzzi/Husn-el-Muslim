import 'package:flutter/material.dart';
import 'package:small_husn_muslim/core/widgets/app_feedback.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class TodoCategoryDialog extends StatefulWidget {
  final Function(String name, int iconCode, int colorValue) onSave;

  const TodoCategoryDialog({super.key, required this.onSave});

  @override
  State<TodoCategoryDialog> createState() => _TodoCategoryDialogState();
}

class _TodoCategoryDialogState extends State<TodoCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();

  static const List<int> _availableColors = [
    0xFF693B42, // Husn burgundy
    0xFF2E6B34, // Green
    0xFF3B82F6, // Blue
    0xFFF59E0B, // Amber
    0xFF8B5CF6, // Purple
    0xFF06B6D4, // Cyan
    0xFFEC4899, // Pink
  ];

  static const List<IconData> _availableIcons = [
    Icons.list_rounded,
    Icons.mosque_rounded,
    Icons.favorite_rounded,
    Icons.work_rounded,
    Icons.school_rounded,
    Icons.home_rounded,
    Icons.shopping_cart_rounded,
    Icons.star_rounded,
  ];

  late int _selectedColor;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedColor = _availableColors[0];
    _selectedIcon = _availableIcons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Text(loc.todoNewCategory, style: theme.dialogTheme.titleTextStyle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: loc.todoCategoryName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Color picker
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableColors.map((c) {
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(c).withValues(alpha: 0.5),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            // Icon picker
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableIcons.map((ico) {
                final isSelected = _selectedIcon == ico;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ico),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(_selectedColor).withValues(alpha: 0.2)
                          : (isDark ? Colors.white10 : Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Color(_selectedColor)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      ico,
                      color: isSelected
                          ? Color(_selectedColor)
                          : (isDark ? Colors.white70 : Colors.black87),
                      size: 20,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.todoCancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              AppFeedback.snack(context, loc.todoCategoryName,
                  type: AppFeedbackType.warn);
              return;
            }
            widget.onSave(name, _selectedIcon.codePoint, _selectedColor);
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: Color(_selectedColor),
          ),
          child: Text(loc.todoSave),
        ),
      ],
    );
  }
}
