import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/settings/presentation/settings_screen.dart';
import 'package:small_husn_muslim/features/tracking/data/points_engine.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// "التفاصيل" bottom sheet from the design: level progress, المراحل
/// thresholds, السياق (man/woman) toggle, the in-app points table with a
/// meanings dialog, and the prayer points multipliers.
///
/// Returns true when the caller should reload (context changed).
Future<bool> showTrackingDetailsSheet(BuildContext context) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TrackingDetailsSheet(),
  );
  return changed ?? false;
}

class _TrackingDetailsSheet extends StatefulWidget {
  const _TrackingDetailsSheet();

  @override
  State<_TrackingDetailsSheet> createState() => _TrackingDetailsSheetState();
}

class _TrackingDetailsSheetState extends State<_TrackingDetailsSheet> {
  static const _accent = Color(0xFFD64463);

  int _points = 0;
  int _level = 1;
  double _progress = 0.0;
  String _context = PrayerTrackingRepository.contextMan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = PrayerTrackingRepository.instance;
    final points = await repo.rolling30DayPoints();
    final ctx = await repo.context();
    if (!mounted) return;
    setState(() {
      _points = points;
      _level = PointsEngine.levelForPoints(points);
      _progress = PointsEngine.progressToNextLevel(points);
      _context = ctx;
      _loading = false;
    });
  }

  void _close() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final sub = isDark ? Colors.white54 : Colors.black54;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('pt_details_close'),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _close,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(loc.ptDetails,
                          style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      key: const ValueKey('pt_details_list'),
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        _levelCard(loc, isDark, sub),
                        const SizedBox(height: 16),
                        Text(loc.ptHowItWorks,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _stagesCard(loc, isDark, sub),
                        const SizedBox(height: 12),
                        _contextCard(loc, isDark, sub),
                        const SizedBox(height: 12),
                        _pointsCard(loc, isDark, sub),
                        const SizedBox(height: 12),
                        _multipliersCard(loc, isDark, sub),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelCard(AppLocalizations loc, bool isDark, Color sub) {
    final next = PointsEngine.pointsToNextLevel(_points);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond_rounded, size: 44, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.ptLevelTitle(_level),
                    style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ClipRRect(
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
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.ptPointsCount(_points),
                        style: TextStyle(color: sub, fontSize: 12)),
                    if (next != null)
                      Text(loc.ptPointsCount(_points + next),
                          style: TextStyle(color: sub, fontSize: 12)),
                  ],
                ),
                Text(loc.ptBasedOn30,
                    style: TextStyle(color: sub, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stagesCard(AppLocalizations loc, bool isDark, Color sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(loc.ptStages,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          Text(loc.ptStagesHint,
              style: TextStyle(color: sub, fontSize: 13)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: PointsEngine.maxLevel,
            itemBuilder: (ctx, i) {
              final unlocked = _level >= i + 1;
              final threshold =
                  PointsEngine.thresholdForLevel(i + 1);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? _accent.withValues(alpha: 0.25)
                          : (isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Icon(
                      unlocked
                          ? Icons.diamond_rounded
                          : Icons.lock_rounded,
                      size: 20,
                      color: unlocked
                          ? _accent
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$threshold',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? Colors.white70 : Colors.black87)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _contextCard(AppLocalizations loc, bool isDark, Color sub) {
    final isMan = _context == PrayerTrackingRepository.contextMan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(loc.ptContext,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          Text(loc.ptContextHint,
              style: TextStyle(color: sub, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _contextOption(
                  label: loc.ptWoman,
                  emoji: '🧕',
                  selected: !isMan,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _contextOption(
                  label: loc.ptMan,
                  emoji: '👨🏻',
                  selected: isMan,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              key: const ValueKey('pt_ctx_settings'),
              onPressed: () {
                Navigator.of(context).pop(false);
                Get.to(() => const SettingsScreen());
              },
              child: Text(loc.ptMenuSettings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextOption({
    required String label,
    required String emoji,
    required bool selected,
    required bool isDark,
  }) {
    return Container(
      key: ValueKey('pt_ctx_$label'),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? _accent
              : (isDark ? Colors.white12 : Colors.black12),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(label, style: const TextStyle(fontFamily: 'Amiri')),
        ],
      ),
    );
  }

  Widget _pointsCard(AppLocalizations loc, bool isDark, Color sub) {
    final rows = [
      (Icons.auto_awesome_rounded, loc.ptOptTakbeer, 30, Colors.amber),
      (Icons.mosque_rounded, loc.ptOptMosque, 27, Colors.orange),
      (Icons.groups_rounded, loc.ptOptJamaa, 14, Colors.green),
      (Icons.check_circle_rounded, loc.ptOptOnTime, 1, _accent),
      (Icons.history_rounded, loc.ptOptLate, 1, Colors.grey),
      (Icons.cancel_rounded, loc.ptOptMissed, -10, Colors.red),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton.tonal(
                onPressed: () => _showMeanings(loc),
                child: Text(loc.ptOptionMeanings),
              ),
              Text(loc.ptPointsInApp,
                  style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      r.$3 >= 0
                          ? loc.ptPointsNum(r.$3)
                          : loc.ptPointsCount(r.$3),
                      style: TextStyle(
                          color: r.$3 < 0 ? Colors.red : sub,
                          fontSize: 13),
                    ),
                    Expanded(
                      child: Text(r.$2,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontFamily: 'Amiri')),
                    ),
                    const SizedBox(width: 10),
                    Icon(r.$1, color: r.$4),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _showMeanings(AppLocalizations loc) {
    final rows = [
      (Icons.auto_awesome_rounded, loc.ptOptTakbeer, loc.ptMeanTakbeer),
      (Icons.mosque_rounded, loc.ptOptMosque, loc.ptMeanMosque),
      (Icons.groups_rounded, loc.ptOptJamaa, loc.ptMeanJamaa),
      (Icons.check_circle_rounded, loc.ptOptOnTime, loc.ptMeanOnTime),
      (Icons.history_rounded, loc.ptOptLate, loc.ptMeanLate),
      (Icons.cancel_rounded, loc.ptOptMissed, loc.ptMeanMissed),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.ptOptionMeanings,
            style: const TextStyle(fontFamily: 'Amiri')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: rows
                .map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(r.$1, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(r.$2,
                                    style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.bold)),
                                Text(r.$3,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.ctClose),
          ),
        ],
      ),
    );
  }

  Widget _multipliersCard(AppLocalizations loc, bool isDark, Color sub) {
    final dayPrayers =
        '${loc.nsPrayerDhuhr}، ${loc.nsPrayerAsr}، ${loc.nsPrayerMaghrib}';
    final rows = [
      (loc.nsPrayerFajr, '×2', Icons.wb_twilight_rounded),
      (dayPrayers, '×1', Icons.sunny),
      (loc.nsPrayerIsha, '×1,5', Icons.bedtime_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(loc.ptMultipliers,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          Text(loc.ptMultipliersHint,
              style: TextStyle(color: sub, fontSize: 13)),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(r.$2,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(r.$1,
                          textAlign: TextAlign.end,
                          style:
                              const TextStyle(fontFamily: 'Amiri')),
                    ),
                    const SizedBox(width: 10),
                    Icon(r.$3, color: Colors.amber),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
