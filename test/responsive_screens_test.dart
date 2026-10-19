import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircle/models/pickup.dart';
import 'package:recircle/models/recycling_item.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/ai_screen.dart';
import 'package:recircle/screens/home_screen.dart';
import 'package:recircle/screens/impact_screen.dart';
import 'package:recircle/screens/main_navigation_screen.dart';
import 'package:recircle/screens/pickup_booking_screen.dart';
import 'package:recircle/screens/pickup_tracking_screen.dart';
import 'package:recircle/screens/pickups_screen.dart';
import 'package:recircle/screens/profile_screen.dart';
import 'package:recircle/screens/reuse_detail_screen.dart';
import 'package:recircle/screens/rewards_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  testWidgets('screens lay out without overflow on narrow Android widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [320.0, 360.0, 412.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 780);
      final state = AppState();
      final testTheme = AppTheme.theme.copyWith(
        splashFactory: NoSplash.splashFactory,
      );
      final pickup = Pickup.samplePickups.first;
      final idea = RecyclingItem.sampleItems.first.reuseIdeas.first;
      final screens = <Widget>[
        HomeScreen(appState: state, onNavigateToTab: (_, {actionMode}) {}),
        AIScreen(appState: state),
        PickupsScreen(appState: state),
        ImpactScreen(appState: state),
        ProfileScreen(appState: state),
        RewardsScreen(appState: state),
        ReuseDetailScreen(idea: idea, appState: state),
        PickupTrackingScreen(pickup: pickup, appState: state),
        PickupBookingScreen(appState: state),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(MaterialApp(theme: testTheme, home: screen));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason:
              '${screen.runtimeType} overflowed at ${width.toInt()} logical pixels',
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme,
          home: MainNavigationScreen(appState: state),
        ),
      );
      await tester.pumpAndSettle();
      for (final tab in ['Scan', 'Pickups', 'Impact', 'Profile', 'Home']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Navigation to $tab overflowed',
        );
      }
    }
  });
}
