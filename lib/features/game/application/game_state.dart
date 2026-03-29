import '../domain/quiz_card.dart';

class RoundResult {
  const RoundResult({
    required this.score,
    required this.bestStreak,
    required this.totalSwipes,
    required this.correctSwipes,
    required this.avgSwipeSeconds,
  });

  final int score;
  final int bestStreak;
  final int totalSwipes;
  final int correctSwipes;
  final double avgSwipeSeconds;

  double get accuracy {
    if (totalSwipes == 0) return 0;
    return (correctSwipes / totalSwipes) * 100;
  }
}

class GameState {
  const GameState({
    required this.deck,
    required this.currentRule,
    required this.currentIndex,
    required this.score,
    required this.streak,
    required this.bestStreak,
    required this.totalSwipes,
    required this.correctSwipes,
    required this.remainingMs,
    required this.isRunning,
    required this.isFinished,
    required this.lastResult,
    required this.startedAt,
  });

  factory GameState.initial() => const GameState(
        deck: [],
        currentRule: '',
        currentIndex: 0,
        score: 0,
        streak: 0,
        bestStreak: 0,
        totalSwipes: 0,
        correctSwipes: 0,
        remainingMs: 10000,
        isRunning: false,
        isFinished: false,
        lastResult: null,
        startedAt: null,
      );

  final List<QuizCard> deck;
  final String currentRule;
  final int currentIndex;
  final int score;
  final int streak;
  final int bestStreak;
  final int totalSwipes;
  final int correctSwipes;
  final int remainingMs;
  final bool isRunning;
  final bool isFinished;
  final RoundResult? lastResult;
  final DateTime? startedAt;

  QuizCard? get currentCard {
    if (deck.isEmpty) return null;
    return deck[currentIndex % deck.length];
  }

  GameState copyWith({
    List<QuizCard>? deck,
    String? currentRule,
    int? currentIndex,
    int? score,
    int? streak,
    int? bestStreak,
    int? totalSwipes,
    int? correctSwipes,
    int? remainingMs,
    bool? isRunning,
    bool? isFinished,
    RoundResult? lastResult,
    DateTime? startedAt,
    bool clearResult = false,
  }) {
    return GameState(
      deck: deck ?? this.deck,
      currentRule: currentRule ?? this.currentRule,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalSwipes: totalSwipes ?? this.totalSwipes,
      correctSwipes: correctSwipes ?? this.correctSwipes,
      remainingMs: remainingMs ?? this.remainingMs,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
