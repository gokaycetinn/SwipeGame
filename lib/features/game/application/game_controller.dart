import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sample_cards.dart';
import 'game_state.dart';

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
  return GameController();
});

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState.initial());

  static const int _roundDurationMs = 10000;

  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  int _penaltyMs = 0;
  bool _inputLocked = false;

  void startNewRound() {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _penaltyMs = 0;
    _inputLocked = false;

    final random = Random();
    final deck = [...sampleCards]..shuffle(random);
    final currentRule = gameRules[random.nextInt(gameRules.length)];

    state = state.copyWith(
      deck: deck,
      currentRule: currentRule,
      currentIndex: 0,
      score: 0,
      streak: 0,
      bestStreak: 0,
      totalSwipes: 0,
      correctSwipes: 0,
      remainingMs: _roundDurationMs,
      isRunning: true,
      isFinished: false,
      startedAt: DateTime.now(),
      clearResult: true,
    );

    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void submitAnswer({required bool matchesRule}) {
    if (!state.isRunning || _inputLocked || state.currentCard == null) {
      return;
    }

    final card = state.currentCard!;
    final expected = card.rules[state.currentRule] ?? false;
    final isCorrect = expected == matchesRule;

    final streak = isCorrect ? state.streak + 1 : 0;
    final bestStreak = max(state.bestStreak, streak);

    if (isCorrect) {
      _fireHaptic(isSuccess: true);
    } else {
      _penaltyMs += 1000;
      _inputLocked = true;
      _fireHaptic(isSuccess: false);
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        _inputLocked = false;
      });
    }

    state = state.copyWith(
      score: state.score + (isCorrect ? 1 : 0),
      streak: streak,
      bestStreak: bestStreak,
      totalSwipes: state.totalSwipes + 1,
      correctSwipes: state.correctSwipes + (isCorrect ? 1 : 0),
      currentIndex: state.currentIndex + 1,
      remainingMs: _remainingMs(),
    );

    if (_remainingMs() <= 0) {
      _finishRound();
    }
  }

  void _tick() {
    if (!state.isRunning) return;

    final remaining = _remainingMs();
    if (remaining <= 0) {
      _finishRound();
      return;
    }

    state = state.copyWith(remainingMs: remaining);
  }

  int _remainingMs() {
    final elapsed = _stopwatch.elapsedMilliseconds + _penaltyMs;
    return max(0, _roundDurationMs - elapsed);
  }

  void _finishRound() {
    _ticker?.cancel();
    _stopwatch.stop();

    final totalDuration = _stopwatch.elapsedMilliseconds.clamp(1, 100000).toInt();
    final avgSwipeSeconds = state.totalSwipes == 0
      ? 0.0
        : (totalDuration / state.totalSwipes) / 1000.0;

    state = state.copyWith(
      isRunning: false,
      isFinished: true,
      remainingMs: 0,
      lastResult: RoundResult(
        score: state.score,
        bestStreak: state.bestStreak,
        totalSwipes: state.totalSwipes,
        correctSwipes: state.correctSwipes,
        avgSwipeSeconds: avgSwipeSeconds,
      ),
    );
  }

  Future<void> _fireHaptic({required bool isSuccess}) async {
    if (isSuccess) {
      await HapticFeedback.lightImpact();
      return;
    }
    await HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
