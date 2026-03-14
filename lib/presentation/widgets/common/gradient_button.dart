// lib/presentation/widgets/common/gradient_button.dart
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class GradientButton extends StatelessWidget {
  final String       text;
  final VoidCallback onPressed;
  final double       height;
  final double?      width;
  final IconData?    icon;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 56,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin:  Alignment.centerLeft,
          end:    Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
          BoxShadow(
            color:      AppTheme.secondary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize:      MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color:         Colors.white,
                    fontSize:      16,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
