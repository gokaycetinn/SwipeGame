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
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: Column(
          children: [
            _GameTopBar(
              onPause: () => _openPauseMenu(context, ref, controller),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 6),
            SizedBox(
              height: 24,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: state.isPaused ? 1 : 0,
                  child: Text(
                    'DURAKLATILDI',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.amber,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _RuleBar(text: state.currentRule),
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -20,
                    right: -20,
                    top: 0,
                    bottom: -MediaQuery.paddingOf(context).bottom,
                    child: currentCard == null
                        ? const SizedBox.shrink()
                        : _SwipeCard(
                            key: ValueKey('${currentCard.id}-${state.totalSwipes}'),
                            name: currentCard.name,
                            imageUrl: currentCard.imageUrl,
                            onSwipeLeft: () => controller.submitAnswer(matchesRule: false),
                            onSwipeRight: () => controller.submitAnswer(matchesRule: true),
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 8),
                    child: Row(
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
                  ),
                ],
              ),
            ),
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

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PauseMenu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AlertDialog(
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
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
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
    required this.imageUrl,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final String name;
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
      background: const _SwipeRevealBackground(),
      secondaryBackground: const _SwipeRevealBackground(),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1D2B3F), Color(0xFF0E1625)],
                    ),
                  ),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      const Color(0xEE05090E),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 182,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 38,
                            shadows: const [Shadow(color: Colors.black87, blurRadius: 12)],
                          ),
                    ),
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

class _RuleBar extends StatelessWidget {
  const _RuleBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 28,
              height: 1.05,
            ),
      ),
    );
  }
}

class _SwipeRevealBackground extends StatelessWidget {
  const _SwipeRevealBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withValues(alpha: 0.06),
      ),
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
