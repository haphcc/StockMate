import 'admin_exception.dart';
import 'admin_repository.dart';
import 'models/admin_account_model.dart';
import 'models/admin_customer_model.dart';
import 'models/admin_page.dart';
import 'models/admin_dashboard_model.dart';
import 'models/admin_stock_model.dart';
import 'models/admin_notification_model.dart';
import 'models/admin_order_model.dart';
import 'models/admin_transaction_model.dart';
import 'models/admin_portfolio_model.dart';

String _money(Object? value) {
  if (value == null) return '0.00';
  final n = num.tryParse(value.toString());
  return n == null ? '0.00' : n.toStringAsFixed(2);
}

String? _moneyOrNull(Object? value) => value == null ? null : _money(value);
double _bandOf(String exchange) {
  switch (exchange) {
    case 'HNX':
      return 0.10;
    case 'UPCOM':
      return 0.15;
    default:
      return 0.07;
  }
}

String _price2(num value) => value.toStringAsFixed(2);

// Làm tròn bước giá 50 đồng, khớp kết quả backend.
num _roundTo50(num value) => (value / 50).round() * 50;

AdminStockModel _makeStock({
  required int id,
  required String symbol,
  required String name,
  required String exchange,
  String? industry,
  required int shares,
  required num reference,
  required num current,
  num? ceiling,
  num? floor,
  int volume = 0,
  String status = 'ACTIVE',
}) {
  final band = _bandOf(exchange);
  final change = current - reference;
  final percent = reference == 0 ? 0 : change / reference * 100;
  return AdminStockModel(
    stockId: id,
    stockSymbol: symbol,
    companyName: name,
    exchange: exchange,
    industry: industry,
    listedShares: shares,
    currentPrice: _price2(current),
    referencePrice: _price2(reference),
    ceilingPrice: _price2(ceiling ?? _roundTo50(reference * (1 + band))),
    floorPrice: _price2(floor ?? _roundTo50(reference * (1 - band))),
    priceChange: _price2(change),
    changePercent: _price2(percent),
    totalVolume: volume,
    status: status,
  );
}

AdminTransactionModel _makeTx({
  required int id,
  required int orderId,
  required int accountId,
  required String accountNumber,
  required String symbol,
  required String type,
  required int quantity,
  required num price,
  required String date,
  required String settlement,
}) {
  final total = quantity * price;
  final fee = total * 0.0015;
  final tax = type == 'SELL' ? total * 0.001 : 0;
  final net = type == 'BUY' ? total + fee : total - fee - tax;
  return AdminTransactionModel(
    transactionId: id,
    orderId: orderId,
    accountId: accountId,
    accountNumber: accountNumber,
    stockSymbol: symbol,
    transactionType: type,
    quantity: quantity,
    price: _price2(price),
    totalAmount: _price2(total),
    transactionFee: _price2(fee),
    taxAmount: _price2(tax),
    netAmount: _price2(net),
    transactionDate: date,
    settlementDate: settlement,
  );
}

AdminPortfolioModel _valued(AdminPortfolioModel p, num currentPrice) {
  final avg = num.tryParse(p.averagePrice) ?? 0;
  final value = p.quantity * currentPrice;
  final cost = p.quantity * avg;
  final pl = value - cost;
  final percent = cost == 0 ? 0 : pl / cost * 100;
  return p.copyWith(
    currentValue: _price2(value),
    profitLoss: _price2(pl),
    profitLossPercent: _price2(percent),
  );
}

class MockAdminRepository implements AdminRepository {
  final List<AdminCustomerModel> _customers = [
    const AdminCustomerModel(
      customerId: 100,
      fullName: 'NGUYEN AN',
      email: 'an.nguyen@gmail.com',
      phoneNumber: '0901000001',
      role: 'ADMIN',
      status: 'ACTIVE',
    ),
    const AdminCustomerModel(
      customerId: 1,
      fullName: 'TRAN THI BICH',
      email: 'bich.tran@gmail.com',
      phoneNumber: '0901000002',
      role: 'CUSTOMER',
      status: 'ACTIVE',
    ),
    const AdminCustomerModel(
      customerId: 2,
      fullName: 'LE MINH CUONG',
      email: 'cuong.le@gmail.com',
      phoneNumber: '0901000003',
      role: 'CUSTOMER',
      status: 'ACTIVE',
    ),
    const AdminCustomerModel(
      customerId: 3,
      fullName: 'PHAM THU DUNG',
      email: 'dung.pham@gmail.com',
      phoneNumber: '0901000004',
      role: 'CUSTOMER',
      status: 'LOCKED',
    ),
    const AdminCustomerModel(
      customerId: 4,
      fullName: 'HOANG VAN EM',
      email: 'em.hoang@gmail.com',
      phoneNumber: '0901000005',
      role: 'CUSTOMER',
      status: 'PENDING',
    ),
    const AdminCustomerModel(
      customerId: 5,
      fullName: 'VU THI PHUONG',
      email: 'phuong.vu@gmail.com',
      phoneNumber: '0901000006',
      role: 'CUSTOMER',
      status: 'ACTIVE',
    ),
  ];

