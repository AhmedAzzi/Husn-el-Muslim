import 'package:small_husn_muslim/features/tracking/data/prayer_log_entry.dart';

/// Pure scoring engine for the prayer tracker. No I/O, no dates — just math,
/// so it is trivially unit-testable.
///
/// Rules (from the tracker design "النقاط في التطبيق" + "مضاعف النقاط"):
/// - Base points per status: takbeer +30, mosque +27, jamaa +14,
///   onTimeAlone +1, late +1, missed −10.
/// - Prayer multiplier: Fajr ×2, Dhuhr/Asr/Maghrib ×1, Isha ×1.5.
///   Applied to every status including missed (−10 × 2 = −20 for Fajr);
///   fractional results round to the nearest integer.
/// - Level comes from the rolling 30-day total against 8 thresholds:
///   1 / 250 / 600 / 1100 / 1800 / 2800 / 4100 / 5450.
///   Zero points still shows level 1 (matches the design's empty state).
class PointsEngine {
  PointsEngine._();

  /// Base points per [PrayerStatus], in declaration order of the design table.
  static const Map<PrayerStatus, int> basePoints = {
    PrayerStatus.takbeer: 30,
    PrayerStatus.mosque: 27,
    PrayerStatus.jamaa: 14,
    PrayerStatus.onTimeAlone: 1,
    PrayerStatus.late: 1,
    PrayerStatus.missed: -10,
  };

  /// Multiplier per prayer index (0 Fajr .. 4 Isha).
  static const Map<int, double> prayerMultipliers = {
    0: 2.0,
    1: 1.0,
    2: 1.0,
    3: 1.0,
    4: 1.5,
  };

  /// Points thresholds for levels 1..8 ("المراحل").
  static const List<int> levelThresholds = [
    1,
    250,
    600,
    1100,
    1800,
    2800,
    4100,
    5450,
  ];

  static int get maxLevel => levelThresholds.length;

  /// Points for a single logged prayer.
  static int entryPoints(PrayerLogEntry entry) {
    final base = basePoints[entry.status] ?? 0;
    final multiplier = prayerMultipliers[entry.prayerIndex] ?? 1.0;
    return (base * multiplier).round();
  }

  /// Sum of points for a collection of entries (e.g. one day, or 30 days).
  static int totalPoints(Iterable<PrayerLogEntry> entries) =>
      entries.fold(0, (sum, e) => sum + entryPoints(e));

  /// Level 1..[maxLevel] for a rolling total. Always ≥ 1.
  static int levelForPoints(int points) {
    var level = 1;
    for (var i = 0; i < levelThresholds.length; i++) {
      if (points >= levelThresholds[i]) level = i + 1;
    }
    return level;
  }

  /// Threshold that unlocked [level] (level is 1-based).
  static int thresholdForLevel(int level) {
    final clamped = level.clamp(1, maxLevel);
    return levelThresholds[clamped - 1];
  }

  /// Points needed to reach the next level, or null at max level.
  static int? pointsToNextLevel(int points) {
    for (final t in levelThresholds) {
      if (points < t) return t - points;
    }
    return null;
  }

  /// 0.0..1.0 progress from the current level's threshold to the next one.
  /// Full (1.0) at max level.
  static double progressToNextLevel(int points) {
    final level = levelForPoints(points);
    if (level >= maxLevel) return 1.0;
    final base = thresholdForLevel(level);
    final next = thresholdForLevel(level + 1);
    if (points <= base) return 0.0;
    return ((points - base) / (next - base)).clamp(0.0, 1.0);
  }
}
