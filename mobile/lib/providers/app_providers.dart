import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/market_repository.dart';
import '../data/repositories/mock_market_repository.dart';
import '../l10n/app_localizations.dart';
// import '../data/repositories/api_auth_repository.dart';
// import '../data/repositories/api_market_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMock) {
    return MockAuthRepository();
  } else {
    // return ApiAuthRepository(dio: ref.watch(dioProvider));
    throw UnimplementedError('API auth repository chưa được triển khai');
  }
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  if (AppConfig.useMock) {
    return MockMarketRepository();
  } else {
    // return ApiMarketRepository(dio: ref.watch(dioProvider));
    throw UnimplementedError('API market repository chưa được triển khai');
  }
});

// Chế độ sáng/tối
class ThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() => true; // true = dark mode

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, bool>(ThemeModeNotifier.new);

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

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

final l10nProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});
