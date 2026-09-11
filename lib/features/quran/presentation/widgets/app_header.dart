import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/husn_style.dart';
import '../../../settings/presentation/quran_settings_screen.dart';

/// Shared reader header, styled after Husn-el-Muslim detail screens:
/// burgundy background, light foreground, Amiri title.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.showBack = true});

  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: HusnTheme.primary,
      iconTheme: IconThemeData(color: bgLight),
      leading: (showBack && canPop)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        'القرآن الملوّن',
        style: TextStyle(
          fontSize: HusnTheme.fontSize18,
          fontFamily: HusnTheme.fontFamily,
          color: bgLight,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Get.to(() => const QuranSettingsScreen()),
        ),
      ],
    );
  }
}
