import '../../core/network/dio_client.dart';
import '../datasources/market_datasource.dart';
import '../models/account_model.dart';
import '../models/portfolio_model.dart';
import '../models/stock_model.dart';
import 'market_repository.dart';

class ApiMarketRepository implements MarketRepository {
  final MarketDatasource datasource;

  ApiMarketRepository({required DioClient client})
      : datasource = MarketDatasource(client);

  @override
  Future<List<StockModel>> getMarketBoard({
    String? exchange = 'ALL',
    String? q,
  }) async {
    return datasource.getMarketBoard(exchange: exchange, q: q);
  }

  @override
  Future<StockModel> getStockDetail(String symbol) async {
    return datasource.getStockDetail(symbol);
  }

  @override
  Future<AccountModel> getAccountSummary(int userId) async {
    throw UnimplementedError('Handled via AccountRepository');
  }

  @override
  Future<List<PortfolioModel>> getPortfolio(int accountId) async {
    throw UnimplementedError('Handled via AccountRepository');
  }
}
