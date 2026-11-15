import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/stock_model.dart';

class MarketDatasource {
  final Dio _dio;

  MarketDatasource(DioClient client) : _dio = client.dio;

  Future<List<StockModel>> getMarketBoard({
    String? exchange,
    String? q,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.marketBoard,
        queryParameters: {
          if (exchange != null && exchange != 'ALL') 'exchange': exchange,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = response.data;
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .map((e) => StockModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<StockModel> getStockDetail(String symbol) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.stockDetail(symbol),
      );
      return StockModel.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
