import 'package:flutter/material.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

enum TodoPriority {
  none(0),
  low(1),
  medium(2),
  high(3);

  final int value;
  const TodoPriority(this.value);

  static TodoPriority fromValue(int? value) {
    return TodoPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TodoPriority.none,
    );
  }

  Color get color => switch (this) {
        TodoPriority.none => Colors.transparent,
        TodoPriority.low => const Color(0xFF3B82F6), // soft blue
        TodoPriority.medium => const Color(0xFFF59E0B), // amber
        TodoPriority.high => const Color(0xFFD64463), // Husn burgundy/accent
      };

  String label(AppLocalizations loc) => switch (this) {
        TodoPriority.none => loc.todoPriorityNone,
        TodoPriority.low => loc.todoPriorityLow,
        TodoPriority.medium => loc.todoPriorityMedium,
        TodoPriority.high => loc.todoPriorityHigh,
      };

  IconData get icon => switch (this) {
        TodoPriority.none => Icons.outlined_flag_rounded,
        TodoPriority.low => Icons.flag_rounded,
        TodoPriority.medium => Icons.flag_rounded,
        TodoPriority.high => Icons.flag_rounded,
      };
}
