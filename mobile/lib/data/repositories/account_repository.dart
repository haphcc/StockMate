import '../models/account_model.dart';
import '../models/deposit_model.dart';
import '../models/portfolio_model.dart';

abstract class AccountRepository {
  Future<List<AccountModel>> listAccounts();
  Future<AssetModel> getAssets(int accountId);
  Future<List<PortfolioModel>> getPortfolio(int accountId);
  Future<DepositModel> createDeposit(int accountId, String amount);
}
