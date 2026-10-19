import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/analysis_history_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  testWidgets('history shows an empty state when the account has no analyses', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_HistoryApi()));
    await tester.pumpAndSettle();

    expect(find.text('No saved analyses yet'), findsOneWidget);
    expect(
      find.text('Analyze an item and it will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('history lists saved results and opens backend detail data', (
    tester,
  ) async {
    final api = _HistoryApi(withRecord: true);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Desk lamp'), findsOneWidget);
    expect(find.textContaining('80% confidence'), findsOneWidget);
    await tester.tap(find.text('Desk lamp'));
    await tester.pumpAndSettle();

    expect(find.text('Saved Analysis'), findsOneWidget);
    expect(find.text('A lamp is visible.'), findsOneWidget);
    expect(api.detailRequests, 1);
  });

  testWidgets('history shows a retry action for backend errors', (
    tester,
  ) async {
    final api = _HistoryApi(failFirstHistoryRequest: true);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('History unavailable'), findsOneWidget);
    expect(
      find.text('Saved analyses could not be loaded. Please retry.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No saved analyses yet'), findsOneWidget);
  });
}

Widget _app(_HistoryApi api) => MaterialApp(
  theme: AppTheme.theme,
  home: AnalysisHistoryScreen(appState: AppState(api: api)),
);

class _HistoryApi extends ReCircleApi {
  _HistoryApi({this.withRecord = false, this.failFirstHistoryRequest = false});

  final bool withRecord;
  final bool failFirstHistoryRequest;
  int historyRequests = 0;
  int detailRequests = 0;

  static Map<String, dynamic> get _result => {
    'id': 'aaaaaaaaaaaaaaaaaaaaaaaa',
    'itemName': 'Desk lamp',
    'category': 'metal',
    'likelyMaterials': ['metal'],
    'visibleCondition': 'good',
    'reusePotential': 'promising',
    'confidence': 0.8,
    'uncertaintyNotes': <String>[],
    'reuseSuggestions': <Map<String, Object?>>[],
    'recyclingRecommendation': 'Check local guidance.',
    'safetyNotes': <String>[],
    'explanation': 'A lamp is visible.',
    'analyzedAt': '2026-10-18T12:00:00.000Z',
  };

  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/analysis/history?')) {
      historyRequests += 1;
      if (failFirstHistoryRequest && historyRequests == 1) {
        throw const ApiException(
          'Saved analyses could not be loaded. Please retry.',
        );
      }
      return {
        'items': withRecord ? [_result] : <Map<String, dynamic>>[],
        'pagination': {
          'page': 1,
          'limit': 20,
          'total': withRecord ? 1 : 0,
          'totalPages': withRecord ? 1 : 0,
        },
      };
    }
    if (path == '/analysis/history/aaaaaaaaaaaaaaaaaaaaaaaa') {
      detailRequests += 1;
      return _result;
    }
    throw StateError('Unexpected API path: $path');
  }
}
