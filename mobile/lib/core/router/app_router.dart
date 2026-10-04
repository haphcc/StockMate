import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/order/screens/order_book_screen.dart';
import '../../features/order/screens/place_order_screen.dart';
import '../../features/portfolio/screens/portfolio_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Logic điều hướng dựa trên trạng thái xác thực
      final isAuth = authState.value != null;
      final isSplash = state.uri.path == '/splash';
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';

      if (authState.isLoading) return null; // Đợi load xong

      if (isSplash) {
        return isAuth ? '/home/overview' : '/login';
      }

      if (!isAuth && !isLoggingIn) {
        return '/login'; // Chưa đăng nhập -> về login
      }

      if (isAuth && isLoggingIn) {
        return '/home/overview'; // Đã đăng nhập nhưng vào login -> về home
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Thị trường (Dashboard)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/overview',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Sổ lệnh
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/orders',
                builder: (context, state) => const OrderBookScreen(),
              ),
            ],
          ),
          // Tab 2: Đặt lệnh
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/trade',
                builder: (context, state) => const PlaceOrderScreen(),
              ),
            ],
          ),
          // Tab 3: Danh mục
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/portfolio',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
