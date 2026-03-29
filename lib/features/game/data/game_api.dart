import 'dart:convert';
import 'dart:io';

import '../domain/quiz_card.dart';

class GameApi {
  const GameApi();

  static const String _defaultBaseUrl = String.fromEnvironment(
    'FUTSWIPE_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Future<List<QuizCard>> fetchQuestions({
    int count = 14,
    String targetType = 'player',
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    try {
      final uri = Uri.parse('$_defaultBaseUrl/questions/generate');
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 4));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'count': count,
          'target_type': targetType,
        }),
      );

      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Question API failed: ${response.statusCode}', uri: uri);
      }

      final body = await response.transform(utf8.decoder).join().timeout(
            const Duration(seconds: 5),
          );
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        throw const FormatException('Invalid question payload format');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(QuizCard.fromBackendJson)
          .where((card) =>
              card.name.trim().isNotEmpty &&
              card.imageUrl.trim().isNotEmpty &&
              card.ruleText.trim().isNotEmpty)
          .toList();
    } finally {
      client.close();
    }
  }
}
