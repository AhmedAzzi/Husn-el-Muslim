/// Data models mirroring the web JSON shapes.
library;

import '../../../../core/logic/mushaf_align.dart';

class Surah {
  const Surah({
    required this.id,
    required this.suratName,
    required this.suratText,
    required this.suratTerjemahan,
    required this.countAyat,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        id: (json['id'] as num).toInt(),
        suratName: json['surat_name'] as String? ?? '',
        suratText: json['surat_text'] as String? ?? '',
        suratTerjemahan: json['surat_terjemahan'] as String? ?? '',
        countAyat: (json['count_ayat'] as num?)?.toInt() ?? 0,
      );

  final int id;
  final String suratName;
  final String suratText;
  final String suratTerjemahan;
  final int countAyat;
}

class MushafLine {
  const MushafLine({
    required this.t,
    this.s,
    this.x,
    this.v,
    this.w = const [],
  });

  factory MushafLine.fromJson(Map<String, dynamic> json) {
    final w = <List<String>>[];
    final raw = json['w'] as List?;
    if (raw != null) {
      for (final e in raw) {
        final pair = (e as List).map((x) => x.toString()).toList();
        if (pair.length >= 2) w.add([pair[0], pair[1]]);
      }
    }
    return MushafLine(
      t: json['t'] as String? ?? 't',
      s: json['s']?.toString(),
      x: json['x']?.toString(),
      v: json['v']?.toString(),
      w: w,
    );
  }

  final String t; // h | b | t
  final String? s;
  final String? x;
  final String? v;
  final List<List<String>> w;
}

class MushafPageData {
  const MushafPageData({required this.p, required this.lines});

  factory MushafPageData.fromJson(Map<String, dynamic> json) {
    final l = (json['l'] as List? ?? [])
        .map((e) => MushafLine.fromJson(e as Map<String, dynamic>))
        .toList();
    return MushafPageData(p: (json['p'] as num?)?.toInt() ?? 0, lines: l);
  }

  final int p;
  final List<MushafLine> lines;
}

class TajAya {
  const TajAya({required this.a, required this.text, required this.slices});

  factory TajAya.fromJson(Map<String, dynamic> json) {
    final j = (json['j'] as List? ?? []).map((e) {
      final arr = e as List;
      return KemSlice(
        start: (arr[0] as num).toInt(),
        end: (arr[1] as num).toInt(),
        cls: arr.length > 2 ? arr[2].toString() : '',
      );
    }).toList();
    return TajAya(
      a: (json['a'] as num).toInt(),
      text: json['t'] as String? ?? '',
      slices: j,
    );
  }

  final int a;
  final String text;
  final List<KemSlice> slices;
}

class MushafMeta {
  const MushafMeta({
    required this.start,
    required this.pageJuz,
    required this.aya,
  });

  factory MushafMeta.fromJson(Map<String, dynamic> json) {
    Map<String, int> toIntMap(Object? o) {
      final m = <String, int>{};
      if (o is Map) {
        o.forEach((k, v) => m[k.toString()] = (v as num).toInt());
      }
      return m;
    }

    return MushafMeta(
      start: toIntMap(json['start']),
      pageJuz: toIntMap(json['pageJuz']),
      aya: toIntMap(json['aya']),
    );
  }

  final Map<String, int> start; // surahId -> page
  final Map<String, int> pageJuz; // page -> juz
  final Map<String, int> aya; // "s:v" -> page
}
