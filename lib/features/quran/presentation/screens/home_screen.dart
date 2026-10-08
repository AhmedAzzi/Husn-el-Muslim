import 'dart:async';

import 'package:flutter/material.dart';
import 'package:small_husn_muslim/core/widgets/husn_feedback_widgets.dart';
import 'package:get/get.dart';

import '../../../../core/logic/quran_index.dart';
import '../../../../core/theme/husn_style.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/husn_app_bar.dart';
import '../../../../core/widgets/islamic_ornaments.dart';
import '../../data/models/quran_models.dart';
import '../providers/ayah_search_controller.dart';
import '../providers/quran_providers.dart';
import 'mushaf_screen.dart';

/// Surah index, styled after Husn-el-Muslim's `MyHomePageScreen`:
/// image-header AppBar with toggleable search, then a plain
/// `ListTile` + thin-divider list — powered by GetX.
// Batch 2 (perf-only): compiled once; the filter runs it per surah per build.
final RegExp _digitsOnly = RegExp(r'^\d+$');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Debounced so the 114-row list isn't refiltered on every keystroke.
  void _onSearchChanged(String v, HomeFilterController filterCtl) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => filterCtl.setQuery(v),
    );
  }

  void _stopSearching(HomeFilterController filterCtl) {
    _debounce?.cancel();
    _searchController.clear();
    filterCtl.setQuery('');
    setState(() => _searching = false);
  }

  /// Arabic-Indic digits → Latin for surah-number search.
  static String _latinDigits(String v) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    return v.split('').map((c) {
      final i = arabic.indexOf(c);
      return i == -1 ? c : '$i';
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final quranCtl = Get.find<QuranController>();
    final filterCtl = Get.find<HomeFilterController>();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          // Main section inside MainShell: drawer is the primary navigation
          // between sections; detail (Mushaf reader) keeps its Back button.
          drawer: const AppDrawer(),
          appBar: HusnAppBar(
            title: _searching ? null : 'القرآن الملوّن',
            titleWidget: _searching
                ? Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                      child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      onChanged: (v) => _onSearchChanged(v, filterCtl),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: HusnTheme.fontFamily,
                          fontSize: 16,
                        ),
                        hintText: 'ابحث بالاسم أو الرقم',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: HusnTheme.fontFamily,
                        fontSize: 18,
                      ),
                    ),
                  )
                : null,
            // Single search action: while a query is present the button
            // clears it; once the field is empty it exits search mode.
            // (Previously a clear ✕ inside the field sat next to this ✕.)
            actions: _searching
                ? [
                    Obx(() {
                      final hasQuery = filterCtl.query.value.isNotEmpty;
                      return IconButton(
                        icon: Icon(hasQuery ? Icons.clear : Icons.close),
                        tooltip: hasQuery ? 'مسح البحث' : 'إغلاق البحث',
                        onPressed: () {
                          if (hasQuery) {
                            _debounce?.cancel();
                            _searchController.clear();
                            filterCtl.setQuery('');
                          } else {
                            _stopSearching(filterCtl);
                          }
                        },
                      );
                    }),
                  ]
                : [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: 'بحث',
                        onPressed: () => setState(() => _searching = true),
                      ),
                    ),
                  ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Obx(() {
                  if (quranCtl.isLoadingSurahs.value &&
                      quranCtl.surahs.value == null) {
                    return const HusnLoading();
                  }
                  if (quranCtl.surahsError.value != null &&
                      quranCtl.surahs.value == null) {
                    return Center(
                      child: Text(
                        'خطأ: ${quranCtl.surahsError.value}',
                        style: const TextStyle(
                          fontFamily: HusnTheme.fontFamily,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  final list = quranCtl.surahs.value ?? const [];
                  final rawQ = filterCtl.query.value.trim();
                  // Diacritic-insensitive on both sides: plain "الفاتحة"
                  // matches "ٱلْفَاتِحَة", "إبراهيم" matches "ابراهيم".
                  final q = AyahSearchController.normAr(rawQ.toLowerCase());
                  final numQ = _latinDigits(rawQ);
                  final scored = <({Surah s, int rank})>[];
                  for (final s in list) {
                    if (q.isEmpty) {
                      scored.add((s: s, rank: 3));
                      continue;
                    }
                    // Surah number (Latin or Arabic-Indic digits).
                    if (_digitsOnly.hasMatch(numQ) &&
                        s.id == int.tryParse(numQ)) {
                      scored.add((s: s, rank: 0));
                      continue;
                    }
                    final name = AyahSearchController.normAr(
                      s.suratName.toLowerCase(),
                    );
                    final text = AyahSearchController.normAr(s.suratText);
                    final meaning = AyahSearchController.normAr(
                      s.suratTerjemahan.toLowerCase(),
                    );
                    final starts = name.startsWith(q) ||
                        text.startsWith(q) ||
                        meaning.startsWith(q);
                    if (starts) {
                      scored.add((s: s, rank: 1));
                    } else if (name.contains(q) ||
                        text.contains(q) ||
                        meaning.contains(q)) {
                      scored.add((s: s, rank: 2));
                    }
                  }
                  scored.sort((a, b) {
                    final r = a.rank.compareTo(b.rank);
                    return r != 0 ? r : a.s.id.compareTo(b.s.id);
                  });
                  final filtered = [for (final e in scored) e.s];
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'لم يتم العثور على السورة',
                        style: TextStyle(
                          fontFamily: HusnTheme.fontFamily,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final surah = filtered[index];
                      final page = resolveSurahPage(quranCtl, surah.id);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            minLeadingWidth: 0,
                            minVerticalPadding: 2,
                            leading: NumberMedallion(
                              label: '${surah.id}',
                              size: 30,
                              ringColor: HusnTheme.primary,
                              fillColor:
                                  dark ? HusnTheme.scaffoldDark : Colors.white,
                              textColor: dark ? bgLight : HusnTheme.primary,
                            ),
                            title: Text(
                              QuranIndex.instance.surahMeta(surah.id)?.nameAr ??
                                  surah.suratText,
                              style: const TextStyle(
                                fontSize: HusnTheme.fontSize18,
                                fontWeight: FontWeight.w600,
                                fontFamily: HusnTheme.fontFamily,
                              ),
                            ),
                            subtitle: Text(
                              page > 0
                                  ? '${surah.countAyat} آية • صفحة $page'
                                  : '${surah.countAyat} آية',
                              style: const TextStyle(
                                fontFamily: HusnTheme.fontFamily,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: dark ? Colors.grey[400] : Colors.grey,
                            ),
                            onTap: () async {
                              // Never guess: if the index isn't ready yet,
                              // retry loading it instead of opening page 1.
                              var target = page;
                              if (target <= 0) {
                                await quranCtl.loadMeta();
                                if (!context.mounted) return;
                                target = resolveSurahPage(quranCtl, surah.id);
                              }
                              if (target <= 0) {
                                if (!context.mounted) return;
                                AppFeedback.snack(
                                  context,
                                  'تعذّر فتح السورة',
                                  type: AppFeedbackType.error,
                                );
                                return;
                              }
                              Get.to(() => MushafScreen(initialPage: target));
                            },
                          ),
                          const Divider(height: 1, thickness: 0.3),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First page of [surahId]: ayah index first, surah-start index as backup.
/// Returns 0 when the mushaf index isn't loaded (callers retry instead of
/// opening the wrong page).
int resolveSurahPage(QuranController quranCtl, int surahId) {
  final meta = quranCtl.meta.value;
  if (meta == null) return 0;
  return meta.aya['$surahId:1'] ?? meta.start['$surahId'] ?? 0;
}


