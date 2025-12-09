import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:community/models/user.dart';
import 'package:community/services/api_service.dart'; // Import the new ApiService

class AuthService {
  final ApiService _apiService;
  final Future<SharedPreferences> _prefs;
  SharedPreferences? _cachedPrefs; // Cache for optimization

  AuthService(
      {ApiService? apiService,
      Future<SharedPreferences>? prefs,
      http.Client? client})
      : _apiService = apiService ?? ApiService(client: client),
        _prefs = prefs ?? SharedPreferences.getInstance();

  /// Attempts to log in the user using `ApiService`.
  /// On success, returns the authenticated User object.
  Future<User> login(String email, String password) async {
    // Let ApiService throw detailed exceptions on failure and bubble them up
    return await _apiService.login(email: email, password: password);
  }

  /// Attempts to register a new user using `ApiService`.
  /// On success, automatically logs the user in and returns the authenticated User object.
  Future<User> register({
    required String username,
    required String email,
    required String password,
    String role = 'attendee',
  }) async {
    // ApiService.register now returns the full user object
    return await _apiService.register(
      username: username,
      email: email,
      password: password,
      role: role,
    );
  }

  /// Sends a password reset link to the user's email using `ApiService`.
  Future<bool> forgotPassword({required String email}) async {
    return await _apiService.forgotPassword(email: email);
  }

  /// Logs out the user by clearing their stored credentials.
  Future<void> logout() async {
    await _apiService.logout();
    _cachedPrefs ??= await _prefs; // Cache prefs for speed
    await _cachedPrefs!.remove('jwt_token');
  }
}
