import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/market_repository.dart';
import '../data/repositories/mock_market_repository.dart';
import '../data/repositories/api_market_repository.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/api_account_repository.dart';
import '../data/repositories/mock_account_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../core/network/dio_client.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

/// Defaults to the build-time setting, but can be changed during a session.
class DataSourceModeNotifier extends Notifier<bool> {
  @override
  bool build() => AppConfig.useMock;

  void setUseMock(bool value) => state = value;
}

final useMockProvider = NotifierProvider<DataSourceModeNotifier, bool>(
  DataSourceModeNotifier.new,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(useMockProvider)) {
    return MockAuthRepository();
  } else {
    return ApiAuthRepository(client: ref.watch(dioClientProvider));
  }
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  if (ref.watch(useMockProvider)) return MockAccountRepository();
  return ApiAccountRepository(ref.watch(dioClientProvider));
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  if (ref.watch(useMockProvider)) return MockMarketRepository();
  return ApiMarketRepository(client: ref.watch(dioClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (ref.watch(useMockProvider)) return MockNotificationRepository();
  return ApiNotificationRepository(client: ref.watch(dioClientProvider));
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
