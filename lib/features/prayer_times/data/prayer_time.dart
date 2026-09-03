enum PrayerTimeSource {
  calculated,
  mosque,
}

class PrayerTime {
  final String name;
  final DateTime time;
  final String time24h;
  final DateTime? iqamaTime;

  PrayerTime({
    required this.name,
    required this.time,
    required this.time24h,
    this.iqamaTime,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'time': time.toIso8601String(),
    'time24h': time24h,
    if (iqamaTime != null) 'iqamaTime': iqamaTime!.toIso8601String(),
  };

  factory PrayerTime.fromJson(Map<String, dynamic> json) => PrayerTime(
    name: json['name'] as String,
    time: DateTime.parse(json['time'] as String),
    time24h: json['time24h'] as String,
    iqamaTime: json['iqamaTime'] != null
        ? DateTime.parse(json['iqamaTime'] as String)
        : null,
  );

  PrayerTime copyWith({String? name, DateTime? time, String? time24h, DateTime? iqamaTime, bool clearIqama = false}) {
    return PrayerTime(
      name: name ?? this.name,
      time: time ?? this.time,
      time24h: time24h ?? this.time24h,
      iqamaTime: clearIqama ? null : (iqamaTime ?? this.iqamaTime),
    );
  }

  /// Returns the effective target time: iqamaTime if available, otherwise adhan time.
  DateTime get effectiveTarget => iqamaTime ?? time;
}
