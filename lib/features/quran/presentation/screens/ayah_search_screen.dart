import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/logic/quran_index.dart';
import '../../../../core/theme/husn_style.dart';
import '../providers/ayah_search_controller.dart';
import 'mushaf_screen.dart';

/// Smart offline ayah search: diacritic-insensitive full text, multi-word
/// AND with phrase-first ranking, and direct `surah:ayah` references.
/// Tapping a hit opens the mushaf page at that ayah.
class AyahSearchScreen extends StatefulWidget {
  const AyahSearchScreen({super.key, this.onPick});

  /// When set (mushaf reader), picking a hit calls this with the page and
  /// pops back instead of pushing a new reader route.
  final void Function(int page)? onPick;

  @override
  State<AyahSearchScreen> createState() => _AyahSearchScreenState();
}

class _AyahSearchScreenState extends State<AyahSearchScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    ensureAyahSearchController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<AyahSearchController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: ctl.setQuery,
              textInputAction: TextInputAction.search,
              onSubmitted: ctl.search,
              decoration: InputDecoration(
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontFamily: HusnTheme.fontFamily,
                  fontSize: 16,
                ),
                hintText: 'ابحث بنص الآية أو بالرقم (2:255)',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                suffixIcon: Obx(
                  () => ctl.query.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            _search.clear();
                            ctl.setQuery('');
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: HusnTheme.fontFamily,
                fontSize: 18,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: HusnTheme.primary,
        ),
        body: Obx(() {
          if (ctl.isLoading.value && ctl.hits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!ctl.hasSearched.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'ابحث بكلمة أو جملة من القرآن\nأو اكتب رقم الآية مثل 2:255',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: HusnTheme.fontFamily,
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.8,
                  ),
                ),
              ),
            );
          }
          if (ctl.hits.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد نتائج',
                style: TextStyle(
                  fontFamily: HusnTheme.fontFamily,
                  fontSize: 18,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: ctl.hits.length,
            itemBuilder: (context, i) {
              final h = ctl.hits[i];
              final surahName =
                  QuranIndex.instance.surahMeta(h.surah)?.nameAr ?? '';
              return Column(
                children: [
                  ListTile(
                    title: _highlightedText(h.text, ctl.query.value),
                    subtitle: Text(
                      '$surahName · آية ${h.ayah}${h.page > 0 ? ' · صفحة ${h.page}' : ''}',
                      style: const TextStyle(
                        fontFamily: HusnTheme.fontFamily,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey,
                    ),
                    onTap: h.page <= 0
                        ? null
                        : () {
                            final pick = widget.onPick;
                            if (pick != null) {
                              pick(h.page);
                              Get.back();
                            } else {
                              Get.to(
                                () => MushafScreen(initialPage: h.page),
                              );
                            }
                          },
                  ),
                  const Divider(height: 1, thickness: 0.3),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  /// Ayah text with every query word highlighted (word-level, so tashkeel
  /// never breaks the match positions).
  Widget _highlightedText(String text, String query) {
    final tokens = AyahSearchController.normAr(query)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();
    final words = text.split(' ');
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'KemenagLPMQ',
          fontSize: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          for (var i = 0; i < words.length; i++) ...[
            if (i > 0) const TextSpan(text: ' '),
            TextSpan(
              text: words[i],
              style: TextStyle(
                backgroundColor: tokens.isNotEmpty &&
                        tokens.any(
                          (t) => AyahSearchController.normAr(words[i])
                              .contains(t),
                        )
                    ? HusnTheme.gold.withValues(alpha: 0.35)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
