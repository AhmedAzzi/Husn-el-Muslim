import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/theme/app_colors.dart';
import 'package:small_husn_muslim/core/widgets/islamic_ornaments.dart';
import 'package:small_husn_muslim/features/book/data/book_models.dart';
import 'package:small_husn_muslim/features/book/services/book_service.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  bool toggle = true;
  String _searchQuery = '';

  BookData? _bookData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await BookService().getBookData();
      if (mounted) {
        setState(() {
          _bookData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text,
      {String message = 'تم نسخ الدعاء إلى الحافظة'}) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              message,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _shareText(String text, String subject) {
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }

  List<Widget> _clearSearchAction() {
    return [
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() {
          searchController.clear();
          _searchQuery = '';
          toggle = true;
        }),
      ),
    ];
  }

  List<Widget> _toggleSearchIcon() {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() {
            toggle = false;
          }),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            leading: toggle
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  )
                : null,
            title: toggle
                ? SizedBox(
                    height: 30,
                    child: Text(
                      'الدعاء',
                      style: TextStyle(
                        fontSize: double.parse(fontSize22),
                        fontFamily: fontFamily,
                        color: bgLight,
                      ),
                    ),
                  )
                : Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: fontFamily,
                          fontSize: 16,
                        ),
                        hintText: search,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Amiri',
                        fontSize: 18,
                      ),
                    ),
                  ),
            iconTheme: IconThemeData(color: bgLight),
            actions: toggle ? _toggleSearchIcon() : _clearSearchAction(),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(appBarBG),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bookData == null
                  ? const Center(
                      child: Text(
                        'تعذر تحميل بيانات الأدعية',
                        style: TextStyle(fontFamily: 'Amiri', fontSize: 18),
                      ),
                    )
                  : _buildDuaList(),
        ),
      ),
    );
  }

  Widget _buildDuaList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionAccent =
        isDark ? IslamicPalette.gold : IslamicPalette.burgundy;
    final duaSection = _bookData!.duaSection;

    final filteredQuranic = duaSection.quranicDuas.where((dua) {
      return BookService.matchesQuery(dua.text, _searchQuery);
    }).toList();

    final filteredSunnah = duaSection.sunnahDuas.where((dua) {
      return BookService.matchesQuery(dua.text, _searchQuery);
    }).toList();

    final filteredVirtues = duaSection.virtues.items
        .where((item) => BookService.matchesQuery(item, _searchQuery))
        .toList();
    final filteredAdab = duaSection.adab.items
        .where((item) => BookService.matchesQuery(item, _searchQuery))
        .toList();
    final filteredTimes = duaSection.times.items
        .where((item) => BookService.matchesQuery(item, _searchQuery))
        .toList();

    final hasContent = filteredQuranic.isNotEmpty ||
        filteredSunnah.isNotEmpty ||
        filteredVirtues.isNotEmpty ||
        filteredAdab.isNotEmpty ||
        filteredTimes.isNotEmpty;

    if (!hasContent) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        IslamicPattern(
          color: isDark ? Colors.white : IslamicPalette.burgundy,
        ),
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          children: [
            if (filteredQuranic.isNotEmpty) ...[
              OrnamentalSectionTitle(
                title: 'أدعية القرآن الكريم',
                accentColor: sectionAccent,
                compact: true,
              ),
              ...filteredQuranic.map((dua) => _buildDuaCard(
                    number: dua.number,
                    text: dua.text,
                    categoryBadge: 'قرآن كريم',
                    isQuran: true,
                  )),
              const SizedBox(height: 12),
            ],
            if (filteredSunnah.isNotEmpty) ...[
              OrnamentalSectionTitle(
                title: 'أدعية السنة النبوية',
                accentColor: sectionAccent,
                compact: true,
              ),
              ...filteredSunnah.map((dua) => _buildDuaCard(
                    number: dua.number,
                    text: dua.text,
                    categoryBadge: 'سنة نبوية',
                    isQuran: false,
                  )),
              const SizedBox(height: 12),
            ],
            if (filteredVirtues.isNotEmpty ||
                filteredAdab.isNotEmpty ||
                filteredTimes.isNotEmpty) ...[
              OrnamentalSectionTitle(
                title: 'فضل وآداب الدعاء',
                accentColor: sectionAccent,
                compact: true,
              ),
              if (filteredVirtues.isNotEmpty) ...[
                ...filteredVirtues
                    .asMap()
                    .entries
                    .map((e) => _buildTextItemCard(
                          index: e.key + 1,
                          text: e.value,
                        )),
                const SizedBox(height: 8),
              ],
              if (filteredAdab.isNotEmpty) ...[
                ...filteredAdab.asMap().entries.map((e) => _buildTextItemCard(
                      index: e.key + 1,
                      text: e.value,
                    )),
                const SizedBox(height: 8),
              ],
              if (filteredTimes.isNotEmpty) ...[
                ...filteredTimes.asMap().entries.map((e) => _buildTextItemCard(
                      index: e.key + 1,
                      text: e.value,
                    )),
              ],
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDuaCard({
    required int number,
    required String text,
    required String categoryBadge,
    required bool isQuran,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? IslamicPalette.gold : IslamicPalette.burgundy;
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF3A3A3A);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.25 : 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryBadge,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
                const Spacer(),
                _buildSoftIconButton(
                  Icons.copy_rounded,
                  () => _copyToClipboard(text),
                ),
                const SizedBox(width: 6),
                _buildSoftIconButton(
                  Icons.share_rounded,
                  () => _shareText(text, 'دعاء رقم $number'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 5, 14, 14),
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: isQuran ? 19 : 17,
                height: 1.7,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftIconButton(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? IslamicPalette.gold : IslamicPalette.burgundy;
    return Material(
      color: accent.withValues(alpha: 0.07),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: accent),
        ),
      ),
    );
  }

  Widget _buildTextItemCard({
    required int index,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? IslamicPalette.gold : IslamicPalette.burgundy;
    final textColor =
        isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF3A3A3A);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.3 : 0.22),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: NumberMedallion(
              label: '$index',
              ringColor: IslamicPalette.gold,
              fillColor: accent.withValues(alpha: 0.08),
              textColor: accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    height: 1.6,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'نسخ',
                    onPressed: () => _copyToClipboard(text),
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد نتائج مطابقة للبحث',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
