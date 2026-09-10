import 'package:flutter/material.dart';
import 'package:small_husn_muslim/features/tracking/data/points_engine.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_log_entry.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// "How did you pray?" bottom sheet ("اختر كيف صليت" from the design).
///
/// Shows every logging option with its effective points for this prayer
/// (base × prayer multiplier), highlights the current selection, and offers
/// clearing the entry. Returns true when the caller should reload.
///
/// Woman context: the mosque option is hidden (rulings differ); congregation
/// at home (جماعة) stays available.
Future<bool> showLogPrayerSheet({
  required BuildContext context,
  required DateTime date,
  required int prayerIndex,
  required String prayerName,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LogPrayerSheet(
      date: date,
      prayerIndex: prayerIndex,
      prayerName: prayerName,
    ),
  );
  return changed ?? false;
}

class _LogPrayerSheet extends StatefulWidget {
  final DateTime date;
  final int prayerIndex;
  final String prayerName;

  const _LogPrayerSheet({
    required this.date,
    required this.prayerIndex,
    required this.prayerName,
  });

  @override
  State<_LogPrayerSheet> createState() => _LogPrayerSheetState();
}

class _Option {
  final PrayerStatus status;
  final IconData icon;
  final String Function(AppLocalizations loc) label;
  final Color color;

  const _Option(this.status, this.icon, this.label, this.color);
}

final _options = [
  _Option(PrayerStatus.takbeer, Icons.auto_awesome_rounded,
      (loc) => loc.ptOptTakbeer, Colors.amber),
  _Option(PrayerStatus.mosque, Icons.mosque_rounded,
      (loc) => loc.ptOptMosque, Colors.orange),
  _Option(PrayerStatus.jamaa, Icons.groups_rounded,
      (loc) => loc.ptOptJamaa, Colors.green),
  _Option(PrayerStatus.onTimeAlone, Icons.check_circle_rounded,
      (loc) => loc.ptOptOnTime, Color(0xFFD64463)),
  _Option(PrayerStatus.late, Icons.history_rounded,
      (loc) => loc.ptOptLate, Colors.grey),
  _Option(PrayerStatus.missed, Icons.cancel_rounded,
      (loc) => loc.ptOptMissed, Colors.red),
];

class _LogPrayerSheetState extends State<_LogPrayerSheet> {
  PrayerStatus? _current;
  String _context = PrayerTrackingRepository.contextMan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = PrayerTrackingRepository.instance;
    final day = await repo.dayEntries(widget.date);
    final ctx = await repo.context();
    if (!mounted) return;
    setState(() {
      _current = day[widget.prayerIndex]?.status;
      _context = ctx;
      _loading = false;
    });
  }

  int _pointsFor(PrayerStatus status) => PointsEngine.entryPoints(
        PrayerLogEntry(
          date: '',
          prayerIndex: widget.prayerIndex,
          status: status,
          updatedAt: 0,
        ),
      );

  Future<void> _pick(PrayerStatus status) async {
    await PrayerTrackingRepository.instance.logPrayer(
      date: widget.date,
      prayerIndex: widget.prayerIndex,
      status: status,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _clear() async {
    await PrayerTrackingRepository.instance.clearPrayer(
      date: widget.date,
      prayerIndex: widget.prayerIndex,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final visible = _context == PrayerTrackingRepository.contextWoman
        ? _options.where((o) => o.status != PrayerStatus.mosque)
        : _options;
    return Container(
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
            Text('${widget.prayerName} • ${loc.ptHowPrayed}',
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
              ...visible.map((o) {
                final selected = _current == o.status;
                final points = _pointsFor(o.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    key: ValueKey('pt_opt_${o.status.name}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: selected
                            ? o.color
                            : (isDark ? Colors.white12 : Colors.black12),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    tileColor: selected
                        ? o.color.withValues(alpha: 0.12)
                        : null,
                    leading: Icon(o.icon, color: o.color),
                    title: Text(o.label(loc),
                        style: const TextStyle(fontFamily: 'Amiri')),
                    trailing: Text(
                      points < 0
                          ? loc.ptPointsCount(points)
                          : loc.ptPointsNum(points),
                      style: TextStyle(
                          color: points < 0 ? Colors.red : o.color,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _pick(o.status),
                  ),
                );
              }),
            if (!_loading && _current != null)
              TextButton.icon(
                key: const ValueKey('pt_opt_clear'),
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                label: Text(loc.ptClearEntry,
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
