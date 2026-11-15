import 'dart:typed_data';

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
    late final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } on Exception {
      throw const ApiException(
        'Could not read the selected photo. Choose it again and retry.',
      );
    }
    final mimeType = (image.mimeType ?? _mimeTypeFromName(image.name))
        ?.toLowerCase();
    _validateImage(bytes, mimeType);
    final response = await api.analyzeImage(
      image: bytes,
      mimeType: mimeType!,
      manualCategory: manualCategory?.name,
    );
    if (response is! Map) {
      throw const ApiException(
        'The analysis service returned an incomplete result. Please retry.',
        statusCode: 502,
      );
    }
    try {
      return ItemAnalysisResult.fromApiJson(
        response.cast<String, dynamic>(),
        categoryWasChosenManually: manualCategory != null,
      );
    } on TypeError {
      throw const ApiException(
        'The analysis service returned an unreadable result. Please retry.',
        statusCode: 502,
      );
    } on FormatException {
      throw const ApiException(
        'The analysis service returned an unreadable result. Please retry.',
        statusCode: 502,
      );
    }
  }

  String? _mimeTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  void _validateImage(Uint8List image, String? mimeType) {
    if (image.isEmpty) {
      throw const ApiException('The selected photo is empty. Choose another.');
    }
    if (image.length > 8 * 1024 * 1024) {
      throw const ApiException(
        'This image is too large. Choose an image under 8 MB.',
        statusCode: 413,
      );
    }

    final isJpeg =
        image.length >= 3 &&
        image[0] == 0xff &&
        image[1] == 0xd8 &&
        image[2] == 0xff;
    const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    final isPng =
        image.length >= pngSignature.length &&
        List.generate(
          pngSignature.length,
          (index) => image[index] == pngSignature[index],
        ).every((matches) => matches);
    final isWebp =
        image.length >= 12 &&
        String.fromCharCodes(image.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(image.sublist(8, 12)) == 'WEBP';
    final matchesType = switch (mimeType) {
      'image/jpeg' => isJpeg,
      'image/png' => isPng,
      'image/webp' => isWebp,
      _ => false,
    };
    if (!matchesType) {
      throw const ApiException(
        'This image format is not supported. Choose a matching JPG, PNG, or WebP photo.',
      );
    }
  }
}
