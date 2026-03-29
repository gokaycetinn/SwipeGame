import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../domain/quiz_card.dart';

class GameApi {
  GameApi();

  final Random _random = Random();
  bool _isLoaded = false;
  List<_EntityRecord> _players = const [];
  List<_EntityRecord> _clubs = const [];
  List<_EntityRecord> _stadiums = const [];
  List<_RuleRecord> _rules = const [];
  List<GameModeConfig> _modes = const [];

  Future<List<GameModeConfig>> fetchModes() async {
    await _ensureLoaded();
    return _modes;
  }

  Future<GameModeConfig> modeById(String modeId) async {
    await _ensureLoaded();
    for (final mode in _modes) {
      if (mode.id == modeId) {
        return mode;
      }
    }
    return _modes.first;
  }

  Future<QuizCard?> buildQuestion({
    required String difficulty,
    required List<String> allowedTargets,
  }) async {
    await _ensureLoaded();

    final targetPool = allowedTargets.where((t) => _entityPool(t).isNotEmpty).toList();
    if (targetPool.isEmpty) {
      return null;
    }

    final target = targetPool[_random.nextInt(targetPool.length)];
    var rules = _rules.where((r) => r.target == target && r.difficulty == difficulty).toList();
    if (rules.isEmpty) {
      rules = _rules.where((r) => r.target == target).toList();
    }
    if (rules.isEmpty) {
      return null;
    }

    final entities = _entityPool(target);
    final rule = rules[_random.nextInt(rules.length)];
    final entity = entities[_random.nextInt(entities.length)];
    final expected = _LogicEvaluator.evaluate(rule.logic, entity.data);

    return QuizCard(
      id: '${target}_${entity.id}_${rule.id}_${DateTime.now().microsecondsSinceEpoch}',
      name: entity.title,
      subtitle: entity.subtitle,
      imageUrl: entity.imageUrl,
      ruleText: rule.text,
      expectedAnswer: expected,
    );
  }

  List<_EntityRecord> _entityPool(String target) {
    switch (target) {
      case 'player':
        return _players;
      case 'club':
        return _clubs;
      case 'stadium':
        return _stadiums;
      default:
        return const [];
    }
  }

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;

    final playersRaw = await rootBundle.loadString('assets/data/players.json');
    final clubsRaw = await rootBundle.loadString('assets/data/clubs.json');
    final stadiumsRaw = await rootBundle.loadString('assets/data/stadiums.json');
    final rulesRaw = await rootBundle.loadString('assets/data/rules.json');
    final modesRaw = await rootBundle.loadString('assets/data/modes.json');

    final playersData = jsonDecode(playersRaw);
    final clubsData = jsonDecode(clubsRaw);
    final stadiumsData = jsonDecode(stadiumsRaw);
    final rulesData = jsonDecode(rulesRaw);
    final modesData = jsonDecode(modesRaw);

    if (playersData is! List || clubsData is! List || stadiumsData is! List || rulesData is! List || modesData is! List) {
      throw const FormatException('One or more data files are not valid JSON arrays.');
    }

    _players = playersData
        .whereType<Map<String, dynamic>>()
        .map(_EntityRecord.player)
        .where((e) => e.title.isNotEmpty)
        .toList();
    _clubs = clubsData
        .whereType<Map<String, dynamic>>()
        .map(_EntityRecord.club)
        .where((e) => e.title.isNotEmpty)
        .toList();
    _stadiums = stadiumsData
        .whereType<Map<String, dynamic>>()
        .map(_EntityRecord.stadium)
        .where((e) => e.title.isNotEmpty)
        .toList();

    _rules = rulesData
        .whereType<Map<String, dynamic>>()
        .expand((category) {
          final rules = category['rules'];
          if (rules is! List) {
            return const <_RuleRecord>[];
          }
          return rules
              .whereType<Map<String, dynamic>>()
              .map(_RuleRecord.fromJson)
              .where((r) => r.text.isNotEmpty && r.logic.isNotEmpty)
              .toList();
        })
        .toList();

    _modes = modesData
        .whereType<Map<String, dynamic>>()
        .map(GameModeConfig.fromJson)
        .toList();
    if (_modes.isEmpty) {
      throw const FormatException('modes.json must contain at least one mode.');
    }

    _isLoaded = true;
  }
}

