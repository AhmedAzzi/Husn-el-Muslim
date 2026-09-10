import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:small_husn_muslim/core/constants/strings.dart';
import 'package:small_husn_muslim/core/theme/app_colors.dart';
import 'package:small_husn_muslim/core/widgets/islamic_ornaments.dart';
import 'package:small_husn_muslim/features/book/data/book_models.dart';
import 'package:small_husn_muslim/core/utils/l10n_ext.dart';

class RuqyahDetailScreen extends StatefulWidget {
  final RuqyahTreatment treatment;

  const RuqyahDetailScreen({super.key, required this.treatment});

  @override
  State<RuqyahDetailScreen> createState() => _RuqyahDetailScreenState();
}

class _RuqyahDetailScreenState extends State<RuqyahDetailScreen> {
  String get _fullText => widget.treatment.items.join('\n\n');

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: _fullText)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              context.loc.ctCopied,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _shareAll() {
    final fullText = StringBuffer();
    fullText.writeln(widget.treatment.title);
    fullText.writeln('--------------------');
    for (var item in widget.treatment.items) {
      fullText.writeln(item);
      fullText.writeln();
    }
    fullText.writeln('من كتاب: الدعاء ويليه العلاج بالرقى من الكتاب والسنة');
    SharePlus.instance.share(
      ShareParams(
        text: fullText.toString(),
        subject: widget.treatment.title,
      ),
    );
  }

  bool _isQuranicOrHadith(String text) {
    return text.contains('﴿') ||
        text.contains('﴾') ||
        text.contains('{') ||
        text.contains('}') ||
        text.contains('«') ||
        text.contains('»') ||
        text.contains('((') ||
        text.contains('))');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? IslamicPalette.gold : IslamicPalette.burgundy;

    return SafeArea(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
            title: Text(
              widget.treatment.title,
              style: TextStyle(
                fontSize: double.parse(fontSize18),
                fontFamily: fontFamily,
                color: bgLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            iconTheme: IconThemeData(color: bgLight),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: context.loc.ctCopyAll,
                onPressed: _copyAll,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: context.loc.ctShareAll,
                onPressed: _shareAll,
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(appBarBG),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              IslamicPattern(
                color: isDark ? Colors.white : IslamicPalette.burgundy,
              ),
              ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                children: [
                  const OrnamentalDivider(color: IslamicPalette.burgundy),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      widget.treatment.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const OrnamentalDivider(color: IslamicPalette.burgundy),
                  const SizedBox(height: 20),
                  for (final item in widget.treatment.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        item,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: _isQuranicOrHadith(item) ? 21 : 19,
                          height: 1.9,
                          fontWeight: _isQuranicOrHadith(item)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}