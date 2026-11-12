import '../../core/utils/money.dart';
import '../models/account_model.dart';
import '../models/deposit_model.dart';
import '../models/portfolio_model.dart';
import 'account_repository.dart';

class MockAccountRepository implements AccountRepository {
  final AccountModel _account = const AccountModel(
    accountId: 1,
    accountNumber: '086C123456',
    accountType: 'CASH',
    status: 'ACTIVE',
  );

  @override
  Future<List<AccountModel>> listAccounts() async => [_account];

  @override
  Future<AssetModel> getAssets(int accountId) async => AssetModel(
        accountId: accountId,
        accountNumber: _account.accountNumber,
        accountType: _account.accountType,
        status: _account.status,
        cashBalance: Money.fromCents(100000000000),
        blockedBalance: Money.zero(),
        stockValue: Money.zero(),
        totalAssetValue: Money.fromCents(100000000000),
        totalProfitLoss: Money.zero(),
        profitLossPercent: Money.zero(),
      );

  @override
  Future<List<PortfolioModel>> getPortfolio(int accountId) async => const [];

  @override
  Future<DepositModel> createDeposit(int accountId, String amount) async => DepositModel(
        orderCode: 1,
        amount: Money.parse(amount),
        checkoutUrl: 'https://pay.payos.vn',
        qrCode: 'MOCK_QR',
        status: 'PENDING',
        accountId: accountId,
      );
}
