abstract final class ApiEndpoints {
  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authRefresh = '/api/auth/refresh';
  static const authMe = '/api/auth/me';
  static const accounts = '/api/accounts';

  static String assets(int accountId) => '$accounts/$accountId/assets';
  static String portfolio(int accountId) => '$accounts/$accountId/portfolio';
  static String deposit(int accountId) => '$accounts/$accountId/deposit';
}
