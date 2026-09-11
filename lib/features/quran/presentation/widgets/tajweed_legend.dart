import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/logic/ahkam.dart';
import '../../../../core/theme/husn_style.dart';
import '../../../../core/theme/tajweed_colors.dart';
import '../../../settings/settings_provider.dart';

/// Shows the Tajweed color legend as a modal bottom sheet.
Future<void> showTajweedLegendSheet(BuildContext context) async {
  final dark = Theme.of(context).brightness == Brightness.dark;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: dark ? AppPalette.darkCard : AppPalette.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 22,
                        color: dark ? bgLight : HusnTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'دليل ألوان التجويد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: HusnTheme.fontFamily,
                          color: dark ? bgLight : HusnTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 0.3),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final it in TajweedColors.legendItems)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: TajweedColors.of(it.cls, dark: dark),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ahkamAr(it.cls).isNotEmpty
                              ? ahkamAr(it.cls)
                              : it.sample,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'KemenagLPMQ',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'اضغط على أي كلمة ملوّنة في المصحف لعرض شرح الحكم',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: HusnTheme.fontFamily,
                  color: dark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Port of `TajweedLegend.svelte`: fixed bottom palette, collapsible.
/// Now powered by GetX.
class TajweedLegend extends StatelessWidget {
  const TajweedLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCtl = Get.find<SettingsController>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Obx(() {
                final showLegend = settingsCtl.settings.value.showLegend;
                return showLegend
                    ? Container(
                        decoration: BoxDecoration(
                          color: dark ? AppPalette.darkCard : AppPalette.paper,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          border: Border.all(
                            color: dark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5D9B8),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 24,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => settingsCtl.toggleLegend(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.palette_outlined,
                                            size: 18,
                                            color: dark
                                                ? bgLight
                                                : HusnTheme.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'دليل ألوان التجويد',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            fontFamily:
                                                HusnTheme.fontFamily,
                                            color: dark
                                                ? bgLight
                                                : HusnTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'إخفاء',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily:
                                                HusnTheme.fontFamily,
                                            color: dark
                                                ? Colors.grey[400]
                                                : HusnTheme.primary,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: Column(
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      for (final it
                                          in TajweedColors.legendItems)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: TajweedColors.of(
                                                  it.cls,
                                                  dark: dark,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.black12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              ahkamAr(it.cls).isNotEmpty
                                                  ? ahkamAr(it.cls)
                                                  : it.sample,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'KemenagLPMQ',
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'اضغط على أي كلمة ملوّنة في المصحف لعرض شرح الحكم',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: HusnTheme.fontFamily,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: dark
                                ? AppPalette.darkCard
                                : AppPalette.paper,
                            foregroundColor: dark
                                ? bgLight
                                : HusnTheme.primary,
                            side: const BorderSide(
                              color: HusnTheme.gold,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => settingsCtl.toggleLegend(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.palette_outlined, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'دليل الألوان',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: HusnTheme.fontFamily,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_up, size: 16),
                            ],
                          ),
                        ),
                      );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
