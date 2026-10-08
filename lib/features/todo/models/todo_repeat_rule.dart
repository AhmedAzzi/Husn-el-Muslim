import 'package:small_husn_muslim/l10n/app_localizations.dart';

enum TodoRepeatRule {
  none('none'),
  daily('daily'),
  // Legacy: kept so old rows still resolve + recur; hidden from the picker.
  weekdays('weekdays'),
  weekly('weekly'),
  monthly('monthly'),
  yearly('yearly'),
  custom('custom');

  final String value;
  const TodoRepeatRule(this.value);

  static TodoRepeatRule fromValue(String? value) {
    return TodoRepeatRule.values.firstWhere(
      (r) => r.value == value,
      orElse: () => TodoRepeatRule.none,
    );
  }

  /// Rules offered in the repeat picker (`weekdays` intentionally excluded).
  static List<TodoRepeatRule> get pickerValues => [
        TodoRepeatRule.none,
        TodoRepeatRule.daily,
        TodoRepeatRule.weekly,
        TodoRepeatRule.monthly,
        TodoRepeatRule.yearly,
        TodoRepeatRule.custom,
      ];

  String label(AppLocalizations loc) => switch (this) {
        TodoRepeatRule.none => loc.todoRepeatNone,
        TodoRepeatRule.daily => loc.todoRepeatDaily,
        TodoRepeatRule.weekdays => loc.todoRepeatWeekdays,
        TodoRepeatRule.weekly => loc.todoRepeatWeekly,
        TodoRepeatRule.monthly => loc.todoRepeatMonthly,
        TodoRepeatRule.yearly => loc.todoRepeatYearly,
        TodoRepeatRule.custom => loc.todoRepeatCustom,
      };

  /// Computes the next due date after [current].
  /// [customWeekdays] holds DateTime weekday numbers (Mon=1 … Sun=7)
  /// and is required when this is [TodoRepeatRule.custom].
  DateTime? computeNextDue(DateTime current, {List<int>? customWeekdays}) {
    switch (this) {
      case TodoRepeatRule.none:
        return null;
      case TodoRepeatRule.daily:
        return DateTime(
          current.year,
          current.month,
          current.day + 1,
          current.hour,
          current.minute,
        );
      case TodoRepeatRule.weekdays:
        var next = current.add(const Duration(days: 1));
        // Skip Friday (5) and Saturday (6) in Islamic work week
        while (next.weekday == DateTime.friday || next.weekday == DateTime.saturday) {
          next = next.add(const Duration(days: 1));
        }
        return DateTime(
          next.year,
          next.month,
          next.day,
          current.hour,
          current.minute,
        );
      case TodoRepeatRule.weekly:
        return DateTime(
          current.year,
          current.month,
          current.day + 7,
          current.hour,
          current.minute,
        );
      case TodoRepeatRule.monthly:
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      case TodoRepeatRule.yearly:
        return DateTime(
          current.year + 1,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
      case TodoRepeatRule.custom:
        final days = (customWeekdays ?? const <int>[])
            .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
            .toSet();
        if (days.isEmpty) return null;
        // Next selected weekday strictly after [current] (always ≤ 7 days).
        for (var offset = 1; offset <= 7; offset++) {
          final candidate = current.add(Duration(days: offset));
          if (days.contains(candidate.weekday)) {
            return DateTime(
              candidate.year,
              candidate.month,
              candidate.day,
              current.hour,
              current.minute,
            );
          }
        }
        return null;
    }
  }
}
