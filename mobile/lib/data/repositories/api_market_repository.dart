import '../../core/network/stockmate_api.dart';
import '../models/account_model.dart';
import '../models/portfolio_model.dart';
import '../models/stock_model.dart';
import 'market_repository.dart';

class ApiMarketRepository implements MarketRepository {
  ApiMarketRepository({StockmateApi? api}) : _api = api ?? StockmateApi();
  final StockmateApi _api;
  int? _accountId;

  @override
  Future<List<StockModel>> getMarketBoard({String exchange = 'HOSE'}) async =>
      (await _api.market(exchange: exchange)).map(StockModel.fromJson).toList();

  @override
  Future<AccountModel> getAccountSummary(int userId) async {
    final accounts = await _api.accounts();
    if (accounts.isEmpty)
      throw Exception('Tài khoản chưa có tài khoản đầu tư.');
    _accountId = (accounts.first['account_id'] as num).toInt();
    final asset = await _api.assets(_accountId!);
    return AccountModel.fromJson(asset);
  }

  @override
  Future<List<PortfolioModel>> getPortfolio(int accountId) async =>
      (await _api.portfolio(
        _accountId ?? accountId,
      )).map(PortfolioModel.fromJson).toList();
}
