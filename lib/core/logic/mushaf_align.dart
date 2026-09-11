/// Letter-level transfer of Kemenag tajweed colors onto mushaf-layout words.
/// Direct Dart port of `src/lib/mushaf-align.ts` — same tiers, same regexes.
library;

class KemSlice {
  const KemSlice({required this.start, required this.end, required this.cls});
  final int start;
  final int end;
  final String cls;
}

class RenderSeg {
  const RenderSeg({required this.text, required this.cls});
  final String text;
  final String cls;
}

class LayWord {
  const LayWord({required this.raw, required this.location});
  final String raw;
  final String location;
}

class RenderWord {
  const RenderWord({
    required this.segs,
    required this.digits,
    required this.location,
  });
  final List<RenderSeg> segs;
  final String digits;
  final String location;
}

final RegExp _attachRe = RegExp(
  '[ءاأإآٱٰـً-ٟۖ-ۭ؉؊؋،؍؎؏ؘؙؚؐؑؒؓؔؕؖؗ؛\u0610-\u061a\u200c\u200f\u061c\\s]',
);
final RegExp _waqfRe = RegExp('[ۖ-ۛ]');

String normSigChar(String c) {
  if (c == 'ى') return 'ي';
  if (c == 'ؤ') return 'و';
  return c;
}

bool isAttach(String c) => c.length == 1 && _attachRe.hasMatch(c);

({String core, String digits}) stripVerseNumber(String word) {
  final m = RegExp(r'^(.*?) ?([٠-٩]+)$').firstMatch(word);
  if (m != null) return (core: m.group(1) ?? '', digits: m.group(2) ?? '');
  return (core: word, digits: '');
}

String arabicDigits(Object n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((d) {
    final v = int.tryParse(d);
    return v == null ? d : digits[v];
  }).join();
}

List<({String ch, int idx})> skeleton(String word) {
  final out = <({String ch, int idx})>[];
  for (var i = 0; i < word.length; i++) {
    if (!isAttach(word[i])) out.add((ch: normSigChar(word[i]), idx: i));
  }
  return out;
}

bool isMarkOnly(String word) {
  final core = stripVerseNumber(word).core;
  for (var i = 0; i < core.length; i++) {
    final ch = core[i];
    if (!isAttach(ch) &&
        ch != '۞' &&
        ch != '۩' &&
        RegExp('[ء-ي]').hasMatch(ch)) {
      return false;
    }
  }
  return true;
}

String _classAt(List<KemSlice> slices, int pos) {
  for (final sl in slices) {
    if (sl.start <= pos && pos < sl.end && sl.cls.isNotEmpty) return sl.cls;
  }
  return '';
}

String _gapClass(List<KemSlice> slices, int s, int e) {
  for (final sl in slices) {
    if (sl.cls.isEmpty) continue;
    if (sl.start < e && s < sl.end) return sl.cls;
  }
  return '';
}

String majorityClass(List<KemSlice> slices, int s, int e) {
  var best = '';
  var bestLen = 0;
  for (final sl in slices) {
    if (sl.cls.isEmpty) continue;
    final a = sl.start > s ? sl.start : s;
    final b = sl.end < e ? sl.end : e;
    if (b - a > bestLen) {
      bestLen = b - a;
      best = sl.cls;
    }
  }
  return best;
}

List<RenderSeg> _segsOf(String text, String cls) =>
    text.isEmpty ? const [] : [RenderSeg(text: text, cls: cls)];

int _sigTotal(String core) {
  var n = 0;
  for (var i = 0; i < core.length; i++) {
    if (!isAttach(core[i])) n++;
  }
  return n;
}

