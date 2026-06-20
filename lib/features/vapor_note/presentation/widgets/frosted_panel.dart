import 'dart:ui';

import 'package:flutter/material.dart';

class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
    this.blur = 18,
    this.surfaceOpacity = 0.12,
    this.borderOpacity = 0.14,
    this.shadowOpacity = 0.26,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double surfaceOpacity;
  final double borderOpacity;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: surfaceOpacity,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: borderOpacity,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: shadowOpacity),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.onSurface.withValues(alpha: 0.045),
                colorScheme.onSurface.withValues(alpha: 0.015),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
