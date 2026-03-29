import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fut_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/neon_button.dart';
import '../../game/application/game_state.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.result,
    required this.onRetry,
  });

  final RoundResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final accuracy = result.accuracy.toStringAsFixed(0);
    final speed = result.avgSwipeSeconds.toStringAsFixed(1);

    return FutBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TIME'S UP!",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.hotPink,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            Text(
              'SESSION EXPIRED',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 28),
            GlassCard(
              borderColor: AppColors.amber,
              child: Column(
                children: [
                  Text(
                    'FINAL SCORE',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFE9BDCA),
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.displayLarge,
                      children: [
                        TextSpan(text: '${result.score}'),
                        TextSpan(
                          text: ' SWIPES',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFFFFBED3),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.amber.withValues(alpha: 0.14),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'NEW PERSONAL BEST!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatBubble(
                    icon: Icons.adjust,
                    iconColor: AppColors.neonGreen,
                    value: '$accuracy%',
                    label: 'ACCURACY',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBubble(
                    icon: Icons.flash_on_rounded,
                    iconColor: AppColors.hotPink,
                    value: '${result.bestStreak}',
                    label: 'STREAK',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBubble(
                    icon: Icons.speed_rounded,
                    iconColor: AppColors.amber,
                    value: '${speed}s',
                    label: 'AVG SPEED',
                  ),
                ),
              ],
            ),
            const Spacer(),
            NeonButton(
              title: 'RETRY',
              icon: Icons.replay_rounded,
              colors: const [Color(0xFF42D66B), Color(0xFF1F973E)],
              onTap: onRetry,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_rounded),
                label: const Text('SHARE RESULTS'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  foregroundColor: const Color(0xFFE9BDCA),
                  minimumSize: const Size.fromHeight(74),
                  textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