  final List<AdminAccountModel> _accounts = [
    const AdminAccountModel(
      accountId: 1,
      customerId: 100,
      customerName: 'NGUYEN AN',
      customerEmail: 'an.nguyen@gmail.com',
      accountNumber: '068C000001',
      accountType: 'CASH',
      cashBalance: '50000000.00',
      totalAssetValue: '50000000.00',
      status: 'ACTIVE',
    ),
    const AdminAccountModel(
      accountId: 2,
      customerId: 1,
      customerName: 'TRAN THI BICH',
      customerEmail: 'bich.tran@gmail.com',
      accountNumber: '068C000002',
      accountType: 'CASH',
      cashBalance: '120000000.00',
      totalAssetValue: '185000000.00',
      status: 'ACTIVE',
    ),
    const AdminAccountModel(
      accountId: 3,
      customerId: 1,
      customerName: 'TRAN THI BICH',
      customerEmail: 'bich.tran@gmail.com',
      accountNumber: '068C000003',
      accountType: 'MARGIN',
      cashBalance: '30000000.00',
      totalAssetValue: '30000000.00',
      marginLimit: '100000000.00',
      status: 'ACTIVE',
    ),
    const AdminAccountModel(
      accountId: 4,
      customerId: 2,
      customerName: 'LE MINH CUONG',
      customerEmail: 'cuong.le@gmail.com',
      accountNumber: '068C000004',
      accountType: 'CASH',
      cashBalance: '75000000.00',
      totalAssetValue: '92000000.00',
      status: 'ACTIVE',
    ),
    const AdminAccountModel(
      accountId: 5,
      customerId: 3,
      customerName: 'PHAM THU DUNG',
      customerEmail: 'dung.pham@gmail.com',
      accountNumber: '068C000005',
      accountType: 'CASH',
      cashBalance: '10000000.00',
      totalAssetValue: '10000000.00',
      status: 'SUSPENDED',
    ),
    const AdminAccountModel(
      accountId: 6,
      customerId: 5,
      customerName: 'VU THI PHUONG',
      customerEmail: 'phuong.vu@gmail.com',
      accountNumber: '068C000006',
      accountType: 'CASH',
      cashBalance: '200000000.00',
      totalAssetValue: '260000000.00',
      status: 'ACTIVE',
    ),
  ];

  int _nextCustomerId = 200;
  int _nextAccountId = 200;
  int _nextStockId = 200;

  // Mã giả lập đang có lệnh chờ khớp: xóa sẽ bị từ chối.
  final Set<String> _stocksWithActiveOrders = {'VCB'};

  final List<AdminStockModel> _stocks = [
    _makeStock(
      id: 1,
      symbol: 'VCB',
      name: 'Ngân hàng TMCP Ngoại thương Việt Nam',
      exchange: 'HOSE',
      industry: 'Ngân hàng',
      shares: 8355675094,
      reference: 91500,
      current: 92300,
      volume: 1850200,
    ),
    _makeStock(
      id: 2,
      symbol: 'ACB',
      name: 'Ngân hàng TMCP Á Châu',
      exchange: 'HOSE',
      industry: 'Ngân hàng',
      shares: 4460000000,
      reference: 25100,
      current: 25350,
      volume: 3206800,
    ),
    _makeStock(
      id: 3,
      symbol: 'FPT',
      name: 'CTCP FPT',
      exchange: 'HOSE',
      industry: 'Công nghệ thông tin',
      shares: 1700000000,
      reference: 128000,
      current: 126500,
      volume: 2105300,
    ),
    _makeStock(
      id: 4,
      symbol: 'HPG',
      name: 'CTCP Tập đoàn Hòa Phát',
      exchange: 'HOSE',
      industry: 'Thép',
      shares: 6400000000,
      reference: 27000,
      current: 27000,
      volume: 9876500,
    ),
    _makeStock(
      id: 5,
      symbol: 'VNM',
      name: 'CTCP Sữa Việt Nam',
      exchange: 'HOSE',
      industry: 'Thực phẩm',
      shares: 2090000000,
      reference: 61200,
      current: 60800,
      volume: 0,
      status: 'HALTED',
    ),
    _makeStock(
      id: 6,
      symbol: 'BVS',
      name: 'CTCP Chứng khoán Bảo Việt',
      exchange: 'HNX',
      industry: 'Dịch vụ tài chính',
      shares: 108000000,
      reference: 33000,
      current: 33400,
      volume: 412300,
    ),
    _makeStock(
      id: 7,
      symbol: 'ACV',
      name: 'Tổng Công ty Cảng hàng không Việt Nam - CTCP',
      exchange: 'UPCOM',
      industry: 'Vận tải và Kho bãi',
      shares: 2177000000,
      reference: 94500,
      current: 95800,
      volume: 156900,
    ),
    _makeStock(
      id: 8,
      symbol: 'BSR',
      name: 'CTCP Lọc hóa dầu Bình Sơn',
      exchange: 'UPCOM',
      industry: 'Năng lượng',
      shares: 3100000000,
      reference: 19800,
      current: 19400,
      volume: 884000,
    ),
  ];

  int _nextNotificationId = 500;

  final List<AdminNotificationModel> _notifications = [
    const AdminNotificationModel(
      notificationId: 1,
      customerId: 1,
      customerName: 'TRAN THI BICH',
      title: 'Lệnh VCB đã khớp',
      content: 'Lệnh mua 1.000 VCB đã khớp hoàn toàn.',
      notificationType: 'ORDER',
      refId: 57,
      createdAt: '2026-11-05T03:15:00Z',
    ),
    const AdminNotificationModel(
      notificationId: 2,
      customerId: 1,
      customerName: 'TRAN THI BICH',
      title: 'Nạp tiền thành công',
      content: 'Tài khoản 068C000002 đã được nạp 5.000.000 đ.',
      notificationType: 'CASH',
      isRead: true,
      createdAt: '2026-11-04T08:00:00Z',
    ),
    const AdminNotificationModel(
      notificationId: 3,
      customerId: 2,
      customerName: 'LE MINH CUONG',
      title: 'Cảnh báo giá FPT',
      content: 'Cổ phiếu FPT đã chạm mức giá 126.500.',
      notificationType: 'PRICE_ALERT',
      createdAt: '2026-11-03T02:30:00Z',
    ),
    const AdminNotificationModel(
      notificationId: 4,
      customerId: 5,
      customerName: 'VU THI PHUONG',
      title: 'Chào mừng đến StockMate',
      content: 'Tài khoản của bạn đã sẵn sàng giao dịch.',
      notificationType: 'SYSTEM',
      isRead: true,
      createdAt: '2026-11-02T01:00:00Z',
    ),
    const AdminNotificationModel(
      notificationId: 5,
      customerId: 100,
      customerName: 'NGUYEN AN',
      title: 'Bảo trì hệ thống',
      content: 'Hệ thống bảo trì lúc 22:00 tối nay.',
      notificationType: 'NEWS',
      createdAt: '2026-11-01T09:00:00Z',
    ),
    const AdminNotificationModel(
      notificationId: 6,
      customerId: 3,
      customerName: 'PHAM THU DUNG',
      title: 'Giao dịch đã thanh toán',
      content: 'Giao dịch mua ACB đã hoàn tất thanh toán T+2.',
      notificationType: 'TRANSACTION',
      createdAt: '2026-11-01T04:00:00Z',
    ),
  ];

