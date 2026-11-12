import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/account_model.dart';
import '../data/models/portfolio_model.dart';
import 'app_providers.dart';
import 'selected_account_provider.dart';

final accountsProvider = FutureProvider.autoDispose<List<AccountModel>>((ref) => ref.watch(accountRepositoryProvider).listAccounts());

final activeAccountProvider = FutureProvider.autoDispose<AccountModel?>((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final selectedId = ref.watch(selectedAccountProvider);
  for (final account in accounts) { if (account.accountId == selectedId) return account; }
  for (final account in accounts) {
    if (account.accountType == 'CASH' && account.status == 'ACTIVE') {
      ref.read(selectedAccountProvider.notifier).select(account.accountId);
      return account;
    }
  }
  return null;
});

final assetsProvider = FutureProvider.autoDispose<AssetModel?>((ref) async {
  final account = await ref.watch(activeAccountProvider.future);
  if (account == null) return null;
  return ref.watch(accountRepositoryProvider).getAssets(account.accountId);
});

final portfolioProvider = FutureProvider.autoDispose<List<PortfolioModel>>((ref) async {
  final account = await ref.watch(activeAccountProvider.future);
  if (account == null) return const [];
  return ref.watch(accountRepositoryProvider).getPortfolio(account.accountId);
});
