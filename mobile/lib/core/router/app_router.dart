import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/market/screens/stock_detail_screen.dart';
import '../../features/notification/screens/notification_screen.dart';
import '../../features/order/screens/order_book_screen.dart';
import '../../features/order/screens/place_order_screen.dart';
import '../../features/portfolio/screens/portfolio_screen.dart';
import '../../features/transaction/screens/transaction_history_screen.dart';
import '../../features/watchlist/screens/watchlist_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isAuthPage =
          state.uri.path == '/splash' ||
          state.uri.path == '/login' ||
          state.uri.path == '/register';
      if (authState.isLoading) return null;
      if (!isAuth &&
          state.uri.path != '/login' &&
          state.uri.path != '/register')
        return '/login';
      if (isAuth && isAuthPage) return '/home/overview';
      final isAdmin = authState.value?.isAdmin ?? false;
      if (state.uri.path.startsWith('/home/admin') && !isAdmin)
        return '/home/overview';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
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
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/watchlist',
                builder: (context, state) => const WatchlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/trade',
                builder: (context, state) => PlaceOrderScreen(
                  symbol: state.uri.queryParameters['symbol'],
                  side: state.uri.queryParameters['side'],
                ),
              ),
            ],
          ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/portfolio',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
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
