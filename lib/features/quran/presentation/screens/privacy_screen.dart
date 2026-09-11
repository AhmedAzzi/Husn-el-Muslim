import 'package:flutter/material.dart';

import '../../../../core/theme/husn_style.dart';
import '../widgets/app_header.dart';

/// Port of `src/routes/privacy-policy/+page.svelte`.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سياسة الخصوصية للقرآن الملوّن',
                  style: TextStyle(
                    fontSize: HusnTheme.fontSize24,
                    fontWeight: FontWeight.bold,
                    fontFamily: HusnTheme.fontFamily,
                  ),
                ),
                SizedBox(height: 12),
                _Section(
                  title: 'جمع المعلومات واستخدامها',
                  body:
                      'لا نجمع أي معلومات تحدد الهوية الشخصية مباشرة من خلال التطبيق.',
                ),
                _Section(
                  title: 'بيانات السجل',
                  body:
                      'قد نجمع المعلومات التي يرسلها جهازك عند استخدام التطبيق ("بيانات السجل"). وقد تشمل بيانات السجل معلومات مثل عنوان بروتوكول الإنترنت (IP) الخاص بجهازك، واسم الجهاز، وإصدار نظام التشغيل.',
                ),
                _Section(
                  title: 'الأذونات',
                  body:
                      'قد يطلب التطبيق الوصول إلى بعض مزايا جهازك، مثل الوصول إلى التخزين لحفظ المحتوى المنزّل. هذه الأذونات لغرض تحسين تجربتك مع التطبيق فقط.',
                ),
                _Section(
                  title: 'خدمات الطرف الثالث',
                  body: 'هذا التطبيق لا يستخدم أي خدمات تابعة لطرف ثالث.',
                ),
                _Section(
                  title: 'الأمان',
                  body:
                      'نقدّر ثقتك بتزويدنا بمعلوماتك الشخصية، ولذلك نسعى لاستخدام وسائل مقبولة تجارياً لحمايتها.',
                ),
                _Section(
                  title: 'اتصل بنا',
                  body:
                      'إذا كانت لديك أي أسئلة أو اقتراحات حول سياسة الخصوصية، فلا تتردد في الاتصال بنا على kodepandaiofficial@gmail.com.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: HusnTheme.fontSize18,
              fontWeight: FontWeight.bold,
              fontFamily: HusnTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              fontFamily: HusnTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
