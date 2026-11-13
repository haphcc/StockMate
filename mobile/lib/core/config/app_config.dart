class AppConfig {
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
