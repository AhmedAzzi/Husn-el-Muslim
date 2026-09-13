import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:small_husn_muslim/core/constants/strings.dart';

/// The single AppBar definition for the whole app.
///
/// Guarantees on every page, in both light and dark themes:
/// - background = theme AppBar color with the shared [appBarBG] artwork
///   washed over it (dimmed so the title stays readable in both themes),
/// - title, icons and actions = theme AppBar foreground,
/// - title in Amiri 22 bold, start-aligned (right side under the app-wide
///   RTL direction),
/// - no elevation.
///
/// Two modes:
/// - [HusnAppBar] — main sections. Leading is automatic: the drawer
///   hamburger when the Scaffold owns a drawer.
/// - [HusnAppBar.back] — secondary/detail screens. Leading is the standard
///   back button, with an optional [onBack] override (e.g. stop audio before
///   popping).
///
/// [titleWidget] covers search-field bars; [actions] and [bottom] pass
/// straight through to the underlying [AppBar].
class HusnAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const HusnAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  HusnAppBar.back({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    VoidCallback? onBack,
  })  : leading = _HusnBackButton(onBack: onBack),
        automaticallyImplyLeading = false;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.appBarTheme.foregroundColor ?? Colors.white;
    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: fg,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                )),
      actions: actions,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(appBarBG),
            fit: BoxFit.cover,
            opacity: isDark ? 0.35 : 0.15,
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}

class _HusnBackButton extends StatelessWidget {
  final VoidCallback? onBack;

  const _HusnBackButton({this.onBack});

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    return IconButton(
      icon: Icon(Icons.arrow_back, color: fg),
      onPressed: onBack ?? () => Get.back(),
    );
  }
}
