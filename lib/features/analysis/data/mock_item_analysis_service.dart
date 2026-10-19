import 'package:image_picker/image_picker.dart';

import '../../../models/item_analysis_result.dart';
import '../../../models/item_category.dart';
import '../../../models/recycling_item.dart';
import 'item_analysis_service.dart';

/// A deterministic demo fixture selector. It does not inspect image pixels.
class MockItemAnalysisService implements ItemAnalysisService {
  @override
  Future<ItemAnalysisResult> analyze({
    required XFile image,
    ItemCategory? manualCategory,
  }) async {
    final bytes = await image.readAsBytes();
    final hash = bytes.fold<int>(
      2166136261,
      (value, byte) => ((value ^ byte) * 16777619) & 0x7fffffff,
    );
    final category =
        manualCategory ??
        ItemCategory.values[hash % ItemCategory.values.length];
    final sample = _sampleFor(category);
    final confidence = category == ItemCategory.unknown
        ? 0.38
        : 0.58 + ((hash % 33) / 100);
    final ideas = sample?.reuseIdeas ?? const [];
    final reusable = ideas.isNotEmpty;

    return ItemAnalysisResult(
      itemName:
          sample?.name ??
          (category == ItemCategory.unknown
              ? 'Unidentified item'
              : '${category.label} item'),
      category: category,
      material: _materialFor(category),
      confidence: manualCategory == null ? confidence : null,
      condition: ItemCondition.notAssessed,
      reusable: reusable,
      reuseSuggestions: List.unmodifiable(ideas),
      recyclingRecommendation: reusable
          ? 'If reuse is not practical, check local collection guidance for ${category.label.toLowerCase()}.'
          : 'Recycling may be the better option. Check local collection guidance for ${category.label.toLowerCase()}.',
      explanation: manualCategory == null
          ? 'Demo result selected from sample data. The image was not interpreted by an AI model.'
          : 'Demo suggestions for the category you selected. The image was not interpreted by an AI model.',
      analysisKind: AnalysisKind.mock,
      categoryWasChosenManually: manualCategory != null,
    );
  }

  RecyclingItem? _sampleFor(ItemCategory category) {
    final items = RecyclingItem.sampleItems;
    return switch (category) {
      ItemCategory.plastic => items.first,
      ItemCategory.glass => items[1],
      ItemCategory.paper || ItemCategory.cardboard => items[2],
      ItemCategory.electronics => items[3],
      _ => null,
    };
  }

  String _materialFor(ItemCategory category) => switch (category) {
    ItemCategory.plastic => 'PET (sample material)',
    ItemCategory.paper => 'Paper fiber (sample material)',
    ItemCategory.cardboard => 'Corrugated fiberboard (sample material)',
    ItemCategory.glass => 'Glass (sample material)',
    ItemCategory.metal => 'Metal (sample material)',
    ItemCategory.electronics => 'Electronic components (sample material)',
    ItemCategory.textiles => 'Textile fibers (sample material)',
    ItemCategory.mixedMaterials => 'Mixed materials (sample)',
    ItemCategory.unknown => 'Not identified',
  };
}
