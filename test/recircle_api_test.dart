import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  test('debug installs on physical phones default to the hosted API', () {
    expect(
      ReCircleApi.resolveBaseUrl('', debugMode: true),
      ReCircleApi.productionBaseUrl,
    );
    expect(
      ReCircleApi.resolveBaseUrl(
        'http://10.0.2.2:3000/api/v1',
        debugMode: true,
      ),
      'http://10.0.2.2:3000/api/v1',
    );
  });

  test(
    'analysis uploads raw image bytes with matching MIME to hosted API',
    () async {
      late http.Request sent;
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0x01]);
      final storage = _MemorySecureStorage();
      final api = ReCircleApi(
        baseUrl: ReCircleApi.productionBaseUrl,
        storage: storage,
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            '{"success":true,"data":{"itemName":"Laptop"}}',
            201,
          );
        }),
      );

      await api.saveToken('test-jwt');
      await api.analyzeImage(image: bytes, mimeType: 'image/jpeg');

      expect(sent.method, 'POST');
      expect(sent.url.toString(), '${ReCircleApi.productionBaseUrl}/analysis');
      expect(sent.headers['content-type'], 'image/jpeg');
      expect(sent.bodyBytes, bytes);
      expect(sent.headers['authorization'], 'Bearer test-jwt');
    },
  );

  test(
    'analysis 401 clears expired JWT and asks the user to sign in again',
    () async {
      final storage = _MemorySecureStorage();
      late http.Request sent;
      final api = ReCircleApi(
        storage: storage,
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            '{"success":false,"error":{"message":"Session is invalid or expired"}}',
            401,
            request: request,
          );
        }),
      );
      await api.saveToken('expired-jwt');

      await expectLater(
        api.analyzeImage(
          image: Uint8List.fromList([0xff, 0xd8, 0xff]),
          mimeType: 'image/jpeg',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('Your session expired'),
          ),
        ),
      );
      expect(sent.headers['authorization'], 'Bearer expired-jwt');
      expect(api.hasSessionToken, isFalse);
      expect(storage.values, isEmpty);
    },
  );

  test(
    'analysis backend timeout and connection failures are actionable',
    () async {
      final timedOutApi = ReCircleApi(
        client: _FailingClient(TimeoutException('timeout')),
      );
      await expectLater(
        timedOutApi.analyzeImage(
          image: Uint8List.fromList([0xff, 0xd8, 0xff]),
          mimeType: 'image/jpeg',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('hosted analysis service may still be starting'),
          ),
        ),
      );

      final unavailableApi = ReCircleApi(
        client: _FailingClient(
          http.ClientException('private connection detail'),
        ),
      );
      await expectLater(
        unavailableApi.analyzeImage(
          image: Uint8List.fromList([0xff, 0xd8, 0xff]),
          mimeType: 'image/jpeg',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('Could not reach the ReCircle analysis service'),
          ),
        ),
      );
    },
  );

  test('explicit API URL is trimmed and trailing slashes are removed', () {
    expect(
      ReCircleApi.resolveBaseUrl(
        ' https://example.com/api/v1/ ',
        debugMode: false,
      ),
      'https://example.com/api/v1',
    );
  });

  test(
    'login posts expected fields and parses token and user response',
    () async {
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

      expect(
        sent.url.toString(),
        '${ReCircleApi.productionBaseUrl}/auth/login',
      );
      expect(sent.method, 'POST');
      expect(jsonDecode(sent.body), {
        'email': 'sam@example.com',
        'password': 'password123',
      });
      expect(result['token'], 'test-token');
      expect((result['user'] as Map)['role'], 'customer');
    },
  );

  test(
    'registration posts expected fields to the registration endpoint',
    () async {
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

      expect(
        sent.url.toString(),
        '${ReCircleApi.productionBaseUrl}/auth/register',
      );
      expect(jsonDecode(sent.body), {
        'name': 'Sam',
        'email': 'sam@example.com',
        'password': 'password123',
      });
    },
  );

  test(
    'authentication and server errors use safe actionable messages',
    () async {
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
    },
  );
}

class _FailingClient extends http.BaseClient {
  _FailingClient(this.failure);

  final Object failure;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (failure is TimeoutException) throw failure as TimeoutException;
    throw failure as http.ClientException;
  }
}

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}
