import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/logic/quran_index.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/husn_style.dart';
import '../../../../core/widgets/islamic_ornaments.dart';
import '../controllers/nakhtem_controller.dart';
import '../controllers/nakhtem_settings_controller.dart';

/// Lets the user choose a (surah, ayah) to start a new khatma.
class StartAyahPickerScreen extends StatefulWidget {
  const StartAyahPickerScreen({super.key});

  @override
  State<StartAyahPickerScreen> createState() => _StartAyahPickerScreenState();
}

class _StartAyahPickerScreenState extends State<StartAyahPickerScreen> {
  final QuranIndex _index = QuranIndex.instance;

  int _selectedSurah = -1; // 1-based; -1 = "start of Quran"
  int _selectedAyah = 1;
  int _globalIndex = 1;

  void _chooseSurah(int surah) {
    setState(() {
      _selectedSurah = surah;
      _selectedAyah = 1;
      _globalIndex = _index.startOfSurah(surah);
    });
  }

  void _setAyah(int ayah, int surah) {
    setState(() {
      _selectedAyah = ayah;
      _selectedSurah = surah;
      _globalIndex = _index.globalIndex(surah, ayah) ?? _globalIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<NakhtemController>();
    final l = L10n.of(khatmaLang());
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.t('choose_start'),
            style: const TextStyle(
              fontFamily: HusnTheme.fontFamily,
              fontSize: HusnTheme.fontSize18,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: HusnTheme.primary,
        ),
        body: Column(
          children: [
            Expanded(
              child: _selectedSurah == -1 ? _surahList(dark) : _ayahList(dark),
            ),
            if (_selectedSurah != -1)
              Padding(
                padding: const EdgeInsets.all(12),
                child: _selectedCard(ctl, l),
              ),
          ],
        ),
      ),
    );
  }

  Widget _surahList(bool dark) {
    return ListView.builder(
      itemCount: _index.surahCount,
      itemBuilder: (context, i) {
        final m = _index.surahMeta(i + 1)!;
        return Column(
          children: [
            ListTile(
              leading: NumberMedallion(
                label: '${m.number}',
                ringColor: HusnTheme.primary,
                fillColor: dark ? HusnTheme.scaffoldDark : Colors.white,
                textColor: dark ? Colors.white : HusnTheme.primary,
              ),
              title: Text(
                m.nameAr,
                style: const TextStyle(
                  fontFamily: HusnTheme.fontFamily,
                  fontSize: HusnTheme.fontSize18,
                ),
              ),
              subtitle: Text(
                '${m.ayahCount} آية',
                style: const TextStyle(fontFamily: HusnTheme.fontFamily),
              ),
              trailing: Icon(
                Icons.chevron_left,
                color: dark ? Colors.grey[400] : Colors.grey,
              ),
              onTap: () => _chooseSurah(m.number),
            ),
            const Divider(height: 1, thickness: 0.3),
          ],
        );
      },
    );
  }

  Widget _ayahList(bool dark) {
    final m = _index.surahMeta(_selectedSurah)!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: dark ? Colors.white12 : Colors.black12,
              ),
            ),
          ),
          child: Text(
            m.nameAr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: HusnTheme.fontFamily,
              fontSize: HusnTheme.fontSize18,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: m.ayahCount,
            itemBuilder: (context, i) {
              final ayah = i + 1;
              final selected =
                  _selectedSurah == m.number && _selectedAyah == ayah;
              return Material(
                color: selected
                    ? HusnTheme.primary
                    : (dark ? Colors.white10 : Colors.black12),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _setAyah(ayah, m.number),
                  child: Center(
                    child: Text(
                      '$ayah',
                      style: TextStyle(
                        fontFamily: HusnTheme.fontFamily,
                        fontSize: HusnTheme.fontSize18,
                        color: selected ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _selectedCard(NakhtemController ctl, L10n l) {
    final m = _index.surahMeta(_selectedSurah)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.nameAr} • ${l.t('ayah')} $_selectedAyah',
                    style: const TextStyle(
                      fontFamily: HusnTheme.fontFamily,
                      fontSize: HusnTheme.fontSize18,
                    ),
                  ),
                  Text(
                    l.t('start'),
                    style: const TextStyle(
                      fontFamily: HusnTheme.fontFamily,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await ctl.startKhatma(
                  startingGlobalAyah: _globalIndex,
                  edition: Get.find<NakhtemSettingsController>()
                      .settings
                      .value
                      .edition,
                );
                if (!ok) return;
                Get.back();
              },
              child: Text(l.t('start')),
            ),
          ],
        ),
      ),
    );
  }
}
