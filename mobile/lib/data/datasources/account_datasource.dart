import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

class AccountDatasource {
  final Dio _dio;

  AccountDatasource(DioClient client) : _dio = client.dio;

  Future<List<Map<String, dynamic>>> listAccounts() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.accounts);
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> assets(int accountId) async {
    final response = await _dio.get<dynamic>(ApiEndpoints.assets(accountId));
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> portfolio(int accountId) async {
    final response = await _dio.get<dynamic>(ApiEndpoints.portfolio(accountId));
    return (response.data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> deposit(int accountId, MoneyPayload payload) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.deposit(accountId),
      data: payload.toJson(),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}

class MoneyPayload {
  final String amount;
  final String? returnUrl;
  final String? cancelUrl;

  const MoneyPayload(this.amount, {this.returnUrl, this.cancelUrl});

  Map<String, dynamic> toJson() => {
        'amount': amount,
        if (returnUrl != null) 'return_url': returnUrl,
        if (cancelUrl != null) 'cancel_url': cancelUrl,
      };
}
