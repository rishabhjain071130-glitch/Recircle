import 'package:image_picker/image_picker.dart';

import '../../../models/item_analysis_result.dart';
import '../../../models/item_category.dart';

abstract interface class ItemAnalysisService {
  Future<ItemAnalysisResult> analyze({
    required XFile image,
    ItemCategory? manualCategory,
  });
}
