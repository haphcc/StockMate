import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/market_repository.dart';
import '../data/repositories/mock_market_repository.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/api_market_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMock) {
    return MockAuthRepository();
  } else {
    return ApiAuthRepository();
  }
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  if (AppConfig.useMock) {
    return MockMarketRepository();
  }
  return ApiMarketRepository();
});

// Chế độ sáng/tối
class ThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() => true; // true = dark mode

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, bool>(
  ThemeModeNotifier.new,
);
