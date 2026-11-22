import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmate/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('vi_VN', null);
  });

  testWidgets('App should build successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: StockMateApp()));
    expect(find.byType(StockMateApp), findsOneWidget);
  });
}
