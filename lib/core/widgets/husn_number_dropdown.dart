import 'package:flutter/material.dart';

/// Reusable dropdown number picker replacing slider-based choosers.
///
/// Tap-to-choose is easier than dragging a slider, especially for older
/// users. Styled to match the app theme (Amiri font, card colors, RTL
/// friendly) with an [accentColor] tint for the selected affordance.
///
/// If [value] is not inside [options] (e.g. a legacy stored value), it is
/// appended automatically so no saved setting is ever lost or clamped.
class HusnNumberDropdown extends StatelessWidget {
  const HusnNumberDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.labelOf,
    this.accentColor = const Color(0xFFD64463),
    this.icon,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final String Function(int value) labelOf;
  final Color accentColor;
  final IconData? icon;

  List<int> get _effectiveOptions {
    if (options.contains(value)) return options;
    return [...options, value]..sort();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282836) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              underline: const SizedBox.shrink(),
              isExpanded: false,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: accentColor, size: 22),
              dropdownColor:
                  isDark ? const Color(0xFF282836) : Colors.white,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
              items: [
                for (final o in _effectiveOptions)
                  DropdownMenuItem<int>(
                    value: o,
                    child: Text(
                      labelOf(o),
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: o == value
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 15,
                        color: o == value
                            ? accentColor
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Labeled row: title on one side, [HusnNumberDropdown] on the other.
/// Single consistent layout for every former slider row.
class HusnNumberPickerRow extends StatelessWidget {
  const HusnNumberPickerRow({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.labelOf,
    this.accentColor = const Color(0xFFD64463),
    this.icon,
  });

  final String title;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final String Function(int value) labelOf;
  final Color accentColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        HusnNumberDropdown(
          value: value,
          options: options,
          onChanged: onChanged,
          labelOf: labelOf,
          accentColor: accentColor,
          icon: icon,
        ),
      ],
    );
  }
}

/// Duration picker with separate hour + minute dropdowns, e.g. "2h 30m".
///
/// Hours and minutes are chosen independently; [onChanged] receives the
/// total minutes. [minuteStep] controls the minute granularity (default 5).
/// Invalid combinations are impossible by construction.
class HusnDurationPicker extends StatelessWidget {
  const HusnDurationPicker({
    super.key,
    required this.totalMinutes,
    required this.onChanged,
    this.maxHours = 12,
    this.minuteStep = 5,
    this.accentColor = const Color(0xFFD64463),
    required this.hoursLabelOf,
    required this.minutesLabelOf,
  });

  final int totalMinutes;
  final ValueChanged<int> onChanged;
  final int maxHours;
  final int minuteStep;
  final Color accentColor;
  final String Function(int hours) hoursLabelOf;
  final String Function(int minutes) minutesLabelOf;

  @override
  Widget build(BuildContext context) {
    final hours = (totalMinutes ~/ 60).clamp(0, maxHours);
    final minutes = (totalMinutes - hours * 60).clamp(0, 59);
    // Snap displayed minutes down to the step grid; the stored value is
    // only rewritten when the user picks a new entry.
    final snappedMinutes = (minutes ~/ minuteStep) * minuteStep;
    final minuteOptions = [
      for (var m = 0; m < 60; m += minuteStep) m,
      if (snappedMinutes % minuteStep != 0) snappedMinutes,
    ]..sort();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HusnNumberDropdown(
            value: hours,
            options: [for (var h = 0; h <= maxHours; h++) h],
            onChanged: (h) => onChanged(h * 60 + snappedMinutes),
            labelOf: hoursLabelOf,
            accentColor: accentColor,
          ),
          const SizedBox(width: 8),
          HusnNumberDropdown(
            value: snappedMinutes,
            options: minuteOptions,
            onChanged: (m) => onChanged(hours * 60 + m),
            labelOf: minutesLabelOf,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}

/// Single-row pill toggle buttons for a fixed set of string [values].
///
/// Each value is a pill button with its label inside; tapping toggles it
/// on/off directly. All values fit in one row via [Expanded]. Styled with
/// [accentColor] when selected. Works single-select (caller enforces one)
/// or multi-select — the widget itself just reports toggles.
class HusnChoicePills extends StatelessWidget {
  const HusnChoicePills({
    super.key,
    required this.values,
    required this.isSelected,
    required this.onToggle,
    required this.labelOf,
    this.accentColor = const Color(0xFFD64463),
  });

  final List<String> values;
  final bool Function(String value) isSelected;
  final void Function(String value, bool selected) onToggle;
  final String Function(String value) labelOf;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _PrayerTogglePill(
                label: labelOf(values[i]),
                selected: isSelected(values[i]),
                accentColor: accentColor,
                isDark: isDark,
                onTap: () {
                  final p = values[i];
                  onToggle(p, !isSelected(p));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single-row prayer toggle buttons (e.g. Fajr/Dhuhr/Asr/Maghrib/Isha).
///
/// Thin alias of [HusnChoicePills] kept for prayer pickers.
class HusnPrayerToggleRow extends HusnChoicePills {
  const HusnPrayerToggleRow({
    super.key,
    required List<String> prayers,
    required super.isSelected,
    required super.onToggle,
    required super.labelOf,
    super.accentColor,
  }) : super(values: prayers);
}

class _PrayerTogglePill extends StatelessWidget {
  const _PrayerTogglePill({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF282836) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        // FittedBox shrinks long labels (e.g. "Questions", "30 seconds")
        // to fit instead of truncating them or overflowing the pill.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected
                  ? accentColor
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}

/// Time-of-day picker with separate hour (0-23) + minute dropdowns.
/// Suitable for alarm/bedtime clock times.
class HusnTimeOfDayPicker extends StatelessWidget {
  const HusnTimeOfDayPicker({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
    this.accentColor = const Color(0xFFD64463),
    required this.hoursLabelOf,
    required this.minutesLabelOf,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;
  final Color accentColor;
  final String Function(int hour) hoursLabelOf;
  final String Function(int minute) minutesLabelOf;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HusnNumberDropdown(
            value: hour.clamp(0, 23),
            options: [for (var h = 0; h < 24; h++) h],
            onChanged: (h) => onChanged(h, minute),
            labelOf: hoursLabelOf,
            accentColor: accentColor,
          ),
          const SizedBox(width: 8),
          HusnNumberDropdown(
            value: minute.clamp(0, 59),
            options: [for (var m = 0; m < 60; m += 5) m],
            onChanged: (m) => onChanged(hour, m),
            labelOf: minutesLabelOf,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }
}
