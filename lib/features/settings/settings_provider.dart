import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A saved spot in the mushaf: either a whole page (`surah == 0`) or one
/// ayah (`surah > 0`). Ayah bookmarks resolve their page lazily through
/// `MushafMeta.aya` when listed.
class MushafBookmark {
  const MushafBookmark({
    required this.surah,
    required this.ayah,
    this.page = 0,
  });

  factory MushafBookmark.page(int page) =>
      MushafBookmark(surah: 0, ayah: 0, page: page);

  factory MushafBookmark.ayah(int surah, int ayah) =>
      MushafBookmark(surah: surah, ayah: ayah);

  factory MushafBookmark.fromJson(Map<String, dynamic> json) => MushafBookmark(
        surah: (json['s'] as num?)?.toInt() ?? 0,
        ayah: (json['a'] as num?)?.toInt() ?? 0,
        page: (json['p'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toJson() => {'s': surah, 'a': ayah, 'p': page};

  final int surah;
  final int ayah;
  final int page;

  String get id => surah > 0 ? 'a:$surah:$ayah' : 'p:$page';

  bool get isPage => surah <= 0;

  bool isAyahOf(int s, int a) => surah == s && ayah == a;

  bool isPageOf(int p) => isPage && page == p;

  @override
  bool operator ==(Object other) => other is MushafBookmark && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Mushaf display settings + bookmarks, persisted in SharedPreferences.
///
/// Only what the reader actually consumes is kept: the tajweed legend flag
/// and the bookmark list. Theme and language live in Husn-el-Muslim's global
/// settings.
class AppSettings {
  const AppSettings({
    this.showLegend = true,
  });

  final bool showLegend;

  AppSettings copyWith({
    bool? showLegend,
  }) =>
      AppSettings(
        showLegend: showLegend ?? this.showLegend,
      );
}

class SettingsController extends GetxController {
  SettingsController(this._prefs);

  final SharedPreferences _prefs;

  /// Reactive settings state (replaces Riverpod's StateNotifierProvider).
  final settings = const AppSettings().obs;

  /// Saved pages + ayahs (the "super bookmark"), newest first.
  final bookmarks = <MushafBookmark>[].obs;

  bool get showLegend => settings.value.showLegend;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    try {
      settings.value = AppSettings(
        showLegend: _prefs.getBool('showLegend') ?? true,
      );
      bookmarks.value = _decodeBookmarks(_prefs.getString('bookmarks_json'));
    } catch (_) {
      // keep defaults
    }
  }

  static List<MushafBookmark> _decodeBookmarks(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [
        for (final e in list)
          if (e is Map<String, dynamic>) MushafBookmark.fromJson(e),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() async {
    final s = settings.value;
    await _prefs.setBool('showLegend', s.showLegend);
    await _prefs.setString(
      'bookmarks_json',
      jsonEncode([for (final b in bookmarks) b.toJson()]),
    );
  }

  Future<void> toggleLegend() async {
    settings.value = settings.value.copyWith(
      showLegend: !settings.value.showLegend,
    );
    await _persist();
  }

  bool isPageBookmarked(int page) => bookmarks.any((b) => b.isPageOf(page));

  bool isAyahBookmarked(int surah, int ayah) =>
      bookmarks.any((b) => b.isAyahOf(surah, ayah));

  /// Toggles a whole-page bookmark. Returns true when added.
  Future<bool> togglePageBookmark(int page) async {
    final i = bookmarks.indexWhere((b) => b.isPageOf(page));
    if (i >= 0) {
      bookmarks.removeAt(i);
      await _persist();
      return false;
    }
    bookmarks.insert(0, MushafBookmark.page(page));
    await _persist();
    return true;
  }

  /// Toggles one ayah bookmark. Returns true when added.
  Future<bool> toggleAyahBookmark(int surah, int ayah) async {
    final i = bookmarks.indexWhere((b) => b.isAyahOf(surah, ayah));
    if (i >= 0) {
      bookmarks.removeAt(i);
      await _persist();
      return false;
    }
    bookmarks.insert(0, MushafBookmark.ayah(surah, ayah));
    await _persist();
    return true;
  }

  Future<void> removeBookmark(String id) async {
    bookmarks.removeWhere((b) => b.id == id);
    await _persist();
  }
}
