import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../data/models/reciter_model.dart';
import '../controllers/nakhtem_settings_controller.dart';

/// Selects the reciter used for ayah audio — a searchable bottom-sheet
/// selector (no separate page).
///
/// The list comes from the alquran.cloud API via [NakhtemSettingsController];
/// the bundled [ReciterCatalog.defaults] are shown while loading or offline.
/// Names follow the app language, and the search field filters by either name.
/// Tapping a reciter saves the selection into the [forKhatma] slot
/// (khatma overlay audio) or the mushaf slot (reader audio) and closes
/// the sheet. The two slots are fully independent.
Future<void> showReciterPickerSheet({required bool forKhatma}) {
  final isDark = Get.isDarkMode;
  final lang = khatmaLang();
  final l = L10n.of(lang);

  return Get.bottomSheet(
    Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.78),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E28) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.t('reciter'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: HusnTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _ReciterSheetBody(forKhatma: forKhatma),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

class _ReciterSheetBody extends StatefulWidget {
  const _ReciterSheetBody({required this.forKhatma});

  final bool forKhatma;

  @override
  State<_ReciterSheetBody> createState() => _ReciterSheetBodyState();
}

class _ReciterSheetBodyState extends State<_ReciterSheetBody> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Reciter r, String q) {
    if (q.isEmpty) return true;
    final query = q.trim().toLowerCase();
    return r.name.toLowerCase().contains(query) ||
        r.localizedName.contains(q.trim());
  }

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<NakhtemSettingsController>();
    final lang = khatmaLang();
    final l = L10n.of(lang);

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: lang == 'ar' ? 'ابحث عن القارئ' : l.t('reciter'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Obx(() {
              final s = ctl.settings.value;
              final currentId =
                  widget.forKhatma ? s.khatmaReciterId : s.mushafReciterId;
              final catalog =
                  ctl.reciters.where((r) => _matches(r, _query)).toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slim non-blocking bar (never a big spinner): the bundled
                  // list stays fully usable while the online list loads.
                  if (ctl.recitersLoading.value)
                    const LinearProgressIndicator(minHeight: 2),
                  if (!ctl.recitersLoading.value &&
                      ctl.recitersError.value != null)
                    ListTile(
                      leading: const Icon(Icons.cloud_off),
                      title: const Text('Offline list'),
                      subtitle: Text(ctl.recitersError.value!),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: ctl.loadReciters,
                      ),
                    ),
                  Flexible(
                    child: catalog.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                lang == 'ar'
                                    ? 'لا يوجد قارئ بهذا الاسم'
                                    : 'No reciter found',
                                style: const TextStyle(
                                  fontFamily: HusnTheme.fontFamily,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: catalog.length,
                            itemBuilder: (context, i) {
                              final r = catalog[i];
                              final subtitle = r.subtitleFor(lang);
                              return Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.volume_up,
                                      color: HusnTheme.primary,
                                    ),
                                    title: Text(
                                      r.titleFor(lang),
                                      style: const TextStyle(
                                        fontFamily: HusnTheme.fontFamily,
                                      ),
                                    ),
                                    subtitle: subtitle == null
                                        ? null
                                        : Text(subtitle),
                                    trailing: r.id == currentId
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      if (widget.forKhatma) {
                                        ctl.setKhatmaReciter(r.id);
                                      } else {
                                        ctl.setMushafReciter(r.id);
                                      }
                                      Get.back();
                                    },
                                  ),
                                  const Divider(
                                    height: 1,
                                    thickness: 0.3,
                                    indent: 56,
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
