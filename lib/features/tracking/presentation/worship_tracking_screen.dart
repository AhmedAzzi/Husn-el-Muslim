import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
// Hide intl's bidi TextDirection helper: we only need DateFormat from intl,
// while Flutter's TextDirection drives layout direction.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:small_husn_muslim/features/tracking/data/worship_tracking_repository.dart';
import 'package:small_husn_muslim/features/tracking/data/worship_type.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Worship tracker ("تتبع الصيام والورد"): voluntary fasting (Mon/Thu +
/// White days + Arafah/Ashura + …), the daily wird and extra good deeds.
///
/// Same Husn visual language as the other trackers (Amiri, deep-night
/// cards, rose accents). One tap toggles a deed/fast for the viewed day;
/// future days are viewable but not loggable.
class WorshipTrackingScreen extends StatefulWidget {
  /// When true, renders only the page content (no Scaffold/AppBar) for
  /// embedding as a tab in [TrackingHomeScreen].
  final bool embedded;

  const WorshipTrackingScreen({super.key, this.embedded = false});

  @override
  State<WorshipTrackingScreen> createState() => _WorshipTrackingScreenState();
}

class _WorshipTrackingScreenState extends State<WorshipTrackingScreen> {
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

  List<bool> _day = List<bool>.filled(DeedType.values.length, false);
  FastKind? _viewFast;
  FastKind? _monFast;
  FastKind? _thuFast;
  late DateTime _monDate;
  late DateTime _thuDate;
  List<(bool, bool)> _weeks = const [];

