import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmate/core/widgets/language_switch_button.dart';
import 'package:stockmate/features/auth/screens/login_screen.dart';
import 'package:stockmate/features/auth/screens/register_screen.dart';
import 'package:stockmate/features/home/screens/settings_screen.dart';
import 'package:stockmate/features/profile/screens/profile_screen.dart';
import 'package:stockmate/l10n/app_localizations.dart';
import 'package:stockmate/providers/app_providers.dart';

Widget _buildTestApp(Widget child) {
  return Consumer(
    builder: (context, ref, _) {
      final currentLocale = ref.watch(localeProvider);
      return MaterialApp(
        locale: currentLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      );
    },
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LanguageSwitchButton widget tests', () {
    testWidgets('renders VI and EN options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _buildTestApp(
            const Scaffold(
              body: Center(
                child: LanguageSwitchButton(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('VI'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('taps EN and switches locale to English', (WidgetTester tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              final currentLocale = ref.watch(localeProvider);
              return MaterialApp(
                locale: currentLocale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const Scaffold(
                  body: Center(
                    child: LanguageSwitchButton(),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(capturedRef.read(localeProvider).languageCode, 'vi');

      // Tap 'EN'
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(capturedRef.read(localeProvider).languageCode, 'en');

      // Tap 'VI'
      await tester.tap(find.text('VI'));
      await tester.pumpAndSettle();

      expect(capturedRef.read(localeProvider).languageCode, 'vi');
    });
  });

  group('LoginScreen language toggle tests', () {
    testWidgets('LoginScreen updates strings dynamically when switching language', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _buildTestApp(const LoginScreen()),
        ),
      );

      // Ban đầu là Tiếng Việt
      expect(find.text('Đăng nhập tài khoản'), findsOneWidget);
      expect(find.text('Đăng Nhập Ngay'), findsOneWidget);
      expect(find.text('Ghi nhớ'), findsOneWidget);

      // Chuyển sang Tiếng Anh bằng cách bấm nút EN
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      // Kiểm tra các nhãn chuyển sang tiếng Anh
      expect(find.text('Sign In to Account'), findsOneWidget);
      expect(find.text('Sign In Now'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);

      // Chuyển lại về Tiếng Việt
      await tester.tap(find.text('VI'));
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập tài khoản'), findsOneWidget);
      expect(find.text('Đăng Nhập Ngay'), findsOneWidget);
    });
  });

  group('RegisterScreen language toggle tests', () {
    testWidgets('RegisterScreen updates strings dynamically when switching language', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _buildTestApp(const RegisterScreen()),
        ),
      );

      // Ban đầu là Tiếng Việt
      expect(find.text('Tạo tài khoản StockMate'), findsOneWidget);

      // Chuyển sang Tiếng Anh
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      // Kiểm tra chuyển sang tiếng Anh
      expect(find.text('Create StockMate Account'), findsOneWidget);
    });
  });

  group('SettingsScreen (Hồ sơ & Cài đặt) language toggle tests', () {
    testWidgets('SettingsScreen renders with language options and toggles language', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _buildTestApp(const SettingsScreen()),
        ),
      );

      // Ban đầu là Tiếng Việt
      expect(find.text('Cài đặt & Tài khoản'), findsOneWidget);
      expect(find.text('TÀI KHOẢN'), findsOneWidget);
      expect(find.text('Sửa thông tin'), findsOneWidget);
      expect(find.text('CÀI ĐẶT & NGÔN NGỮ'), findsOneWidget);

      // Chuyển sang Tiếng Anh bằng nút EN trên AppBar
      await tester.tap(find.text('EN').first);
      await tester.pumpAndSettle();

      // Kiểm tra chuyển sang tiếng Anh
      expect(find.text('Settings & Account'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('PREFERENCES & LANGUAGE'), findsOneWidget);
    });
  });

  group('ProfileScreen language toggle tests', () {
    testWidgets('ProfileScreen renders with language options and toggles language', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _buildTestApp(const ProfileScreen()),
        ),
      );

      // Ban đầu là Tiếng Việt
      expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
      expect(find.text('Đăng xuất tài khoản'), findsOneWidget);

      // Chuyển sang Tiếng Anh bằng nút EN trên AppBar
      await tester.tap(find.text('EN').first);
      await tester.pumpAndSettle();

      // Kiểm tra chuyển sang tiếng Anh
      expect(find.text('Personal Profile'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}
