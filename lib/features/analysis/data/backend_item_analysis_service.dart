import 'package:image_picker/image_picker.dart';

import '../../../models/item_analysis_result.dart';
import '../../../models/item_category.dart';
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
    return ItemAnalysisResult.fromApiJson(
      data,
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
