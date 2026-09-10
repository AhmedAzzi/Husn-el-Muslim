import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:small_husn_muslim/features/tracking/data/points_engine.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_log_entry.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';
import 'package:small_husn_muslim/features/tracking/presentation/log_prayer_sheet.dart';
import 'package:small_husn_muslim/features/tracking/presentation/tracking_details_sheet.dart';
import 'package:small_husn_muslim/features/settings/presentation/settings_screen.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_reminder_service.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// 5-prayer tracker ("تتبع الصلوات") in the Husn app visual language
/// (Amiri, deep-night cards, rose accents): level pill + gem strip, اليوم
/// 5-prayer day card, الهدف اليومي stats, Hijri/Gregorian month calendar,
/// 30-day overview.
///
/// Tapping a prayer circle opens the "how did you pray" picker sheet
/// (takbeer/mosque/jamaa/on-time/late/missed with per-option points).
/// Future days are viewable but not loggable. All tracking settings live
/// in the app Settings screen — this page is settings-free.
class PrayerTrackingScreen extends StatefulWidget {
  const PrayerTrackingScreen({super.key});

  @override
  State<PrayerTrackingScreen> createState() => _PrayerTrackingScreenState();
}

class _PrayerTrackingScreenState extends State<PrayerTrackingScreen> {
  static const _accent = Color(0xFFD64463);

  /// App card decoration (mirrors SettingsWidgets.buildCardContainer).
  static BoxDecoration _cardDeco(bool isDark) => BoxDecoration(
        color: isDark ? const Color(0xFF1E1E28) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  late DateTime _viewingDate;
  late DateTime _viewMonth;
  bool _loading = true;

  List<PrayerLogEntry?> _day = const [];
  int _current = 0;
  int _longest = 0;
  int _goal = PrayerTrackingRepository.defaultDailyGoal;
  int _points30 = 0;
  int _level = 1;
  double _progress = 0.0;
  int _hijriOffset = 0;
  bool _disabled = false;

  /// 42 ascending calendar cells (newest-first storage reversed).
  List<List<PrayerLogEntry?>> _grid = const [];
  late DateTime _gridStart;

  /// Last 30 days ending today, for the overview card.
  int _totalPerformed = 0;
  double _onTimeRate = 0.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewingDate = DateTime(now.year, now.month, now.day);
    _viewMonth = DateTime(now.year, now.month);
    _gridStart = _viewingDate;
    _load();
  }

  Future<void> _load() async {
    final repo = PrayerTrackingRepository.instance;
    final day = await repo.dayEntries(_viewingDate);
    final current = await repo.currentStreak();
    final longest = await repo.longestStreak();
    final goal = await repo.dailyGoal();
    final points = await repo.rolling30DayPoints();
    final offset = await repo.hijriOffsetDays();
    final disabled = await repo.isDisabled();

    // Calendar grid: 6 weeks ascending ending at the grid's last cell.
    final first = DateTime(_viewMonth.year, _viewMonth.month);
    final leading = (first.weekday + 1) % 7; // Saturday-first.
    final start = first.subtract(Duration(days: leading));
    final end = start.add(const Duration(days: 41));
    final range = await repo.entriesForRange(42, end: end);
    final grid = range.reversed.toList();

    // Overview: last 30 days ending today.
    final last30 = await repo.entriesForRange(30);
    var performed = 0;
    var onTime = 0;
    for (final d in last30) {
      for (final e in d) {
        if (e == null || !e.countsTowardGoal) continue;
        performed++;
        if (e.status != PrayerStatus.late) onTime++;
      }
    }

    if (!mounted) return;
    setState(() {
      _day = day;
      _current = current;
      _longest = longest;
      _goal = goal;
      _points30 = points;
      _level = PointsEngine.levelForPoints(points);
      _progress = PointsEngine.progressToNextLevel(points);
      _hijriOffset = offset;
      _disabled = disabled;
      _grid = grid;
      _gridStart = start;
      _totalPerformed = performed;
      _onTimeRate = performed == 0 ? 0.0 : onTime / performed;
      _loading = false;
    });
  }

