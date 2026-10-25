class AppConfig {
  static const bool useMock = true; // Chuyển thành false khi có backend
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');
}
