import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../domain/quiz_card.dart';

class GameApi {
  const GameApi();

  Future<List<QuizCard>> fetchQuestions({
    int count = 14,
    String targetType = 'player',
  }) async {
    final raw = await rootBundle.loadString('assets/data/players.json');
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('players.json must be a list');
    }

    final players = decoded
        .whereType<Map<String, dynamic>>()
        .map(_LocalPlayer.fromJson)
        .where((p) => p.fullName.isNotEmpty && p.photoUrl.isNotEmpty)
        .toList();

    if (players.isEmpty) {
      return [];
    }

    final rules = _localRules;
    final random = Random();
    final safeCount = max(1, min(count, 40));

    return List<QuizCard>.generate(safeCount, (index) {
      final player = players[random.nextInt(players.length)];
      final rule = rules[random.nextInt(rules.length)];
      final expected = rule.evaluate(player);

      return QuizCard(
        id: '${player.fullName.toLowerCase().replaceAll(' ', '_')}-$index',
        name: player.fullName,
        subtitle: '${player.primaryPosition.toUpperCase()} • ${player.country.toUpperCase()}',
        imageUrl: player.photoUrl,
        ruleText: rule.label,
        expectedAnswer: expected,
      );
    });
  }
}

class _LocalPlayer {
  const _LocalPlayer({
    required this.firstName,
    required this.lastName,
    required this.photoUrl,
    required this.country,
    required this.primaryPosition,
    required this.clubs,
    required this.competitions,
  });

  final String firstName;
  final String lastName;
  final String photoUrl;
  final String country;
  final String primaryPosition;
  final List<String> clubs;
  final List<String> competitions;

  String get fullName => '$firstName $lastName'.trim();

  factory _LocalPlayer.fromJson(Map<String, dynamic> json) {
    List<String> splitPipe(dynamic value) {
      return value
              .toString()
              .split('|')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    }

    return _LocalPlayer(
      firstName: (json['first_name'] ?? '').toString().trim(),
      lastName: (json['last_name'] ?? '').toString().trim(),
      photoUrl: (json['photo_url'] ?? '').toString().trim(),
      country: (json['country'] ?? '').toString().trim(),
      primaryPosition: (json['primary_position'] ?? '').toString().trim(),
      clubs: splitPipe(json['clubs_csv']),
      competitions: splitPipe(json['competitions_won_csv']),
    );
  }
}

class _RuleDef {
  const _RuleDef(this.label, this.evaluate);

  final String label;
  final bool Function(_LocalPlayer player) evaluate;
}

bool _containsToken(List<String> values, String token) {
  final lower = token.toLowerCase();
  return values.any((v) => v.toLowerCase().contains(lower));
}

final List<_RuleDef> _localRules = [
  _RuleDef(
    'Sampiyonlar Ligi kazandi',
    (p) => _containsToken(p.competitions, 'champions league'),
  ),
  _RuleDef(
    'Manchester City formasini giydi',
    (p) => _containsToken(p.clubs, 'manchester city'),
  ),
  _RuleDef(
    'Forvet pozisyonunda oynadi',
    (p) => p.primaryPosition.toLowerCase().contains('forward'),
  ),
  _RuleDef(
    'Ballon d\'Or kazandi',
    (p) => _containsToken(p.competitions, "ballon d'or"),
  ),
  _RuleDef(
    'Premier League kazandi',
    (p) => _containsToken(p.competitions, 'premier league'),
  ),
  _RuleDef(
    'Brezilyali futbolcu',
    (p) => p.country.toLowerCase() == 'brazil',
  ),
];
