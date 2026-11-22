import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../l10n/app_localizations.dart';

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

// Quản lý ngôn ngữ (Tiếng Việt / Tiếng Anh)
class LocaleNotifier extends Notifier<Locale> {
  static const String _prefKey = 'selected_locale_code';

  @override
  Locale build() {
    _loadFromPrefs();
    return const Locale('vi');
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code == 'en' || code == 'vi') {
        state = Locale(code!);
      }
    } catch (_) {
      // Bỏ qua lỗi SharedPreferences khi mock/test
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, locale.languageCode);
    } catch (_) {}
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'vi' ? const Locale('en') : const Locale('vi');
    await setLocale(next);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

final l10nProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});
