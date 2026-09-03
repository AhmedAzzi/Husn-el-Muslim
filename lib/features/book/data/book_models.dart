class AllahName {
  final String name;
  final String meaning;
  final String source;

  const AllahName({
    required this.name,
    required this.meaning,
    this.source = '',
  });

  factory AllahName.fromJson(Map<String, dynamic> json) {
    return AllahName(
      name: json['name'] ?? '',
      meaning: json['meaning'] ?? '',
      source: json['source'] ?? '',
    );
  }
}

class BookData {
  final String title;
  final String author;
  final String? digitalTextNote;
  final List<AllahName> asmaAllahHusna;
  final DuaSection duaSection;
  final RuqyahSection ruqyahSection;

  BookData({
    required this.title,
    required this.author,
    this.digitalTextNote,
    required this.asmaAllahHusna,
    required this.duaSection,
    required this.ruqyahSection,
  });

  factory BookData.fromJson(Map<String, dynamic> json) {
    final bookMeta = json['book'] as Map<String, dynamic>? ?? {};
    final sections = json['sections'] as List<dynamic>? ?? [];

    Map<String, dynamic> duaJson = {};
    Map<String, dynamic> ruqyahJson = {};

    for (var s in sections) {
      if (s is Map<String, dynamic>) {
        if (s['id'] == 1 || s['filename'] == 'do3aa') {
          duaJson = s;
        } else if (s['id'] == 2 || s['filename'] == 'roqia') {
          ruqyahJson = s;
        }
      }
    }

    return BookData(
      title: bookMeta['title'] ?? 'الدعاء ويليه العلاج بالرقى',
      author: bookMeta['author'] ?? 'د. سعيد بن علي بن وهف القحطاني',
      digitalTextNote: bookMeta['digital_text_note'],
      asmaAllahHusna: (bookMeta['asma_allah_husna'] as List<dynamic>?)
              ?.map((e) => AllahName.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      duaSection: DuaSection.fromJson(duaJson),
      ruqyahSection: RuqyahSection.fromJson(ruqyahJson),
    );
  }
}

class SectionTextGroup {
  final String title;
  final List<String> items;

  SectionTextGroup({required this.title, required this.items});

  factory SectionTextGroup.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SectionTextGroup(title: '', items: []);
    return SectionTextGroup(
      title: json['title'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class DuaEntry {
  final int number;
  final String text;

  DuaEntry({required this.number, required this.text});

  factory DuaEntry.fromJson(Map<String, dynamic> json) {
    return DuaEntry(
      number: json['number'] is int
          ? json['number']
          : int.tryParse(json['number'].toString()) ?? 0,
      text: json['text'] ?? '',
    );
  }
}

class DuaSection {
  final int id;
  final String title;
  final SectionTextGroup virtues;
  final SectionTextGroup adab;
  final SectionTextGroup times;
  final String duaaTitle;
  final String quranicTitle;
  final List<DuaEntry> quranicDuas;
  final String sunnahTitle;
  final List<DuaEntry> sunnahDuas;

  DuaSection({
    required this.id,
    required this.title,
    required this.virtues,
    required this.adab,
    required this.times,
    required this.duaaTitle,
    required this.quranicTitle,
    required this.quranicDuas,
    required this.sunnahTitle,
    required this.sunnahDuas,
  });

  factory DuaSection.fromJson(Map<String, dynamic> json) {
    final duaaMap = json['duaa'] as Map<String, dynamic>? ?? {};
    final quranicMap = duaaMap['quranic'] as Map<String, dynamic>? ?? {};
    final sunnahMap = duaaMap['sunnah'] as Map<String, dynamic>? ?? {};

    return DuaSection(
      id: json['id'] ?? 1,
      title: json['title'] ?? 'الدعاء من الكتاب والسنة',
      virtues: SectionTextGroup.fromJson(json['virtues'] as Map<String, dynamic>?),
      adab: SectionTextGroup.fromJson(json['adab'] as Map<String, dynamic>?),
      times: SectionTextGroup.fromJson(json['times'] as Map<String, dynamic>?),
      duaaTitle: duaaMap['title'] ?? 'الأدعية الجامعية من الكتاب والسنة',
      quranicTitle: quranicMap['title'] ?? 'الأدعية من القرآن الكريم',
      quranicDuas: (quranicMap['items'] as List<dynamic>?)
              ?.map((e) => DuaEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sunnahTitle: sunnahMap['title'] ?? 'الأدعية من السنة النبوية الشريفة',
      sunnahDuas: (sunnahMap['items'] as List<dynamic>?)
              ?.map((e) => DuaEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RuqyahTreatment {
  final int id;
  final String title;
  final List<String> items;

  RuqyahTreatment({
    required this.id,
    required this.title,
    required this.items,
  });

  factory RuqyahTreatment.fromJson(Map<String, dynamic> json) {
    return RuqyahTreatment(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class RuqyahSection {
  final int id;
  final String title;
  final List<RuqyahTreatment> treatments;

  RuqyahSection({
    required this.id,
    required this.title,
    required this.treatments,
  });

  factory RuqyahSection.fromJson(Map<String, dynamic> json) {
    return RuqyahSection(
      id: json['id'] ?? 2,
      title: json['title'] ?? 'العلاج بالرقى من الكتاب والسنة',
      treatments: (json['treatments'] as List<dynamic>?)
              ?.map((e) => RuqyahTreatment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
