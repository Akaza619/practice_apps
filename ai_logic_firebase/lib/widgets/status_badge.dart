import 'package:flutter/material.dart';
import 'view_state.dart';

class StatusBadge extends StatelessWidget {
  final ViewState state;

  const StatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ViewState.loading:
        return _badge(
          color: const Color(0xFFFF9500),
          icon: Icons.hourglass_top_rounded,
          label: 'Analysing…',
        );
      case ViewState.success:
        return _badge(
          color: const Color(0xFF34C759),
          icon: Icons.check_circle_rounded,
          label: 'Extracted',
        );
      case ViewState.error:
        return _badge(
          color: const Color(0xFFFF3B30),
          icon: Icons.error_rounded,
          label: 'Failed',
        );
    }
  }

  Widget _badge({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
