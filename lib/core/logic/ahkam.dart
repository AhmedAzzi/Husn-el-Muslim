/// Arabic names for tajweed rules (ahkam). Port of `src/contract/ahkam.ts`.
/// Keys match the `cls` values stored in taj JSON slices.
const Map<String, String> ahkamArMap = {
  'ghunnah': 'غُنَّة',
  'ikhfa': 'إِخْفَاء',
  'madd-wajib': 'مَدّ وَاجِب مُتَّصِل',
  'madd-jaiz': 'مَدّ جَائِز مُنْفَصِل',
  'hamzah-wasl': 'هَمْزَةُ الْوَصْل',
  'silent': 'لَا يُلْفَظ',
  'madd-4-5': 'مَدّ (4-5 حَرَكَات)',
  'madd-2-4-6': 'مَدّ (2-4-6 حَرَكَات)',
  'madd-6': 'مَدّ لَازِم (6 حَرَكَات)',
  'madd-arid-lissukun': 'مَدّ عَارِض لِلسُّكُون',
  'madd-lazim-mutsaqal-harfi': 'مَدّ لَازِم حَرْفِيّ مُثَقَّل',
  'madd-lazim-mukhofaf-harfi': 'مَدّ لَازِم حَرْفِيّ مُخَفَّف',
  'idgham-mimi': 'إِدْغَام شَفَوِيّ',
  'ikhfa-syafawi': 'إِخْفَاء شَفَوِيّ',
  'idgham-bighunnah': 'إِدْغَام بِغُنَّة',
  'idgham-bilaghunnah': 'إِدْغَام بِغَيْرِ غُنَّة',
  'idgham-mutamatsilain': 'إِدْغَام مُتَمَاثِلَيْن',
  'idgham-mutajanisain': 'إِدْغَام مُتَجَانِسَيْن',
  'iqlab': 'إِقْلَاب',
  'qalqalah': 'قَلْقَلَة',
  '': '',
};

String ahkamAr(String cls) => ahkamArMap[cls] ?? cls;

/// Short descriptions shown in the tajweed tooltip bottom sheet.
/// Port of the inline descriptions in `MushafPage.svelte`.
String? tajweedDescription(String cls) {
  switch (cls) {
    case 'madd-wajib':
    case 'madd-jaiz':
      return 'المدّ هو إطالة الصوت بحرف من حروف المدّ.';
    case 'madd-arid-lissukun':
      return 'مدٌّ سببه الوقف، ومقداره حركتان أو أربع أو ست حركات.';
    case 'ghunnah':
      return 'غنّ الميم والنون المشدّدتين، والغنّة صوت يخرج من الخيشوم.';
    case 'idgham-mimi':
      return 'إذا جاءت ميم ساكنة بعدها ميم متحركة تُدغم فيها مع الغنّة.';
    case 'ikhfa-syafawi':
      return 'إذا جاءت ميم ساكنة بعدها باء تُخفى مع الغنّة.';
    case 'idgham-bighunnah':
      return 'إذا جاء نون ساكنة أو تنوين بعدها أحد حروف (م، ن، و، ي) تُدغم مع الغنّة.';
    case 'idgham-bilaghunnah':
      return 'إذا جاء نون ساكنة أو تنوين بعدها الراء أو اللام تُدغم بغير غنّة.';
    case 'ikhfa':
      return 'إذا جاء نون ساكنة أو تنوين بعدها حرف من حروف الإخفاء (ت، ث، ج، د، ذ، ز، س، ش، ص، ض، ط، ظ، ف، ق، ك) يُخفى مع الغنّة.';
    case 'iqlab':
      return 'إذا جاء نون ساكنة أو تنوين بعدها الباء تُقلب ميماً مخفاة مع الغنّة.';
    case 'qalqalah':
      return 'اضطراب الحرف في مخرجه عند سكونه، وحروفها خمسة: ق، ط، ب، ج، د.';
    default:
      return null;
  }
}
