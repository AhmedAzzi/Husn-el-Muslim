import 'package:flutter/material.dart';

/// Shared stateless feedback widgets: loading, empty states, body text.
/// Each replaces byte-identical clones scattered across features; no visual
/// or behavioral change by design (same widget tree, same constants).
class HusnText {
  const HusnText._();

  /// Bare Amiri body style (29 former call sites).
  static const body = TextStyle(fontFamily: 'Amiri');
}
class HusnLoading extends StatelessWidget {
  const HusnLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// No-search-results placeholder shared by dua / asmaa / ruqyah.
/// [fontFamily] is a parameter (not a hardcoded constant) because callers
/// read the user-adjustable global font.
class HusnEmptySearch extends StatelessWidget {
  const HusnEmptySearch({super.key, required this.message, this.fontFamily = 'Amiri'});

  final String message;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
