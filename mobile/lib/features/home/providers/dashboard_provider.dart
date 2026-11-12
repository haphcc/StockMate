import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stock_model.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/selected_account_provider.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardData {
  final AccountModel account;
  final AssetModel assets;
  final List<PortfolioModel> portfolio;
  final List<StockModel> marketBoard;
  final List<AccountModel> accounts;

  DashboardData(this.account, this.assets, this.portfolio, this.marketBoard, this.accounts);
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) throw Exception('User not logged in');

  final accountRepo = ref.watch(accountRepositoryProvider);
  final accounts = await accountRepo.listAccounts();
  final selectedId = ref.watch(selectedAccountProvider);
  AccountModel? account;
  for (final candidate in accounts) {
    if (candidate.accountId == selectedId) {
      account = candidate;
      break;
    }
  }
  if (account == null) {
    for (final candidate in accounts) {
      if (candidate.accountType == 'CASH' && candidate.status == 'ACTIVE') {
        account = candidate;
        break;
      }
    }
  }
  if (account == null) throw StateError('Tài khoản CASH đang hoạt động không tồn tại.');
  if (selectedId != account.accountId) {
    ref.read(selectedAccountProvider.notifier).select(account.accountId);
  }
  final assets = await accountRepo.getAssets(account.accountId);
  final portfolio = await accountRepo.getPortfolio(account.accountId);
  // The market board remains owned by TV3 and is still rendered from its
  // existing local data. TV2 only loads account data here.
  const marketBoard = <StockModel>[];

  return DashboardData(account, assets, portfolio, marketBoard, accounts);
});
