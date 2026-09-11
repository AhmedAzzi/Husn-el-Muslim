import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../data/models/khatma_models.dart';
import '../../domain/services/khatma_service.dart';
import '../controllers/nakhtem_controller.dart';

/// Shows all khatmas (active, paused, completed) and lets the user switch /
/// resume / pause / finish a pass.
class KhatmaBoardScreen extends StatelessWidget {
  const KhatmaBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<KhatmaService>();
    final l = L10n.of(khatmaLang());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.t('khatma'),
            style: const TextStyle(
              fontFamily: HusnTheme.fontFamily,
              fontSize: HusnTheme.fontSize18,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: HusnTheme.primary,
        ),
        body: FutureBuilder<List<dynamic>>(
          future: Future.wait([service.all(), service.active()]),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = (snap.data![0] as List).cast<Khatma>();
            final active = snap.data![1] as Khatma?;
            if (list.isEmpty) {
              return Center(child: Text(l.t('no_khatma')));
            }
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final k = list[i];
                final isActive = k.id == active?.id;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: Icon(
                      k.isCompleted ? Icons.task_alt : Icons.menu_book,
                      color: isActive
                          ? HusnTheme.primary
                          : Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      k.name,
                      style: const TextStyle(fontFamily: HusnTheme.fontFamily),
                    ),
                    subtitle: Text(
                      _subtitle(k),
                      style: const TextStyle(fontFamily: HusnTheme.fontFamily),
                    ),
                    trailing: isActive
                        ? const Icon(
                            Icons.radio_button_checked,
                            color: HusnTheme.primary,
                          )
                        : null,
                    onTap: () async {
                      if (!k.isCompleted) {
                        await service.setActive(k.id);
                        await Get.find<NakhtemController>().refresh();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _subtitle(Khatma k) {
    final status = k.isCompleted
        ? 'مكتملة'
        : (k.status == KhatmaStatus.paused ? 'مؤجلة' : 'نشطة');
    return '$status • ${k.versesRead} آية';
  }
}
