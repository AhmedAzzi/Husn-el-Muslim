import '../../data/models/khatma_models.dart';
import '../../data/repositories/reading_repository.dart';

/// Normalizes [t] to local midnight.
DateTime localDay(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime addDays(DateTime day, int n) =>
    DateTime(day.year, day.month, day.day + n);

/// Aggregates reading events into the statistics the UI shows.
///
/// All quantities derive from `ReadingEvent` records (`completed` status only),
/// so charts and counters can never disagree with history.
class StatisticsService {
  StatisticsService(this._readingRepo);

  final ReadingRepository _readingRepo;

  /// Completed ayahs on the local day [day].
  Future<int> countOn(DateTime day) async {
    final start = localDay(day);
    final counts = await _readingRepo.dailyCounts(start, addDays(start, 1));
    return counts.isEmpty ? 0 : counts.first.count;
  }

  /// Minutes read on the local day [day].
  Future<int> minutesOn(DateTime day) async {
    final start = localDay(day);
    final mins = await _readingRepo.dailyMinutes(start, addDays(start, 1));
    return mins.isEmpty ? 0 : mins.first.minutes;
  }

  /// Per-day completed counts for the last [days] local days (oldest first).
  Future<List<DailyCount>> lastDays(int days, {DateTime? today}) async {
    final end0 = localDay(today ?? DateTime.now());
    final start = addDays(end0, -(days - 1));
    final counts = await _readingRepo.dailyCounts(start, addDays(end0, 1));
    final byDay = {for (final c in counts) localDay(c.day): c.count};
    return List.generate(days, (i) {
      final d = addDays(start, i);
      return DailyCount(day: d, count: byDay[d] ?? 0);
    });
  }

  /// Aggregates for the weekly chart (Saturday .. Friday, or any 7-day window).
  Future<List<DailyCount>> lastWeek({DateTime? today}) async {
    final now = today ?? DateTime.now();
    // Roll back to the most recent Saturday (ISO weekday 6 => Saturday).
    final end0 = localDay(now);
    final saturday = addDays(end0, -(end0.weekday % 7));
    final counts =
        await _readingRepo.dailyCounts(saturday, addDays(saturday, 7));
    final byDay = {for (final c in counts) localDay(c.day): c.count};
    return List.generate(7, (i) {
      final d = addDays(saturday, i);
      return DailyCount(day: d, count: byDay[d] ?? 0);
    });
  }

  /// Aggregates for the monthly chart.
  Future<List<DailyCount>> lastMonth({DateTime? today}) async {
    final now = localDay(today ?? DateTime.now());
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final counts = await _readingRepo.dailyCounts(start, end);
    final byDay = {for (final c in counts) localDay(c.day): c.count};
    final daysInMonth = end.subtract(const Duration(days: 1)).day;
    return List.generate(daysInMonth, (i) {
      final d = DateTime(now.year, now.month, i + 1);
      return DailyCount(day: d, count: byDay[d] ?? 0);
    });
  }

  /// Cumulative / lifetime statistics.
  Future<CumulativeStats> cumulative() async {
    final totals = await _readingRepo.totals();
    final activeDays = await _readingRepo.activeDays();
    final first = await _readingRepo.firstCompleted();
    final now = localDay(DateTime.now());
    final streak = await currentStreak(today: now);

    return CumulativeStats(
      totalVerses: totals.completed,
      totalEvents: totals.total,
      totalShown: totals.shown,
      totalLater: totals.later,
      totalMinutes: await _totalMinutes(),
      longestStreak: await _longestStreak(activeDays),
      currentStreak: streak,
      activeDays: activeDays.length,
      firstReadingDate: first?.completedAt ?? first?.startedAt,
    );
  }

  Future<int> _totalMinutes() async {
    final now = localDay(DateTime.now());
    final days = await _readingRepo.dailyMinutes(
      DateTime(2000, 1, 1),
      addDays(now, 1),
    );
    var sum = 0;
    for (final d in days) {
      sum += d.minutes;
    }
    return sum;
  }

  /// Current streak (consecutive local days with >= 1 completed ayah, ending
  /// today or yesterday). Reading today does not "quarantine" a streak.
  Future<int> currentStreak({DateTime? today}) async {
    final now = localDay(today ?? DateTime.now());
    final days = await _readingRepo.activeDays();
    final daySet = {for (final d in days) localDay(d)};

    var streak = 0;
    var cursor = now;
    if (!daySet.contains(cursor)) {
      cursor = addDays(cursor, -1); // allow a stale today to start a streak
      if (!daySet.contains(cursor)) return 0;
    }
    while (daySet.contains(cursor)) {
      streak++;
      cursor = addDays(cursor, -1);
    }
    return streak;
  }

  Future<int> _longestStreak(List<DateTime> activeDays) async {
    final set = {for (final d in activeDays) localDay(d)};
    if (set.isEmpty) return 0;
    final sorted = set.toList()..sort();
    var best = 1, cur = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        cur++;
      } else {
        if (cur > best) best = cur;
        cur = 1;
      }
    }
    if (cur > best) best = cur;
    return best;
  }

  /// Shared labels for weekdays, starting Saturday.
  static const List<String> weekdayLabels = [
    'Sat', // Saturday
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
  ];
}

/// Immutable cumulative statistics.
class CumulativeStats {
  const CumulativeStats({
    required this.totalVerses,
    required this.totalEvents,
    required this.totalShown,
    required this.totalLater,
    required this.totalMinutes,
    required this.longestStreak,
    required this.currentStreak,
    required this.activeDays,
    this.firstReadingDate,
  });

  final int totalVerses;
  final int totalEvents;
  final int totalShown;
  final int totalLater;
  final int totalMinutes;
  final int longestStreak;
  final int currentStreak;
  final int activeDays;
  final DateTime? firstReadingDate;
}
