import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/home/screens/deposit_screen.dart';
import '../../features/home/screens/settings_screen.dart';
import '../../features/market/screens/stock_detail_screen.dart';
import '../../features/notification/screens/notification_screen.dart';
import '../../features/watchlist/screens/watchlist_screen.dart';
import '../../features/order/screens/order_book_screen.dart';
import '../../features/order/screens/place_order_screen.dart';
import '../../features/portfolio/screens/portfolio_screen.dart';
import '../../features/transaction/screens/transaction_history_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, _) {
      notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.value != null;
      final isSplash = state.uri.path == '/splash';
      final isLoggingIn =
          state.uri.path == '/login' || state.uri.path == '/register';

      if (authState.isLoading) return null;

      if (isSplash) {
        return isAuth ? '/home/overview' : '/login';
      }

      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      if (isAuth && isLoggingIn) {
        return '/home/overview';
      }

      final isAdmin = authState.value?.isAdmin ?? false;
      if (state.uri.path.startsWith('/home/admin') && !isAdmin) {
        return '/home/overview';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/deposit',
        builder: (context, state) => const DepositScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Thị trường (Dashboard)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/overview',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'stock/:symbol',
                    builder: (context, state) => StockDetailScreen(
                      symbol: state.pathParameters['symbol']!,
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/home/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          // Branch 1: Theo dõi (Watchlist)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/watchlist',
                builder: (context, state) => const WatchlistScreen(),
              ),
            ],
          ),
          // Branch 2: Đặt lệnh
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/trade',
                builder: (context, state) {
                  final symbol = state.uri.queryParameters['symbol'];
                  final side = state.uri.queryParameters['side'];
                  final priceStr = state.uri.queryParameters['price'];
                  final price =
                      priceStr != null ? double.tryParse(priceStr) : null;
                  return PlaceOrderScreen(
                    symbol: symbol,
                    side: side,
                    initialSymbol: symbol,
                    isBuy: side?.toLowerCase() == 'sell' ? false : true,
                    initialPrice: price,
                  );
                },
              ),
            ],
          ),
          // Branch 3: Sổ lệnh
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/orders',
                builder: (context, state) => const OrderBookScreen(),
                routes: [
                  GoRoute(
                    path: 'transactions',
                    builder: (context, state) =>
                        const TransactionHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Danh mục (Portfolio)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/portfolio',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
          // Branch 5: Quản trị (Admin)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/admin',
                builder: (context, state) => const AdminHomeScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
