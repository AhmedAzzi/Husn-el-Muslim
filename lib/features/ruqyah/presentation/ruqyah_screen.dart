import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/theme/app_colors.dart';
import 'package:small_husn_muslim/core/widgets/islamic_ornaments.dart';
import 'package:small_husn_muslim/features/book/data/book_models.dart';
import 'package:small_husn_muslim/features/book/services/book_service.dart';
import 'package:small_husn_muslim/features/ruqyah/presentation/ruqyah_detail_screen.dart';
import 'package:small_husn_muslim/core/utils/l10n_ext.dart';

class RuqyahScreen extends StatefulWidget {
  const RuqyahScreen({super.key});

  @override
  State<RuqyahScreen> createState() => _RuqyahScreenState();
}

class _RuqyahScreenState extends State<RuqyahScreen> {
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

  String _stripDiacritics(String text) {
    return BookService.normalizeArabic(text);
  }

  IconData _getIconForTreatment(int id, String title) {
    final t = _stripDiacritics(title);
    if (t.contains('السحر')) {
      return Icons.shield_rounded;
    } else if (t.contains('العين')) {
      return Icons.visibility_rounded;
    } else if (t.contains('الجن') || t.contains('الصرع')) {
      return Icons.security_rounded;
    } else if (t.contains('النفسية') || t.contains('الصدر')) {
      return Icons.self_improvement_rounded;
    } else if (t.contains('القرحة') || t.contains('الجرح')) {
      return Icons.healing_rounded;
    } else if (t.contains('المصيبة') ||
        t.contains('الهم') ||
        t.contains('الكرب')) {
      return Icons.sentiment_satisfied_alt_rounded;
    } else if (t.contains('المريض')) {
      return Icons.health_and_safety_rounded;
    } else if (t.contains('النوم') || t.contains('القلق')) {
      return Icons.bedtime_rounded;
    } else if (t.contains('الحمى') || t.contains('اللسعة')) {
      return Icons.medication_rounded;
    } else if (t.contains('الغضب')) {
      return Icons.water_drop_rounded;
    } else if (t.contains('الحبة') || t.contains('العسل')) {
      return Icons.eco_rounded;
    } else if (t.contains('زمزم')) {
      return Icons.water_rounded;
    } else if (t.contains('القلوب')) {
      return Icons.favorite_rounded;
    }
    return Icons.auto_stories_rounded;
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
                      context.loc.navRuqyah,
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
                  ? Center(
                      child: Text(
                        context.loc.rqLoadFailed,
                        style: const TextStyle(
                            fontFamily: 'Amiri', fontSize: 18),
                      ),
                    )
                  : _buildTreatmentsList(),
        ),
      ),
    );
  }

  Widget _buildTreatmentsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final treatments = _bookData!.ruqyahSection.treatments.where((treatment) {
      if (BookService.matchesQuery(treatment.title, _searchQuery)) {
        return true;
      }
      return treatment.items
          .any((item) => BookService.matchesQuery(item, _searchQuery));
    }).toList();

    if (treatments.isEmpty) {
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
              context.loc.ctNoSearchResults,
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

    return Stack(
      children: [
        IslamicPattern(
          color: isDark ? Colors.white : IslamicPalette.burgundy,
        ),
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          itemCount: treatments.length,
          itemBuilder: (context, index) {
            final treatment = treatments[index];
            return _buildTreatmentCard(
              treatment,
              _getIconForTreatment(treatment.id, treatment.title),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTreatmentCard(RuqyahTreatment treatment, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: IslamicPalette.gold.withValues(alpha: isDark ? 0.3 : 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(() => RuqyahDetailScreen(treatment: treatment));
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        IslamicPalette.burgundyMid,
                        IslamicPalette.burgundyDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: IslamicPalette.gold.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: IslamicPalette.gold, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treatment.title,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            size: 15,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.loc.rqItems(treatment.items.length),
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: IslamicPalette.gold.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: IslamicPalette.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
