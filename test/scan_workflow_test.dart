import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recircle/features/analysis/data/item_analysis_service.dart';
import 'package:recircle/features/analysis/data/mock_item_analysis_service.dart';
import 'package:recircle/features/analysis/data/backend_item_analysis_service.dart';
import 'package:recircle/features/scan/data/image_capture_service.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/models/item_analysis_result.dart';
import 'package:recircle/models/item_category.dart';
import 'package:recircle/models/pickup.dart';
import 'package:recircle/models/recycling_item.dart';
import 'package:recircle/models/reuse_idea.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/ai_screen.dart';
import 'package:recircle/screens/main_navigation_screen.dart';
import 'package:recircle/screens/pickup_booking_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  test(
    'backend analysis maps structured results without mock fallback',
    () async {
      final image = XFile.fromData(
        Uint8List.fromList([0xff, 0xd8, 0xff, 1]),
        name: 'laptop.jpg',
        mimeType: 'image/jpeg',
      );
      final api = _FixedAnalysisApi();
      final result = await BackendItemAnalysisService(api)
          .analyze(image: image);

      expect(api.mimeType, 'image/jpeg');
      expect(result.analysisKind, AnalysisKind.backend);
      expect(result.itemName, 'Laptop');
      expect(result.category, ItemCategory.electronics);
      expect(result.likelyMaterials, ['Aluminum']);
      expect(result.uncertaintyNotes, isNotEmpty);
      expect(result.safetyNotes, isNotEmpty);
      expect(result.reusable, isFalse);
    },
  );

  test(
    'mock analysis is deterministic and supports manual categories',
    () async {
      final image = XFile.fromData(
        Uint8List.fromList([0xff, 0xd8, 0xff, 1, 2, 3]),
        name: 'sample.jpg',
        mimeType: 'image/jpeg',
      );
      final service = MockItemAnalysisService();

      final first = await service.analyze(image: image);
      final second = await service.analyze(image: image);
      final manual = await service.analyze(
        image: image,
        manualCategory: ItemCategory.electronics,
      );

      expect(first.category, second.category);
      expect(first.itemName, second.itemName);
      expect(first.analysisKind, AnalysisKind.mock);
      expect(first.explanation, contains('not interpreted'));
      expect(manual.category, ItemCategory.electronics);
      expect(manual.categoryWasChosenManually, isTrue);
      expect(manual.confidence, isNull);
    },
  );

  testWidgets('lost Android image is restored into the scan result', (
    tester,
  ) async {
    final appState = AppState();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme.copyWith(splashFactory: NoSplash.splashFactory),
        home: MainNavigationScreen(
          appState: appState,
          imageCaptureService: _FixedImageCaptureService(
            recoveredImage: _FixedImageCaptureService.image,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Analyze Item'), findsOneWidget);
  });

  testWidgets(
    'photo selection shows mock results, reuse guide, and pickup fallback',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = AppState();
      final idea = RecyclingItem.sampleItems.first.reuseIdeas.first;
      final analysis = _FixedAnalysisService(idea);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme.copyWith(splashFactory: NoSplash.splashFactory),
          home: AIScreen(
            appState: appState,
            imageCaptureService: _FixedImageCaptureService(),
            analysisService: analysis,
          ),
        ),
      );

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();
      expect(find.text('Analyze Item'), findsOneWidget);
      await tester.tap(find.text('Analyze Item'));
      await tester.pumpAndSettle();
      expect(find.text('Sample analysis · demo data'), findsOneWidget);
      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(
        find.textContaining('image was not interpreted'),
        findsNWidgets(2),
      );

      await tester.ensureVisible(find.text('Use a Reuse Idea'));
      await tester.tap(find.text('Use a Reuse Idea'));
      await tester.pumpAndSettle();
      expect(find.text('DIY Reuse Guide'), findsOneWidget);
      expect(find.textContaining('Safety:'), findsOneWidget);
      await tester.tap(find.byTooltip('Save idea'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove saved idea'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Recycle Instead'));
      await tester.tap(find.text('Recycle Instead'));
      await tester.pumpAndSettle();
      expect(find.text('Book Recycling Pickup'), findsOneWidget);
      expect(find.text('Plastic Bottle'), findsOneWidget);
    },
  );

  testWidgets('tracking confirmation opens the newly booked pickup', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState(api: _SuccessfulRequestApi());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme.copyWith(splashFactory: NoSplash.splashFactory),
        home: PickupBookingScreen(
          appState: appState,
          initialItemName: 'Test e-waste item',
          initialCategory: 'E-Waste',
        ),
      ),
    );

    await tester.ensureVisible(find.text('Submit Request'));
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();
    expect(find.text('Request Submitted'), findsOneWidget);

    await tester.tap(find.text('Track My Pickup'));
    await tester.pumpAndSettle();
    expect(find.text('Request #request-test-1'), findsOneWidget);
    expect(appState.pickups.first.itemName, 'Test e-waste item');
    expect(appState.pickups.first.status, PickupStatus.booked);
  });
}

