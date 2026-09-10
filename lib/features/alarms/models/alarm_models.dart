/// Central alarm model. All alarms (Fajr, Suhoor, Pre-Fajr, Bedtime,
/// pre/post prayer, custom) go through one reliable native scheduling layer
/// ([AlarmSchedulerService] → Android AlarmManager).
///
/// IDs are deterministic (`date + prayer + type`) so reschedule() cancels the
/// old PendingIntent first and never creates duplicates.
enum AlarmType {
  fajr,
  suhoor,
  preFajr,
  tahajjud,
  fajrExtra1,
  fajrExtra2,
  bedtime,
  prePrayer,
  postPrayer,
  custom,
}

/// Wake-up vs informational priority. Wake-up alarms use
/// `setAlarmClock()` (Doze-proof, shown in system clock UI);
/// informational ones use `setExactAndAllowWhileIdle()`.
enum AlarmPriority { wakeUp, informational }

/// Serializable alarm configuration with migration-safe defaults.
class AlarmConfig {
  final String id;
  final AlarmType type;
  final bool enabled;
  final int? triggerAtMillis;
  final String? relativeTo;
  final int offsetMinutes;
  final bool loop;
  final bool vibrate;
  final bool fullScreen;
  final bool showOnLockScreen;
  final bool requiresChallenge;

  const AlarmConfig({
    required this.id,
    required this.type,
    this.enabled = false,
    this.triggerAtMillis,
    this.relativeTo,
    this.offsetMinutes = 0,
    this.loop = true,
    this.vibrate = true,
    this.fullScreen = true,
    this.showOnLockScreen = true,
    this.requiresChallenge = false,
  });

  AlarmPriority get priority => switch (type) {
        AlarmType.fajr ||
        AlarmType.suhoor ||
        AlarmType.preFajr ||
        AlarmType.tahajjud ||
        AlarmType.fajrExtra1 ||
        AlarmType.fajrExtra2 =>
          AlarmPriority.wakeUp,
        _ => AlarmPriority.informational,
      };

  /// Deterministic identity: `date + prayer + alarm type`.
  static String deterministicId(AlarmType type, DateTime date, [String extra = '']) {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${type.name}|$d|$extra';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'enabled': enabled,
        'triggerAtMillis': triggerAtMillis,
        'relativeTo': relativeTo,
        'offsetMinutes': offsetMinutes,
        'loop': loop,
        'vibrate': vibrate,
        'fullScreen': fullScreen,
        'showOnLockScreen': showOnLockScreen,
        'requiresChallenge': requiresChallenge,
      };

  factory AlarmConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'custom';
    final type = AlarmType.values.asNameMap()[typeName] ?? AlarmType.custom;
    return AlarmConfig(
      id: json['id'] as String? ?? '${type.name}|unknown|',
      type: type,
      enabled: json['enabled'] as bool? ?? false,
      triggerAtMillis: (json['triggerAtMillis'] as num?)?.toInt(),
      relativeTo: json['relativeTo'] as String?,
      offsetMinutes: (json['offsetMinutes'] as num?)?.toInt() ?? 0,
      loop: json['loop'] as bool? ?? true,
      vibrate: json['vibrate'] as bool? ?? true,
      fullScreen: json['fullScreen'] as bool? ?? true,
      showOnLockScreen: json['showOnLockScreen'] as bool? ?? true,
      requiresChallenge: json['requiresChallenge'] as bool? ?? false,
    );
  }
}

/// Computes a Fajr-anchored trigger: `fajr - offsetMinutes`, rolled to the
/// next future occurrence (today or tomorrow) relative to [now].
DateTime? fajrAnchoredTrigger({
  required DateTime fajrToday,
  required int offsetMinutes,
  required DateTime now,
}) {
  if (offsetMinutes < 0) return null;
  var candidate = fajrToday.subtract(Duration(minutes: offsetMinutes));
  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}
