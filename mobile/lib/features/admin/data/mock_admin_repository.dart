import 'admin_exception.dart';
import 'admin_repository.dart';
import 'models/admin_account_model.dart';
import 'models/admin_customer_model.dart';
import 'models/admin_page.dart';
import 'models/admin_dashboard_model.dart';
import 'models/admin_stock_model.dart';

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