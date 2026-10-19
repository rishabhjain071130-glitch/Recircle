class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.points,
    required this.earnedAt,
    this.eligibilityNote,
  }) : assert(points >= 0);

  final String id;
  final String title;
  final int points;
  final DateTime earnedAt;
  final String? eligibilityNote;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'points': points,
    'earnedAt': earnedAt.toIso8601String(),
    'eligibilityNote': eligibilityNote,
  };
}
