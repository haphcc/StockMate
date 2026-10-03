import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stock_model.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../providers/app_providers.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardData {
  final AccountModel account;
  final List<PortfolioModel> portfolio;
  final List<StockModel> marketBoard;

  DashboardData(this.account, this.portfolio, this.marketBoard);
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) throw Exception('User not logged in');

  final marketRepo = ref.watch(marketRepositoryProvider);
  
  final account = await marketRepo.getAccountSummary(user.id);
  final portfolio = await marketRepo.getPortfolio(account.accountId);
  final marketBoard = await marketRepo.getMarketBoard();

  return DashboardData(account, portfolio, marketBoard);
});
