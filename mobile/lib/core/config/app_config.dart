import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
  );
}