class _SuccessfulRequestApi extends ReCircleApi {
  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    if (path != '/requests' || body == null) {
      throw StateError('Unexpected API call: $path');
    }
    return {
      '_id': 'request-test-1',
      'item': body['item'],
      'pickup': body['pickup'],
      'status': 'Submitted',
      'createdAt': DateTime.utc(2026, 10, 16).toIso8601String(),
      'history': [
        {
          'from': null,
          'to': 'Submitted',
          'actor': 'customer-test',
          'at': DateTime.utc(2026, 10, 16).toIso8601String(),
          'note': '',
        },
      ],
    };
  }
}

class _FixedAnalysisApi extends ReCircleApi {
  String? mimeType;

  @override
  Future<dynamic> analyzeImage({
    required Uint8List image,
    required String mimeType,
    String? manualCategory,
  }) async {
    this.mimeType = mimeType;
    return {
      'itemName': 'Laptop',
      'category': 'electronics',
      'likelyMaterials': ['Aluminum'],
      'visibleCondition': 'worn',
      'reusePotential': 'unlikely',
      'confidence': 0.84,
      'uncertaintyNotes': ['Internal function cannot be seen.'],
      'reuseSuggestions': [],
      'recyclingRecommendation': 'Check local e-waste guidance.',
      'safetyNotes': ['Do not use a swollen battery.'],
      'explanation': 'A laptop is visible.',
    };
  }
}

class _FixedImageCaptureService implements ImageCaptureService {
  _FixedImageCaptureService({this.recoveredImage});

  static final _image = XFile.fromData(
    Uint8List.fromList([0xff, 0xd8, 0xff, 0x10, 0x20, 0x30]),
    name: 'capture.jpg',
    mimeType: 'image/jpeg',
  );
  static XFile get image => _image;

  final XFile? recoveredImage;

  @override
  Future<XFile?> captureOrChoose(ImageSource source) async => _image;

  @override
  Future<XFile?> retrieveLostImage() async => recoveredImage;
}

class _FixedAnalysisService implements ItemAnalysisService {
  const _FixedAnalysisService(this.idea);

  final ReuseIdea idea;

  @override
  Future<ItemAnalysisResult> analyze({
    required XFile image,
    ItemCategory? manualCategory,
  }) async => ItemAnalysisResult(
    itemName: 'Plastic Bottle',
    category: ItemCategory.plastic,
    material: 'PET · mock sample',
    confidence: 0.94,
    condition: ItemCondition.notAssessed,
    reusable: true,
    reuseSuggestions: [idea],
    recyclingRecommendation: 'Use the demo pickup flow if reuse is unsuitable.',
    explanation: 'Mock result; the image was not interpreted by an AI model.',
    analysisKind: AnalysisKind.mock,
  );
}
