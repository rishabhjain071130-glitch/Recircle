import 'item_category.dart';
import 'reuse_idea.dart';

enum ItemCondition { notAssessed, reusable, damaged, unknown }

enum AnalysisKind { mock, backend }

class ItemAnalysisResult {
  const ItemAnalysisResult({
    required this.itemName,
    required this.category,
    required this.material,
    required this.condition,
    required this.reusable,
    required this.reuseSuggestions,
    required this.recyclingRecommendation,
    required this.explanation,
    required this.analysisKind,
    this.confidence,
    this.categoryWasChosenManually = false,
    this.likelyMaterials = const [],
    this.uncertaintyNotes = const [],
    this.safetyNotes = const [],
    this.visibleCondition,
  }) : assert(confidence == null || (confidence >= 0 && confidence <= 1));

  final String itemName;
  final ItemCategory category;
  final String material;
  final double? confidence;
  final ItemCondition condition;
  final bool reusable;
  final List<ReuseIdea> reuseSuggestions;
  final String recyclingRecommendation;
  final String explanation;
  final AnalysisKind analysisKind;
  final bool categoryWasChosenManually;
  final List<String> likelyMaterials;
  final List<String> uncertaintyNotes;
  final List<String> safetyNotes;
  final String? visibleCondition;

  bool get needsManualCategory =>
      category == ItemCategory.unknown ||
      (!categoryWasChosenManually &&
          (confidence == null || confidence! < 0.65));
}
