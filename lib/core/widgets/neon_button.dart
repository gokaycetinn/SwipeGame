import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.colors = const [AppColors.neonGreen, AppColors.hotPink],
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          height: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(colors: colors),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF121212),
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 14),
                Icon(icon, color: const Color(0xFF121212), size: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
