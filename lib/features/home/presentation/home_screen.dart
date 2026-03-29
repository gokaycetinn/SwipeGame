import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fut_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/neon_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return FutBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
              child: Column(
                children: [
                  const _TopBar(),
                  const SizedBox(height: 24),
                  Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.38),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withValues(alpha: 0.22),
                          blurRadius: 36,
                        ),
                      ],
                      color: Colors.white.withValues(alpha: 0.02),
                    ),
                    child: const Icon(Icons.sports_soccer_rounded, size: 86),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  Text('FUTSWIPE', style: Theme.of(context).textTheme.displayMedium)
                      .animate()
                      .fade(duration: 450.ms)
                      .slideY(begin: 0.35, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    '10 Seconds. Infinite Cards. Perfect Swipes.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textMuted, fontSize: 17),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(
                        child: _FeatureTile(
                          icon: Icons.flash_on_rounded,
                          iconColor: AppColors.neonGreen,
                          title: 'LIGHTNING\nFAST',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _FeatureTile(
                          icon: Icons.emoji_events_rounded,
                          iconColor: AppColors.amber,
                          title: 'ELITE\nCOMPETE',
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _FeatureTile(
                          icon: Icons.dynamic_feed_rounded,
                          iconColor: AppColors.hotPink,
                          title: 'DYNAMIC\nFEED',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  NeonButton(
                    title: 'START GAME',
                    icon: Icons.play_arrow_rounded,
                    onTap: onStart,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings_rounded, size: 30),
        ),
        Expanded(
          child: Text(
            'FUTSWIPE',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.bar_chart_rounded, size: 30),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
        ],
      ),
    );
  }
}
