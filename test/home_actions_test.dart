import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recircle/features/scan/data/image_capture_service.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/main_navigation_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  testWidgets('Home quick actions open their existing workflows', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final captureService = _RecordingImageCaptureService();
    final appState = AppState();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme.copyWith(splashFactory: NoSplash.splashFactory),
        home: MainNavigationScreen(
          appState: appState,
          imageCaptureService: captureService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book Pickup'));
    await tester.pumpAndSettle();
    expect(find.text('Book Recycling Pickup'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sell / Reuse'));
    await tester.pumpAndSettle();
    expect(captureService.sources.last, ImageSource.gallery);
    expect(find.text('Take Photo'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan Item'));
    await tester.pumpAndSettle();
    expect(captureService.sources.last, ImageSource.camera);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI Assistant'));
    await tester.pumpAndSettle();
    expect(find.text('Take Photo'), findsOneWidget);
    expect(captureService.sources.length, 2);
  });
}

class _RecordingImageCaptureService implements ImageCaptureService {
  final List<ImageSource> sources = [];

  @override
  Future<XFile?> captureOrChoose(ImageSource source) async {
    sources.add(source);
    return null;
  }

  @override
  Future<XFile?> retrieveLostImage() async => null;
}
