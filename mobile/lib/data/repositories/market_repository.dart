import '../models/stock_model.dart';
import '../models/account_model.dart';
import '../models/portfolio_model.dart';

abstract class MarketRepository {
  Future<List<StockModel>> getMarketBoard({String exchange = 'HOSE'});
  Future<AccountModel> getAccountSummary(int userId);
  Future<List<PortfolioModel>> getPortfolio(int accountId);
}
