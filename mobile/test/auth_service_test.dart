import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:community/services/auth_service.dart';
import 'package:community/services/api_service.dart';
import 'package:mockito/annotations.dart';
import 'package:community/models/user.dart';

import 'auth_service_test.mocks.dart';

// This annotation is used by build_runner to generate the mock classes
@GenerateMocks([http.Client, SharedPreferences, ApiService])
void main() {
  group('AuthService', () {
    late MockApiService mockApiService;
    late MockSharedPreferences mockSharedPreferences;
    late AuthService authService;

    setUp(() {
      mockApiService = MockApiService();
      mockSharedPreferences = MockSharedPreferences();
      // Inject the mock apiService and mock SharedPreferences into the service
      authService = AuthService(
        apiService: mockApiService,
        prefs: Future.value(mockSharedPreferences),
      );
    });

    test('login returns User on successful request', () async {
      // Arrange: Mock a successful response from the apiService
      final mockUser = User(
        id: 'user_id',
        username: 'testuser',
        email: 'test@example.com',
        role: 'attendee',
        following: [],
        followers: [],
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );
      when(mockApiService.login(
        email: 'test@example.com',
        password: 'password',
      )).thenAnswer((_) async => mockUser);

      // Act
      final result = await authService.login('test@example.com', 'password');

      // Assert
      expect(result, isNotNull);
      expect(result.username, 'testuser');
      expect(result.email, 'test@example.com');
      expect(result.role, 'attendee');
    });

    test('login returns null on failed request', () async {
      // Arrange: Mock a failed response from apiService
      when(mockApiService.login(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      )).thenThrow(Exception('Invalid credentials'));

      // Act
      final result =
          await authService.login('wrong@example.com', 'wrongpassword');

      // Assert
      expect(result, isNull);
    });

    test('register returns User on successful request', () async {
      // Arrange: Mock a successful response from apiService
      final mockUser = User(
        id: 'user_id',
        username: 'newuser',
        email: 'test@example.com',
        role: 'attendee',
        following: [],
        followers: [],
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
      );
      when(mockApiService.register(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password',
      )).thenAnswer((_) async => mockUser);

      // Act
      final result = await authService.register(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password');

      // Assert
      expect(result, isNotNull);
      expect(result.username, 'newuser');
      expect(result.email, 'test@example.com');
      expect(result.role, 'attendee');
    });

    test('register throws exception on failed request', () async {
      // Arrange: Mock a failed response from apiService
      when(mockApiService.register(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password',
      )).thenThrow(Exception('Registration failed'));

      // Act & Assert
      expect(
        () => authService.register(
            username: 'testuser',
            email: 'test@example.com',
            password: 'password'),
        throwsA(isA<Exception>()),
      );
    });

    test('forgotPassword returns true on successful request', () async {
      // Arrange
      when(mockApiService.forgotPassword(email: 'test@example.com'))
          .thenAnswer((_) async => true);

      // Act
      final result =
          await authService.forgotPassword(email: 'test@example.com');

      // Assert
      expect(result, isTrue);
    });

    test('forgotPassword returns false on failed request', () async {
      // Arrange
      when(mockApiService.forgotPassword(email: 'test@example.com'))
          .thenAnswer((_) async => false);

      // Act
      final result =
          await authService.forgotPassword(email: 'test@example.com');

      // Assert
      expect(result, isFalse);
    });

    test('logout clears stored credentials', () async {
      // Arrange
      when(mockApiService.logout()).thenAnswer((_) async {});
      when(mockSharedPreferences.remove(any)).thenAnswer((_) async => true);
      // Act
      await authService.logout();
      // Assert
      verify(mockApiService.logout());
      verify(mockSharedPreferences.remove('jwt_token'));
    });
  });
}
