import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:small_husn_muslim/features/prayer_times/services/prayer_notification_helper.dart';

/// Severity for transient feedback. Maps to one fixed Husn palette color —
/// call sites must use this instead of hardcoding their own background
/// colors, so every SnackBar / dialog in the app shares a single theme.
enum AppFeedbackType { info, success, warn, error }

/// Single entry point for all in-app transient alerts (SnackBar, dialogs,
/// GetX snackbars). Visual identity: floating rounded card, Amiri text,
/// direction-aware alignment, white-on-deep-color per severity.
class AppFeedback {
  const AppFeedback._();

  /// Fixed background per severity — the only alert colors in the app.
  static Color backgroundOf(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.info => const Color(0xFF693B42), // Husn burgundy
      AppFeedbackType.success => const Color(0xFF2E6B34), // deep green
      AppFeedbackType.warn => const Color(0xFF9A5B00), // deep amber
      AppFeedbackType.error => const Color(0xFF9B2C2C), // deep red
    };
  }

  static const _textStyle = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 15,
    color: Colors.white,
  );

  static TextAlign _alignOf(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
  }

  static SnackBar snackBar(
    BuildContext context,
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Severity background stays here; shape / behavior / text / action
    // colors come from SnackBarTheme so ad-hoc SnackBars match.
    final theme = Theme.of(context).snackBarTheme;
    final resolvedAction = action == null || action.textColor != null
        ? action
        : SnackBarAction(
            label: action.label,
            onPressed: action.onPressed,
            textColor: theme.actionTextColor ?? Colors.white,
          );
    return SnackBar(
      content: Text(
        message,
        textAlign: _alignOf(context),
        style: theme.contentTextStyle ?? _textStyle,
      ),
      backgroundColor: backgroundOf(type),
      behavior: theme.behavior ?? SnackBarBehavior.floating,
      shape: theme.shape,
      duration: duration,
      action: resolvedAction,
    );
  }

  /// Shows the themed SnackBar. One line replaces every ad-hoc
  /// `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` block.
  static void snack(
    BuildContext context,
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      snackBar(context, message, type: type, duration: duration, action: action),
    );
  }

  /// Themed confirmation/info dialog. Title + body in Amiri, actions built
  /// by [actionsBuilder] with the *dialog* context so pops target the
  /// dialog route even when dialogs nest; surface follows the current
  /// light/dark theme.
  static Future<T?> dialog<T>(
    BuildContext context, {
    required String title,
    required String content,
    List<Widget> Function(BuildContext dialogContext) actionsBuilder =
        _noActions,
  }) {
    final rtl =
        Directionality.of(context) == TextDirection.rtl;
    // Title / content / shape / surface come from DialogTheme so dark
    // mode contrast follows the active theme (AppFeedback only routes).
    final dialogTheme = Theme.of(context).dialogTheme;
    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          textAlign: rtl ? TextAlign.right : TextAlign.left,
          style: dialogTheme.titleTextStyle,
        ),
        content: Text(
          content,
          textAlign: rtl ? TextAlign.right : TextAlign.left,
          style: dialogTheme.contentTextStyle,
        ),
        actions: actionsBuilder(ctx),
      ),
    );
  }

  static List<Widget> _noActions(BuildContext _) => const [];

  /// Destructive confirm (clear logs, reset khatma, restore defaults).
  /// Single red-FilledButton scaffold replacing the `_confirmClear` clones
  /// (tracking ×3) and the khatma / custom-dikr restore variants.
  static Future<bool> confirmDestructive(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    required String cancelLabel,
    Key? confirmKey,
  }) async {
    final confirmed = await dialog<bool>(
      context,
      title: title,
      content: content,
      actionsBuilder: (dialogCtx) => [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: confirmKey,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9B2C2C)),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
    return confirmed ?? false;
  }

  /// The "Display over other apps" permission dialog, shared by every
  /// settings screen (was duplicated in general + notification settings).
  /// Returns true when the user taps activate (permission is requested),
  /// false on later/dismiss.
  static Future<bool?> overlayPermissionDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String laterLabel,
    required String activateLabel,
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.layers_rounded,
                color: Color(0xFFD64463), size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(body),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(laterLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD64463),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              PrayerNotificationHelper.requestOverlayPermission();
              Get.back(result: true);
            },
            child: Text(
              activateLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// GetX equivalent of [snack] for Get-controlled flows (fajr, khatma…).
  static void getSnack(
    String title,
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundOf(type),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
    );
  }
}

/// Guards an "enable floating reminder" toggle behind the
/// SYSTEM_ALERT_WINDOW permission: checks, shows the shared
/// [AppFeedback.overlayPermissionDialog] when missing, and returns whether
/// the caller may proceed. Replaces the guard clones in general +
/// notification settings.
class OverlayGate {
  const OverlayGate._();

  static Future<bool> ensure(
    BuildContext context, {
    required String title,
    required String body,
    required String laterLabel,
    required String activateLabel,
  }) async {
    final granted = await PrayerNotificationHelper.checkOverlayPermission();
    if (granted) return true;
    if (!context.mounted) return false;
    final proceed = await AppFeedback.overlayPermissionDialog(
      context,
      title: title,
      body: body,
      laterLabel: laterLabel,
      activateLabel: activateLabel,
    );
    return proceed == true;
  }
}

/// Shorthand for `AppFeedback.snack` inside a [State]: handles `mounted`.
extension SnackX on State {
  void snack(
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    AppFeedback.snack(context, message, type: type, duration: duration);
  }
}