    final List<AdminOrderModel> _orders = [
    const AdminOrderModel(
      orderId: 101,
      accountId: 2,
      accountNumber: '068C000002',
      customerName: 'TRAN THI BICH',
      stockSymbol: 'ACB',
      clientOrderId: 'mock-101',
      orderType: 'BUY',
      quantity: 1000,
      filledQuantity: 1000,
      orderPrice: '25000.00',
      orderDate: '2026-11-10T01:00:00Z',
      matchedAt: '2026-11-10T02:00:00Z',
      status: 'COMPLETED',
    ),
    const AdminOrderModel(
      orderId: 102,
      accountId: 2,
      accountNumber: '068C000002',
      customerName: 'TRAN THI BICH',
      stockSymbol: 'FPT',
      clientOrderId: 'mock-102',
      orderType: 'SELL',
      quantity: 200,
      filledQuantity: 200,
      orderPrice: '127000.00',
      orderDate: '2026-11-10T02:00:00Z',
      matchedAt: '2026-11-10T03:00:00Z',
      status: 'COMPLETED',
    ),
    const AdminOrderModel(
      orderId: 103,
      accountId: 4,
      accountNumber: '068C000004',
      customerName: 'LE MINH CUONG',
      stockSymbol: 'VCB',
      clientOrderId: 'mock-103',
      orderType: 'BUY',
      orderKind: 'MP',
      quantity: 1000,
      orderPrice: '0.00',
      orderDate: '2026-11-10T03:00:00Z',
      status: 'PENDING',
    ),
    const AdminOrderModel(
      orderId: 104,
      accountId: 4,
      accountNumber: '068C000004',
      customerName: 'LE MINH CUONG',
      stockSymbol: 'HPG',
      clientOrderId: 'mock-104',
      orderType: 'BUY',
      quantity: 5000,
      filledQuantity: 2000,
      orderPrice: '26500.00',
      orderDate: '2026-11-10T04:00:00Z',
      status: 'PARTIAL',
    ),
    const AdminOrderModel(
      orderId: 105,
      accountId: 6,
      accountNumber: '068C000006',
      customerName: 'VU THI PHUONG',
      stockSymbol: 'BVS',
      clientOrderId: 'mock-105',
      orderType: 'SELL',
      quantity: 300,
      orderPrice: '34000.00',
      orderDate: '2026-11-10T05:00:00Z',
      status: 'PENDING',
    ),
    const AdminOrderModel(
      orderId: 106,
      accountId: 6,
      accountNumber: '068C000006',
      customerName: 'VU THI PHUONG',
      stockSymbol: 'ACV',
      clientOrderId: 'mock-106',
      orderType: 'BUY',
      quantity: 100,
      orderPrice: '95000.00',
      orderDate: '2026-11-10T06:00:00Z',
      status: 'CANCELLED',
      rejectReason: 'Khách hàng hủy lệnh',
    ),
    const AdminOrderModel(
      orderId: 107,
      accountId: 1,
      accountNumber: '068C000001',
      customerName: 'NGUYEN AN',
      stockSymbol: 'BSR',
      clientOrderId: 'mock-107',
      orderType: 'BUY',
      quantity: 2000,
      orderPrice: '19000.00',
      orderDate: '2026-11-10T07:00:00Z',
      status: 'REJECTED',
      rejectReason: 'Không đủ số dư',
    ),
    const AdminOrderModel(
      orderId: 108,
      accountId: 5,
      accountNumber: '068C000005',
      customerName: 'PHAM THU DUNG',
      stockSymbol: 'ACB',
      clientOrderId: 'mock-108',
      orderType: 'BUY',
      quantity: 1500,
      filledQuantity: 1500,
      orderPrice: '25100.00',
      orderDate: '2026-11-10T08:00:00Z',
      matchedAt: '2026-11-10T09:00:00Z',
      status: 'COMPLETED',
    ),
    const AdminOrderModel(
      orderId: 109,
      accountId: 2,
      accountNumber: '068C000002',
      customerName: 'TRAN THI BICH',
      stockSymbol: 'BVS',
      clientOrderId: 'mock-109',
      orderType: 'BUY',
      quantity: 500,
      orderPrice: '33000.00',
      orderDate: '2026-11-10T09:00:00Z',
      status: 'PENDING',
    ),
    const AdminOrderModel(
      orderId: 110,
      accountId: 4,
      accountNumber: '068C000004',
      customerName: 'LE MINH CUONG',
      stockSymbol: 'VCB',
      clientOrderId: 'mock-110',
      orderType: 'SELL',
      quantity: 100,
      filledQuantity: 100,
      orderPrice: '92000.00',
      orderDate: '2026-11-10T10:00:00Z',
      matchedAt: '2026-11-10T10:30:00Z',
      status: 'COMPLETED',
    ),
  ];

