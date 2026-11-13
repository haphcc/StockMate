import '../../core/network/dio_client.dart';
import '../datasources/account_datasource.dart';
import '../models/account_model.dart';
import '../models/deposit_model.dart';
import '../models/portfolio_model.dart';
import 'account_repository.dart';

class ApiAccountRepository implements AccountRepository {
  final AccountDatasource datasource;

  ApiAccountRepository(DioClient client) : datasource = AccountDatasource(client);

  @override
  Future<List<AccountModel>> listAccounts() async =>
      (await datasource.listAccounts()).map(AccountModel.fromJson).toList();

  @override
  Future<AssetModel> getAssets(int accountId) async =>
      AssetModel.fromJson(await datasource.assets(accountId));

  @override
  Future<List<PortfolioModel>> getPortfolio(int accountId) async =>
      (await datasource.portfolio(accountId)).map(PortfolioModel.fromJson).toList();

  @override
  Future<DepositModel> createDeposit(int accountId, String amount) async =>
      DepositModel.fromJson(
        await datasource.deposit(accountId, MoneyPayload(amount)),
      );
}
