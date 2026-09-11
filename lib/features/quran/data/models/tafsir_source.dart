/// Available tafsir sources in `tafsir.db`, with Arabic labels.
library;

enum TafsirSource {
  moyassar('tafsir_moyassar', 'الميسر'),
  mukhtasar('quran_tafseer_mukhtasar', 'المختصر'),
  saadi('tafsir_saadi', 'السعدي'),
  baghawy('tafsir_baghawy', 'البغوي'),
  tabary('tafsir_tabary', 'الطبري'),
  katheer('tafsir_katheer', 'ابن كثير');

  const TafsirSource(this.table, this.arabicName);

  final String table;
  final String arabicName;
}
