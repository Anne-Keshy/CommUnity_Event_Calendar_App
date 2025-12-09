import 'package:flutter_test/flutter_test.dart';
import 'package:community/main.dart';
import 'package:community/screens/login_screen.dart';
import 'package:community/screens/splash_screen.dart';

void main() {
  // Note: This test requires mocking for service initializations to run in a CI environment.
  // For local testing, it verifies the navigation flow after a delay.
  testWidgets(
      'SplashScreen shows first, then navigates to LoginScreen after initialization',
      (WidgetTester tester) async {
    // Build the entire app.
    await tester.pumpWidget(const CommUnityApp());

    // 1. Verify that the SplashScreen is being shown initially.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    // 2. Wait for the initialization and the navigation to complete.
    // We use pumpAndSettle to wait for all animations and async tasks to finish.
    // A timeout is added to prevent the test from hanging indefinitely if navigation fails.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 3. Verify that we have navigated away from the SplashScreen to the LoginScreen.
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
