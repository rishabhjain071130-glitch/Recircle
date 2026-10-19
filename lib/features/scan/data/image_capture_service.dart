import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

abstract interface class ImageCaptureService {
  Future<XFile?> captureOrChoose(ImageSource source);
  Future<XFile?> retrieveLostImage();
}

class ImageSelectionException implements Exception {
  const ImageSelectionException(this.message, {this.permissionDenied = false});

  final String message;
  final bool permissionDenied;

  @override
  String toString() => message;
}

class PlatformImageCaptureService implements ImageCaptureService {
  PlatformImageCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  static const int maxImageBytes = 8 * 1024 * 1024;

  @override
  Future<XFile?> captureOrChoose(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (image == null) return null;
      await _validateImage(image);
      return image;
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  @override
  Future<XFile?> retrieveLostImage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      if (response.exception != null) {
        throw _mapPlatformException(response.exception!);
      }
      final files = response.files;
      final image =
          response.file ??
          (files != null && files.isNotEmpty ? files.first : null);
      if (image == null) {
        throw const ImageSelectionException(
          'The interrupted image selection could not be restored. Please choose the image again.',
        );
      }
      await _validateImage(image);
      return image;
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  ImageSelectionException _mapPlatformException(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('denied') || code.contains('permission')) {
      return const ImageSelectionException(
        'Camera or photo access was declined. Check this app’s camera and photo permissions in Android Settings, then try again.',
        permissionDenied: true,
      );
    }
    return ImageSelectionException(
      error.message ??
          'Could not open the camera or photo picker. Please try again.',
    );
  }

  Future<void> _validateImage(XFile image) async {
    final length = await image.length();
    if (length == 0) {
      throw const ImageSelectionException(
        'The selected image is empty. Choose another image.',
      );
    }
    if (length > maxImageBytes) {
      throw const ImageSelectionException(
        'That image is too large. Choose an image under 8 MB.',
      );
    }
    if (!await _hasSupportedImageSignature(image)) {
      throw const ImageSelectionException(
        'This image format is not supported. Choose a JPG, PNG, or WebP image.',
      );
    }
  }

  Future<bool> _hasSupportedImageSignature(XFile image) async {
    final length = await image.length();
    final bytes = await image
        .openRead(0, length < 16 ? length : 16)
        .fold<List<int>>([], (all, part) => all..addAll(part));
    bool startsWith(List<int> signature) =>
        bytes.length >= signature.length &&
        List.generate(
          signature.length,
          (index) => bytes[index] == signature[index],
        ).every((matches) => matches);

    final isJpeg =
        bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final isPng = startsWith([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    final isWebp =
        bytes.length >= 12 &&
        startsWith([0x52, 0x49, 0x46, 0x46]) &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    return isJpeg || isPng || isWebp;
  }
}
