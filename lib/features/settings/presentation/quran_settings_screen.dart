import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/husn_app_bar.dart';
import '../../../../core/widgets/settings_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../nakhtem/presentation/controllers/nakhtem_controller.dart';
import '../../nakhtem/presentation/controllers/nakhtem_settings_controller.dart';
import '../../nakhtem/presentation/screens/khatma_home_screen.dart';
import '../../prayer_times/services/prayer_notification_helper.dart';
import '../settings_provider.dart';

/// Quran (Mushaf + Khatma) settings, hosted inside Husn-el-Muslim's
/// [SettingsScreen] as a sub-page.
///
/// Three groups, each with a single responsibility: narration (edition),
/// Khatma progress, and Mushaf display. Every setting appears exactly
/// once. Visuals reuse the shared [SettingsWidgets] like every other
/// settings page.
///
/// Note: the reciter is picked from the Mushaf audio sheets instead, so
/// it intentionally does not appear here.
class QuranSettingsScreen extends StatelessWidget {
  const QuranSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final mushafCtl = Get.find<SettingsController>();
    final khatmaCtl = Get.find<NakhtemSettingsController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: HusnAppBar.back(title: loc.stQuran),
          body: Obx(() {
            final m = mushafCtl.settings.value;
            final k = khatmaCtl.settings.value;
            final l = L10n.of(khatmaLang());
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Narration (edition) only. The reciter is chosen from
                  // the Mushaf audio sheets, not from settings.
                  SettingsWidgets.buildSectionHeader(
                    context: context,
                    title: l.t('narration'),
                    icon: Icons.volume_up_outlined,
                    color: const Color(0xFFC9A227),
                  ),
                  SettingsWidgets.buildCardContainer(
                    context: context,
                    children: [
                      _editionTile(khatmaCtl, k.edition, l),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Khatma progress: overlay, daily summary, reset.
                  SettingsWidgets.buildSectionHeader(
                    context: context,
                    title: 'الختمة',
                    icon: Icons.menu_book_outlined,
                    color: HusnTheme.primary,
                  ),
                  SettingsWidgets.buildCardContainer(
                    context: context,
                    children: [
                      SettingsWidgets.buildSwitchTile(
                        context: context,
                        icon: Icons.layers_outlined,
                        iconColor: HusnTheme.primary,
                        title: l.t('phone_experience'),
                        subtitle: l.t('overlay_lock_hint'),
                        value: k.overlayEnabled,
                        onChanged: (v) =>
                            _setOverlayEnabled(context, khatmaCtl, v),
                      ),
                      SettingsWidgets.buildDivider(context),
                      SettingsWidgets.buildSwitchTile(
                        context: context,
                        icon: Icons.summarize_outlined,
                        iconColor: HusnTheme.primary,
                        title: 'ملخص يومي',
                        subtitle: 'عرض ملخص القراءة مرة واحدة في اليوم',
                        value: k.showDailySummary,
                        onChanged: khatmaCtl.setShowDailySummary,
                      ),
                      SettingsWidgets.buildDivider(context),
                      ListTile(
                        onTap: () => confirmAndResetKhatma(context),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.delete_forever_outlined,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                        title: const Text(
                          'إعادة تعيين التقدم',
                          style: TextStyle(
                            fontFamily: HusnTheme.fontFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: const Text(
                          'مسح كل تقدم الختمة نهائياً',
                          style: TextStyle(
                            fontFamily: HusnTheme.fontFamily,
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Mushaf display: tajweed legend + word translation tab.
                  SettingsWidgets.buildSectionHeader(
                    context: context,
                    title: 'المصحف',
                    icon: Icons.auto_stories_outlined,
                    color: const Color(0xFF0EA5E9),
                  ),
                  SettingsWidgets.buildCardContainer(
                    context: context,
                    children: [
                      SettingsWidgets.buildSwitchTile(
                        context: context,
                        icon: Icons.legend_toggle_outlined,
                        iconColor: const Color(0xFF0EA5E9),
                        title: 'دليل ألوان التجويد',
                        subtitle: 'إظهار الدليل أسفل صفحات المصحف',
                        value: m.showLegend,
                        onChanged: (_) => mushafCtl.toggleLegend(),
                      ),
                      SettingsWidgets.buildDivider(context),
                      SettingsWidgets.buildSwitchTile(
                        context: context,
                        icon: Icons.translate,
                        iconColor: const Color(0xFF0EA5E9),
                        title: l.t('translation'),
                        subtitle: 'تبويب الترجمة في تفاصيل الكلمة',
                        value: k.translationEnabled,
                        onChanged: khatmaCtl.setTranslationEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // ---------- building blocks ----------

  /// Master overlay switch: persists the flag, applies it to the native
  /// unlock cache (dismissing any visible overlay when turned off), and —
  /// when turning on — guides the user to grant "display over other apps".
  Future<void> _setOverlayEnabled(
    BuildContext context,
    NakhtemSettingsController ctl,
    bool v,
  ) async {
    await ctl.setOverlayEnabled(v);
    try {
      await Get.find<NakhtemController>().syncOverlayCache();
    } catch (_) {}
    if (!v || !context.mounted) return;
    final granted = await PrayerNotificationHelper.checkOverlayPermission();
    if (granted) return;
    AppFeedback.getSnack(
      'السماح مطلوب',
      'فعّل السماح بالعرض فوق التطبيقات لتعمل الآية العائمة',
      type: AppFeedbackType.warn,
      duration: const Duration(seconds: 5),
    );
    await PrayerNotificationHelper.requestOverlayPermission();
  }

  Widget _editionTile(
    NakhtemSettingsController ctl,
    String edition,
    L10n l,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A227).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: Color(0xFFC9A227),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l.t('narration'),
                style: const TextStyle(
                  fontFamily: HusnTheme.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                  title: Text(
                    'حفص عن عاصم',
                    style: TextStyle(fontFamily: HusnTheme.fontFamily),
                  ),
                  dense: true,
                  activeColor: Color(0xFFD64463),
                ),
                RadioListTile<String>(
                  value: 'warsh',
                  title: Text(
                    'ورش عن نافع (يتطلب حزمة بيانات)',
                    style: TextStyle(fontFamily: HusnTheme.fontFamily),
                  ),
                  dense: true,
                  activeColor: Color(0xFFD64463),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
