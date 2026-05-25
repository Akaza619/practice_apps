import 'package:flutter/material.dart';

class AnimatedDotsLoader extends StatelessWidget {
  final AnimationController controller;

  const AnimatedDotsLoader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final scale =
                0.5 +
                0.5 *
                    (1 -
                        (2 * ((t - delay).abs() % 1) - 1).abs().clamp(
                          0.0,
                          1.0,
                        ));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale.clamp(0.5, 1.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      const Color(0xFF6C63FF).withOpacity(0.3),
                      const Color(0xFF6C63FF),
                      scale.clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
