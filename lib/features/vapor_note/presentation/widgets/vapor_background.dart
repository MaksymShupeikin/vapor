import 'package:flutter/material.dart';

class VaporBackground extends StatelessWidget {
  const VaporBackground({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(color: color)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 0.95,
                colors: [
                  Color(0x00000000),
                  Color(0x22000000),
                  Color(0x4A000000),
                ],
                stops: [0, 0.62, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
