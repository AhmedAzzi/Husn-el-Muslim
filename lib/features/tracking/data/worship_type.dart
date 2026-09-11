// Catalogue for the worship tracker (fasting + daily wird + good deeds).
//
// Enum orders are stable and persisted in SharedPreferences, so never
// reorder or remove entries — only append new ones at the end.

/// Daily toggles: the wird (first five) and extra good deeds (last three).
enum DeedType {
  /// ورد القرآن.
  quranWird,

  /// أذكار الصباح.
  morningAdhkar,

  /// أذكار المساء.
  eveningAdhkar,

  /// الاستغفار (100).
  istighfar,

  /// الصلاة على النبي (100).
  salawat,

  /// صدقة.
  sadaqah,

  /// صلة رحم.
  silatRahim,

  /// بر الوالدين.
  birrParents,
}

/// The daily wird section (Quran + adhkar + dhikr).
const List<DeedType> wirdTypes = [
  DeedType.quranWird,
  DeedType.morningAdhkar,
  DeedType.eveningAdhkar,
  DeedType.istighfar,
  DeedType.salawat,
];

/// Extra good deeds section.
const List<DeedType> extraDeedTypes = [
  DeedType.sadaqah,
  DeedType.silatRahim,
  DeedType.birrParents,
];

/// Points per completed daily deed.
const Map<DeedType, int> deedPoints = {
  DeedType.quranWird: 10,
  DeedType.morningAdhkar: 8,
  DeedType.eveningAdhkar: 8,
  DeedType.istighfar: 6,
  DeedType.salawat: 6,
  DeedType.sadaqah: 8,
  DeedType.silatRahim: 8,
  DeedType.birrParents: 8,
};

/// Voluntary fast kinds. One fast per day — the kind records the intention.
enum FastKind {
  /// صيام الاثنين.
  monday,

  /// صيام الخميس.
  thursday,

  /// الأيام البيض (13-15).
  whiteDays,

  /// يوم عرفة.
  arafah,

  /// عاشوراء / تاسوعاء.
  ashura,

  /// الست من شوال.
  shawwal,

  /// قضاء.
  qadaa,

  /// نفل مطلق.
  nafl,
}

/// Points per fasted day, by kind.
const Map<FastKind, int> fastPoints = {
  FastKind.monday: 20,
  FastKind.thursday: 20,
  FastKind.whiteDays: 15,
  FastKind.arafah: 30,
  FastKind.ashura: 25,
  FastKind.shawwal: 15,
  FastKind.qadaa: 10,
  FastKind.nafl: 10,
};
