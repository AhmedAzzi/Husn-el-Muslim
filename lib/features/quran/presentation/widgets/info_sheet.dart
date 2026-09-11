import 'package:flutter/material.dart';

import '../../../../core/theme/husn_style.dart';

/// Port of `ModalInfo.svelte` (offline-safe: no GitHub fetch on mobile).
Future<void> showInfoSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const Directionality(
      textDirection: TextDirection.rtl,
      child: _InfoBody(),
    ),
  );
}

class _InfoBody extends StatefulWidget {
  const _InfoBody();

  @override
  State<_InfoBody> createState() => _InfoBodyState();
}

class _InfoBodyState extends State<_InfoBody> {
  var _tab = 'about';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'القرآن الملوّن',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: HusnTheme.fontSize18,
                fontFamily: HusnTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _tab = 'about'),
                    child: Text(
                      'من نحن',
                      style: TextStyle(
                        color: _tab == 'about'
                            ? HusnTheme.primary
                            : Colors.grey,
                        fontFamily: HusnTheme.fontFamily,
                        fontWeight: _tab == 'about'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _tab = 'changelog'),
                    child: Text(
                      'سجل التغييرات',
                      style: TextStyle(
                        color: _tab == 'changelog'
                            ? HusnTheme.primary
                            : Colors.grey,
                        fontFamily: HusnTheme.fontFamily,
                        fontWeight: _tab == 'changelog'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_tab == 'about')
              const Text(
                'هذا التطبيق مفتوح المصدر ويمكن استخدامه بحرية. بيانات السور والآيات مأخوذة من وزارة الشؤون الدينية الإندونيسية. التطبيق ما زال بعيداً عن الكمال، فإذا وجدت خطأً أو لديك اقتراح، يُرجى إرساله إلى مستودع GitHub الخاص بنا وسنصلحه في النسخة القادمة.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.8,
                  fontFamily: HusnTheme.fontFamily,
                ),
              )
            else
              const Text(
                'v0.7.1 — نسخة Flutter: نفس بيانات المصحف (604 صفحة) مع أحكام التجويد الملوّنة — تعمل دون إنترنت.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.8,
                  fontFamily: HusnTheme.fontFamily,
                ),
              ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.code, size: 22),
                SizedBox(width: 8),
                Text(
                  'Github / KodePandai',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: HusnTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
