/// Canonical English -> Arabic name mapping for prayer times and night
/// prayer (Third of the Night) markers.
///
/// Centralized so the mapping is defined once and reused by the prayer
/// controller and the UI screens, avoiding duplicated map literals drifting
/// out of sync.
const Map<String, String> kArabicPrayerNames = {
  'Fajr': 'الفجر',
  'Sunrise': 'الشروق',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
  'First Third': 'الثلث الأول',
  'Midnight': 'منتصف الليل',
  'Last Third': 'الثلث الأخير',
};

/// The three night-boundary prayers that are computed in addition to the five
/// daily prayers.
const List<String> kNightPrayerNames = <String>[
  'First Third',
  'Midnight',
  'Last Third',
];
