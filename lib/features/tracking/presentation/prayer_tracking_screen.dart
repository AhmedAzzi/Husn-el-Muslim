import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
/// (Amiri, deep-night cards, rose accents): compact single-screen layout
/// with level pill + gem strip, اليوم 5-prayer day card, الهدف اليومي
/// stats and 30-day overview — no scrolling needed.
///
/// Tapping a prayer circle opens the "how did you pray" picker sheet
/// (takbeer/mosque/jamaa/on-time/late/missed with per-option points).
/// Future days are viewable but not loggable. All tracking settings live
/// in the app Settings screen — this page is settings-free.
class PrayerTrackingScreen extends StatefulWidget {
  /// When true, renders only the page content (no Scaffold/AppBar) for
  /// embedding as a tab in [TrackingHomeScreen].
  final bool embedded;

  const PrayerTrackingScreen({super.key, this.embedded = false});

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
  bool _loading = true;

  List<PrayerLogEntry?> _day = const [];
  int _current = 0;
  int _longest = 0;
  int _goal = PrayerTrackingRepository.defaultDailyGoal;
  int _points30 = 0;
  int _level = 1;
  double _progress = 0.0;
  bool _disabled = false;

  /// Last 30 days ending today, for the overview card.
  int _totalPerformed = 0;
  double _onTimeRate = 0.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewingDate = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final repo = PrayerTrackingRepository.instance;
    final day = await repo.dayEntries(_viewingDate);
    final current = await repo.currentStreak();
    final longest = await repo.longestStreak();
    final goal = await repo.dailyGoal();
    final points = await repo.rolling30DayPoints();
    final disabled = await repo.isDisabled();

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
      _disabled = disabled;
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
    });
    _load();
  }

  // ---------- paused banner ----------

  Widget _pausedBanner(AppLocalizations loc, Color card, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
    if (widget.embedded) return _buildBody();
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
      body: _buildBody(),
    );
  }

  /// Page content without Scaffold/AppBar, shared by the standalone screen
  /// and the embedded tab in [TrackingHomeScreen].
  Widget _buildBody() {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF20202B) : Colors.white;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Compact single-screen layout: tight padding/gaps so the whole page
    // fits without scrolling on a regular phone. The ListView stays as the
    // Scrollable for pull-to-refresh (and tests) but has nothing to scroll.
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_disabled) _pausedBanner(loc, card, isDark),
          if (_disabled) const SizedBox(height: 8),
          _levelPill(loc, card, isDark),
          const SizedBox(height: 8),
          _gemStrip(card, isDark),
          const SizedBox(height: 8),
          _dayCard(loc, card, isDark),
          const SizedBox(height: 8),
          _goalCard(loc, card, isDark),
          const SizedBox(height: 8),
          _overviewCard(loc, card, isDark),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 5,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? _accent.withValues(alpha: 0.25)
                      : (isDark ? Colors.white10 : Colors.black12),
                ),
                child: Icon(
                  unlocked ? Icons.diamond_rounded : Icons.lock_rounded,
                  size: 16,
                  color: unlocked
                      ? _accent
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
              const SizedBox(height: 2),
              Text('$threshold',
                  style: TextStyle(
                      fontSize: 9,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                onPressed: () => _shiftDay(1),
              ),
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onPressed: () => _shiftDay(-1),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
                      width: 42,
                      height: 42,
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
                    const SizedBox(height: 4),
                    Text(names[i],
                        style: const TextStyle(
                            fontFamily: 'Amiri', fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
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
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: highlight ? _accent : null)),
        const SizedBox(height: 2),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 12)),
        if (subtitle != null)
          Text(subtitle, style: TextStyle(fontSize: 10, color: sub)),
      ],
    );
  }

  // ---------- overview ----------

  Widget _overviewCard(AppLocalizations loc, Color card, bool isDark) {
    final sub = isDark ? Colors.white54 : Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(loc.ptLast30Days,
                    style: const TextStyle(fontSize: 11)),
              ),
              Text(loc.ptOverview,
                  style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          if (_totalPerformed == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.ptEmptyTitle,
                      style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(loc.ptEmptyHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: sub, fontSize: 12)),
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