class GameModeConfig {
  const GameModeConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.roundDurationMs,
    required this.penaltyMs,
    required this.allowedTargets,
    required this.strategy,
    required this.fixedDifficulty,
    required this.timeline,
  });

  final String id;
  final String name;
  final String description;
  final int roundDurationMs;
  final int penaltyMs;
  final List<String> allowedTargets;
  final String strategy;
  final String fixedDifficulty;
  final List<DifficultyStep> timeline;

  factory GameModeConfig.fromJson(Map<String, dynamic> json) {
    final timelineRaw = json['difficulty_timeline'];
    return GameModeConfig(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      roundDurationMs: _toInt(json['round_duration_ms'], fallback: 60000),
      penaltyMs: _toInt(json['penalty_ms'], fallback: 1000),
      allowedTargets: (json['allowed_targets'] is List)
          ? (json['allowed_targets'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : const ['player'],
      strategy: (json['difficulty_strategy'] ?? 'fixed').toString(),
      fixedDifficulty: (json['fixed_difficulty'] ?? 'easy').toString(),
      timeline: timelineRaw is List
          ? timelineRaw
              .whereType<Map<String, dynamic>>()
              .map(DifficultyStep.fromJson)
              .toList()
          : const [],
    );
  }
}

class DifficultyStep {
  const DifficultyStep({
    required this.fromProgress,
    required this.toProgress,
    required this.difficulty,
  });

  final double fromProgress;
  final double toProgress;
  final String difficulty;

  factory DifficultyStep.fromJson(Map<String, dynamic> json) {
    return DifficultyStep(
      fromProgress: _toDouble(json['from_progress'], fallback: 0),
      toProgress: _toDouble(json['to_progress'], fallback: 1),
      difficulty: (json['difficulty'] ?? 'easy').toString(),
    );
  }
}

class _EntityRecord {
  const _EntityRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.data,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final Map<String, dynamic> data;

  factory _EntityRecord.player(Map<String, dynamic> json) {
    final first = (json['first_name'] ?? '').toString().trim();
    final last = (json['last_name'] ?? '').toString().trim();
    final fullName = (json['full_name'] ?? '$first $last').toString().trim();
    final position = (json['primary_position'] ?? '').toString().trim();
    final country = (json['country'] ?? '').toString().trim();

    return _EntityRecord(
      id: (json['id'] ?? fullName).toString(),
      title: fullName,
      subtitle: '${position.toUpperCase()} • ${country.toUpperCase()}',
      imageUrl: (json['photo_url'] ?? '').toString(),
      data: Map<String, dynamic>.from(json),
    );
  }

  factory _EntityRecord.club(Map<String, dynamic> json) {
    final country = (json['country'] ?? '').toString().trim();
    final league = (json['current_league'] ?? '').toString().trim();
    return _EntityRecord(
      id: (json['id'] ?? '').toString(),
      title: (json['short_name'] ?? json['name'] ?? '').toString(),
      subtitle: '${country.toUpperCase()} • $league',
      imageUrl: (json['logo_url'] ?? '').toString(),
      data: Map<String, dynamic>.from(json),
    );
  }

  factory _EntityRecord.stadium(Map<String, dynamic> json) {
    final city = (json['city'] ?? '').toString().trim();
    final country = (json['country'] ?? '').toString().trim();
    return _EntityRecord(
      id: (json['id'] ?? '').toString(),
      title: (json['name'] ?? '').toString(),
      subtitle: '${city.toUpperCase()} • ${country.toUpperCase()}',
      imageUrl: (json['photo_url'] ?? '').toString(),
      data: Map<String, dynamic>.from(json),
    );
  }
}

class _RuleRecord {
  const _RuleRecord({
    required this.id,
    required this.text,
    required this.logic,
    required this.target,
    required this.difficulty,
  });

  final String id;
  final String text;
  final String logic;
  final String target;
  final String difficulty;

  factory _RuleRecord.fromJson(Map<String, dynamic> json) {
    return _RuleRecord(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      logic: (json['logic'] ?? '').toString(),
      target: (json['target'] ?? 'player').toString(),
      difficulty: (json['difficulty'] ?? 'easy').toString(),
    );
  }
}

class _LogicEvaluator {
  static bool evaluate(String expression, Map<String, dynamic> entity) {
    final expr = expression.trim();
    if (expr.isEmpty) return false;
    return _evalExpr(expr, entity);
  }

  static bool _evalExpr(String expr, Map<String, dynamic> entity) {
    final cleaned = _stripOuterParens(expr.trim());

    final orParts = _splitTopLevel(cleaned, '||');
    if (orParts.length > 1) {
      for (final part in orParts) {
        if (_evalExpr(part, entity)) {
          return true;
        }
      }
      return false;
    }

    final andParts = _splitTopLevel(cleaned, '&&');
    if (andParts.length > 1) {
      for (final part in andParts) {
        if (!_evalExpr(part, entity)) {
          return false;
        }
      }
      return true;
    }

    return _evalAtomic(cleaned, entity);
  }

  static bool _evalAtomic(String expr, Map<String, dynamic> entity) {
    final contains =
      RegExp('^([A-Za-z0-9_.]+)\\.contains\\((.+)\\)').firstMatch(expr);
    if (contains != null) {
      final field = contains.group(1)!;
      final rawArg = contains.group(2)!;
      final listValue = _resolveField(entity, field);
      final needle = _parseLiteral(rawArg);
      if (listValue is List) {
        for (final item in listValue) {
          if (_compareEquality(item, needle)) return true;
        }
      }
      if (listValue is String && needle is String) {
        return listValue.toLowerCase().contains(needle.toLowerCase());
      }
      return false;
    }

    final lengthCompare = RegExp(
      '^([A-Za-z0-9_.]+)\\.length\\s*(==|!=|>=|<=|>|<)\\s*(-?\\d+)',
    ).firstMatch(expr);
    if (lengthCompare != null) {
      final field = lengthCompare.group(1)!;
      final op = lengthCompare.group(2)!;
      final rhs = int.tryParse(lengthCompare.group(3)!) ?? 0;
      final value = _resolveField(entity, field);
      final length = value is List ? value.length : value is String ? value.length : 0;
      return _compareNumbers(length.toDouble(), rhs.toDouble(), op);
    }

    final compare =
      RegExp('^([A-Za-z0-9_.]+)\\s*(==|!=|>=|<=|>|<)\\s*(.+)').firstMatch(expr);
    if (compare != null) {
      final field = compare.group(1)!;
      final op = compare.group(2)!;
      final rhsRaw = compare.group(3)!;
      final lhs = _resolveField(entity, field);
      final rhs = _parseLiteral(rhsRaw);

      if (op == '==' || op == '!=') {
        final equals = _compareEquality(lhs, rhs);
        return op == '==' ? equals : !equals;
      }

      final lhsNum = _toNullableDouble(lhs);
      final rhsNum = _toNullableDouble(rhs);
      if (lhsNum == null || rhsNum == null) {
        return false;
      }
      return _compareNumbers(lhsNum, rhsNum, op);
    }

    return false;
  }

  static String _stripOuterParens(String input) {
    var text = input;
    while (text.startsWith('(') && text.endsWith(')')) {
      var depth = 0;
      var wrapsAll = true;
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        if (char == '(') depth++;
        if (char == ')') depth--;
        if (depth == 0 && i != text.length - 1) {
          wrapsAll = false;
          break;
        }
      }
      if (!wrapsAll) break;
      text = text.substring(1, text.length - 1).trim();
    }
    return text;
  }

  static List<String> _splitTopLevel(String expr, String separator) {
    final parts = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i <= expr.length - separator.length; i++) {
      final char = expr[i];
      if (char == '(') depth++;
      if (char == ')') depth--;
      if (depth == 0 && expr.substring(i, i + separator.length) == separator) {
        parts.add(expr.substring(start, i).trim());
        start = i + separator.length;
        i += separator.length - 1;
      }
    }
    if (parts.isEmpty) {
      return [expr];
    }
    parts.add(expr.substring(start).trim());
    return parts;
  }

  static dynamic _resolveField(Map<String, dynamic> entity, String path) {
    dynamic current = entity;
    for (final part in path.split('.')) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  static dynamic _parseLiteral(String raw) {
    final text = raw.trim();
    if (text.startsWith("'") && text.endsWith("'") && text.length >= 2) {
      return text
          .substring(1, text.length - 1)
          .replaceAll("\\'", "'")
          .replaceAll('\\"', '"');
    }
    if (text == 'true') return true;
    if (text == 'false') return false;
    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(text);
    if (asDouble != null) return asDouble;
    return text;
  }

  static bool _compareEquality(dynamic left, dynamic right) {
    if (left is String && right is String) {
      return left.toLowerCase() == right.toLowerCase();
    }
    return left == right;
  }

  static bool _compareNumbers(double left, double right, String op) {
    switch (op) {
      case '>':
        return left > right;
      case '>=':
        return left >= right;
      case '<':
        return left < right;
      case '<=':
        return left <= right;
      default:
        return false;
    }
  }

  static double? _toNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

int _toInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _toDouble(dynamic value, {required double fallback}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