  int _current = 0;
  int _goal = WorshipTrackingRepository.defaultDailyGoal;
  int _points30 = 0;
  int _todayPoints = 0;
  int _fastWeeks = 0;
  int _fastCount30 = 0;
  bool _disabled = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewingDate = DateTime(now.year, now.month, now.day);
    _monDate = _viewingDate;
    _thuDate = _viewingDate;
    _load();
  }

  Future<void> _load() async {
    final repo = WorshipTrackingRepository.instance;
    final day = await repo.dayEntries(_viewingDate);
    final viewFast = await repo.fastOn(_viewingDate);
    final monday = WorshipTrackingRepository.mondayOfWeek(_viewingDate);
    final thursday = monday.add(const Duration(days: 3));
    final monFast = await repo.fastOn(monday);
    final thuFast = await repo.fastOn(thursday);
    final current = await repo.currentStreak();
    final goal = await repo.dailyGoal();
    final points30 = await repo.rolling30DayPoints();
    final todayPoints = await repo.dayPoints(_viewingDate) +
        await repo.fastPointsOn(_viewingDate);
    final fastWeeks = await repo.fastingWeekStreak();
    final fastCount30 = await repo.fastCount30();
    final disabled = await repo.isDisabled();

    // Last 8 weeks (oldest first) for the strip, ending this week.
    final thisMonday =
        WorshipTrackingRepository.mondayOfWeek(DateTime.now());
    final weeks = <(bool, bool)>[];
    for (var i = 7; i >= 0; i--) {
      final mon = thisMonday.subtract(Duration(days: 7 * i));
      final thu = mon.add(const Duration(days: 3));
      weeks.add((
        await repo.fastOn(mon) != null,
        await repo.fastOn(thu) != null,
      ));
    }

    if (!mounted) return;
    setState(() {
      _day = day;
      _viewFast = viewFast;
      _monDate = monday;
      _thuDate = thursday;
      _monFast = monFast;
      _thuFast = thuFast;
      _weeks = weeks;
      _current = current;
      _goal = goal;
      _points30 = points30;
      _todayPoints = todayPoints;
      _fastWeeks = fastWeeks;
      _fastCount30 = fastCount30;
      _disabled = disabled;
      _loading = false;
    });
  }

  bool get _viewingFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _viewingDate.isAfter(today);
  }

  int get _doneCount => _day.where((d) => d).length;

  Future<void> _toggleDeed(DeedType type) async {
    if (_viewingFuture || _disabled) return;
    await WorshipTrackingRepository.instance.toggleDeed(
      date: _viewingDate,
      type: type,
    );
    await _load();
  }

  /// Toggles the Monday/Thursday tile of the viewed week with its
  /// natural kind (clearing any other kind logged there).
  Future<void> _toggleWeekFast(DateTime date, FastKind kind) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today) || _disabled) return;
    final repo = WorshipTrackingRepository.instance;
    final current = await repo.fastOn(date);
    if (current != null) {
      await repo.clearFast(date);
    } else {
      await repo.logFast(date: date, kind: kind);
    }
    await _load();
  }

  Future<void> _openFastSheet() async {
    if (_viewingFuture || _disabled) return;
    final changed = await showFastKindSheet(
      context: context,
      date: _viewingDate,
    );
    if (changed) await _load();
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
          title: Text(loc.wtDailyGoal,
              style: const TextStyle(fontFamily: 'Amiri')),
          content: StatefulBuilder(
            builder: (ctx, setD) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed:
                      value > 1 ? () => setD(() => value--) : null,
                ),
                Text('$value',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: value < DeedType.values.length
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
      await WorshipTrackingRepository.instance.setDailyGoal(value);
      await _load();
    }
  }

  Future<void> _confirmClear(AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _dir(ctx),
        child: AlertDialog(
          title: Text(loc.wtClearTitle,
              style: const TextStyle(fontFamily: 'Amiri')),
          content: Text(loc.wtClearHint),
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
      await WorshipTrackingRepository.instance.clearAll();
      await _load();
    }
  }

  ({String title, String sub, IconData icon}) _deedMeta(
      DeedType t, AppLocalizations loc) {
    switch (t) {
      case DeedType.quranWird:
        return (title: loc.wtQuran, sub: loc.wtQuranSub, icon: Icons.menu_book_rounded);
      case DeedType.morningAdhkar:
        return (title: loc.wtMorning, sub: loc.wtMorningSub, icon: Icons.wb_twilight_rounded);
      case DeedType.eveningAdhkar:
        return (title: loc.wtEvening, sub: loc.wtEveningSub, icon: Icons.nights_stay_rounded);
      case DeedType.istighfar:
        return (title: loc.wtIstighfar, sub: loc.wtIstighfarSub, icon: Icons.refresh_rounded);
      case DeedType.salawat:
        return (title: loc.wtSalawat, sub: loc.wtSalawatSub, icon: Icons.favorite_rounded);
      case DeedType.sadaqah:
        return (title: loc.wtSadaqah, sub: loc.wtSadaqahSub, icon: Icons.volunteer_activism_rounded);
      case DeedType.silatRahim:
        return (title: loc.wtSilah, sub: loc.wtSilahSub, icon: Icons.group_rounded);
      case DeedType.birrParents:
        return (title: loc.wtBirr, sub: loc.wtBirrSub, icon: Icons.home_rounded);
    }
  }

  String _kindName(FastKind k, AppLocalizations loc) {
    switch (k) {
      case FastKind.monday:
        return loc.wtKindMonday;
      case FastKind.thursday:
        return loc.wtKindThursday;
      case FastKind.whiteDays:
        return loc.wtKindWhite;
      case FastKind.arafah:
        return loc.wtKindArafah;
      case FastKind.ashura:
        return loc.wtKindAshura;
      case FastKind.shawwal:
        return loc.wtKindShawwal;
      case FastKind.qadaa:
        return loc.wtKindQadaa;
      case FastKind.nafl:
        return loc.wtKindNafl;
    }
  }

  /// Hijri occasion flags for the viewed date (best-effort hint only).
  ({bool white, bool arafah, bool ashura}) _hijriFlags(DateTime date) {
    try {
      final h = HijriCalendar.fromDate(date);
      return (
        white: h.hDay == 13 || h.hDay == 14 || h.hDay == 15,
        arafah: h.hMonth == 12 && h.hDay == 9,
        ashura: h.hMonth == 1 && (h.hDay == 9 || h.hDay == 10),
      );
    } catch (_) {
      return (white: false, arafah: false, ashura: false);
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
        title: Text(loc.wtTitle,
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
            tooltip: loc.wtClear,
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
          _fastingCard(loc, isDark),
          const SizedBox(height: 8),
          _sectionCard(loc, isDark, loc.wtWirdSection, wirdTypes),
          const SizedBox(height: 8),
          _sectionCard(loc, isDark, loc.wtDeedsSection, extraDeedTypes),
          const SizedBox(height: 8),
          _weeksCard(loc, isDark),
        ],
      ),
    );
  }

  Widget _headerCard(AppLocalizations loc, bool isDark) {
    final sub = isDark ? Colors.white54 : Colors.black54;
    final done = _doneCount;
    final progress = _goal == 0 ? 0.0 : (done / _goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(loc.wtSubtitle,
              style: TextStyle(color: sub, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                onPressed: () => _shiftDay(1),
              ),
              Text(_dayLabel(loc),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${loc.wtDailyGoal}: ${loc.snProgress(done, _goal)}',
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _stat('🔥', loc.trackDays(_current),
                      loc.trackCurrent, sub)),
              Expanded(
                  child: _stat('🌙', '$_fastWeeks', loc.wtWeeksStreak, sub)),
              Expanded(
                  child: _stat('$_points30', loc.wtTotal30, null, sub)),
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
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
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

  String _occasionHint(AppLocalizations loc) {
    final flags = _hijriFlags(_viewingDate);
    if (flags.arafah) return loc.wtArafahHint;
    if (flags.ashura) return loc.wtAshuraHint;
    if (flags.white) return loc.wtWhiteHint;
    if (_viewingDate.weekday == DateTime.monday) return loc.wtMondayHint;
    if (_viewingDate.weekday == DateTime.thursday) {
      return loc.wtThursdayHint;
    }
    return '';
  }

  Widget _fastingCard(AppLocalizations loc, bool isDark) {
    final sub = isDark ? Colors.white54 : Colors.black54;
    final code = Localizations.localeOf(context).languageCode;
    final hint = _occasionHint(loc);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.wtFastingSection,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text(loc.wtWeekHint, style: TextStyle(color: sub, fontSize: 12)),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(hint,
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.green, size: 16),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _fastTile(
                  loc: loc,
                  isDark: isDark,
                  code: code,
                  date: _monDate,
                  label: loc.wtMonday,
                  fast: _monFast,
                  kind: FastKind.monday,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _fastTile(
                  loc: loc,
                  isDark: isDark,
                  code: code,
                  date: _thuDate,
                  label: loc.wtThursday,
                  fast: _thuFast,
                  kind: FastKind.thursday,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed:
                  (_viewingFuture || _disabled) ? null : _openFastSheet,
              child: Text(_viewFast == null
                  ? loc.wtLogOtherFast
                  : '${loc.wtLogOtherFast} • ${_kindName(_viewFast!, loc)} ✓'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fastTile({
    required AppLocalizations loc,
    required bool isDark,
    required String code,
    required DateTime date,
    required String label,
    required FastKind? fast,
    required FastKind kind,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = date.isAfter(today);
    final done = fast != null;
    final tappable = !isFuture && !_disabled;
    final dateLabel = DateFormat('d MMMM', code).format(date);
    return GestureDetector(
      key: ValueKey('wt_fast_${kind.name}'),
      onTap: tappable ? () => _toggleWeekFast(date, kind) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: done ? _accent.withValues(alpha: 0.12) : null,
          border: Border.all(
            color: done
                ? _accent
                : (isDark ? Colors.white12 : Colors.black12),
            width: done ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isFuture
                  ? Colors.grey
                  : (done ? _accent : Colors.grey),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            Text(dateLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54)),
            Text('+${fastPoints[kind] ?? 0}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _accent)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(AppLocalizations loc, bool isDark, String title,
      List<DeedType> types) {
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
          ...types.map((t) => _deedRow(loc, isDark, t)),
        ],
      ),
    );
  }

  Widget _deedRow(AppLocalizations loc, bool isDark, DeedType t) {
    final meta = _deedMeta(t, loc);
    final done = _day[t.index];
    final points = deedPoints[t] ?? 0;
    final tappable = !_viewingFuture && !_disabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        key: ValueKey('wt_row_${t.name}'),
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: done
                ? _accent
                : (isDark ? Colors.white12 : Colors.black12),
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
                color: done
                    ? _accent
                    : (isDark ? Colors.white38 : Colors.black38),
                width: 2),
          ),
          child: done
              ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 15)
              : null,
        ),
        title: Text(meta.title,
            textAlign: TextAlign.start,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 14)),
        subtitle: Text('${meta.sub} • +$points',
            textAlign: TextAlign.start,
            style: const TextStyle(fontSize: 11)),
        trailing:
            Icon(meta.icon, color: done ? _accent : Colors.grey, size: 20),
        onTap: tappable ? () => _toggleDeed(t) : null,
      ),
    );
  }

  Widget _weeksCard(AppLocalizations loc, bool isDark) {
    final sub = isDark ? Colors.white54 : Colors.black54;
    final empty = _weeks.isEmpty ||
        _weeks.every((w) => !w.$1 && !w.$2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDeco(isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.wtWeeksOverview,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('${loc.wtWeeksStreak}: $_fastWeeks • '
              '${loc.wtTotalFasts}: $_fastCount30',
              style: TextStyle(color: sub, fontSize: 12)),
          const SizedBox(height: 8),
          if (empty)
            Text(loc.snEmptyHint,
                textAlign: TextAlign.start,
                style: TextStyle(color: sub, fontSize: 12))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(8, (i) {
                final w = _weeks[i];
                final full = w.$1 && w.$2;
                return Container(
                  width: 28,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: full
                        ? _accent.withValues(alpha: 0.3)
                        : (isDark ? Colors.white10 : Colors.black12),
                    border: (w.$1 || w.$2) && !full
                        ? Border.all(
                            color:
                                Colors.amber.withValues(alpha: 0.7),
                            width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 9,
                          color: w.$1
                              ? _accent
                              : (isDark
                                  ? Colors.white24
                                  : Colors.black26)),
                      const SizedBox(height: 3),
                      Icon(Icons.circle,
                          size: 9,
                          color: w.$2
                              ? _accent
                              : (isDark
                                  ? Colors.white24
                                  : Colors.black26)),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

/// "What kind of fast?" bottom sheet for the viewed day.
///
/// Highlights the logged kind (if any) and offers clearing it.
/// Returns true when the caller should reload.
Future<bool> showFastKindSheet({
  required BuildContext context,
  required DateTime date,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FastKindSheet(date: date),
  );
  return changed ?? false;
}

class _FastKindSheet extends StatefulWidget {
  final DateTime date;

  const _FastKindSheet({required this.date});

  @override
  State<_FastKindSheet> createState() => _FastKindSheetState();
}

class _FastKindSheetState extends State<_FastKindSheet> {
  FastKind? _current;
  bool _loading = true;

  static const _icons = {
    FastKind.monday: Icons.today_rounded,
    FastKind.thursday: Icons.date_range_rounded,
    FastKind.whiteDays: Icons.brightness_2_rounded,
    FastKind.arafah: Icons.landscape_rounded,
    FastKind.ashura: Icons.water_drop_rounded,
    FastKind.shawwal: Icons.local_florist_rounded,
    FastKind.qadaa: Icons.history_rounded,
    FastKind.nafl: Icons.volunteer_activism_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current =
        await WorshipTrackingRepository.instance.fastOn(widget.date);
    if (!mounted) return;
    setState(() {
      _current = current;
      _loading = false;
    });
  }

  String _name(FastKind k, AppLocalizations loc) {
    switch (k) {
      case FastKind.monday:
        return loc.wtKindMonday;
      case FastKind.thursday:
        return loc.wtKindThursday;
      case FastKind.whiteDays:
        return loc.wtKindWhite;
      case FastKind.arafah:
        return loc.wtKindArafah;
      case FastKind.ashura:
        return loc.wtKindAshura;
      case FastKind.shawwal:
        return loc.wtKindShawwal;
      case FastKind.qadaa:
        return loc.wtKindQadaa;
      case FastKind.nafl:
        return loc.wtKindNafl;
    }
  }

  Future<void> _pick(FastKind kind) async {
    await WorshipTrackingRepository.instance.logFast(
      date: widget.date,
      kind: kind,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _clear() async {
    await WorshipTrackingRepository.instance.clearFast(widget.date);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final dir = Localizations.localeOf(context).languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;
    return Directionality(
      textDirection: dir,
      child: Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(loc.wtFastSheetTitle,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              )
            else
              ...FastKind.values.map((k) {
                final selected = _current == k;
                final points = fastPoints[k] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    key: ValueKey('wt_kind_${k.name}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFFD64463)
                            : (isDark
                                ? Colors.white12
                                : Colors.black12),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    tileColor: selected
                        ? const Color(0xFFD64463)
                            .withValues(alpha: 0.12)
                        : null,
                    leading: Icon(_icons[k],
                        color: selected
                            ? const Color(0xFFD64463)
                            : Colors.grey),
                    title: Text(_name(k, loc),
                        textAlign: TextAlign.start,
                        style:
                            const TextStyle(fontFamily: 'Amiri')),
                    trailing: Text(
                      loc.ptPointsNum(points),
                      style: const TextStyle(
                          color: Color(0xFFD64463),
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _pick(k),
                  ),
                );
              }),
            if (!_loading && _current != null)
              TextButton.icon(
                key: const ValueKey('wt_kind_clear'),
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                label: Text(loc.ptClearEntry,
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
