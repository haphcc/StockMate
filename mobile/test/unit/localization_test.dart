import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmate/l10n/app_localizations.dart';
import 'package:stockmate/providers/app_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLocalizations unit tests', () {
    test('Vietnamese localizations return correct strings', () {
      const l10n = AppLocalizations(Locale('vi'));

      expect(l10n.isVietnamese, isTrue);
      expect(l10n.loginTitle, 'Đăng nhập tài khoản');
      expect(l10n.registerTitle, 'Tạo tài khoản StockMate');
      expect(l10n.profileTitle, 'Hồ sơ cá nhân');
      expect(l10n.tabMarket, 'Thị trường');
      expect(l10n.tabOrders, 'Sổ lệnh');
      expect(l10n.tabTrade, 'Đặt lệnh');
      expect(l10n.tabPortfolio, 'Danh mục');
      expect(l10n.loginButton, 'Đăng Nhập Ngay');
      expect(l10n.labelLanguage, 'Ngôn ngữ hiển thị');
      expect(l10n.darkMode, 'Chế độ tối');
      expect(l10n.logoutButton, 'Đăng xuất tài khoản');
    });

    test('English localizations return correct strings', () {
      const l10n = AppLocalizations(Locale('en'));

      expect(l10n.isVietnamese, isFalse);
      expect(l10n.loginTitle, 'Sign In to Account');
      expect(l10n.registerTitle, 'Create StockMate Account');
      expect(l10n.profileTitle, 'Personal Profile');
      expect(l10n.tabMarket, 'Market');
      expect(l10n.tabOrders, 'Orders');
      expect(l10n.tabTrade, 'Trade');
      expect(l10n.tabPortfolio, 'Portfolio');
      expect(l10n.loginButton, 'Sign In Now');
      expect(l10n.labelLanguage, 'Display Language');
      expect(l10n.darkMode, 'Dark Mode');
      expect(l10n.logoutButton, 'Log Out');
    });

    test('All critical strings are distinct between VI and EN', () {
      const vi = AppLocalizations(Locale('vi'));
      const en = AppLocalizations(Locale('en'));

      expect(vi.loginTitle, isNot(equals(en.loginTitle)));
      expect(vi.registerTitle, isNot(equals(en.registerTitle)));
      expect(vi.profileTitle, isNot(equals(en.profileTitle)));
      expect(vi.tabMarket, isNot(equals(en.tabMarket)));
      expect(vi.tabOrders, isNot(equals(en.tabOrders)));
      expect(vi.tabTrade, isNot(equals(en.tabTrade)));
      expect(vi.tabPortfolio, isNot(equals(en.tabPortfolio)));
      expect(vi.loginButton, isNot(equals(en.loginButton)));
      expect(vi.accountLabel, isNot(equals(en.accountLabel)));
      expect(vi.passwordLabel, isNot(equals(en.passwordLabel)));
      expect(vi.fullNameLabel, isNot(equals(en.fullNameLabel)));
      expect(vi.termsOfService, isNot(equals(en.termsOfService)));
      expect(vi.logoutButton, isNot(equals(en.logoutButton)));
    });
  });

  group('LocaleNotifier provider tests', () {
    test('Initial locale is Vietnamese', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale.languageCode, 'vi');
    });

    test('toggleLocale switches from VI to EN and back', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(localeProvider.notifier);

      await notifier.toggleLocale();
      expect(container.read(localeProvider).languageCode, 'en');

      await notifier.toggleLocale();
      expect(container.read(localeProvider).languageCode, 'vi');
    });

    test('setLocale sets specific locale directly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(localeProvider.notifier);

      await notifier.setLocale(const Locale('en'));
      expect(container.read(localeProvider).languageCode, 'en');

      await notifier.setLocale(const Locale('vi'));
      expect(container.read(localeProvider).languageCode, 'vi');
    });

    test('l10nProvider updates when localeProvider changes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(l10nProvider).isVietnamese, isTrue);

      await container.read(localeProvider.notifier).setLocale(const Locale('en'));
      expect(container.read(l10nProvider).isVietnamese, isFalse);
      expect(container.read(l10nProvider).loginTitle, 'Sign In to Account');
    });
  });
}
