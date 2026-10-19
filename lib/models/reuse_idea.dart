class ReuseIdea {
  final String id;
  final String title;
  final String shortDescription;
  final String category;
  final String difficulty; // e.g. "Easy", "Medium"
  final String timeRequired; // e.g. "15 mins"
  final List<String> materialsNeeded;
  final List<String> steps;
  final String iconName;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'shortDescription': shortDescription,
    'category': category,
    'difficulty': difficulty,
    'timeRequired': timeRequired,
    'materialsNeeded': materialsNeeded,
    'steps': steps,
    'iconName': iconName,
  };

  factory ReuseIdea.fromJson(Map<String, Object?> json) => ReuseIdea(
    id: json['id']! as String,
    title: json['title']! as String,
    shortDescription: json['shortDescription']! as String,
    category: json['category']! as String,
    difficulty: json['difficulty']! as String,
    timeRequired: json['timeRequired']! as String,
    materialsNeeded: (json['materialsNeeded'] as List<Object?>? ?? const [])
        .cast<String>(),
    steps: (json['steps'] as List<Object?>? ?? const []).cast<String>(),
    iconName: json['iconName'] as String? ?? 'lightbulb',
  );

  const ReuseIdea({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.category,
    required this.difficulty,
    required this.timeRequired,
    required this.materialsNeeded,
    required this.steps,
    this.iconName = 'lightbulb',
  });
}
