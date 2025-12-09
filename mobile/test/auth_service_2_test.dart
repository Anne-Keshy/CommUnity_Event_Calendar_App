import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:community/services/auth_service.dart';
import 'dart:convert';
import 'package:community/services/constants.dart';
import 'package:community/models/user.dart';
import 'package:mockito/annotations.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([http.Client, SharedPreferences])
void main() {
  group('AuthService', () {
    late MockClient mockClient;
    late MockSharedPreferences mockSharedPreferences;
    late AuthService authService;

    setUp(() {
      mockClient = MockClient();
      mockSharedPreferences = MockSharedPreferences();
      authService = AuthService(
        client: mockClient,
        prefs: Future.value(mockSharedPreferences),
      );
    });

    // Test cases for login
    test('login returns User on successful request', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(
                json.encode({
                  'access_token': 'fake_jwt_token',
                  'user': {
                    'id': 1,
                    'username': 'testuser',
                    'email': 'test@example.com',
                    'role': 'attendee',
                  }
                }),
                200,
              ));

      final result = await authService.login('test@example.com', 'password');

      expect(result, isA<User>());
      expect(result.username, 'testuser');
    });

    test('login throws exception on failed request', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(
                json.encode({'message': 'Invalid credentials'}),
                401,
              ));

      expect(
        () async =>
            await authService.login('wrong@example.com', 'wrongpassword'),
        throwsException,
      );
    });

    test('login uses http.post with correct url and body', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('', 401));

      await authService.login('test@example.com', 'password');

      verify(mockClient.post(Uri.parse('$API_BASE_URL/api/v1/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json
              .encode({'email': 'test@example.com', 'password': 'password'})));
    });

    test('login saves token and user data on success', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(
              json.encode({
                'access_token': 'test_jwt_token',
                'username': 'testuser',
                'role': 'attendee'
              }),
              200));
      when(mockSharedPreferences.setString(any, any))
          .thenAnswer((_) async => true);

      await authService.login('test@example.com', 'password');

      verify(mockSharedPreferences.setString('jwt_token', 'test_jwt_token'));
      verify(mockSharedPreferences.setString('username', 'testuser'));
      verify(mockSharedPreferences.setString('role', 'attendee'));
    });

    // Test cases for register
    test('register returns true on successful request', () async {
      // Mock the registration call
      when(mockClient.post(
        Uri.parse('$API_BASE_URL/api/v1/auth/register'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('', 201));

      // Mock the subsequent login call
      when(mockClient.post(
        Uri.parse('$API_BASE_URL/api/v1/auth/login'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            json.encode({
              'access_token': 'new_fake_token',
              'username': 'newuser',
              'role': 'attendee',
            }),
            200,
          ));

      final result = await authService.register(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password');

      expect(result, isTrue);
    });

    test('register returns false on failed request', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Registration failed', 400));

      final result = await authService.register(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password');

      expect(result, isFalse);
    });

    // Test cases for forgotPassword
    test('forgotPassword returns true on successful request', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('', 200));

      final result =
          await authService.forgotPassword(email: 'test@example.com');

      expect(result, isTrue);
    });

    test('forgotPassword returns false on failed request', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response('Email not found', 404));

      final result =
          await authService.forgotPassword(email: 'test@example.com');

      expect(result, isFalse);
    });

    // Test case for logout
    test('logout clears stored credentials', () async {
      when(mockSharedPreferences.remove(any)).thenAnswer((_) async => true);
      await authService.logout();
      verify(mockSharedPreferences.remove('jwt_token'));
      verify(mockSharedPreferences.remove('username'));
      verify(mockSharedPreferences.remove('user_role'));
    });
  });
}
