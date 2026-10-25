// Owner: TV2 - Sơn. Mirror backend/openapi.json; TV3 proposes trading changes here.
class ApiEndpoints {
  static const login = '/api/auth/login';
  static const register = '/api/auth/register';
  static const refresh = '/api/auth/refresh';
  static const me = '/api/auth/me';
  static const marketBoard = '/api/market/board';
  static const accounts = '/api/accounts';
  static const watchlist = '/api/watchlist';
  static const notifications = '/api/notifications';

  static String stock(String symbol) => '/api/stocks/${Uri.encodeComponent(symbol)}';
  static String chart(String symbol) => '${stock(symbol)}/chart';
  static String assets(int accountId) => '/api/accounts/$accountId/assets';
  static String portfolio(int accountId) => '/api/accounts/$accountId/portfolio';
  static String orders(int accountId) => '/api/accounts/$accountId/orders';
  static String transactions(int accountId) => '/api/accounts/$accountId/transactions';
  static String cancelOrder(int orderId) => '/api/orders/$orderId';
  static String removeWatchlist(String symbol) => '$watchlist/${Uri.encodeComponent(symbol)}';
  static String readNotification(int id) => '$notifications/$id/read';
}
