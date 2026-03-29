import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fut_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../application/game_controller.dart';
import '../application/game_state.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({
    super.key,
    required this.onRoundEnd,
    required this.onExitToHome,
  });

  final VoidCallback onRoundEnd;
  final VoidCallback onExitToHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<GameState>(gameControllerProvider, (prev, next) {
      final switchedToFinished = (prev?.isFinished ?? false) == false && next.isFinished;
      if (switchedToFinished) {
        onRoundEnd();
      }
    });

    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final currentCard = state.currentCard;

    final timerSeconds = state.remainingMs / 1000.0;
    final dangerMode = timerSeconds <= 3;

    return FutBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: Column(
          children: [
            _GameTopBar(
              onPause: () => _openPauseMenu(context, ref, controller),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEVCUT KURAL',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textMuted,
                                letterSpacing: 1.7,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.currentRule,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: GlassCard(
                    borderColor: AppColors.neonGreen.withValues(alpha: 0.65),
                    child: Column(
                      children: [
                        Text(
                          'SERI',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                letterSpacing: 1.3,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${state.streak}',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              timerSeconds.toStringAsFixed(2),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: dangerMode ? AppColors.hotPink : Colors.white.withValues(alpha: 0.16),
                  ),
            )
                .animate(target: dangerMode ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 340.ms)
                .then()
                .scale(begin: const Offset(1.08, 1.08), end: const Offset(1, 1), duration: 340.ms),
            if (state.isPaused) ...[
              const SizedBox(height: 6),
              Text(
                'DURAKLATILDI',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.amber,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: currentCard == null
                  ? const SizedBox.shrink()
                  : _SwipeCard(
                      key: ValueKey('${currentCard.id}-${state.totalSwipes}'),
                      name: currentCard.name,
                      subtitle: currentCard.subtitle,
                      imageUrl: currentCard.imageUrl,
                      onSwipeLeft: () => controller.submitAnswer(matchesRule: false),
                      onSwipeRight: () => controller.submitAnswer(matchesRule: true),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundActionButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFFFA8B7),
                  onTap: () => controller.submitAnswer(matchesRule: false),
                ),
                const SizedBox(width: 26),
                _RoundActionButton(
                  icon: Icons.check_rounded,
                  color: AppColors.neonGreen,
                  onTap: () => controller.submitAnswer(matchesRule: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openPauseMenu(
    BuildContext context,
    WidgetRef ref,
    GameController controller,
  ) async {
    controller.pauseRound();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1A28),
          title: const Text('Oyun Duraklatildi'),
          content: const Text('Devam etmek veya ana menuye donmek icin secim yap.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.resumeRound();
              },
              child: const Text('Devam Et'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.exitToHome();
                onExitToHome();
              },
              child: const Text('Ana Menu'),
            ),
          ],
        );
      },
    );

    final postDialogState = ref.read(gameControllerProvider);
    if (postDialogState.isRunning && postDialogState.isPaused) {
      controller.resumeRound();
    }
  }
}

class _GameTopBar extends StatelessWidget {
  const _GameTopBar({required this.onPause});

  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPause, icon: const Icon(Icons.pause_rounded, size: 28)),
        Expanded(
          child: Text(
            'FUTSWIPE',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final String name;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onSwipeRight();
          return;
        }
        onSwipeLeft();
      },
      background: _SwipeBg(color: AppColors.neonGreen, icon: Icons.check_rounded, alignLeft: true),
      secondaryBackground:
          _SwipeBg(color: const Color(0xFFFFA7B9), icon: Icons.close_rounded, alignLeft: false),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF16202D),
                  alignment: Alignment.center,
                  child: const Icon(Icons.sports_soccer_rounded, size: 84, color: Colors.white38),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return Container(
                    color: const Color(0xFF16202D),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  );
                },
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xEE05090E)],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFF7B9C7),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 40)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({required this.color, required this.icon, required this.alignLeft});

  final Color color;
  final IconData icon;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.45)],
          begin: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: alignLeft ? Alignment.centerRight : Alignment.centerLeft,
        ),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Icon(icon, color: color, size: 44),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Ink(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 24),
          ],
        ),
        child: Icon(icon, color: color, size: 56),
      ),
    );
  }
}
