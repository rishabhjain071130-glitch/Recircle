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
