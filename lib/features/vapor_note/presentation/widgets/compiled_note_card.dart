import 'package:flutter/material.dart';

import 'frosted_panel.dart';

class CompiledNoteCard extends StatelessWidget {
  const CompiledNoteCard({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: FrostedPanel(
          radius: 26,
          blur: 18,
          surfaceOpacity: 0.16,
          borderOpacity: 0.18,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.94),
              fontSize: 23,
              fontWeight: FontWeight.w600,
              height: 1.28,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
