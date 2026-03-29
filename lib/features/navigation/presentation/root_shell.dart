import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../game/application/game_controller.dart';
import '../../game/application/game_state.dart';
import '../../game/data/game_api.dart';
import '../../game/presentation/game_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../results/presentation/results_screen.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(navigationIndexProvider);
    final gameState = ref.watch(gameControllerProvider);
    final modesAsync = ref.watch(gameModesProvider);
    final modeOptions = modesAsync.valueOrNull ?? const <GameModeConfig>[];
    final result = gameState.lastResult;
    const navToScreen = [0, 2, 3];
    final selectedNavIndex =
      navIndex == 2 ? 1 : navIndex == 3 ? 2 : 0;

    final screens = [
      HomeScreen(
        modes: modeOptions,
        onStart: (modeId) {
          ref.read(gameControllerProvider.notifier).startNewRound(modeId: modeId);
          ref.read(navigationIndexProvider.notifier).state = 1;
        },
      ),
      GameScreen(
        onRoundEnd: () {
          ref.read(navigationIndexProvider.notifier).state = 2;
        },
        onExitToHome: () {
          ref.read(navigationIndexProvider.notifier).state = 0;
        },
      ),
      ResultsScreen(
        result: result ??
            const RoundResult(
              score: 0,
              bestStreak: 0,
              totalSwipes: 0,
              correctSwipes: 0,
              avgSwipeSeconds: 0,
            ),
        onRetry: () {
          ref
              .read(gameControllerProvider.notifier)
              .startNewRound(modeId: gameState.activeModeId);
          ref.read(navigationIndexProvider.notifier).state = 1;
        },
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[navIndex],
      bottomNavigationBar: navIndex == 1
          ? null
          : Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xCC091624),
                borderRadius: BorderRadius.circular(28),
              ),
              child: BottomNavigationBar(
                currentIndex: selectedNavIndex,
                onTap: (index) {
                  ref.read(navigationIndexProvider.notifier).state = navToScreen[index];
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                selectedItemColor: AppColors.hotPink,
                unselectedItemColor: AppColors.textMuted,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
                  BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Ligler'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
                ],
              ),
            ),
    );
  }
}
