import 'package:flutter/material.dart';
import 'package:small_husn_muslim/core/utils/share_helper.dart';
import 'package:small_husn_muslim/core/widgets/husn_app_bar.dart';
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
    ShareHelper.copyToClipboard(context, _fullText, message: context.loc.ctCopied);
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
    ShareHelper.shareText(
      fullText.toString(),
      subject: widget.treatment.title,
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: HusnAppBar.back(
            title: widget.treatment.title,
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