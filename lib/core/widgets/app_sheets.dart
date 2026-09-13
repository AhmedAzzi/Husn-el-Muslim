import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Single entry point for the app's bottom sheets.
/// Replaces the triplicate `_showCustomBottomSheet` builders
/// (general / notification / prayer-data settings): one themed card
/// container, drag handle, Amiri title + subtitle, scrollable child.
/// Surface + shape come from BottomSheetTheme; the handle is drawn here
/// because Get.bottomSheet does not render the theme's showDragHandle.
class AppSheets {
  const AppSheets._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetTheme = theme.bottomSheetTheme;
    final background = sheetTheme.backgroundColor ??
        (isDark ? const Color(0xFF1E1E28) : Colors.white);
    final shape = sheetTheme.shape;
    final borderRadius = shape is RoundedRectangleBorder
        ? shape.borderRadius
        : const BorderRadius.vertical(top: Radius.circular(28));
    // Inherits the app-wide Directionality (forceRtl) — no forced
    // direction here so sheets follow the single app source.
    return Get.bottomSheet<T>(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: borderRadius,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.dialogTheme.titleTextStyle,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: (theme.dialogTheme.contentTextStyle ??
                        const TextStyle(fontFamily: 'Amiri'))
                    .copyWith(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              // Options scroll when taller than the sheet allows (e.g. the
              // 11-item calculation-method list on small screens).
              Flexible(
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
            ],
          ),
        ),
      isScrollControlled: true,
    );
  }

  /// Wrap of selectable chips with the single app-wide chip style.
  /// Replaces the twin interval pickers (general + notification settings).
  static Widget chipGroup<T>({
    required BuildContext context,
    required List<T> values,
    required T selected,
    required String Function(T value) labelOf,
    required void Function(T value) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: values.map((value) {
        final isSelected = value == selected;
        return ChoiceChip(
          label: Text(
            labelOf(value),
            style: TextStyle(
              fontFamily: 'Amiri',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : null,
              fontSize: 15,
            ),
          ),
          selected: isSelected,
          selectedColor: const Color(0xFFD64463),
          backgroundColor: isDark
              ? const Color(0xFF2C2C38)
              : Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color:
                  isSelected ? const Color(0xFFD64463) : Colors.transparent,
            ),
          ),
          onSelected: (chosen) {
            if (chosen) onSelected(value);
          },
        );
      }).toList(),
    );
  }
}
