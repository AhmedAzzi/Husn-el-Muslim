import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Hide intl's bidi TextDirection helper: we only need DateFormat from intl,
// while Flutter's TextDirection drives layout direction.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:small_husn_muslim/features/tracking/data/sunnah_tracking_repository.dart';
import 'package:small_husn_muslim/features/tracking/data/sunnah_type.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Sunnah tracker ("تتبع السنن"): Rawatib (12 rak'a) + Duha + Witr + Qiyam.
///
/// Same Husn visual language as the 5-prayer tracker (Amiri, deep-night
/// cards, rose accents). One tap toggles a Sunnah for the viewed day;
/// future days are viewable but not loggable. Streak = days meeting the
/// daily goal; points = per-Sunnah table + full-Rawatib bonus.
class SunnahTrackingScreen extends StatefulWidget {
  /// When true, renders only the page content (no Scaffold/AppBar) for
  /// embedding as a tab in [TrackingHomeScreen].
  final bool embedded;

  const SunnahTrackingScreen({super.key, this.embedded = false});

  @override
  State<SunnahTrackingScreen> createState() => _SunnahTrackingScreenState();
}

class _SunnahTrackingScreenState extends State<SunnahTrackingScreen> {
  static const _accent = Color(0xFFD64463);

  /// Follows the app's current locale (Arabic → RTL, others → LTR) instead
  /// of hardcoding a direction, so rows, icons, progress and text alignment
  /// mirror automatically when the language changes.
  TextDirection _dir(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }

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
  List<bool> _day = List<bool>.filled(SunnahType.values.length, false);
  int _current = 0;
  int _longest = 0;
  int _goal = SunnahTrackingRepository.defaultDailyGoal;
  int _points30 = 0;
  int _todayPoints = 0;
  bool _rawatibDone = false;
  bool _disabled = false;
  List<int> _week = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewingDate = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final repo = SunnahTrackingRepository.instance;
    final day = await repo.dayEntries(_viewingDate);
    final current = await repo.currentStreak();
    final longest = await repo.longestStreak();
    final goal = await repo.dailyGoal();
    final points30 = await repo.rolling30DayPoints();
    final todayPoints = await repo.dayPoints(_viewingDate);
    final rawatibDone = await repo.rawatibComplete(_viewingDate);
    final disabled = await repo.isDisabled();
    final week = await repo.countsForRange(7);
    if (!mounted) return;
    setState(() {
      _day = day;
      _current = current;
      _longest = longest;
      _goal = goal;
      _points30 = points30;
      _todayPoints = todayPoints;
      _rawatibDone = rawatibDone;
      _disabled = disabled;
      _week = week;
      _loading = false;
    });
  }

  bool get _viewingFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _viewingDate.isAfter(today);
  }

  int get _doneCount => _day.where((d) => d).length;

  Future<void> _toggle(SunnahType type) async {
    if (_viewingFuture || _disabled) return;
    await SunnahTrackingRepository.instance.toggleSunnah(
      date: _viewingDate,
      type: type,
    );
    await _load();
  }

  void _shiftDay(int delta) {
    setState(() {
      _viewingDate = _viewingDate.add(Duration(days: delta));
    });
    _load();
  }

  Future<void> _editGoal(AppLocalizations loc) async {
    var value = _goal;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _dir(ctx),
        child: AlertDialog(
          title: Text(loc.snDailyGoal,
              style: const TextStyle(fontFamily: 'Amiri')),
          content: StatefulBuilder(
            builder: (ctx, setD) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: value > 1 ? () => setD(() => value--) : null,
                ),
                Text('$value',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: value < SunnahType.values.length
                      ? () => setD(() => value++)
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.ctCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.ptSave),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await SunnahTrackingRepository.instance.setDailyGoal(value);
      await _load();
    }
  }

  Future<void> _confirmClear(AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _dir(ctx),
        child: AlertDialog(
          title: Text(loc.snClearTitle,
              style: const TextStyle(fontFamily: 'Amiri')),
          content: Text(loc.snClearHint),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.ctCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.ptDelete),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await SunnahTrackingRepository.instance.clearAll();
      await _load();
    }
  }

  ({String title, String sub, IconData icon}) _meta(
      SunnahType t, AppLocalizations loc) {
    switch (t) {
      case SunnahType.fajrSunnah:
        return (
          title: loc.snFajrSunnah,
          sub: loc.snFajrSunnahSub,
          icon: Icons.wb_twilight_rounded
        );
      case SunnahType.dhuhrBefore:
        return (
          title: loc.snDhuhrBefore,
          sub: loc.snDhuhrBeforeSub,
          icon: Icons.wb_sunny_outlined
        );
      case SunnahType.dhuhrAfter:
        return (
          title: loc.snDhuhrAfter,
          sub: loc.snDhuhrAfterSub,
          icon: Icons.sunny
        );
      case SunnahType.maghribAfter:
        return (
          title: loc.snMaghribAfter,
          sub: loc.snMaghribAfterSub,
          icon: Icons.brightness_6_rounded
        );
      case SunnahType.ishaAfter:
        return (
          title: loc.snIshaAfter,
          sub: loc.snIshaAfterSub,
          icon: Icons.bedtime_rounded
        );
      case SunnahType.duha:
        return (
          title: loc.snDuha,
          sub: loc.snDuhaSub,
          icon: Icons.light_mode_rounded
        );
      case SunnahType.witr:
        return (
          title: loc.snWitr,
          sub: loc.snWitrSub,
          icon: Icons.star_rounded
        );
      case SunnahType.qiyam:
        return (
          title: loc.snQiyam,
          sub: loc.snQiyamSub,
          icon: Icons.nightlight_rounded
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF14141C) : const Color(0xFFF7F7FA);
    // Follow the app locale (Arabic → RTL, others → LTR) so the layout
    // mirrors automatically instead of being hardcoded.
    final dir = _dir(context);
    if (widget.embedded) {
      return Directionality(
        textDirection: dir,
        child: _buildBody(),
      );
    }
    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
          elevation: 0,
          title: Text(loc.snTitle,
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
          actions: [
            IconButton(
              tooltip: loc.snClear,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmClear(loc),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  /// Page content without Scaffold/AppBar, shared by the standalone screen
  /// and the embedded tab in [TrackingHomeScreen].
  Widget _buildBody() {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Compact single-screen layout: tight padding/gaps so the whole page
    // fits without scrolling on a regular phone. The ListView stays as the
    // Scrollable for pull-to-refresh but has nothing to scroll.
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _headerCard(loc, isDark),
          const SizedBox(height: 8),
          _sectionCard(loc, isDark, loc.snRawatibSection, rawatibTypes),
          const SizedBox(height: 8),
          _sectionCard(loc, isDark, loc.snExtraSection, extraSunnahTypes),
          const SizedBox(height: 8),
          _weekCard(loc, isDark),
        ],
      ),
    );
  }

  Widget _headerCard(AppLocalizations loc, bool isDark) {
    final sub = isDark ? Colors.white54 : Colors.black54;
    final label = _dayLabel(loc);
    final done = _doneCount;
    final progress = _goal == 0 ? 0.0 : (done / _goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(loc.snSubtitle, style: TextStyle(color: sub, fontSize: 12)),
          const SizedBox(height: 4),
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
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _editGoal(loc),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${loc.snDailyGoal}: ${loc.snProgress(done, _goal)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Text(loc.ptPointsNum(_todayPoints),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: _accent)),
            ],
          ),
          if (_rawatibDone) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded,
                    color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text(loc.snRawatibBonus,
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _stat(
                      '🔥', loc.trackDays(_current), loc.trackCurrent, sub)),
              Expanded(
                  child: _stat(
                      '🏅', loc.trackDays(_longest), loc.trackLongest, sub)),
              Expanded(child: _stat('$_points30', loc.snTotal30, null, sub)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String title, String? subtitle, Color sub) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 11)),
        if (subtitle != null)
          Text(subtitle, style: TextStyle(fontSize: 10, color: sub)),
      ],
    );
  }

  String _dayLabel(AppLocalizations loc) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_viewingDate == today) return loc.trackToday;
    return DateFormat('d MMMM', Localizations.localeOf(context).languageCode)
        .format(_viewingDate);
  }

  Widget _sectionCard(
      AppLocalizations loc, bool isDark, String title, List<SunnahType> types) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...types.map((t) => _row(loc, isDark, t)),
        ],
      ),
    );
  }

  Widget _row(AppLocalizations loc, bool isDark, SunnahType t) {
    final meta = _meta(t, loc);
    final done = _day[t.index];
    final points = sunnahPoints[t] ?? 0;
    final tappable = !_viewingFuture && !_disabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        key: ValueKey('sn_row_${t.name}'),
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: done ? _accent : (isDark ? Colors.white12 : Colors.black12),
            width: done ? 2 : 1,
          ),
        ),
        tileColor: done ? _accent.withValues(alpha: 0.1) : null,
        leading: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? _accent : Colors.transparent,
            border: Border.all(
                color:
                    done ? _accent : (isDark ? Colors.white38 : Colors.black38),
                width: 2),
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
              : null,
        ),
        title: Text(meta.title,
            textAlign: TextAlign.start,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 14)),
        subtitle: Text('${meta.sub} • +$points',
            textAlign: TextAlign.start, style: const TextStyle(fontSize: 11)),
        trailing:
            Icon(meta.icon, color: done ? _accent : Colors.grey, size: 20),
        onTap: tappable ? () => _toggle(t) : null,
      ),
    );
  }

  Widget _weekCard(AppLocalizations loc, bool isDark) {
    final sub = isDark ? Colors.white54 : Colors.black54;
    final code = Localizations.localeOf(context).languageCode;
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final empty = _week.isEmpty || _week.every((c) => c == 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.snWeekOverview,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (empty)
            Text(loc.snEmptyHint,
                textAlign: TextAlign.start,
                style: TextStyle(color: sub, fontSize: 12))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                // _week is newest-first; display oldest-first.
                final idx = 6 - i;
                final count = idx < _week.length ? _week[idx] : 0;
                final date = base.subtract(Duration(days: idx));
                final dayLetter =
                    DateFormat('E', code).format(date).characters.first;
                final full = count >= _goal && _goal > 0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: full
                            ? _accent.withValues(alpha: 0.3)
                            : (isDark ? Colors.white10 : Colors.black12),
                        border: count > 0 && !full
                            ? Border.all(
                                color: Colors.amber.withValues(alpha: 0.7),
                                width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text('$count',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(dayLetter, style: TextStyle(color: sub, fontSize: 11)),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }
}
