import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recircle/features/scan/data/image_capture_service.dart';

void main() {
  test('image picker cancellation returns null without an error', () async {
    final service = PlatformImageCaptureService(
      picker: _FixedImagePicker(null),
    );

    expect(await service.captureOrChoose(ImageSource.gallery), isNull);
  });

  test('valid JPEG image passes signature validation', () async {
    final image = XFile.fromData(
      Uint8List.fromList([0xff, 0xd8, 0xff, 0x10, 0x20]),
      name: 'valid.jpg',
      mimeType: 'image/jpeg',
    );
    final service = PlatformImageCaptureService(
      picker: _FixedImagePicker(image),
    );

    expect(await service.captureOrChoose(ImageSource.gallery), same(image));
  });

  test('unsupported image signature is rejected', () async {
    final image = XFile.fromData(
      Uint8List.fromList([0x00, 0x01, 0x02, 0x03]),
      name: 'unsupported.jpg',
      mimeType: 'image/jpeg',
    );
    final service = PlatformImageCaptureService(
      picker: _FixedImagePicker(image),
    );

    await expectLater(
      service.captureOrChoose(ImageSource.gallery),
      throwsA(isA<ImageSelectionException>()),
    );
  });
}

class _FixedImagePicker extends ImagePicker {
  _FixedImagePicker(this.image);

  final XFile? image;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => image;
}
