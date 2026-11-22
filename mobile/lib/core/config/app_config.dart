import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '187891683350-r6s6qgf2kem2l5ji6gks1g9ofvjvhtm9.apps.googleusercontent.com',
  );
}
