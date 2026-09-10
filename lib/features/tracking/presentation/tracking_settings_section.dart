import 'package:flutter/material.dart';
import 'package:small_husn_muslim/core/widgets/settings_widgets.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_reminder_service.dart';
import 'package:small_husn_muslim/features/tracking/data/prayer_tracking_repository.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

/// Prayer-tracker settings, rendered in the Husn settings language and
/// embedded in the app Settings screen (single home for all tracking
/// settings — the tracker page itself stays settings-free).
class TrackingSettingsSection extends StatefulWidget {
  const TrackingSettingsSection({super.key});

  @override
  State<TrackingSettingsSection> createState() =>
      _TrackingSettingsSectionState();
}

class _TrackingSettingsSectionState extends State<TrackingSettingsSection> {
  static const _rose = Color(0xFFD64463);

  int _goal = PrayerTrackingRepository.defaultDailyGoal;
  String _ctx = PrayerTrackingRepository.contextMan;
  bool _reminders = false;
  bool _disabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = PrayerTrackingRepository.instance;
    final goal = await repo.dailyGoal();
    final ctx = await repo.context();
    final reminders = await repo.remindersEnabled();
    final disabled = await repo.isDisabled();
    if (!mounted) return;
    setState(() {
      _goal = goal;
      _ctx = ctx;
      _reminders = reminders;
      _disabled = disabled;
      _loading = false;
    });
  }

  Future<void> _goalDialog(AppLocalizations loc) async {
    var value = _goal;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.ptGoalDialogTitle,
            style: const TextStyle(fontFamily: 'Amiri')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.ptGoalDialogHint),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, setDialog) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed:
                        value > 1 ? () => setDialog(() => value--) : null,
                  ),
                  Text('$value / 5',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed:
                        value < 5 ? () => setDialog(() => value++) : null,
                  ),
                ],
              ),
            ),
          ],
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
    );
    if (saved == true) {
      await PrayerTrackingRepository.instance.setDailyGoal(value);
      await _load();
    }
  }

  Future<void> _contextDialog(AppLocalizations loc) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.ptContext,
            style: const TextStyle(fontFamily: 'Amiri')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsWidgets.buildChoiceCard(
              context: ctx,
              title: loc.ptMan,
              subtitle: '',
              isSelected: _ctx == PrayerTrackingRepository.contextMan,
              onTap: () => Navigator.of(ctx)
                  .pop(PrayerTrackingRepository.contextMan),
            ),
            SettingsWidgets.buildChoiceCard(
              context: ctx,
              title: loc.ptWoman,
              subtitle: '',
              isSelected: _ctx == PrayerTrackingRepository.contextWoman,
              onTap: () => Navigator.of(ctx)
                  .pop(PrayerTrackingRepository.contextWoman),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.ctCancel),
          ),
        ],
      ),
    );
    if (picked != null && picked != _ctx) {
      await PrayerTrackingRepository.instance.setContext(picked);
      await _load();
    }
  }

  Future<void> _toggleReminders(bool value) async {
    await PrayerTrackingRepository.instance.setReminders(value);
    if (value) {
      await PrayerReminderService.instance.refreshFromCache();
    } else {
      await PrayerReminderService.instance.cancelAll();
    }
    await _load();
  }

  Future<void> _togglePaused(bool value) async {
    await PrayerTrackingRepository.instance.setDisabled(value);
    if (value) {
      await PrayerReminderService.instance.cancelAll();
    } else {
      await PrayerReminderService.instance.refreshFromCache();
    }
    await _load();
  }

  void _widgetHelp(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.ptWidgetTitle,
            style: const TextStyle(fontFamily: 'Amiri')),
        content: Text(loc.ptWidgetHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.ctClose),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.ptClearTitle,
            style: const TextStyle(fontFamily: 'Amiri')),
        content: Text(loc.ptClearHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.ctCancel),
          ),
          FilledButton(
            key: const ValueKey('pt_clear_confirm'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.ptDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PrayerTrackingRepository.instance.clearAll();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_loading) return const SizedBox.shrink();
    final ctxLabel = _ctx == PrayerTrackingRepository.contextWoman
        ? loc.ptWoman
        : loc.ptMan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsWidgets.buildSectionHeader(
          context: context,
          title: loc.navFajrLog,
          icon: Icons.local_fire_department_rounded,
          color: _rose,
        ),
        SettingsWidgets.buildCardContainer(
          context: context,
          children: [
            KeyedSubtree(
              key: const ValueKey('pt_settings_goal'),
              child: SettingsWidgets.buildValueTile(
                context: context,
                title: loc.ptGoalDialogTitle,
                subtitle: loc.ptGoalDialogHint,
                icon: Icons.track_changes_rounded,
                iconColor: _rose,
                valueBadge: '$_goal/5',
                onTap: () => _goalDialog(loc),
              ),
            ),
            SettingsWidgets.buildDivider(context),
            KeyedSubtree(
              key: const ValueKey('pt_settings_ctx'),
              child: SettingsWidgets.buildValueTile(
                context: context,
                title: loc.ptContext,
                subtitle: loc.ptContextHint,
                icon: Icons.person_rounded,
                iconColor: _rose,
                valueBadge: ctxLabel,
                onTap: () => _contextDialog(loc),
              ),
            ),
            SettingsWidgets.buildDivider(context),
            KeyedSubtree(
              key: const ValueKey('pt_settings_reminders'),
              child: SettingsWidgets.buildSwitchTile(
                context: context,
                title: loc.ptRemindToggle,
                subtitle: loc.ptRemindHint,
                icon: Icons.notifications_active_rounded,
                iconColor: _rose,
                value: _reminders,
                onChanged: _toggleReminders,
              ),
            ),
            SettingsWidgets.buildDivider(context),
            KeyedSubtree(
              key: const ValueKey('pt_settings_pause'),
              child: SettingsWidgets.buildSwitchTile(
                context: context,
                title: loc.ptMenuDisable,
                subtitle: loc.ptPausedHint,
                icon: Icons.pause_rounded,
                iconColor: _rose,
                value: _disabled,
                onChanged: _togglePaused,
              ),
            ),
            SettingsWidgets.buildDivider(context),
            KeyedSubtree(
              key: const ValueKey('pt_settings_widget'),
              child: SettingsWidgets.buildActionTile(
                context: context,
                title: loc.ptMenuWidget,
                subtitle: loc.ptWidgetHint,
                icon: Icons.widgets_outlined,
                iconColor: _rose,
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey),
                onTap: () => _widgetHelp(loc),
              ),
            ),
            SettingsWidgets.buildDivider(context),
            KeyedSubtree(
              key: const ValueKey('pt_settings_clear'),
              child: SettingsWidgets.buildActionTile(
                context: context,
                title: loc.ptMenuClear,
                subtitle: loc.ptClearHint,
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red,
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey),
                onTap: () => _confirmClear(loc),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
