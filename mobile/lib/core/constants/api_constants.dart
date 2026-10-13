class ApiConstants {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const String emulatorBaseUrl = 'http://10.0.2.2:8080';

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';

  // Customer endpoints
  static const String customers = '/api/customers';

  // Site endpoints
  static const String sites = '/api/sites';

  // Note endpoints
  static const String notes = '/api/notes';

  // Sync endpoints
  static const String syncPush = '/api/sync/push';
  static const String syncPull = '/api/sync/pull';
}
