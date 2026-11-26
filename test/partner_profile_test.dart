import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/models/partner_profile.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/partner_profile_screen.dart';
import 'package:recircle/screens/pickup_booking_screen.dart';

void main() {
  test(
    'partner profile parsing handles missing and optional fields safely',
    () {
      final basic = PartnerProfile.fromJson({
        'partnerId': 'partner-1',
        'name': 'Riya',
      });
      expect(basic.id, 'partner-1');
      expect(basic.displayName, 'Riya');
      expect(basic.acceptedCategories, isEmpty);
      expect(basic.available, isFalse);
      expect(basic.registeredAt, isNull);

      final complete = PartnerProfile.fromJson(_profileData());
      expect(complete.businessName, 'Green Loop');
      expect(complete.partnerType, 'Recycler');
      expect(complete.isApproved, isTrue);
      expect(complete.acceptedCategories, ['Electronics', 'Batteries']);
      expect(complete.distanceKm, 2.4);
    },
  );

  testWidgets(
    'approved partner profile shows verification and pickup details',
    (tester) async {
      final state = _state();
      await tester.pumpWidget(
        MaterialApp(
          home: PartnerProfileScreen(
            appState: state,
            partnerId: 'partner-1',
            initialProfile: PartnerProfile.fromJson(_profileData()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Approved ReCircle partner'), findsOneWidget);
      expect(find.text('Green Loop'), findsOneWidget);
      expect(find.text('Recycler'), findsOneWidget);
      expect(find.textContaining('Electronics, Batteries'), findsOneWidget);
      expect(find.text('2.4 km away'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Select Partner'), 300);
      expect(find.text('Select Partner'), findsOneWidget);
    },
  );

  testWidgets('unavailable partner is shown and cannot be selected', (
    tester,
  ) async {
    final data = _profileData()..['available'] = false;
    final state = _state(data);
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerProfileScreen(
          appState: state,
          partnerId: 'partner-1',
          initialProfile: PartnerProfile.fromJson(data),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Currently unavailable'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('Partner unavailable'), 300);
    expect(find.text('Partner unavailable'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Partner unavailable'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'Select Partner passes the profile ID into existing pickup booking',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PartnerProfileScreen(
            appState: _state(),
            partnerId: 'partner-1',
            initialProfile: PartnerProfile.fromJson(_profileData()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Select Partner'), 300);
      await tester.tap(find.text('Select Partner'));
      await tester.pumpAndSettle();

      final booking = tester.widget<PickupBookingScreen>(
        find.byType(PickupBookingScreen),
      );
      expect(booking.preferredPartnerId, 'partner-1');
      expect(booking.preferredPartnerName, 'Green Loop');
      expect(find.text('Pickup partner: Green Loop'), findsOneWidget);
    },
  );
}

AppState _state([Map<String, dynamic>? data]) => AppState(
  api: ReCircleApi(
    client: MockClient(
      (request) async => http.Response(
        jsonEncode({'success': true, 'data': data ?? _profileData()}),
        200,
        request: request,
      ),
    ),
  ),
);

Map<String, dynamic> _profileData() => {
  'id': 'partner-1',
  'name': 'Riya Owner',
  'businessName': 'Green Loop',
  'partnerType': 'Recycler',
  'acceptedCategories': ['Electronics', 'Batteries'],
  'phone': '+911234567890',
  'address': '12 Green Street',
  'city': 'Pune',
  'pinCode': '411001',
  'serviceArea': 'Central Pune',
  'partnerStatus': 'approved',
  'available': true,
  'registeredAt': '2025-03-10T00:00:00Z',
  'distanceKm': 2.4,
};
