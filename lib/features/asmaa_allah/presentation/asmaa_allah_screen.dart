import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/theme/app_colors.dart';
import 'package:small_husn_muslim/core/widgets/islamic_ornaments.dart';
import 'package:small_husn_muslim/features/book/data/book_models.dart';
import 'package:small_husn_muslim/features/book/services/book_service.dart';

class AsmaaAllahScreen extends StatefulWidget {
  const AsmaaAllahScreen({super.key});

  @override
  State<AsmaaAllahScreen> createState() => _AsmaaAllahScreenState();
}

class _CutePalette {
  final Color lightBg1;
  final Color lightBg2;
  final Color accent;

  const _CutePalette(this.lightBg1, this.lightBg2, this.accent);
}

const _cutePalettes = [
  _CutePalette(Color(0xFFFFEDF0), Color(0xFFFFE3E8), Color(0xFFD6587A)),
  _CutePalette(Color(0xFFFFF2E4), Color(0xFFFFE8D1), Color(0xFFE0732F)),
  _CutePalette(Color(0xFFF0EAFF), Color(0xFFE5DBFF), Color(0xFF8B5CF6)),
  _CutePalette(Color(0xFFE3F9F0), Color(0xFFD3F2E4), Color(0xFF1E9E75)),
  _CutePalette(Color(0xFFE5F2FF), Color(0xFFD4E9FA), Color(0xFF3B82D9)),
  _CutePalette(Color(0xFFFFF8E1), Color(0xFFFFF0C0), Color(0xFFC48A1B)),
  _CutePalette(Color(0xFFFDEEF1), Color(0xFFFFE3E6), Color(0xFFE2576E)),
];

class _AsmaaAllahScreenState extends State<AsmaaAllahScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  bool toggle = true;
  String _searchQuery = '';
  List<AllahName> _names = [];
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
          _names = data.asmaAllahHusna;
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

  void _copyToClipboard(String text, {String message = 'تم النسخ ✿'}) {
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
    final filteredNames = _names.where((name) {
      return BookService.matchesQuery(name.name, _searchQuery);
    }).toList();

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
                      'أسماء الله الحسنى',
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
              : filteredNames.isEmpty
                  ? _buildEmptyState()
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeaderBanner()),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            delegate:
                                SliverChildBuilderDelegate((context, index) {
                              return _buildNameCard(
                                  filteredNames[index], index);
                            }, childCount: filteredNames.length),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E4E5C),
            Color(0xFF6A3444),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IslamicPalette.gold.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF693B42).withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 16,
                color: IslamicPalette.gold,
              ),
              const SizedBox(width: 6),
              const Text(
                'أسماء الله الحسنى',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.favorite_rounded,
                size: 16,
                color: IslamicPalette.gold,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'قُلِ ادْعُوا اللَّهَ أَوِ ادْعُوا الرَّحْمَٰنَ ۖ أَيًّا مَا تَدْعُوا فَلَهُ الْأَسْمَاءُ الْحُسْنَىٰ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: Color(0xFFFBE9EC),
            ),
          ),
          const SizedBox(height: 8),
          OrnamentalDivider(color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 12,
                color: IslamicPalette.gold.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Text(
                'اضغط للعرض، اضغط مطولة للنسخ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.favorite_rounded,
                size: 12,
                color: IslamicPalette.gold.withValues(alpha: 0.9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard(AllahName entry, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = entry.name;
    final palette = _cutePalettes[index % _cutePalettes.length];
    final accent = palette.accent;
    final bg1 = isDark
        ? accent.withValues(alpha: 0.22)
        : palette.lightBg1;
    final bg2 = isDark
        ? accent.withValues(alpha: 0.08)
        : palette.lightBg2;
    final textColor = isDark ? Colors.white : const Color(0xFF3A2E35);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg1, bg2],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMeaningDialog(entry, index),
          onLongPress: () => _copyToClipboard(
            'يا $name',
            message: 'يا $name ✿',
          ),
          child: Stack(
            children: [
              Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 8,
                  color: accent.withValues(alpha: 0.5),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 7,
                  color: accent.withValues(alpha: 0.4),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMeaningDialog(AllahName entry, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _cutePalettes[index % _cutePalettes.length];
    final accent = palette.accent;
    void dismiss() => Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        accent,
                        Theme.of(context).cardColor,
                      ]
                    : [palette.lightBg1, palette.lightBg2],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(height: 8),
                Text(
                  entry.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF3A2E35),
                  ),
                ),
                const SizedBox(height: 14),
                OrnamentalDivider(color: accent.withValues(alpha: 0.5)),
                const SizedBox(height: 14),
                Text(
                  entry.meaning,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 17,
                    height: 1.6,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF3A3A3A),
                  ),
                ),
                if (entry.source.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      entry.source,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSoftButton(
                      icon: Icons.copy_rounded,
                      label: 'نسخ',
                      onTap: () {
                        dismiss();
                        _copyToClipboard('يا ${entry.name}',
                            message: 'يا ${entry.name} ✿');
                      },
                      accent: accent,
                    ),
                    const SizedBox(width: 14),
                    _buildSoftButton(
                      icon: Icons.close,
                      label: 'إغلاق',
                      onTap: dismiss,
                      accent: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoftButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return Material(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
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