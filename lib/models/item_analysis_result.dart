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
    this.analysisId,
    this.analyzedAt,
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
  final String? analysisId;
  final DateTime? analyzedAt;

  factory ItemAnalysisResult.fromApiJson(
    Map<String, dynamic> data, {
    bool categoryWasChosenManually = false,
  }) {
    final materials = (data['likelyMaterials'] as List? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final rawIdeas = (data['reuseSuggestions'] as List? ?? const []);
    final ideas = rawIdeas.indexed
        .map((entry) {
          final json = (entry.$2 as Map).cast<String, Object?>();
          json['id'] ??= 'saved-reuse-${entry.$1}';
          return ReuseIdea.fromJson(json);
        })
        .toList(growable: false);
    final visibleCondition = data['visibleCondition'] as String? ?? 'unknown';
    final reusePotential = data['reusePotential'] as String? ?? 'uncertain';
    final categoryName = data['category'] as String? ?? 'unknown';
    final category = ItemCategory.values.firstWhere(
      (item) => item.name == categoryName,
      orElse: () => ItemCategory.unknown,
    );
    final analyzedAtValue = data['analyzedAt'];

    return ItemAnalysisResult(
      itemName: data['itemName'] as String? ?? 'Unidentified item',
      category: category,
      material: materials.isEmpty
          ? 'Not clear from the image'
          : materials.join(', '),
      confidence: (data['confidence'] as num?)?.toDouble(),
      condition: visibleCondition == 'damaged'
          ? ItemCondition.damaged
          : visibleCondition == 'good' && reusePotential == 'promising'
          ? ItemCondition.reusable
          : ItemCondition.unknown,
      visibleCondition: visibleCondition,
      likelyMaterials: materials,
      uncertaintyNotes: (data['uncertaintyNotes'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      safetyNotes: (data['safetyNotes'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      reusable: reusePotential == 'promising' && ideas.isNotEmpty,
      reuseSuggestions: ideas,
      recyclingRecommendation:
          data['recyclingRecommendation'] as String? ??
          'Check local recycling guidance.',
      explanation:
          data['explanation'] as String? ??
          'No additional analysis details were saved.',
      analysisKind: AnalysisKind.backend,
      categoryWasChosenManually: categoryWasChosenManually,
      analysisId: (data['id'] ?? data['analysisId'])?.toString(),
      analyzedAt: analyzedAtValue == null
          ? null
          : DateTime.tryParse(analyzedAtValue.toString()),
    );
  }

  bool get needsManualCategory =>
      category == ItemCategory.unknown ||
      (!categoryWasChosenManually &&
          (confidence == null || confidence! < 0.65));
}
