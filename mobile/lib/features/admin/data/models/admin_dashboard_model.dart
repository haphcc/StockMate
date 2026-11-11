class AdminDashboardModel {
  // Khách hàng
  final int totalCustomers;
  final int activeCustomers;
  final int lockedCustomers;
  final int adminCount;
  // Tài khoản
  final int totalAccounts;
  final int activeAccounts;
  final int suspendedAccounts;
  final String totalCashBalance;
  final String totalAssetValue;
  // Cổ phiếu
  final int totalStocks;
  final int activeStocks;
  final int haltedStocks;
  // Lệnh và giao dịch hôm nay
  final int totalOrdersToday;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int totalTransactionsToday;
  final int totalTradingVolumeToday;
  final String totalTradingValueToday;

  const AdminDashboardModel({
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.lockedCustomers = 0,
    this.adminCount = 0,
    this.totalAccounts = 0,
    this.activeAccounts = 0,
    this.suspendedAccounts = 0,
    this.totalCashBalance = '0',
    this.totalAssetValue = '0',
    this.totalStocks = 0,
    this.activeStocks = 0,
    this.haltedStocks = 0,
    this.totalOrdersToday = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.totalTransactionsToday = 0,
    this.totalTradingVolumeToday = 0,
    this.totalTradingValueToday = '0',
  });

  /// Backend trả { "kpis": {...}, "recent_orders": [...], ... }.
  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    final k = (json['kpis'] as Map<String, dynamic>?) ?? json;
    return AdminDashboardModel(
      totalCustomers: k['total_customers'] ?? 0,
      activeCustomers: k['active_customers'] ?? 0,
      lockedCustomers: k['locked_customers'] ?? 0,
      adminCount: k['admin_count'] ?? 0,
      totalAccounts: k['total_accounts'] ?? 0,
      activeAccounts: k['active_accounts'] ?? 0,
      suspendedAccounts: k['suspended_accounts'] ?? 0,
      totalCashBalance: k['total_cash_balance']?.toString() ?? '0',
      totalAssetValue: k['total_asset_value']?.toString() ?? '0',
      totalStocks: k['total_stocks'] ?? 0,
      activeStocks: k['active_stocks'] ?? 0,
      haltedStocks: k['halted_stocks'] ?? 0,
      totalOrdersToday: k['total_orders_today'] ?? 0,
      pendingOrders: k['pending_orders'] ?? 0,
      completedOrders: k['completed_orders'] ?? 0,
      cancelledOrders: k['cancelled_orders'] ?? 0,
      totalTransactionsToday: k['total_transactions_today'] ?? 0,
      totalTradingVolumeToday: k['total_trading_volume_today'] ?? 0,
      totalTradingValueToday: k['total_trading_value_today']?.toString() ?? '0',
    );
  }
}