  final List<AdminTransactionModel> _transactions = [
    _makeTx(
      id: 1,
      orderId: 101,
      accountId: 2,
      accountNumber: '068C000002',
      symbol: 'ACB',
      type: 'BUY',
      quantity: 1000,
      price: 25000,
      date: '2026-11-10T02:00:00Z',
      settlement: '2026-11-12',
    ),
    _makeTx(
      id: 2,
      orderId: 102,
      accountId: 2,
      accountNumber: '068C000002',
      symbol: 'FPT',
      type: 'SELL',
      quantity: 200,
      price: 127000,
      date: '2026-11-10T03:00:00Z',
      settlement: '2026-11-12',
    ),
    _makeTx(
      id: 3,
      orderId: 104,
      accountId: 4,
      accountNumber: '068C000004',
      symbol: 'HPG',
      type: 'BUY',
      quantity: 2000,
      price: 26500,
      date: '2026-11-10T05:00:00Z',
      settlement: '2026-11-12',
    ),
    _makeTx(
      id: 4,
      orderId: 108,
      accountId: 5,
      accountNumber: '068C000005',
      symbol: 'ACB',
      type: 'BUY',
      quantity: 1500,
      price: 25100,
      date: '2026-11-10T09:00:00Z',
      settlement: '2026-11-12',
    ),
    _makeTx(
      id: 5,
      orderId: 110,
      accountId: 4,
      accountNumber: '068C000004',
      symbol: 'VCB',
      type: 'SELL',
      quantity: 100,
      price: 92000,
      date: '2026-11-10T10:30:00Z',
      settlement: '2026-11-12',
    ),
  ];

  int _nextPortfolioId = 300;

