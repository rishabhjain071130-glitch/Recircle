import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircle/models/ewaste_weight_estimates.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/impact_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  test('category weight estimates cover common products and fallback', () {
    expect(
      EwasteWeightEstimates.kilogramsByCategory,
      containsPair('phone/mobile', 0.1),
    );
    expect(
      EwasteWeightEstimates.estimateKg(
        category: 'Electronics',
        itemName: 'Laptop',
      ),
      2.9,
    );
    expect(EwasteWeightEstimates.estimateKg(category: 'Unknown'), 1.0);
  });

  test('reuse and recycling actions update local estimated impact', () {
    final state = AppState();

    state.markAnalyzedItemAsReused(
      itemName: 'Laptop',
      category: 'Electronics / E-waste',
    );
    state.markAnalyzedItemAsRecycled(
      itemName: 'Printer',
      category: 'Electronics / E-waste',
    );

    expect(state.impactStats.itemsReused, 1);
    expect(state.impactStats.itemsRecycled, 1);
    expect(state.impactStats.estimatedWasteDivertedKg, 10.8);
    expect(state.impactStats.rewardPoints, 20);
    expect(state.rewardActivities.first.points, 0);
    expect(state.rewardActivities.first.note, contains('not been verified'));
  });

  testWidgets('impact screen labels estimates and explains methodology', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: ImpactScreen(appState: AppState()),
      ),
    );

    expect(
      find.text('Demo totals · impact is estimated, not physically measured'),
      findsOneWidget,
    );
    expect(find.text('Estimated Waste Diverted'), findsOneWidget);
    expect(find.text('Demo Points'), findsOneWidget);

    await tester.tap(find.byTooltip('How is this estimated?'));
    await tester.pumpAndSettle();
    expect(find.text('How is the impact estimated?'), findsOneWidget);
    expect(
      find.textContaining('does not prove that a specific amount'),
      findsOneWidget,
    );
  });
}