List<RenderSeg>? _colorizePair(
  String layWord,
  String kemWord,
  int kemWordStart,
  List<KemSlice> kemSlices,
) {
  final laySk = skeleton(layWord);
  final kemSk = skeleton(kemWord);
  if (laySk.length != kemSk.length || laySk.isEmpty) return null;
  for (var i = 0; i < laySk.length; i++) {
    if (laySk[i].ch != kemSk[i].ch) return null;
  }
  final out = <RenderSeg>[];
  var cur = '';
  String? curCls;
  void flush() {
    if (cur.isNotEmpty) out.add(RenderSeg(text: cur, cls: curCls ?? ''));
    cur = '';
    curCls = null;
  }

  var sigPos = 0;
  for (var i = 0; i < layWord.length; i++) {
    final ch = layWord[i];
    late final String cls;
    if (_waqfRe.hasMatch(ch)) {
      cls = '';
    } else if (!isAttach(ch)) {
      cls = _classAt(kemSlices, kemWordStart + kemSk[sigPos].idx);
      sigPos++;
    } else {
      final prevK = sigPos > 0 ? kemSk[sigPos - 1].idx : -1;
      final nextK = sigPos < kemSk.length ? kemSk[sigPos].idx : kemWord.length;
      final g = _gapClass(
        kemSlices,
        kemWordStart + prevK + 1,
        kemWordStart + nextK,
      );
      if (g.isNotEmpty) {
        cls = g;
      } else if (sigPos > 0) {
        cls = _classAt(kemSlices, kemWordStart + kemSk[sigPos - 1].idx);
      } else {
        cls = '';
      }
    }
    if (curCls == null) {
      cur = ch;
      curCls = cls;
    } else if (cls == curCls) {
      cur += ch;
    } else {
      flush();
      cur = ch;
      curCls = cls;
    }
  }
  flush();
  return out;
}

class KemWordEntry {
  const KemWordEntry({required this.text, required this.start});
  final String text;
  final int start;
}

/// Order-align word lists with 2-step lookahead (cascade-proof).
List<({String lay, String kem, int kemStart})> alignWordLists(
  List<KemWordEntry> kemWords,
  List<String> layWords,
) {
  final pairs = <({String lay, String kem, int kemStart})>[];
  var i = 0;
  var j = 0;
  bool skelEq(String a, String b) {
    final sa = skeleton(a).map((s) => s.ch).toList();
    final sb = skeleton(b).map((s) => s.ch).toList();
    return sa.isNotEmpty &&
        sa.length == sb.length &&
        Iterable.generate(sa.length).every((k) => sa[k] == sb[k]);
  }

  while (i < kemWords.length && j < layWords.length) {
    if (skelEq(kemWords[i].text, layWords[j])) {
      pairs.add((
        lay: layWords[j],
        kem: kemWords[i].text,
        kemStart: kemWords[i].start,
      ));
      i++;
      j++;
      continue;
    }
    var found = false;
    for (var di = 0; di <= 2 && !found; di++) {
      for (var dj = 0; dj <= 2 && !found; dj++) {
        if (di == 0 && dj == 0) continue;
        if (i + di < kemWords.length &&
            j + dj < layWords.length &&
            skelEq(kemWords[i + di].text, layWords[j + dj])) {
          for (var k = 0; k < di; k++) {
            pairs.add((
              lay: '',
              kem: kemWords[i + k].text,
              kemStart: kemWords[i + k].start,
            ));
          }
          for (var k = 0; k < dj; k++) {
            pairs.add((lay: layWords[j + k], kem: '', kemStart: -1));
          }
          i += di;
          j += dj;
          found = true;
        }
      }
    }
    if (!found) {
      pairs.add((lay: layWords[j], kem: '', kemStart: -1));
      i++;
      j++;
    }
  }
  while (j < layWords.length) {
    pairs.add((lay: layWords[j], kem: '', kemStart: -1));
    j++;
  }
  return pairs;
}

