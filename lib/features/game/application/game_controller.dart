import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_api.dart';
import '../data/sample_cards.dart';
import '../domain/quiz_card.dart';
import 'game_state.dart';

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
  return GameController();
});

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState.initial());

  static const int _roundDurationMs = 60000;
  static const int _roundCardCount = 14;

  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  final GameApi _api = const GameApi();
  int _penaltyMs = 0;
  bool _inputLocked = false;

  Future<void> startNewRound() async {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _penaltyMs = 0;
    _inputLocked = false;

    final deck = await _loadRoundDeck();
    final firstRule = deck.isEmpty ? '' : deck.first.ruleText;

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
      isPaused: false,
      isRunning: true,
      isFinished: false,
      startedAt: DateTime.now(),
      clearResult: true,
    );

    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  Future<List<QuizCard>> _loadRoundDeck() async {
    try {
      final cards = await _api.fetchQuestions(count: _roundCardCount, targetType: 'player');
      if (cards.isNotEmpty) {
        return cards;
      }
    } catch (_) {
      // Fallback to built-in samples if json asset load fails.
    }

    final random = Random();
    return [...sampleCards]..shuffle(random);
  }

  void submitAnswer({required bool matchesRule}) {
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
      _penaltyMs += 1000;
      _inputLocked = true;
      _fireHaptic(isSuccess: false);
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        _inputLocked = false;
      });
    }

    final nextIndex = state.currentIndex + 1;
    final nextRule = state.deck.isEmpty
        ? ''
        : state.deck[nextIndex % state.deck.length].ruleText;

    state = state.copyWith(
      score: state.score + (isCorrect ? 1 : 0),
      streak: streak,
      bestStreak: bestStreak,
      totalSwipes: state.totalSwipes + 1,
      correctSwipes: state.correctSwipes + (isCorrect ? 1 : 0),
      currentIndex: nextIndex,
      currentRule: nextRule,
      remainingMs: _remainingMs(),
    );

    if (_remainingMs() <= 0) {
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