  bool get _viewingFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _viewingDate.isAfter(today);
  }

  /// Opens the "how did you pray" picker (Milestone 3). Future days and
  /// paused tracking are viewable but not loggable.
  Future<void> _openLogSheet(int prayer, String prayerName) async {
    if (_viewingFuture || _disabled) return;
    final changed = await showLogPrayerSheet(
      context: context,
      date: _viewingDate,
      prayerIndex: prayer,
      prayerName: prayerName,
    );
    if (changed) await _load();
  }

  void _shiftDay(int delta) {
    setState(() {
      _viewingDate = _viewingDate.add(Duration(days: delta));
      _viewMonth = DateTime(_viewingDate.year, _viewingDate.month);
    });
    _load();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta, 1);
    });
    _load();
  }

  // ---------- paused banner ----------

  Widget _pausedBanner(AppLocalizations loc, Color card, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          FilledButton.tonal(
            key: const ValueKey('pt_resume_btn'),
            onPressed: () async {
              final repo = PrayerTrackingRepository.instance;
              await repo.setDisabled(false);
              await PrayerReminderService.instance.refreshFromCache();
              await _load();
            },
            child: Text(loc.ptResume),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(loc.ptPausedTitle,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold)),
                Text(loc.ptPausedHint,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF14141C) : const Color(0xFFF7F7FA);
    final card = isDark ? const Color(0xFF20202B) : Colors.white;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
        elevation: 0,
        title: Text(loc.ptTrackerTitle,
            style: TextStyle(
              fontFamily: 'Amiri',
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_disabled) _pausedBanner(loc, card, isDark),
                  if (_disabled) const SizedBox(height: 12),
                  _levelPill(loc, card, isDark),
                  const SizedBox(height: 12),
                  _gemStrip(card, isDark),
                  const SizedBox(height: 12),
                  _dayCard(loc, card, isDark),
                  const SizedBox(height: 12),
                  _goalCard(loc, card, isDark),
                  const SizedBox(height: 12),
                  _calendarCard(loc, card, isDark),
                  const SizedBox(height: 12),
                  _overviewCard(loc, card, isDark),
                ],
              ),
            ),
    );
  }

  // ---------- header: level pill + gems ----------

  Widget _levelPill(AppLocalizations loc, Color card, bool isDark) {
    return GestureDetector(
      key: const ValueKey('pt_level_pill'),
      onTap: () async {
        final changed = await showTrackingDetailsSheet(context);
        if (changed) await _load();
      },
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: _cardDeco(isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.ptLevelTitle(_level),
                    style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.black12,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _gemStrip(Color card, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: _cardDeco(isDark),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(PointsEngine.maxLevel, (i) {
          final unlocked = _level >= i + 1;
          final threshold = PointsEngine.thresholdForLevel(i + 1);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? _accent.withValues(alpha: 0.25)
                      : (isDark ? Colors.white10 : Colors.black12),
                ),
                child: Icon(
                  unlocked ? Icons.diamond_rounded : Icons.lock_rounded,
                  size: 18,
                  color: unlocked
                      ? _accent
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
              const SizedBox(height: 4),
              Text('$threshold',
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54)),
            ],
          );
        }),
      ),
    );
  }

  // ---------- day card ----------

  List<String> _prayerNames(AppLocalizations loc) => [
        loc.nsPrayerFajr,
        loc.nsPrayerDhuhr,
        loc.nsPrayerAsr,
        loc.nsPrayerMaghrib,
        loc.nsPrayerIsha,
      ];

  Widget _dayCard(AppLocalizations loc, Color card, bool isDark) {
    final names = _prayerNames(loc);
    final label = _dayLabel(loc);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => _shiftDay(1),
              ),
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: () => _shiftDay(-1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final e = _day[i];
              final logged = e != null;
              final missed = e?.status == PrayerStatus.missed;
              return GestureDetector(
                key: ValueKey('pt_circle_$i'),
                onTap: (_viewingFuture || _disabled)
                    ? null
                    : () => _openLogSheet(i, names[i]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !logged
                            ? Colors.transparent
                            : missed
                                ? Colors.red.withValues(alpha: 0.2)
                                : _accent.withValues(alpha: 0.25),
                        border: Border.all(
                          color: !logged
                              ? (isDark ? Colors.white38 : Colors.black38)
                              : missed
                                  ? Colors.red
                                  : _accent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        !logged
                            ? null
                            : missed
                                ? Icons.close_rounded
                                : Icons.check_rounded,
                        color: missed ? Colors.red : _accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(names[i],
                        style: const TextStyle(
                            fontFamily: 'Amiri', fontSize: 13)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _dayLabel(AppLocalizations loc) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = _viewingDate.difference(today).inDays;
    if (diff == 0) return loc.trackToday;
    return DateFormat('d MMMM', Localizations.localeOf(context).languageCode)
        .format(_viewingDate);
  }

  // ---------- goal card ----------

  Widget _goalCard(AppLocalizations loc, Color card, bool isDark) {
    var done = 0;
    for (final e in _day) {
      if (e != null && e.countsTowardGoal) done++;
    }
    final sub = isDark ? Colors.white54 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton.tonal(
                onPressed: () => Get.to(() => const SettingsScreen()),
                child: Text(loc.ptEdit),
              ),
              Text(loc.ptDailyGoal,
                  style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stat(
                  '🔥',
                  loc.trackDays(_current),
                  loc.trackCurrent,
                  sub,
                ),
              ),
              Expanded(
                child: _stat(
                  '🏅',
                  loc.trackDays(_longest),
                  loc.trackLongest,
                  sub,
                ),
              ),
              Expanded(
                child: _stat(
                  done >= _goal ? '✓' : '$done/$_goal',
                  loc.ptGoalToday,
                  null,
                  sub,
                  highlight: done >= _goal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String title, String? subtitle, Color sub,
      {bool highlight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: highlight ? _accent : null)),
        const SizedBox(height: 4),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 13)),
        if (subtitle != null)
          Text(subtitle, style: TextStyle(fontSize: 11, color: sub)),
      ],
    );
  }

  // ---------- calendar ----------

  List<String> _weekdayLetters(String code) {
    if (code == 'ar') return const ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    // Narrow-ish initials starting from a known Saturday (2026-09-05).
    final sat = DateTime(2026, 9, 5);
    return List.generate(
        7,
        (i) => DateFormat('E', code)
            .format(sat.add(Duration(days: i)))
            .characters
            .first);
  }

  String _hijriMonthLabel(String code) {
    try {
      HijriCalendar.setLocal(code == 'ar' ? 'ar' : 'en');
    } catch (_) {
      // Fall back to whatever locale the package already has.
    }
    final first = DateTime(_viewMonth.year, _viewMonth.month)
        .add(Duration(days: _hijriOffset));
    final h = HijriCalendar.fromDate(first);
    return '${h.longMonthName} ${h.hYear}';
  }

  Widget _calendarCard(AppLocalizations loc, Color card, bool isDark) {
    final code = Localizations.localeOf(context).languageCode;
    final greg = DateFormat('MMMM yyyy', code).format(_viewMonth);
    final hijri = _hijriMonthLabel(code);
    final letters = _weekdayLetters(code);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sub = isDark ? Colors.white54 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => _shiftMonth(1),
              ),
              Column(
                children: [
                  Text(greg,
                      style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text(hijri,
                      style: TextStyle(
                          fontFamily: 'Amiri', fontSize: 13, color: sub)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: () => _shiftMonth(-1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: letters
                .map((w) => Expanded(
                      child: Center(
                          child: Text(w,
                              style:
                                  TextStyle(color: sub, fontSize: 13))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: 42,
            itemBuilder: (ctx, i) {
              final date = _gridStart.add(Duration(days: i));
              final inMonth = date.month == _viewMonth.month;
              final dayData =
                  _grid.length == 42 ? _grid[i] : const <PrayerLogEntry?>[];
              var performed = 0;
              for (final e in dayData) {
                if (e != null && e.countsTowardGoal) performed++;
              }
              final isFuture = date.isAfter(today);
              final selected = date == _viewingDate;
              final full = performed >= 5;
              final partial = performed > 0 && !full;
              Color? fill;
              Color fg = inMonth
                  ? (isDark ? Colors.white : Colors.black87)
                  : sub;
              if (full && !isFuture) {
                fill = _accent.withValues(alpha: 0.3);
                fg = isDark ? Colors.white : Colors.black87;
              }
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _viewingDate = date;
                    _viewMonth = DateTime(date.year, date.month);
                  });
                  _load();
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: _accent, width: 2)
                        : partial && !isFuture
                            ? Border.all(
                                color: Colors.amber.withValues(alpha: 0.7),
                                width: 1.5)
                            : null,
                  ),
                  child: Center(
                    child: Text('${date.day}',
                        style: TextStyle(
                            color: isFuture ? sub.withValues(alpha: 0.5) : fg,
                            fontWeight:
                                full ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- overview ----------

  Widget _overviewCard(AppLocalizations loc, Color card, bool isDark) {
    final sub = isDark ? Colors.white54 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(isDark),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(loc.ptLast30Days,
                    style: const TextStyle(fontSize: 12)),
              ),
              Text(loc.ptOverview,
                  style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (_totalPerformed == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(loc.ptEmptyTitle,
                      style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(loc.ptEmptyHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: sub, fontSize: 13)),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                    child: _stat('$_totalPerformed', loc.ptTotalPrayers, null,
                        sub)),
                Expanded(
                    child: _stat('${(_onTimeRate * 100).round()}٪',
                        loc.ptOnTimeRate, null, sub)),
                Expanded(
                    child:
                        _stat('$_points30', loc.ptTotalPoints, null, sub)),
              ],
          ),
        ],
      ),
    );
  }
}
