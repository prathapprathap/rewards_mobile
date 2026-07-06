class ApiConstants {
  // Adaptive Base URL
  // Pass the backend host at build time:
  //   prod : flutter build apk --release --dart-define=API_BASE=https://api.rupirewards.xyz
  //   stage: flutter build apk --release --dart-define=API_BASE=https://rewards-backend-zkhh.onrender.com
  // If no value is provided (e.g. plain `flutter run`), it falls back to the old backend.
  static const String _apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://rewards-backend-zkhh.onrender.com',
  );

  // Public website used to build referral share links (the static landing site).
  // Pass it at build time, the same way as API_BASE:
  //   prod : flutter build apk --release --dart-define=SITE_URL=https://rupirewards.xyz
  // Leave it unset for staging — the app then falls back to the admin `site_url`
  // setting + backend /api/download flow on Render (unchanged).
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: '',
  );

  static String get baseUrl => '$_apiBase/api';

  static String get loginEndpoint => '$baseUrl/users/google-login';
  static String get userProfileEndpoint => '$baseUrl/users';
  static String get offersEndpoint => '$baseUrl/admin/offers';
  static String get tasksEndpoint => '$baseUrl/admin/tasks';
}
