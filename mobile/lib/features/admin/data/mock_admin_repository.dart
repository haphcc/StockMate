import 'admin_exception.dart';
import 'admin_repository.dart';
import 'models/admin_account_model.dart';
import 'models/admin_customer_model.dart';
import 'models/admin_page.dart';

String _money(Object? value) {
  if (value == null) return '0.00';
  final n = num.tryParse(value.toString());
  return n == null ? '0.00' : n.toStringAsFixed(2);
}

String? _moneyOrNull(Object? value) => value == null ? null : _money(value);

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
      accountNumber: '086C000001',
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
      accountNumber: '086C000002',
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
      accountNumber: '086C000003',
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
      accountNumber: '086C000004',
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
      accountNumber: '086C000005',
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
      accountNumber: '086C000006',
      accountType: 'CASH',
      cashBalance: '200000000.00',
      totalAssetValue: '260000000.00',
      status: 'ACTIVE',
    ),
  ];

  int _nextCustomerId = 200;
  int _nextAccountId = 200;

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
        accountNumber: '086C${accountId.toString().padLeft(6, '0')}',
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
        'Không tìm thấy khách hàng.',
        code: 'NOT_FOUND',
      );
    }
    final customer = _customers[customerIndex];
    final accountId = _nextAccountId++;
    final cash = _money(data['cash_balance']);
    final account = AdminAccountModel(
      accountId: accountId,
      customerId: customer.customerId,
      customerName: customer.fullName,
      customerEmail: customer.email,
      accountNumber: data['account_number'] as String? ??
          '086C${accountId.toString().padLeft(6, '0')}',
      accountType: data['account_type'] as String? ?? 'CASH',
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
}