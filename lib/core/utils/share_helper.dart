import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:small_husn_muslim/core/widgets/app_feedback.dart';

/// Single entry point for copy-to-clipboard and share actions.
/// Replaces the per-screen `_copyToClipboard` / `_shareText` / `_shareAll`
/// clones (asmaa, dua, ruqyah, azkar details, mosque map).
class ShareHelper {
  const ShareHelper._();

  /// Copies [text] and shows the themed confirmation snack.
  /// [message] defaults to a generic Arabic confirmation when null.
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String? message,
    Duration duration = const Duration(seconds: 2),
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    AppFeedback.snack(
      context,
      message ?? 'تم النسخ',
      duration: duration,
    );
  }

  /// Shares [text] with an optional [subject] and optional file attachments.
  static Future<void> shareText(
    String text, {
    String? subject,
    List<XFile>? files,
  }) {
    return SharePlus.instance.share(
      ShareParams(text: text, subject: subject, files: files),
    );
  }
}
