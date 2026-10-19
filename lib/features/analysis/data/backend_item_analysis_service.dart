import 'package:image_picker/image_picker.dart';

import '../../../models/item_analysis_result.dart';
import '../../../models/item_category.dart';
import '../../../models/reuse_idea.dart';
import '../../requests/data/recircle_api.dart';
import 'item_analysis_service.dart';

class BackendItemAnalysisService implements ItemAnalysisService {
  const BackendItemAnalysisService(this.api);

  final ReCircleApi api;

  @override
  Future<ItemAnalysisResult> analyze({
    required XFile image,
    ItemCategory? manualCategory,
  }) async {
    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? _mimeTypeFromName(image.name);
    final data = (await api.analyzeImage(
      image: bytes,
      mimeType: mimeType,
      manualCategory: manualCategory?.name,
    ) as Map).cast<String, dynamic>();
    final materials = (data['likelyMaterials'] as List).cast<String>();
    final ideas = (data['reuseSuggestions'] as List).indexed
        .map((entry) {
          final json = (entry.$2 as Map).cast<String, Object?>();
          json['id'] = 'ai-reuse-${entry.$1}';
          return ReuseIdea.fromJson(json);
        })
        .toList(growable: false);
    final visibleCondition = data['visibleCondition'] as String;
    final reusePotential = data['reusePotential'] as String;

    return ItemAnalysisResult(
      itemName: data['itemName'] as String,
      category: ItemCategory.values.byName(data['category'] as String),
      material: materials.isEmpty
          ? 'Not clear from the image'
          : materials.join(', '),
      confidence: (data['confidence'] as num).toDouble(),
      condition: visibleCondition == 'damaged'
          ? ItemCondition.damaged
          : visibleCondition == 'good' && reusePotential == 'promising'
          ? ItemCondition.reusable
          : ItemCondition.unknown,
      visibleCondition: visibleCondition,
      likelyMaterials: materials,
      uncertaintyNotes: (data['uncertaintyNotes'] as List).cast<String>(),
      safetyNotes: (data['safetyNotes'] as List).cast<String>(),
      reusable: reusePotential == 'promising' && ideas.isNotEmpty,
      reuseSuggestions: ideas,
      recyclingRecommendation: data['recyclingRecommendation'] as String,
      explanation: data['explanation'] as String,
      analysisKind: AnalysisKind.backend,
      categoryWasChosenManually: manualCategory != null,
    );
  }

  String _mimeTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
