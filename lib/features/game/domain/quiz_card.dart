class QuizCard {
  const QuizCard({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.rules,
  });

  final String id;
  final String name;
  final String subtitle;
  final String imageUrl;
  final Map<String, bool> rules;
}