  final List<AdminPortfolioModel> _portfolios = [
    const AdminPortfolioModel(
      portfolioId: 1,
      accountId: 2,
      accountNumber: '068C000002',
      customerName: 'TRAN THI BICH',
      stockSymbol: 'ACB',
      companyName: 'Ngân hàng TMCP Á Châu',
      quantity: 3000,
      availableQuantity: 3000,
      averagePrice: '24000.00',
    ),
    const AdminPortfolioModel(
      portfolioId: 2,
      accountId: 2,
      accountNumber: '068C000002',
      customerName: 'TRAN THI BICH',
      stockSymbol: 'FPT',
      companyName: 'CTCP FPT',
      quantity: 500,
      availableQuantity: 300,
      blockedQuantity: 200,
      averagePrice: '120000.00',
    ),
    const AdminPortfolioModel(
      portfolioId: 3,
      accountId: 4,
      accountNumber: '068C000004',
      customerName: 'LE MINH CUONG',
      stockSymbol: 'HPG',
      companyName: 'CTCP Tập đoàn Hòa Phát',
      quantity: 2000,
      availableQuantity: 2000,
      averagePrice: '26500.00',
    ),
    const AdminPortfolioModel(
      portfolioId: 4,
      accountId: 4,
      accountNumber: '068C000004',
      customerName: 'LE MINH CUONG',
      stockSymbol: 'VCB',
      companyName: 'Ngân hàng TMCP Ngoại thương Việt Nam',
      quantity: 400,
      availableQuantity: 400,
      averagePrice: '90000.00',
    ),
    const AdminPortfolioModel(
      portfolioId: 5,
      accountId: 6,
      accountNumber: '068C000006',
      customerName: 'VU THI PHUONG',
      stockSymbol: 'BVS',
      companyName: 'CTCP Chứng khoán Bảo Việt',
      quantity: 1000,
      availableQuantity: 700,
      blockedQuantity: 300,
      averagePrice: '32000.00',
    ),
    const AdminPortfolioModel(
      portfolioId: 6,
      accountId: 5,
      accountNumber: '068C000005',
      customerName: 'PHAM THU DUNG',
      stockSymbol: 'ACB',
      companyName: 'Ngân hàng TMCP Á Châu',
      quantity: 1500,
      availableQuantity: 1500,
      averagePrice: '25100.00',
    ),
    const AdminPortfolioModel(
      portfolioId: 7,
      accountId: 1,
      accountNumber: '068C000001',
      customerName: 'NGUYEN AN',
      stockSymbol: 'BSR',
      companyName: 'CTCP Lọc hóa dầu Bình Sơn',
      quantity: 2000,
      availableQuantity: 2000,
      averagePrice: '20000.00',
    ),
  ];

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 300));

  AdminPage<T> _paginate<T>(List<T> all, int page, int pageSize) {
    final start = (page - 1) * pageSize;
    final items =
        start >= all.length ? <T>[] : all.skip(start).take(pageSize).toList();
    return AdminPage<T>(
      items: items,
      page: page,
      pageSize: pageSize,
      total: all.length,
    );
  }

  AdminCustomerModel _view(AdminCustomerModel c, {bool withAccounts = false}) {
    final accounts =
        _accounts.where((a) => a.customerId == c.customerId).toList();
    return c.copyWith(
      accountsCount: accounts.length,
      accounts: withAccounts ? accounts : const [],
    );
  }

  int _customerIndex(int id) {
    final index = _customers.indexWhere((c) => c.customerId == id);
    if (index < 0) {
      throw const AdminException(
        'Không tìm thấy khách hàng.',
        code: 'NOT_FOUND',
      );
    }
    return index;
  }

  int _accountIndex(int id) {
    final index = _accounts.indexWhere((a) => a.accountId == id);
    if (index < 0) {
      throw const AdminException(
        'Không tìm thấy tài khoản.',
        code: 'NOT_FOUND',
      );
    }
    return index;
  }

  // ---------------- Khách hàng ----------------

  @override
  Future<AdminPage<AdminCustomerModel>> listCustomers({
    String? q,
    String? role,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    await _delay();
    final keyword = (q ?? '').trim().toLowerCase();
    final filtered = _customers.where((c) {
      if (role != null && c.role != role) return false;
      if (status != null && c.status != status) return false;
      if (keyword.isEmpty) return true;
      return c.fullName.toLowerCase().contains(keyword) ||
          c.email.toLowerCase().contains(keyword) ||
          c.phoneNumber.contains(keyword);
    }).toList();
    final views = filtered.map((c) => _view(c)).toList();
    return _paginate(views, page, pageSize);
  }

  @override
  Future<AdminCustomerModel> getCustomer(int customerId) async {
    await _delay();
    return _view(_customers[_customerIndex(customerId)], withAccounts: true);
  }

  @override
  Future<AdminCustomerModel> createCustomer(Map<String, dynamic> data) async {
    await _delay();
    final email = (data['email'] as String? ?? '').trim();
    final duplicated =
        _customers.any((c) => c.email.toLowerCase() == email.toLowerCase());
    if (duplicated) {
      throw const AdminException(
        'Email đã được sử dụng.',
        code: 'EMAIL_ALREADY_EXISTS',
      );
    }
    final customer = AdminCustomerModel(
      customerId: _nextCustomerId++,
      fullName: data['full_name'] as String? ?? '',
      email: email,
      phoneNumber: data['phone_number'] as String? ?? '',
      role: data['role'] as String? ?? 'CUSTOMER',
      status: data['status'] as String? ?? 'ACTIVE',
      dateOfBirth: data['date_of_birth'] as String?,
      idCardNumber: data['id_card_number'] as String?,
      address: data['address'] as String?,
      createdAt: DateTime.now().toIso8601String(),
    );
    _customers.add(customer);

    final accountId = _nextAccountId++;
    final cash = _money(data['initial_cash_balance']);
    _accounts.add(
      AdminAccountModel(
        accountId: accountId,
        customerId: customer.customerId,
        customerName: customer.fullName,
        customerEmail: customer.email,
        accountNumber: '068C${accountId.toString().padLeft(6, '0')}',
        accountType: 'CASH',
        cashBalance: cash,
        totalAssetValue: cash,
        status: 'ACTIVE',
      ),
    );
    return _view(customer);
  }

  @override
  Future<AdminCustomerModel> updateCustomer(
    int customerId,
    Map<String, dynamic> data,
  ) async {
    await _delay();
    final index = _customerIndex(customerId);
    final newEmail = data['email'] as String?;
    if (newEmail != null) {
      final duplicated = _customers.any(
        (c) =>
            c.customerId != customerId &&
            c.email.toLowerCase() == newEmail.toLowerCase(),
      );
      if (duplicated) {
        throw const AdminException(
          'Email đã được sử dụng.',
          code: 'EMAIL_ALREADY_EXISTS',
        );
      }
    }
    // Khóa 'password' (đặt lại mật khẩu) được bỏ qua trong mock.
    final updated = _customers[index].copyWith(
      fullName: data['full_name'] as String?,
      email: newEmail,
      phoneNumber: data['phone_number'] as String?,
      role: data['role'] as String?,
      status: data['status'] as String?,
      dateOfBirth: data['date_of_birth'] as String?,
      idCardNumber: data['id_card_number'] as String?,
      address: data['address'] as String?,
      avatarUrl: data['avatar_url'] as String?,
    );
    _customers[index] = updated;
    for (var i = 0; i < _accounts.length; i++) {
      if (_accounts[i].customerId == customerId) {
        _accounts[i] = _accounts[i].copyWith(
          customerName: updated.fullName,
          customerEmail: updated.email,
        );
      }
    }
    return _view(updated);
  }

  @override
  Future<void> deleteCustomer(int customerId) async {
    await _delay();
    final index = _customerIndex(customerId);
    _customers.removeAt(index);
    _accounts.removeWhere((a) => a.customerId == customerId);
  }

  // ---------------- Tài khoản đầu tư ----------------

  @override
  Future<AdminPage<AdminAccountModel>> listAccounts({
    String? q,
    int? customerId,
    String? accountType,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    await _delay();
    final keyword = (q ?? '').trim().toLowerCase();
    final filtered = _accounts.where((a) {
      if (customerId != null && a.customerId != customerId) return false;
      if (accountType != null && a.accountType != accountType) return false;
      if (status != null && a.status != status) return false;
      if (keyword.isEmpty) return true;
      return a.accountNumber.toLowerCase().contains(keyword) ||
          a.customerName.toLowerCase().contains(keyword);
    }).toList();
    return _paginate(filtered, page, pageSize);
  }

    @override
  Future<AdminAccountModel> createAccount(Map<String, dynamic> data) async {
    await _delay();
    final customerId = data['customer_id'] as int?;
    final customerIndex =
        _customers.indexWhere((c) => c.customerId == customerId);
    if (customerIndex < 0) {
      throw const AdminException(
        'Không tìm thấy khách hàng để mở tài khoản.',
        code: 'NOT_FOUND',
      );
    }
    final customer = _customers[customerIndex];

    final type = data['account_type'] as String? ?? 'CASH';
    final requested = (data['account_number'] as String?)?.trim();
    if (requested != null &&
        requested.isNotEmpty &&
        _accounts.any((a) => a.accountNumber == requested)) {
      throw const AdminException(
        'Số tài khoản đã tồn tại.',
        code: 'DUPLICATE_ACCOUNT_NUMBER',
      );
    }

    final accountId = _nextAccountId++;
    final prefix = type == 'MARGIN' ? '068M' : '068C';
    final accountNumber = (requested != null && requested.isNotEmpty)
        ? requested
        : '$prefix${accountId.toString().padLeft(6, '0')}';
    final cash = _money(data['cash_balance']);

    final account = AdminAccountModel(
      accountId: accountId,
      customerId: customer.customerId,
      customerName: customer.fullName,
      customerEmail: customer.email,
      accountNumber: accountNumber,
      accountType: type,
      cashBalance: cash,
      totalAssetValue: cash,
      marginLimit: _money(data['margin_limit']),
      status: data['status'] as String? ?? 'ACTIVE',
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<AdminAccountModel> updateAccount(
    int accountId,
    Map<String, dynamic> data,
  ) async {
    await _delay();
    final index = _accountIndex(accountId);
    final updated = _accounts[index].copyWith(
      accountType: data['account_type'] as String?,
      cashBalance: _moneyOrNull(data['cash_balance']),
      blockedBalance: _moneyOrNull(data['blocked_balance']),
      totalAssetValue: _moneyOrNull(data['total_asset_value']),
      marginLimit: _moneyOrNull(data['margin_limit']),
      status: data['status'] as String?,
    );
    _accounts[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteAccount(int accountId) async {
    await _delay();
    _accounts.removeAt(_accountIndex(accountId));
  }

    // ---------------- Cổ phiếu ----------------

  int _stockIndex(int id) {
    final index = _stocks.indexWhere((s) => s.stockId == id);
    if (index < 0) {
      throw const AdminException(
        'Không tìm thấy mã cổ phiếu.',
        code: 'NOT_FOUND',
      );
    }
    return index;
  }

  @override
  Future<AdminPage<AdminStockModel>> listStocks({
    String? q,
    String? exchange,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    await _delay();
    final keyword = (q ?? '').trim().toLowerCase();
    final filtered = _stocks.where((s) {
      if (exchange != null && s.exchange != exchange) return false;
      if (status != null && s.status != status) return false;
      if (keyword.isEmpty) return true;
      return s.stockSymbol.toLowerCase().contains(keyword) ||
          s.companyName.toLowerCase().contains(keyword);
    }).toList()
      ..sort((a, b) => a.stockSymbol.compareTo(b.stockSymbol));
    return _paginate(filtered, page, pageSize);
  }

  @override
  Future<AdminStockModel> createStock(Map<String, dynamic> data) async {
    await _delay();
    final symbol = (data['stock_symbol'] as String? ?? '').trim().toUpperCase();
    if (_stocks.any((s) => s.stockSymbol == symbol)) {
      throw AdminException(
        'Mã cổ phiếu $symbol đã tồn tại trên sàn.',
        code: 'DUPLICATE_STOCK_SYMBOL',
      );
    }
    final reference = num.tryParse('${data['reference_price']}') ?? 0;
    final stock = _makeStock(
      id: _nextStockId++,
      symbol: symbol,
      name: data['company_name'] as String? ?? '',
      exchange: data['exchange'] as String? ?? 'HOSE',
      industry: data['industry'] as String?,
      shares: data['listed_shares'] as int? ?? 0,
      reference: reference,
      current: num.tryParse('${data['current_price']}') ?? reference,
      ceiling: num.tryParse('${data['ceiling_price'] ?? ''}'),
      floor: num.tryParse('${data['floor_price'] ?? ''}'),
      status: data['status'] as String? ?? 'ACTIVE',
    );
    _stocks.add(stock);
    return stock;
  }

  @override
  Future<AdminStockModel> updateStock(
    int stockId,
    Map<String, dynamic> data,
  ) async {
    await _delay();
    final index = _stockIndex(stockId);
    final old = _stocks[index];
    num? numOf(String key) =>
        data.containsKey(key) ? num.tryParse('${data[key]}') : null;

    final exchange = data['exchange'] as String? ?? old.exchange;
    final reference = numOf('reference_price') ?? num.parse(old.referencePrice);
    final current = numOf('current_price') ?? num.parse(old.currentPrice);
    var ceiling = numOf('ceiling_price');
    var floor = numOf('floor_price');
    // Giống backend: đổi giá tham chiếu mà không gửi trần/sàn thì tính lại.
    if (data.containsKey('reference_price') &&
        ceiling == null &&
        floor == null) {
      final band = _bandOf(exchange);
      ceiling = _roundTo50(reference * (1 + band));
      floor = _roundTo50(reference * (1 - band));
    }
    final change = current - reference;
    final percent = reference == 0 ? 0 : change / reference * 100;
    final updated = old.copyWith(
      companyName: data['company_name'] as String?,
      exchange: data['exchange'] as String?,
      industry: data['industry'] as String?,
      listedShares: data['listed_shares'] as int?,
      currentPrice: _price2(current),
      referencePrice: _price2(reference),
      ceilingPrice: ceiling == null ? null : _price2(ceiling),
      floorPrice: floor == null ? null : _price2(floor),
      priceChange: _price2(change),
      changePercent: _price2(percent),
      status: data['status'] as String?,
    );
    _stocks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteStock(int stockId) async {
    await _delay();
    final index = _stockIndex(stockId);
    if (_stocksWithActiveOrders.contains(_stocks[index].stockSymbol)) {
      throw const AdminException(
        'Không thể xóa cổ phiếu đang có lệnh chờ khớp trên sàn. '
        'Vui lòng hủy các lệnh trước.',
        code: 'STOCK_HAS_ACTIVE_ORDERS',
      );
    }
    _stocks.removeAt(index);
  }

    // ---------------- Thông báo ----------------

  @override
  Future<AdminPage<AdminNotificationModel>> listNotifications({
    int? customerId,
    String? notificationType,
    int page = 1,
    int pageSize = 20,
  }) async {
    await _delay();
    final filtered = _notifications.where((n) {
      if (customerId != null && n.customerId != customerId) return false;
      if (notificationType != null && n.notificationType != notificationType) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _paginate(filtered, page, pageSize);
  }

  @override
  Future<AdminNotificationModel> sendNotification(
    Map<String, dynamic> data,
  ) async {
    await _delay();
    final title = data['title'] as String? ?? '';
    final content = data['content'] as String? ?? '';
    final type = data['notification_type'] as String? ?? 'SYSTEM';
    final refId = data['ref_id'] as int?;
    final now = DateTime.now().toUtc().toIso8601String();
    final customerId = data['customer_id'] as int?;

    if (customerId != null) {
      final index = _customers.indexWhere((c) => c.customerId == customerId);
      if (index < 0) {
        throw const AdminException(
          'Không tìm thấy khách hàng để gửi thông báo.',
          code: 'NOT_FOUND',
        );
      }
      final notification = AdminNotificationModel(
        notificationId: _nextNotificationId++,
        customerId: customerId,
        customerName: _customers[index].fullName,
        title: title,
        content: content,
        notificationType: type,
        refId: refId,
        createdAt: now,
      );
      _notifications.add(notification);
      return notification;
    }

    // Broadcast: mỗi khách hàng đang hoạt động nhận một bản riêng (giống backend).
    final recipients = _customers.where((c) => c.status == 'ACTIVE').toList();
    int? firstId;
    for (final c in recipients) {
      final id = _nextNotificationId++;
      firstId ??= id;
      _notifications.add(
        AdminNotificationModel(
          notificationId: id,
          customerId: c.customerId,
          customerName: c.fullName,
          title: title,
          content: content,
          notificationType: type,
          refId: refId,
          createdAt: now,
        ),
      );
    }
    // Phản hồi là bản tóm tắt, giống backend.
    return AdminNotificationModel(
      notificationId: firstId ?? 0,
      customerId: 0,
      customerName: '[TOÀN BỘ KHÁCH HÀNG]',
      title: title,
      content: '[Broadcast đến ${recipients.length} khách hàng] $content',
      notificationType: type,
      refId: refId,
      createdAt: now,
    );
  }

  @override
  Future<void> deleteNotification(int notificationId) async {
    await _delay();
    final index =
        _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index < 0) {
      throw const AdminException(
        'Không tìm thấy thông báo cần xóa.',
        code: 'NOT_FOUND',
      );
    }
    _notifications.removeAt(index);
  }

    // ---------------- Lệnh đặt ----------------

  @override
  Future<AdminPage<AdminOrderModel>> listOrders({
    int? accountId,
    String? stockSymbol,
    String? status,
    String? orderType,
    int page = 1,
    int pageSize = 20,
  }) async {
    await _delay();
    final symbol = (stockSymbol ?? '').trim().toUpperCase();
    final filtered = _orders.where((o) {
      if (accountId != null && o.accountId != accountId) return false;
      if (symbol.isNotEmpty && o.stockSymbol != symbol) return false;
      if (status != null && o.status != status) return false;
      if (orderType != null && o.orderType != orderType) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return _paginate(filtered, page, pageSize);
  }

  @override
  Future<AdminOrderModel> updateOrder(
    int orderId,
    Map<String, dynamic> data,
  ) async {
    await _delay();
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index < 0) {
      throw const AdminException(
        'Không tìm thấy lệnh đặt.',
        code: 'NOT_FOUND',
      );
    }
    final status = data['status'] as String?;
    final old = _orders[index];
    final updated = old.copyWith(
      status: status,
      filledQuantity: data['filled_quantity'] as int?,
      rejectReason: data['reject_reason'] as String?,
      matchedAt: status == 'COMPLETED' && old.matchedAt == null
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    );
    _orders[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    await _delay();
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index < 0) {
      throw const AdminException(
        'Không tìm thấy lệnh cần xóa.',
        code: 'NOT_FOUND',
      );
    }
    if (_transactions.any((t) => t.orderId == orderId)) {
      throw const AdminException(
        'Lệnh đã có giao dịch khớp nên không thể xóa.',
        code: 'ORDER_HAS_TRANSACTIONS',
      );
    }
    _orders.removeAt(index);
  }

  // ---------------- Giao dịch ----------------

  @override
  Future<AdminPage<AdminTransactionModel>> listTransactions({
    int? accountId,
    String? stockSymbol,
    String? transactionType,
    int page = 1,
    int pageSize = 20,
  }) async {
    await _delay();
    final symbol = (stockSymbol ?? '').trim().toUpperCase();
    final filtered = _transactions.where((t) {
      if (accountId != null && t.accountId != accountId) return false;
      if (symbol.isNotEmpty && t.stockSymbol != symbol) return false;
      if (transactionType != null && t.transactionType != transactionType) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return _paginate(filtered, page, pageSize);
  }

    // ---------------- Danh mục nắm giữ ----------------

  AdminPortfolioModel _portfolioView(AdminPortfolioModel p) {
    final stockIndex = _stocks.indexWhere((s) => s.stockSymbol == p.stockSymbol);
    final price = stockIndex < 0
        ? 0
        : (num.tryParse(_stocks[stockIndex].currentPrice) ?? 0);
    return _valued(p, price);
  }

  // Giống backend: ràng buộc DB bị vi phạm sẽ bị báo nhầm là lỗi cơ sở dữ liệu.
  void _checkHolding(int quantity, int available, int blocked) {
    if (available + blocked > quantity) {
      throw const AdminException(
        'Không thể truy cập cơ sở dữ liệu.',
        code: 'DATABASE_UNAVAILABLE',
      );
    }
  }

  @override
  Future<AdminPage<AdminPortfolioModel>> listPortfolios({
    int? accountId,
    String? stockSymbol,
    int page = 1,
    int pageSize = 20,
  }) async {
    await _delay();
    final symbol = (stockSymbol ?? '').trim().toUpperCase();
    final filtered = _portfolios.where((p) {
      if (accountId != null && p.accountId != accountId) return false;
      if (symbol.isNotEmpty && p.stockSymbol != symbol) return false;
      return true;
    }).map(_portfolioView).toList()
      ..sort((a, b) => a.portfolioId.compareTo(b.portfolioId));
    return _paginate(filtered, page, pageSize);
  }

  @override
  Future<AdminPortfolioModel> createPortfolio(Map<String, dynamic> data) async {
    await _delay();
    final accountId = data['account_id'] as int?;
    final accountIndex = _accounts.indexWhere((a) => a.accountId == accountId);
    if (accountIndex < 0) {
      throw const AdminException(
        'Không tìm thấy tài khoản đầu tư.',
        code: 'NOT_FOUND',
      );
    }
    final symbol = (data['stock_symbol'] as String? ?? '').trim().toUpperCase();
    final stockIndex = _stocks.indexWhere((s) => s.stockSymbol == symbol);
    if (stockIndex < 0) {
      throw AdminException(
        'Không tìm thấy mã cổ phiếu $symbol.',
        code: 'NOT_FOUND',
      );
    }
    final exists = _portfolios.any(
      (p) => p.accountId == accountId && p.stockSymbol == symbol,
    );
    if (exists) {
      throw AdminException(
        'Tài khoản đã nắm giữ mã $symbol. Hãy sửa dòng đã có.',
        code: 'PORTFOLIO_EXISTS',
      );
    }
    final quantity = data['quantity'] as int? ?? 0;
    final available = data['available_quantity'] as int? ?? 0;
    final blocked = data['blocked_quantity'] as int? ?? 0;
    _checkHolding(quantity, available, blocked);

    final account = _accounts[accountIndex];
    final holding = AdminPortfolioModel(
      portfolioId: _nextPortfolioId++,
      accountId: account.accountId,
      accountNumber: account.accountNumber,
      customerName: account.customerName,
      stockSymbol: symbol,
      companyName: _stocks[stockIndex].companyName,
      quantity: quantity,
      availableQuantity: available,
      blockedQuantity: blocked,
      averagePrice: _money(data['average_price']),
    );
    _portfolios.add(holding);
    return _portfolioView(holding);
  }

  @override
  Future<AdminPortfolioModel> updatePortfolio(
    int portfolioId,
    Map<String, dynamic> data,
  ) async {
    await _delay();
    final index = _portfolios.indexWhere((p) => p.portfolioId == portfolioId);
    if (index < 0) {
      throw const AdminException(
        'Không tìm thấy dòng nắm giữ.',
        code: 'NOT_FOUND',
      );
    }
    final old = _portfolios[index];
    final quantity = data['quantity'] as int? ?? old.quantity;
    final available = data['available_quantity'] as int? ?? old.availableQuantity;
    final blocked = data['blocked_quantity'] as int? ?? old.blockedQuantity;
    _checkHolding(quantity, available, blocked);
    final updated = old.copyWith(
      quantity: quantity,
      availableQuantity: available,
      blockedQuantity: blocked,
      averagePrice: _moneyOrNull(data['average_price']),
    );
    _portfolios[index] = updated;
    return _portfolioView(updated);
  }

  @override
  Future<void> deletePortfolio(int portfolioId) async {
    await _delay();
    final index = _portfolios.indexWhere((p) => p.portfolioId == portfolioId);
    if (index < 0) {
      throw const AdminException(
        'Không tìm thấy dòng nắm giữ.',
        code: 'NOT_FOUND',
      );
    }
    _portfolios.removeAt(index);
  }

    // ---------------- Dashboard ----------------

  @override
  Future<AdminDashboardModel> getDashboard() async {
    await _delay();
    // Chỉ dùng cho mock: cộng bằng num là đủ, API thật sẽ trả sẵn chuỗi.
    num sum(Iterable<String> values) =>
        values.fold<num>(0, (s, v) => s + (num.tryParse(v) ?? 0));

    return AdminDashboardModel(
      totalCustomers: _customers.length,
      activeCustomers: _customers.where((c) => c.status == 'ACTIVE').length,
      lockedCustomers: _customers.where((c) => c.status == 'LOCKED').length,
      adminCount: _customers.where((c) => c.isAdmin).length,
      totalAccounts: _accounts.length,
      activeAccounts: _accounts.where((a) => a.status == 'ACTIVE').length,
      suspendedAccounts:
          _accounts.where((a) => a.status == 'SUSPENDED').length,
      totalCashBalance:
          sum(_accounts.map((a) => a.cashBalance)).toStringAsFixed(2),
      totalAssetValue:
          sum(_accounts.map((a) => a.totalAssetValue)).toStringAsFixed(2),
      // Các số dưới đây là dữ liệu mẫu (mock chưa có cổ phiếu, lệnh, giao dịch).
      totalStocks: _stocks.length,
      activeStocks: _stocks.where((s) => s.status == 'ACTIVE').length,
      haltedStocks: _stocks.where((s) => s.status == 'HALTED').length,
      totalOrdersToday: 12,
      pendingOrders: 3,
      completedOrders: 8,
      cancelledOrders: 1,
      totalTransactionsToday: 8,
      totalTradingVolumeToday: 15400,
      totalTradingValueToday: '2350000000.00',
    );
  }
}