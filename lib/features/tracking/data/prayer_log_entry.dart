/// Per-prayer log model for the 5-prayer tracker ecosystem.
///
/// Prayer index convention (matches `mainPrayersList` order in
/// `prayer_times_logic.dart`): 0 Fajr, 1 Dhuhr, 2 Asr, 3 Maghrib, 4 Isha.
class PrayerLogEntry {
  /// Local Gregorian date key `yyyy-MM-dd`.
  final String date;

  /// Prayer index 0..4 (Fajr..Isha).
  final int prayerIndex;

  /// How the prayer was performed (drives the points engine).
  final PrayerStatus status;

  /// Epoch millis of the last update (for future conflict resolution).
  final int updatedAt;

  const PrayerLogEntry({
    required this.date,
    required this.prayerIndex,
    required this.status,
    required this.updatedAt,
  });

  /// A prayer counts toward the daily goal / streak when it was actually
  /// performed (anything except a missed prayer).
  bool get countsTowardGoal => status != PrayerStatus.missed;

  Map<String, dynamic> toJson() => {
        'date': date,
        'prayer': prayerIndex,
        'status': status.name,
        'ts': updatedAt,
      };

  factory PrayerLogEntry.fromJson(Map<String, dynamic> json) {
    final prayer = json['prayer'] as int? ?? -1;
    final statusName = json['status'] as String? ?? '';
    final status = PrayerStatus.values.asNameMap()[statusName];
    if (prayer < 0 || prayer > 4 || status == null) {
      throw const FormatException('Bad prayer log entry');
    }
    return PrayerLogEntry(
      date: json['date'] as String? ?? '',
      prayerIndex: prayer,
      status: status,
      updatedAt: json['ts'] as int? ?? 0,
    );
  }
}

/// How a single prayer was performed. Base points live in [PointsEngine];
/// names mirror the "النقاط في التطبيق" table from the tracker design.
enum PrayerStatus {
  /// تكبيرة الإحرام (caught the opening takbeer).
  takbeer,

  /// في المسجد (prayed in the mosque).
  mosque,

  /// جماعة (in congregation, not in mosque).
  jamaa,

  /// في الوقت منفردًا (on time, alone).
  onTimeAlone,

  /// بعد الوقت (after its time but made up same day).
  late,

  /// فائتة (missed entirely — negative points).
  missed,
}
