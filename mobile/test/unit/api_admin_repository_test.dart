import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/admin/data/admin_exception.dart';
import 'package:stockmate/features/admin/data/admin_token_source.dart';
import 'package:stockmate/features/admin/data/api_admin_repository.dart';

class _FakeTokenSource implements AdminTokenSource {
  String token = 'token-1';
  int invalidatedCount = 0;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> invalidate() async {
    invalidatedCount++;
    token = 'token-refreshed';
  }
}

class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test('listAccounts truyền tham số q và bộ lọc lên API', () async {
    final tokenSource = _FakeTokenSource();
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        captured = options;
        return _jsonResponse({
          'items': [
            {
              'account_id': 1,
              'customer_id': 1,
              'customer_name': 'NGUYEN AN',
              'customer_email': 'an@gmail.com',
              'account_number': '068C000001',
              'account_type': 'CASH',
              'cash_balance': '50000000.00',
              'blocked_balance': '0.00',
              'total_asset_value': '50000000.00',
              'margin_limit': '0.00',
              'status': 'ACTIVE',
            },
          ],
          'page': 1,
          'page_size': 20,
          'total': 1,
        });
      });

    final repo = ApiAdminRepository(
      baseUrl: 'http://test.local',
      tokenSource: tokenSource,
      dio: dio,
    );

    final page = await repo.listAccounts(
      q: '068C',
      accountType: 'CASH',
      status: 'ACTIVE',
    );
    expect(page.total, 1);
    expect(page.items.first.accountNumber, '068C000001');
    expect(captured?.queryParameters['q'], '068C');
    expect(captured?.queryParameters['account_type'], 'CASH');
    expect(captured?.queryParameters['status'], 'ACTIVE');
    expect(captured?.headers['Authorization'], 'Bearer token-1');
  });

  test('tự làm mới token 1 lần khi API trả 401', () async {
    final tokenSource = _FakeTokenSource();
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        calls++;
        if (calls == 1) {
          return _jsonResponse(
            {'error': {'code': 'UNAUTHORIZED', 'message': 'Expired'}},
            statusCode: 401,
          );
        }
        expect(options.headers['Authorization'], 'Bearer token-refreshed');
        return _jsonResponse({'kpis': {'total_customers': 10}});
      });

    final repo = ApiAdminRepository(
      baseUrl: 'http://test.local',
      tokenSource: tokenSource,
      dio: dio,
    );

    final dashboard = await repo.getDashboard();
    expect(dashboard.totalCustomers, 10);
    expect(tokenSource.invalidatedCount, 1);
    expect(calls, 2);
  });

  test('phân giải lỗi validation backend thành AdminException', () async {
    final tokenSource = _FakeTokenSource();
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        return _jsonResponse(
          {
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Dữ liệu không hợp lệ.',
              'details': {
                'fields': [
                  {
                    'loc': ['body', 'ceiling_price'],
                    'message': 'Input should be greater than 0',
                  },
                ],
              },
            },
          },
          statusCode: 422,
        );
      });

    final repo = ApiAdminRepository(
      baseUrl: 'http://test.local',
      tokenSource: tokenSource,
      dio: dio,
    );

    expect(
      () => repo.updateStock(1, {'ceiling_price': '-1'}),
      throwsA(
        isA<AdminException>().having(
          (e) => e.toString(),
          'message',
          contains('ceiling_price'),
        ),
      ),
    );
  });

  test('listPortfolios truyền account_id và stock_symbol lên API', () async {
    final tokenSource = _FakeTokenSource();
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        captured = options;
        return _jsonResponse({
          'items': [
            {
              'portfolio_id': 7,
              'account_id': 2,
              'account_number': '068C000002',
              'customer_name': 'TRAN THI BICH',
              'stock_id': 1,
              'stock_symbol': 'ACB',
              'company_name': 'Ngân hàng TMCP Á Châu',
              'quantity': 1000,
              'available_quantity': 1000,
              'blocked_quantity': 0,
              'average_price': '24000.00',
              'current_value': '25500000.00',
              'profit_loss': '1500000.00',
              'profit_loss_percent': '6.25',
            },
          ],
          'page': 1,
          'page_size': 20,
          'total': 1,
        });
      });

    final repo = ApiAdminRepository(
      baseUrl: 'http://test.local',
      tokenSource: tokenSource,
      dio: dio,
    );

    final page = await repo.listPortfolios(accountId: 2, stockSymbol: 'ACB');
    expect(page.total, 1);
    expect(page.items.first.stockSymbol, 'ACB');
    expect(captured?.queryParameters['account_id'], 2);
    expect(captured?.queryParameters['stock_symbol'], 'ACB');
  });

  test('createCandle gửi payload và phân giải phản hồi nến OHLCV', () async {
    final tokenSource = _FakeTokenSource();
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        captured = options;
        return _jsonResponse(
          {
            'price_history_id': 99,
            'stock_id': 1,
            'stock_symbol': 'ACB',
            'recorded_date': '2026-11-11',
            'open_price': '25000.00',
            'close_price': '25600.00',
            'highest_price': '25800.00',
            'lowest_price': '24900.00',
            'trading_volume': 120000,
            'trading_value': '3060000000.00',
          },
          statusCode: 201,
        );
      });

    final repo = ApiAdminRepository(
      baseUrl: 'http://test.local',
      tokenSource: tokenSource,
      dio: dio,
    );

    final candle = await repo.createCandle({
      'stock_symbol': 'ACB',
      'recorded_date': '2026-11-11',
      'open_price': '25000',
      'close_price': '25600',
      'highest_price': '25800',
      'lowest_price': '24900',
      'trading_volume': 120000,
    });
    expect(candle.candleId, 99);
    expect(candle.stockSymbol, 'ACB');
    expect(candle.isUp, isTrue);
    expect(captured?.path, '/api/admin/price-history');
    expect(captured?.method, 'POST');
  });
}
