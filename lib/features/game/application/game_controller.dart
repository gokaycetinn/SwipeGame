import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_api.dart';
import '../domain/quiz_card.dart';
import 'game_state.dart';

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
  return GameController();
});

final gameModesProvider = FutureProvider<List<GameModeConfig>>((ref) async {
  final api = GameApi();
  return api.fetchModes();
});

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState.initial());

  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  final GameApi _api = GameApi();
  int _penaltyMs = 0;
  bool _inputLocked = false;
  int _roundDurationMs = 60000;
  int _penaltyPerWrongMs = 1000;
  GameModeConfig? _activeMode;

  Future<void> startNewRound({String modeId = 'standard'}) async {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();

    _activeMode = await _api.modeById(modeId);
    _roundDurationMs = _activeMode!.roundDurationMs;
    _penaltyPerWrongMs = _activeMode!.penaltyMs;

    _penaltyMs = 0;
    _inputLocked = false;

    final openingDifficulty = _difficultyForRemaining(_roundDurationMs);
    final openingCard = await _api.buildQuestion(
      difficulty: openingDifficulty,
      allowedTargets: _activeMode!.allowedTargets,
    );
    final deck = openingCard == null ? <QuizCard>[] : <QuizCard>[openingCard];
    final firstRule = openingCard?.ruleText ?? '';

    state = state.copyWith(
      deck: deck,
      currentRule: firstRule,
      currentIndex: 0,
      score: 0,
      streak: 0,
      bestStreak: 0,
      totalSwipes: 0,
      correctSwipes: 0,
      remainingMs: _roundDurationMs,
      activeModeId: _activeMode!.id,
      activeModeLabel: _activeMode!.name,
      currentDifficulty: openingDifficulty,
      isPaused: false,
      isRunning: true,
      isFinished: false,
      startedAt: DateTime.now(),
      clearResult: true,
    );

    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  Future<void> submitAnswer({required bool matchesRule}) async {
    if (!state.isRunning || state.isPaused || _inputLocked || state.currentCard == null) {
      return;
    }

    final card = state.currentCard!;
    final expected = card.expectedAnswer;
    final isCorrect = expected == matchesRule;

    final streak = isCorrect ? state.streak + 1 : 0;
    final bestStreak = max(state.bestStreak, streak);

    if (isCorrect) {
      _fireHaptic(isSuccess: true);
    } else {
      _penaltyMs += _penaltyPerWrongMs;
      _inputLocked = true;
      _fireHaptic(isSuccess: false);
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        _inputLocked = false;
      });
    }

    final remaining = _remainingMs();
    final nextIndex = state.currentIndex + 1;
    final nextDifficulty = _difficultyForRemaining(remaining);
    final nextCard = await _api.buildQuestion(
      difficulty: nextDifficulty,
      allowedTargets: _activeMode?.allowedTargets ?? const ['player'],
    );

    final nextDeck = List.of(state.deck);
    if (nextCard != null) {
      nextDeck.add(nextCard);
    }
    final nextRule = nextCard?.ruleText ?? state.currentRule;

    state = state.copyWith(
      deck: nextDeck,
      score: state.score + (isCorrect ? 1 : 0),
      streak: streak,
      bestStreak: bestStreak,
      totalSwipes: state.totalSwipes + 1,
      correctSwipes: state.correctSwipes + (isCorrect ? 1 : 0),
      currentIndex: nextIndex,
      currentRule: nextRule,
      currentDifficulty: nextDifficulty,
      remainingMs: remaining,
    );

    if (remaining <= 0) {
      _finishRound();
    }
  }

  void _tick() {
    if (!state.isRunning || state.isPaused) return;

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

  String _difficultyForRemaining(int remainingMs) {
    final mode = _activeMode;
    if (mode == null) {
      return 'easy';
    }

    if (mode.strategy == 'fixed') {
      return mode.fixedDifficulty;
    }

    final elapsedRatio = 1 - (remainingMs / _roundDurationMs).clamp(0.0, 1.0);
    for (final step in mode.timeline) {
      if (elapsedRatio >= step.fromProgress && elapsedRatio < step.toProgress) {
        return step.difficulty;
      }
    }
    if (mode.timeline.isNotEmpty) {
      return mode.timeline.last.difficulty;
    }
    return 'easy';
  }

  void _finishRound() {
    _ticker?.cancel();
    _stopwatch.stop();

    final totalDuration = _stopwatch.elapsedMilliseconds.clamp(1, 100000).toInt();
    final avgSwipeSeconds = state.totalSwipes == 0
      ? 0.0
        : (totalDuration / state.totalSwipes) / 1000.0;

    state = state.copyWith(
      isPaused: false,
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

  void pauseRound() {
    if (!state.isRunning || state.isPaused) {
      return;
    }

    _stopwatch.stop();
    state = state.copyWith(isPaused: true, remainingMs: _remainingMs());
  }

  void resumeRound() {
    if (!state.isRunning || !state.isPaused) {
      return;
    }

    _stopwatch.start();
    state = state.copyWith(isPaused: false);
  }

  void exitToHome() {
    _ticker?.cancel();
    _stopwatch.stop();

    state = state.copyWith(
      deck: const <QuizCard>[],
      currentIndex: 0,
      currentRule: '',
      currentDifficulty: 'easy',
      isPaused: false,
      isRunning: false,
      isFinished: false,
      remainingMs: _roundDurationMs,
      clearResult: true,
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
