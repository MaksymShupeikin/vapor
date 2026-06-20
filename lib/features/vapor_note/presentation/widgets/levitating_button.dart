import 'package:flutter/material.dart';

import 'frosted_panel.dart';

class LevitatingButton extends StatelessWidget {
  const LevitatingButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
    this.selected = false,
    this.large = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? label;
  final bool selected;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(label == null ? 999 : 18);
    final foregroundColor = selected
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: enabled ? 0.86 : 0.34);

    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: selected ? 0.58 : 0.48,
                  ),
                  blurRadius: selected ? 42 : 36,
                  spreadRadius: -7,
                  offset: const Offset(0, 22),
                ),
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                  blurRadius: 16,
                  spreadRadius: -10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: FrostedPanel(
              radius: label == null ? 999 : 18,
              blur: 14,
              surfaceOpacity: selected ? 0.22 : 0.14,
              borderOpacity: selected ? 0.34 : 0.18,
              shadowOpacity: 0.10,
              padding: label == null
                  ? EdgeInsets.all(large ? 14 : 12)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: large ? 22 : 19, color: foregroundColor),
                  if (label != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      label!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
