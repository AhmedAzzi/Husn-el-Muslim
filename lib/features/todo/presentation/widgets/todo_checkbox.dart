import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TodoCheckbox extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final double size;

  const TodoCheckbox({
    super.key,
    required this.isCompleted,
    required this.onChanged,
    this.activeColor,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = activeColor ?? const Color(0xFF2E6B34); // deep green

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!isCompleted);
      },
      borderRadius: BorderRadius.circular(size),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? primary : Colors.transparent,
          border: Border.all(
            color: isCompleted
                ? primary
                : (isDark ? Colors.white38 : Colors.black38),
            width: 2.0,
          ),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedScale(
          scale: isCompleted ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
