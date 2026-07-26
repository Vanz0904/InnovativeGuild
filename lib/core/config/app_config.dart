/// Central place to point the Flutter app at your running backend.
///
/// Backend running locally:
/// http://localhost:4000
///
/// - Android emulator: use 10.0.2.2 instead of localhost.
/// - iOS simulator: localhost works directly.
/// - Physical device: use your machine's LAN IP.
/// - Production: replace with your deployed HTTPS API URL.

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  /// Must match the redirect_url configured in your Flutterwave
  /// dashboard / passed to the Flutterwave Standard SDK.
  static const String flutterwaveRedirectUrl =
      'https://safeguard.mw/payment-callback';
}