import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:community/services/auth_service.dart';
import 'package:community/services/api_service.dart';
import 'dart:io';
import 'package:mockito/annotations.dart';
import 'package:community/models/user.dart';
import 'package:hive/hive.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([http.Client, SharedPreferences, ApiService])
void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>('offlineQueue');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('AuthService', () {
    late MockApiService mockApiService;
    late MockSharedPreferences mockSharedPreferences;
    late AuthService authService;

    setUp(() {
      mockApiService = MockApiService();
      mockSharedPreferences = MockSharedPreferences();
      authService = AuthService(
        apiService: mockApiService,
        prefs: Future.value(mockSharedPreferences),
      );
    });

    // Test cases for login
    test('login returns User on successful request', () async {
      final user = User(
        id: 'user_id',
        username: 'testuser',
        email: 'test@example.com',
        role: 'attendee',
        following: [],
        followers: [],
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );
      when(mockApiService.login(
              email: 'test@example.com', password: 'password'))
          .thenAnswer((_) async => user);

      final result = await authService.login('test@example.com', 'password');

      expect(result, isNotNull);
      expect(result.username, 'testuser');
    });

    test('login returns null on failed request', () async {
      when(mockApiService.login(
              email: 'wrong@example.com', password: 'wrongpassword'))
          .thenThrow(Exception('Invalid credentials'));

      final result =
          await authService.login('wrong@example.com', 'wrongpassword');

      expect(result, isNull);
    });

    // Test cases for register
    test('register returns User on successful request', () async {
      final user = User(
        id: 'user_id',
        username: 'newuser',
        email: 'test@example.com',
        role: 'attendee',
        following: [],
        followers: [],
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );
      when(mockApiService.register(
        username: anyNamed('username'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        role: anyNamed('role'),
      )).thenAnswer((_) async => user);

      final result = await authService.register(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password');

      expect(result, isNotNull);
      expect(result.username, 'newuser');
    });

    test('register throws exception on failed request', () async {
      when(mockApiService.register(
        username: anyNamed('username'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        role: anyNamed('role'),
      )).thenThrow(Exception('Registration failed'));

      expect(
        () => authService.register(
            username: 'testuser',
            email: 'test@example.com',
            password: 'password'),
        throwsA(isA<Exception>()),
      );
    });

    // Test cases for forgotPassword
    test('forgotPassword returns true on successful request', () async {
      when(mockApiService.forgotPassword(email: anyNamed('email')))
          .thenAnswer((_) async => true);

      final result =
          await authService.forgotPassword(email: 'test@example.com');

      expect(result, isTrue);
    });

    test('forgotPassword returns false on failed request', () async {
      when(mockApiService.forgotPassword(email: anyNamed('email')))
          .thenAnswer((_) async => false);

      final result =
          await authService.forgotPassword(email: 'test@example.com');

      expect(result, isFalse);
    });

    // Test case for logout
    test('logout clears stored credentials', () async {
      when(mockApiService.logout()).thenAnswer((_) async {});
      when(mockSharedPreferences.remove(any)).thenAnswer((_) async => true);
      await authService.logout();
      verify(mockSharedPreferences.remove('jwt_token'));
    });
  });
}
