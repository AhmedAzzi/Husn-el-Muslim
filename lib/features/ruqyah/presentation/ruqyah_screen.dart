import 'package:flutter/material.dart';
import 'package:small_husn_muslim/core/widgets/husn_feedback_widgets.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/widgets/app_drawer.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
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
          // Main section inside MainShell: drawer hamburger only, no Back
          // button between main sections. Detail (RuqyahDetailScreen) keeps
          // its own Back button.
          drawer: const AppDrawer(),
          appBar: HusnAppBar(
            title: toggle ? context.loc.navRuqyah : null,
            titleWidget: toggle
                ? null
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
            actions: toggle ? _toggleSearchIcon() : _clearSearchAction(),
          ),
          body: _isLoading
              ? const HusnLoading()
              : _bookData == null
                  ? Center(
                      child: Text(
                        context.loc.rqLoadFailed,
                        style:
                            const TextStyle(fontFamily: 'Amiri', fontSize: 18),
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
      return HusnEmptySearch(
        message: context.loc.ctNoSearchResults,
        fontFamily: fontFamily,
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
              Icons.auto_stories_rounded,
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
