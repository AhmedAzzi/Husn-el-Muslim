import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/services/battery_optimization_helper.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';
import 'package:small_husn_muslim/features/tracking/data/fajr_tracking_repository.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';
import 'package:small_husn_muslim/core/utils/l10n_ext.dart';

/// Advanced diagnostics for the alarm engine (bake-in / support screen).
///
/// Everything shown is live data, never canned text:
/// - exact-alarm / battery / overlay permission states (native, real)
/// - armed AlarmManager alarms (`AlarmScheduler.diagnostics()` via native)
/// - Fajr streak truth (legacy tracking repository)
/// - 5-prayer tracker snapshot (streaks, level inputs, flags, reminder cache)
/// - a real 5-second test of the Fajr challenge alarm path
///
/// Follows the existing settings design language (cards, Amiri, RTL).
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _loading = true;
  bool? _canExact;
  bool? _batteryOptimized;
  bool? _overlayGranted;
  bool? _dndGranted;
  String _diag = '…';
  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<String, Object> _five = const {};
  bool _rescheduling = false;
  bool _testingAlarm = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PrayerNotificationHelper.canScheduleExactAlarms(),
        BatteryOptimizationHelper.isBatteryOptimizationEnabled(),
        PrayerNotificationHelper.checkOverlayPermission(),
        PrayerNotificationHelper.getAlarmDiagnostics(),
        FajrTrackingRepository.instance.currentStreak(),
        FajrTrackingRepository.instance.longestStreak(),
        PrayerNotificationHelper.isDndAccessGranted(),
        PrayerTrackingRepository.instance.diagnosticsSnapshot(),
      ]);
      if (!mounted) return;
      setState(() {
        _canExact = results[0] as bool;
        _batteryOptimized = results[1] as bool;
        _overlayGranted = results[2] as bool;
        _diag = results[3] as String;
        _currentStreak = results[4] as int;
        _longestStreak = results[5] as int;
        _dndGranted = results[6] as bool;
        _five = results[7] as Map<String, Object>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _diag = context.loc.diagReadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _rescheduleAll() async {
    setState(() => _rescheduling = true);
    final ok = await PrayerNotificationHelper.rescheduleAllAlarms();
    if (!mounted) return;
    setState(() => _rescheduling = false);
    final loc = context.loc;
    _snack(ok ? loc.diagRescheduled : loc.diagRescheduleFailed);
    await _refresh();
  }

  Future<void> _testAlarm() async {
    setState(() => _testingAlarm = true);
    final ok =
        await PrayerNotificationHelper.testFajrChallengeAlarm(delaySeconds: 5);
    if (!mounted) return;
    setState(() => _testingAlarm = false);
    final loc = context.loc;
    _snack(ok ? loc.diagTestWillRing : loc.diagTestFailed);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 15)),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF14141C) : const Color(0xFFF7F7FA),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1A1A24) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Get.back(),
            ),
            title: Text(
              loc.diagTitle,
              style: TextStyle(
                fontFamily: 'Amiri',
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsWidgets.buildSectionHeader(
                          context: context,
                          title: loc.diagPermissions,
                          icon: Icons.verified_user_outlined,
                          color: const Color(0xFF10B981),
                        ),
                        SettingsWidgets.buildCardContainer(
                          context: context,
                          children: [
                            _permTile(
                              context,
                              title: loc.diagExactTitle,
                              subtitle: _canExact == true
                                  ? loc.diagExactOk
                                  : loc.diagExactDenied,
                              icon: Icons.alarm_on_rounded,
                              ok: _canExact == true,
                              actionLabel: loc.diagOpenSettings,
                              onAction: () async {
                                await PrayerNotificationHelper
                                    .openExactAlarmSettings();
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                await _refresh();
                              },
                            ),
                            SettingsWidgets.buildDivider(context),
                            _permTile(
                              context,
                              title: loc.diagBatteryTitle,
                              subtitle: _batteryOptimized == true
                                  ? loc.diagBatteryOn
                                  : loc.diagBatteryOff,
                              icon: Icons.battery_saver_rounded,
                              ok: _batteryOptimized != true,
                              actionLabel: loc.diagRequestExemption,
                              onAction: () async {
                                await BatteryOptimizationHelper
                                    .requestIgnoreBatteryOptimization();
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                await _refresh();
                              },
                            ),
                            SettingsWidgets.buildDivider(context),
                            _permTile(
                              context,
                              title: loc.diagOverlayTitle,
                              subtitle: _overlayGranted == true
                                  ? loc.diagOverlayOk
                                  : loc.diagOverlayDenied,
                              icon: Icons.layers_outlined,
                              ok: _overlayGranted == true,
                              actionLabel: loc.diagRequestPermission,
                              onAction: () async {
                                await PrayerNotificationHelper
                                    .requestOverlayPermission();
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                await _refresh();
                              },
                            ),
                            SettingsWidgets.buildDivider(context),
                            _permTile(
                              context,
                              title: loc.diagDndTitle,
                              subtitle: _dndGranted == true
                                  ? loc.diagDndOk
                                  : loc.diagDndDenied,
                              icon: Icons.do_not_disturb_on_rounded,
                              ok: _dndGranted == true,
                              actionLabel: loc.diagOpenSettings,
                              onAction: () async {
                                await PrayerNotificationHelper
                                    .openDndSettings();
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                await _refresh();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SettingsWidgets.buildSectionHeader(
                          context: context,
                          title: loc.diagScheduled,
                          icon: Icons.schedule_rounded,
                          color: const Color(0xFF3B82F6),
                        ),
                        SettingsWidgets.buildCardContainer(
                          context: context,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black45
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _diag,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    height: 1.6,
                                    color: isDark
                                        ? Colors.green.shade200
                                        : Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _rescheduling ? null : _rescheduleAll,
                                  icon: _rescheduling
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(
                                          Icons.refresh_rounded,
                                          size: 20),
                                  label: Text(
                                    loc.diagRescheduleAll,
                                    style: const TextStyle(
                                      fontFamily: 'Amiri',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SettingsWidgets.buildSectionHeader(
                          context: context,
                          title: loc.diagTracking,
                          icon: Icons.local_fire_department_outlined,
                          color: const Color(0xFFD64463),
                        ),
                        SettingsWidgets.buildCardContainer(
                          context: context,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _streakStat(
                                      loc.diagCurrent, _currentStreak),
                                  _streakStat(
                                      loc.diagLongest, _longestStreak),
                                ],
                              ),
                            ),
                            SettingsWidgets.buildDivider(context),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    loc.diagFivePrayer,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _streakStat(loc.diagCurrent,
                                          _five['current'] as int? ?? 0),
                                      _streakStat(loc.diagLongest,
                                          _five['longest'] as int? ?? 0),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${loc.ptLevelTitle(_five['level'] as int? ?? 1)}'
                                    ' · ${loc.ptPointsCount(_five['points30'] as int? ?? 0)}'
                                    ' · ${loc.ptDailyGoal} ${_five['goal'] ?? 5}/5',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontFamily: 'Amiri', fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fiveFlagsLine(),
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SettingsWidgets.buildSectionHeader(
                          context: context,
                          title: loc.diagTest,
                          icon: Icons.science_outlined,
                          color: const Color(0xFFF59E0B),
                        ),
                        SettingsWidgets.buildCardContainer(
                          context: context,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.diagTestDesc,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _testingAlarm ? null : _testAlarm,
                                      icon: const Icon(
                                          Icons.alarm_add_rounded),
                                      label: Text(
                                        _testingAlarm
                                            ? loc.diagTestScheduling
                                            : loc.diagTestButton,
                                        style: const TextStyle(
                                          fontFamily: 'Amiri',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _permTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool ok,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon,
              color: ok ? const Color(0xFF10B981) : Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  /// Dev-facing flags line (English, LTR): reminder opt-in, pause state,
  /// man/woman context, today's time-cache presence, today's logged count.
  String _fiveFlagsLine() {
    String onOff(Object? v) => v == true ? 'on' : 'off';
    final cache = (_five['cacheToday'] as bool?) == true ? 'today' : 'none';
    return 'rem=${onOff(_five['reminders'])}'
        ' dis=${onOff(_five['disabled'])}'
        " ctx=${_five['context'] ?? '?'}"
        ' cache=$cache'
        " today=${_five['todayLogged'] ?? 0}/5";
  }

  Widget _streakStat(String label, int value) {
    return Column(
      children: [
        Text('$value',
            style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD64463))),
        Text(label,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 14)),
      ],
    );
  }
}

