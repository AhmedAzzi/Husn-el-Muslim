import 'package:flutter/material.dart';
import 'package:small_husn_muslim/core/utils/l10n_ext.dart';

/// Suggests the nearest mosque as the user's default mosque.
///
/// Shows the mosque [mosqueName] and, when non-empty, its [distanceText],
/// and explains that accepting sets it as the default mosque.
/// Returns true for "Set as Default", false for "Cancel"/dismiss.
Future<bool?> showMosqueSuggestDialog({
  required BuildContext context,
  required String mosqueName,
  required String distanceText,
}) {
  final loc = context.loc;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        key: const ValueKey('mm_suggest_dialog'),
        title: Row(
          children: [
            const Icon(Icons.mosque_rounded, color: Color(0xFFD64463)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.mmSuggestTitle,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mosqueName,
              key: const ValueKey('mm_suggest_name'),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (distanceText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                distanceText,
                key: const ValueKey('mm_suggest_distance'),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              loc.mmSuggestBody,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('mm_suggest_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              loc.ctCancel,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('mm_suggest_set'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD64463),
              foregroundColor: Colors.white,
            ),
            child: Text(
              loc.mmSuggestSet,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
