class PrayerTime {
  final String name;
  final DateTime time;
  final String time24h;

  PrayerTime({
    required this.name,
    required this.time,
    required this.time24h,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'time': time.toIso8601String(),
    'time24h': time24h,
  };

  factory PrayerTime.fromJson(Map<String, dynamic> json) => PrayerTime(
    name: json['name'] as String,
    time: DateTime.parse(json['time'] as String),
    time24h: json['time24h'] as String,
  );

  PrayerTime copyWith({String? name, DateTime? time, String? time24h}) {
    return PrayerTime(
      name: name ?? this.name,
      time: time ?? this.time,
      time24h: time24h ?? this.time24h,
    );
  }
}
