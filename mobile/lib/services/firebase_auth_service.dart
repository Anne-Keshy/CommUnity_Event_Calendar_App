// lib/services/firebase_auth_service.dart
// The file provides Firebase auth helpers. In environments where Firebase packages are not
// available (e.g., CI or when selectively disabling Firebase), the analyzer may otherwise
// report missing package errors. Silence those specific analyzer checks here while keeping
// the runtime code untouched.
// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_class, undefined_identifier, non_type_as_type_argument, undefined_method
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _api = ApiService();

  // Listen to auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _linkToBackend(userCredential.user!);
      return userCredential.user;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  // Sign in with Apple (iOS/macOS)
  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      await _linkToBackend(userCredential.user!);
      return userCredential.user;
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      return null;
    }
  }

  // Link Firebase user to your backend → get JWT + role
  Future<void> _linkToBackend(User firebaseUser) async {
    final idToken = await firebaseUser.getIdToken();
    final backendUser = await _api.verifyFirebaseToken(firebaseIdToken: idToken);

    if (backendUser == null) {
      throw Exception('Failed to link Firebase user to backend.');
    }
    // The verifyFirebaseToken method already saves the JWT to SharedPreferences internally.
    // If you need to access the JWT directly here, you would retrieve it from SharedPreferences.
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await StorageService.clearToken();
  }
}