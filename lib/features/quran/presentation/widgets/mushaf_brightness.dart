import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Mushaf-only brightness plumbing.
///
/// The reader has its own paper toggle (`forceLight`): when on, the mushaf
/// and everything opened from it (tap dialogue, surah audio sheet, tajweed
/// guide, bookmarks, reciter picker, ayah search) stay light even if the app
/// is dark. Otherwise everything follows the app theme (historical behavior).

/// Effective darkness for a mushaf surface.
bool mushafDark(BuildContext context, {required bool forceLight}) =>
    !forceLight && Theme.of(context).brightness == Brightness.dark;

/// Wraps mushaf overlay content (bottom sheets, dialogs, pushed routes) so
/// every `Theme` lookup inside resolves to the mushaf brightness instead of
/// the app theme.
///
/// A bare [Theme] widget is NOT enough: body text inherits its color from
/// [DefaultTextStyle] (set by the route overlay from the app theme), so the
/// default style and icon theme are overridden too — otherwise dark-app
/// text stays light on the forced-light paper and becomes unreadable.
/// No-op when the toggle is off.
Widget mushafOverlayTheme({
  required bool forceLight,
  required Widget child,
}) {
  if (!forceLight) return child;
  return Theme(
    data: lightTheme,
    child: Builder(
      builder: (context) {
        return DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!,
          child: IconTheme(
            data: lightTheme.iconTheme,
            child: child,
          ),
        );
      },
    ),
  );
}