/// Align one aya's layout words to Kemenag text.
List<RenderWord> alignAya(
  String kemText,
  List<KemSlice> kemSlices,
  List<LayWord> layWords,
) {
  final kemWords = <KemWordEntry>[];
  {
    var cursor = 0;
    for (final m in RegExp(r'\S+').allMatches(kemText)) {
      final word = m.group(0)!;
      final start = kemText.indexOf(word, cursor);
      cursor = start + word.length;
      if (isMarkOnly(word)) continue;
      kemWords.add(KemWordEntry(text: word, start: start));
    }
  }
  final layList = layWords.map((w) {
    final d = stripVerseNumber(w.raw);
    return (raw: w.raw, location: w.location, core: d.core, digits: d.digits);
  }).toList();

  final kemSig = <int>[];
  for (final w in kemWords) {
    for (final s in skeleton(w.text)) {
      kemSig.add(w.start + s.idx);
    }
  }
  final laySig = <({int wi, String ch})>[];
  for (var wi = 0; wi < layList.length; wi++) {
    final w = layList[wi];
    if (isMarkOnly(w.core)) continue;
    for (final s in skeleton(w.core)) {
      laySig.add((wi: wi, ch: s.ch));
    }
  }
  final tier1 =
      kemSig.isNotEmpty &&
      kemSig.length == laySig.length &&
      Iterable.generate(laySig.length).every((idx) {
        final kc = kemText[kemSig[idx]];
        return normSigChar(kc) == laySig[idx].ch;
      });

  if (tier1) {
    final out = <RenderWord>[];
    var k = 0;
    String clsOfKem(int pos) => _classAt(kemSlices, pos);
    for (final w in layList) {
      if (isMarkOnly(w.core)) {
        out.add(
          RenderWord(
            segs: _segsOf(w.core, ''),
            digits: w.digits,
            location: w.location,
          ),
        );
        continue;
      }
      final segs = <RenderSeg>[];
      var cur = '';
      String? curCls;
      void flush() {
        if (cur.isNotEmpty) segs.add(RenderSeg(text: cur, cls: curCls ?? ''));
        cur = '';
        curCls = null;
      }

      final myFirstK = k;
      for (var idx = 0; idx < w.core.length; idx++) {
        final ch = w.core[idx];
        late final String cls;
        if (_waqfRe.hasMatch(ch)) {
          cls = '';
        } else if (!isAttach(ch)) {
          cls = clsOfKem(kemSig[k]);
          k++;
        } else {
          final prevK = k > myFirstK ? kemSig[k - 1] : kemSig[myFirstK] - 1;
          final nextK = k < myFirstK + _sigTotal(w.core)
              ? kemSig[k]
              : kemSig[myFirstK] + w.core.length;
          final g = _gapClass(kemSlices, prevK + 1, nextK);
          if (g.isNotEmpty) {
            cls = g;
          } else if (k > myFirstK) {
            cls = clsOfKem(kemSig[k - 1]);
          } else {
            cls = '';
          }
        }
        if (curCls == null) {
          cur = ch;
          curCls = cls;
        } else if (cls == curCls) {
          cur += ch;
        } else {
          flush();
          cur = ch;
          curCls = cls;
        }
      }
      flush();
      out.add(RenderWord(segs: segs, digits: w.digits, location: w.location));
    }
    return out;
  }

  // Tier 2
  final layCores = layList
      .where((w) => !isMarkOnly(w.core))
      .map((w) => w.core)
      .toList();
  final pairs = alignWordLists(kemWords, layCores);
  final used = <String>{};
  final tmp = <RenderWord>[];
  for (final p in pairs) {
    if (p.lay.isEmpty) continue;
    String location = '';
    String digits = stripVerseNumber(p.lay).digits;
    for (final w in layList) {
      if (w.core == p.lay && !used.contains(w.location)) {
        location = w.location;
        digits = w.digits;
        used.add(w.location);
        break;
      }
    }
    List<RenderSeg>? segs;
    if (p.kem.isNotEmpty) {
      KemWordEntry? kw;
      for (final k in kemWords) {
        if (k.start == p.kemStart && k.text == p.kem) {
          kw = k;
          break;
        }
      }
      if (kw != null) {
        segs = _colorizePair(p.lay, kw.text, kw.start, kemSlices);
        segs ??= _segsOf(
          p.lay,
          majorityClass(kemSlices, kw.start, kw.start + kw.text.length),
        );
      } else {
        segs = _segsOf(p.lay, '');
      }
    } else {
      segs = _segsOf(p.lay, '');
    }
    tmp.add(RenderWord(segs: segs, digits: digits, location: location));
  }
  final ordered = <RenderWord>[];
  var cursor = 0;
  for (final w in layWords) {
    final d = stripVerseNumber(w.raw);
    if (isMarkOnly(d.core)) {
      ordered.add(
        RenderWord(
          segs: _segsOf(d.core, ''),
          digits: d.digits,
          location: w.location,
        ),
      );
      continue;
    }
    if (cursor < tmp.length) {
      final r = tmp[cursor++];
      ordered.add(
        RenderWord(segs: r.segs, digits: d.digits, location: w.location),
      );
    } else {
      ordered.add(
        RenderWord(
          segs: _segsOf(d.core, ''),
          digits: d.digits,
          location: w.location,
        ),
      );
    }
  }
  return ordered;
}
