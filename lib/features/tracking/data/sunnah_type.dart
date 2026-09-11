/// Sunnah catalogue for the Sunnah tracker (Rawatib + Duha + Witr + Qiyam).
///
/// Index convention is stable and persisted in SharedPreferences keys
/// (`strak_log_<date>_<index>`), so never reorder or remove entries —
/// only append new ones at the end.
enum SunnahType {
  /// ركعتا الفجر (2 before Fajr).
  fajrSunnah,

  /// السنة القبلية للظهر (4 rak'as).
  dhuhrBefore,

  /// السنة البعدية للظهر (2 rak'as).
  dhuhrAfter,

  /// سنة المغرب البعدية (2 rak'as).
  maghribAfter,

  /// سنة العشاء البعدية (2 rak'as).
  ishaAfter,

  /// صلاة الضحى.
  duha,

  /// الوتر.
  witr,

  /// قيام الليل.
  qiyam,
}

/// Indices 0..4 form the 12-rak'a Rawatib set.
const List<SunnahType> rawatibTypes = [
  SunnahType.fajrSunnah,
  SunnahType.dhuhrBefore,
  SunnahType.dhuhrAfter,
  SunnahType.maghribAfter,
  SunnahType.ishaAfter,
];

/// Duha / Witr / Qiyam — the non-Rawatib night & forenoon prayers.
const List<SunnahType> extraSunnahTypes = [
  SunnahType.duha,
  SunnahType.witr,
  SunnahType.qiyam,
];

/// Points per completed Sunnah (flat, no multipliers — every Sunnah is
/// voluntary, so effort is measured by consistency, not by prayer).
const Map<SunnahType, int> sunnahPoints = {
  SunnahType.fajrSunnah: 10,
  SunnahType.dhuhrBefore: 10,
  SunnahType.dhuhrAfter: 10,
  SunnahType.maghribAfter: 10,
  SunnahType.ishaAfter: 10,
  SunnahType.duha: 8,
  SunnahType.witr: 12,
  SunnahType.qiyam: 15,
};

/// Bonus awarded once per day when all five Rawatib are done.
const int rawatibBonus = 10;
