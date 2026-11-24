import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/models/pickup.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/pickup_tracking_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  testWidgets(
    'tracking auto-refreshes only its pickup and keeps the timeline',
    (tester) async {
      final api = _TrackingApi(responseStatus: 'Accepted');
      final appState = AppState(api: api);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: PickupTrackingScreen(
            pickup: _pickup('Submitted'),
            appState: appState,
          ),
        ),
      );

      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('Tracking Timeline'), findsOneWidget);
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(api.requestIds, ['pickup-1']);
      expect(api.getPaths, isEmpty);
      expect(appState.pickups.single.status, PickupStatus.partnerAssigned);
      expect(find.text('Partner Assigned'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.textContaining('Updated '), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      api.responseStatus = 'Collected';
      await tester.tap(find.byTooltip('Refresh status'));
      await tester.pumpAndSettle();

      expect(api.requestIds, ['pickup-1', 'pickup-1']);
      expect(appState.pickups.single.status, PickupStatus.collected);
      expect(find.text('Collected'), findsNWidgets(2));
      expect(find.text('Pickup status updated to Collected.'), findsOneWidget);
    },
  );

  testWidgets(
    'overlapping refreshes are prevented and timer stops on dispose',
    (tester) async {
      final api = _TrackingApi(responseStatus: 'Accepted')
        ..pendingRequest = Completer<dynamic>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: PickupTrackingScreen(
            pickup: _pickup('Submitted'),
            appState: AppState(api: api),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Refresh status'));
      await tester.pump();
      expect(api.requestIds, ['pickup-1']);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      expect(api.requestIds, ['pickup-1']);

      api.pendingRequest!.complete(_pickupJson('Accepted'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(api.requestIds, ['pickup-1']);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 40));
      expect(api.requestIds, ['pickup-1']);
    },
  );
}

Pickup _pickup(String status) => Pickup.fromApiJson(_pickupJson(status));

Map<String, dynamic> _pickupJson(String status) => {
  '_id': 'pickup-1',
  'item': {
    'name': 'Laptop',
    'category': 'E-Waste',
    'condition': 'Not working',
    'quantity': 1,
  },
  'pickup': {
    'address': '12 Green Street',
    'preferredDate': 'Tomorrow',
    'preferredTime': 'Morning',
  },
  'status': status,
  'createdAt': '2026-11-24T08:00:00.000Z',
  'history': [
    {
      'from': null,
      'to': 'Submitted',
      'at': '2026-11-24T08:00:00.000Z',
      'note': '',
    },
    if (status != 'Submitted')
      {
        'from': 'Submitted',
        'to': status,
        'at': '2026-11-24T09:00:00.000Z',
        'note': '',
      },
  ],
};

class _TrackingApi extends ReCircleApi {
  _TrackingApi({required this.responseStatus});

  String responseStatus;
  final List<String> requestIds = [];
  final List<String> getPaths = [];
  Completer<dynamic>? pendingRequest;

  @override
  Future<dynamic> getRequest(String id) {
    requestIds.add(id);
    if (pendingRequest != null) return pendingRequest!.future;
    return Future.value(_pickupJson(responseStatus));
  }

  @override
  Future<dynamic> get(String path) async {
    getPaths.add(path);
    throw StateError('Tracking must fetch only the selected pickup.');
  }
}
