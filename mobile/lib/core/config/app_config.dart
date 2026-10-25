class AppConfig {
  // TV2: chỉ bật USE_MOCK=false sau khi hoàn thành các API repository.
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');
}
