import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';

void main() {
  test('release URL defaults to the production HTTPS API', () {
    expect(
      ReCircleApi.resolveBaseUrl('', debugMode: false),
      'https://recircle-backend-upbt.onrender.com/api/v1',
    );
  });

  test('explicit API URL is trimmed and trailing slashes are removed', () {
    expect(
      ReCircleApi.resolveBaseUrl(
        ' https://example.com/api/v1/ ',
        debugMode: false,
      ),
      'https://example.com/api/v1',
    );
  });

  test('login posts expected fields and parses token and user response', () async {
    late http.Request sent;
    final api = ReCircleApi(
      baseUrl: ReCircleApi.productionBaseUrl,
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'token': 'test-token',
              'user': {
                'id': 'user-1',
                'name': 'Sam',
                'email': 'sam@example.com',
                'role': 'customer',
              },
            },
          }),
          200,
        );
      }),
    );

    final result = await api.login('sam@example.com', 'password123') as Map;

    expect(sent.url.toString(), '${ReCircleApi.productionBaseUrl}/auth/login');
    expect(sent.method, 'POST');
    expect(jsonDecode(sent.body), {
      'email': 'sam@example.com',
      'password': 'password123',
    });
    expect(result['token'], 'test-token');
    expect((result['user'] as Map)['role'], 'customer');
  });

  test('registration posts expected fields to the registration endpoint', () async {
    late http.Request sent;
    final api = ReCircleApi(
      baseUrl: ReCircleApi.productionBaseUrl,
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          '{"success":true,"data":{"token":"test-token","user":{"role":"customer"}}}',
          201,
        );
      }),
    );

    await api.register('Sam', 'sam@example.com', 'password123');

    expect(sent.url.toString(), '${ReCircleApi.productionBaseUrl}/auth/register');
    expect(jsonDecode(sent.body), {
      'name': 'Sam',
      'email': 'sam@example.com',
      'password': 'password123',
    });
  });

  test('authentication and server errors use safe actionable messages', () async {
    for (final entry in {
      401: 'Email or password is incorrect.',
      409: 'An account with this email already exists. Sign in instead.',
      500: 'ReCircle is having trouble right now. Try again shortly.',
    }.entries) {
      final api = ReCircleApi(
        baseUrl: ReCircleApi.productionBaseUrl,
        client: MockClient(
          (_) async => http.Response(
            '{"success":false,"error":{"message":"private server detail"}}',
            entry.key,
          ),
        ),
      );

      await expectLater(
        api.login('sam@example.com', 'password123'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.message, 'message', entry.value)
              .having((error) => error.statusCode, 'statusCode', entry.key),
        ),
      );
    }
  });
}
