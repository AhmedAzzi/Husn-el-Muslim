import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../nakhtem/presentation/controllers/nakhtem_settings_controller.dart';
import '../../nakhtem/presentation/screens/khatma_home_screen.dart';
import '../../nakhtem/presentation/screens/reciter_picker_screen.dart';
import '../settings_provider.dart';

/// Quran (Mushaf + Khatma) settings, hosted inside Husn-el-Muslim's
/// [SettingsScreen] as a sub-page.
///
/// Only the settings the app actually reads are kept: the shared reciter,
/// the narration (edition) and the tajweed legend. Theme and language live
/// in Husn-el-Muslim's global settings.
class QuranSettingsScreen extends StatelessWidget {
  const QuranSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mushafCtl = Get.find<SettingsController>();
    final khatmaCtl = Get.find<NakhtemSettingsController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'إعدادات المصحف',
              style: TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: HusnTheme.fontSize18,
                color: Colors.white,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: HusnTheme.primary,
          ),
          body: Obx(() {
            final m = mushafCtl.settings.value;
            final k = khatmaCtl.settings.value;
            final l = L10n.of(khatmaLang());
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _sectionHeader('الختمة', Icons.menu_book_outlined),
                _group([
                  SwitchListTile(
                    secondary: const Icon(Icons.summarize_outlined),
                    title: const Text('ملخص يومي'),
                    subtitle: const Text('عرض ملخص القراءة مرة واحدة في اليوم'),
                    value: k.showDailySummary,
                    onChanged: khatmaCtl.setShowDailySummary,
                  ),
                ]),
                _sectionHeader('المصحف', Icons.auto_stories_outlined),
                _group([
                  // Independent from the khatma reciter above.
                  ListTile(
                    leading: const Icon(Icons.volume_up_outlined),
                    title: Text(l.t('reciter')),
                    subtitle: Text(_reciterName(khatmaCtl, forKhatma: false)),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => showReciterPickerSheet(forKhatma: false),
                  ),
                  _editionTile(khatmaCtl, k.edition, l),
                  SwitchListTile(
                    secondary: const Icon(Icons.summarize_outlined),
                    title: const Text('ملخص يومي'),
                    subtitle: const Text('عرض ملخص القراءة مرة واحدة في اليوم'),
                    value: k.showDailySummary,
                    onChanged: khatmaCtl.setShowDailySummary,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'إعادة تعيين التقدم',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('مسح كل تقدم الختمة نهائياً'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => confirmAndResetKhatma(context),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.translate),
                    title: Text(l.t('translation')),
                    subtitle: const Text('تبويب الترجمة في تفاصيل الكلمة'),
                    value: k.translationEnabled,
                    onChanged: khatmaCtl.setTranslationEnabled,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.legend_toggle_outlined),
                    title: const Text('دليل ألوان التجويد'),
                    subtitle: const Text('إظهار الدليل أسفل صفحات المصحف'),
                    value: m.showLegend,
                    onChanged: (_) => mushafCtl.toggleLegend(),
                  ),
                ]),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------- building blocks ----------

  Widget _sectionHeader(String title, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: HusnTheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HusnTheme.primary,
              ),
            ),
          ],
        ),
      );

  Widget _group(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(height: 1, thickness: 0.3, indent: 56),
              ],
            ],
          ),
        ),
      );

  Widget _editionTile(
    NakhtemSettingsController ctl,
    String edition,
    L10n l,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.record_voice_over_outlined),
          title: Text(l.t('narration')),
        ),
        RadioGroup<String>(
          groupValue: edition,
          onChanged: (v) {
            if (v != null) ctl.setEdition(v);
          },
          child: const Column(
            children: [
              RadioListTile<String>(
                value: 'hafs',
                title: Text('حفص عن عاصم'),
                dense: true,
              ),
              RadioListTile<String>(
                value: 'warsh',
                title: Text('ورش عن نافع (يتطلب حزمة بيانات)'),
                dense: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _reciterName(NakhtemSettingsController ctl,
      {required bool forKhatma}) {
    final r = forKhatma ? ctl.selectedKhatmaReciter : ctl.selectedMushafReciter;
    if (r == null) {
      return khatmaLang() == 'ar' ? 'حدد القارئ' : 'Select reciter';
    }
    return r.titleFor(khatmaLang());
  }
}
