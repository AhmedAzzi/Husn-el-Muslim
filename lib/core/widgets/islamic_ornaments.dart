import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared palette for the app's Islamic ornaments.
class IslamicPalette {
  static const burgundy = Color(0xFF693B42);
  static const burgundyDark = Color(0xFF4E2A30);
  static const burgundyMid = Color(0xFF7C414D);
  static const gold = Color(0xFFC9A227);
}

/// A subtle repeating Islamic eight-pointed star pattern.
/// Place inside a [Stack] as a background layer.
class IslamicPattern extends StatelessWidget {
  final Color color;
  final double spacing;

  const IslamicPattern({
    super.key,
    required this.color,
    this.spacing = 110.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _IslamicPatternPainter(color: color, spacing: spacing),
        ),
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _IslamicPatternPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final s = spacing;
    for (double y = s / 2; y < size.height + s; y += s) {
      for (double x = s / 2; x < size.width + s; x += s) {
        _drawEightPointedStar(canvas, Offset(x, y), s * 0.40, paint);
      }
    }
  }

  void _drawEightPointedStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final halfSide = radius / math.sqrt2;
    final rect = Rect.fromCenter(
      center: center,
      width: halfSide * 2,
      height: halfSide * 2,
    );

    canvas.drawRect(rect, paint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}

/// A decorative divider with a central ornamental glyph flanked by fading lines.
class OrnamentalDivider extends StatelessWidget {
  final Color color;
  final String glyph;

  const OrnamentalDivider({
    super.key,
    required this.color,
    this.glyph = '۞',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            glyph,
            style: TextStyle(
              fontFamily: 'Amiri',
              color: color,
              fontSize: 15,
              height: 1,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A framed ornamental section title with double khatam borders.
class OrnamentalSectionTitle extends StatelessWidget {
  final String title;
  final Color accentColor;
  final bool compact;

  const OrnamentalSectionTitle({
    super.key,
    required this.title,
    required this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        top: compact ? 2 : 4,
        bottom: compact ? 10 : 18,
      ),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 12 : 18),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 5 : 12,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(compact ? 9 : 14),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '۞',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: accentColor,
                    fontSize: compact ? 13 : 18,
                    height: 1,
                  ),
                ),
                SizedBox(width: compact ? 6 : 10),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: compact ? 16 : 22,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 6 : 10),
                Text(
                  '۞',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: accentColor,
                    fontSize: compact ? 13 : 18,
                    height: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 5 : 10),
            OrnamentalDivider(color: accentColor),
          ],
        ),
      ),
    );
  }
}

/// A circular numeric medallion used for numbering items.
class NumberMedallion extends StatelessWidget {
  final String label;
  final Color ringColor;
  final Color fillColor;
  final Color textColor;
  final double size;

  const NumberMedallion({
    super.key,
    required this.label,
    required this.ringColor,
    required this.fillColor,
    required this.textColor,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(
          color: ringColor.withValues(alpha: 0.7),
          width: 1.3,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            fontSize: size * 0.42,
            color: textColor,
          ),
        ),
      ),
    );
  }
}