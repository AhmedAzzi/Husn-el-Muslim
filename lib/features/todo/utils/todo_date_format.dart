import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale tag of the current app language (ar / en / fr).
String todoLocaleTag(BuildContext context) =>
    Localizations.localeOf(context).toString();

/// Full date in the app language, e.g. `16 سبتمبر 2026`.
/// Digits are always Latin (0-9): Arabic locale would otherwise render ٠-٩.
String formatTodoDate(BuildContext context, DateTime date) =>
    _withLatinDigits(
      DateFormat.yMMMd(todoLocaleTag(context)).format(date),
    );

/// Short date in the app language, e.g. `16 سبتمبر`.
String formatTodoShortDate(BuildContext context, DateTime date) =>
    _withLatinDigits(
      DateFormat.MMMd(todoLocaleTag(context)).format(date),
    );

/// Date + time in the app language, e.g. `16 سبتمبر 2026 2:30 م`.
String formatTodoDateTime(BuildContext context, DateTime date) =>
    _withLatinDigits(
      DateFormat.yMMMd(todoLocaleTag(context)).add_jm().format(date),
    );

/// [TimeOfDay.format] follows the app locale but may render ٠-٩ digits;
/// force Latin digits for consistency.
String formatTodoTimeOfDay(BuildContext context, TimeOfDay time) =>
    _withLatinDigits(time.format(context));

/// Replaces Arabic-Indic (٠-٩, U+0660–U+0669) and Eastern Arabic-Indic
/// (۰-۹, U+06F0–U+06F9) digits with Latin (0-9) digits.
/// Month/day names, meridiems (ص/م) and separators are left untouched.
String _withLatinDigits(String input) {
  const arabicIndicZero = 0x0660;
  const easternIndicZero = 0x06F0;
  const latinZero = 0x30;
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= arabicIndicZero && rune <= arabicIndicZero + 9) {
      buffer.writeCharCode(rune - arabicIndicZero + latinZero);
    } else if (rune >= easternIndicZero && rune <= easternIndicZero + 9) {
      buffer.writeCharCode(rune - easternIndicZero + latinZero);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
