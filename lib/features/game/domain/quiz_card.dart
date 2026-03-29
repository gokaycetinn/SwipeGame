class QuizCard {
  const QuizCard({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.ruleText,
    required this.expectedAnswer,
  });

  final String id;
  final String name;
  final String subtitle;
  final String imageUrl;
  final String ruleText;
  final bool expectedAnswer;

  factory QuizCard.fromBackendJson(Map<String, dynamic> json) {
    final entityId = json['entity_id'];
    final id = entityId is int ? entityId.toString() : '${entityId ?? ''}';

    return QuizCard(
      id: id,
      name: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      ruleText: (json['rule_text'] ?? '').toString(),
      expectedAnswer: json['expected_answer'] == true,
    );
  }
}
