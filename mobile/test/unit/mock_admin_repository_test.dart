import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/features/admin/data/admin_exception.dart';
import 'package:stockmate/features/admin/data/mock_admin_repository.dart';

void main() {
  test('danh sách khách hàng có tìm kiếm', () async {
    final repo = MockAdminRepository();
    final all = await repo.listCustomers();
    expect(all.total, 6);

    final found = await repo.listCustomers(q: 'bich');
    expect(found.total, 1);
    expect(found.items.first.email, 'bich.tran@gmail.com');
  });

  test('tạo khách hàng mới kèm 1 tài khoản', () async {
    final repo = MockAdminRepository();
    final created = await repo.createCustomer({
      'full_name': 'TEST USER',
      'email': 'test@gmail.com',
      'phone_number': '0909999999',
      'password': '123456',
      'initial_cash_balance': 1000000,
    });
    expect(created.accountsCount, 1);
    expect((await repo.listCustomers()).total, 7);
  });

  test('email trùng bị từ chối', () async {
    final repo = MockAdminRepository();
    expect(
      () => repo.createCustomer({
        'full_name': 'TRUNG EMAIL',
        'email': 'bich.tran@gmail.com',
        'phone_number': '0908888888',
        'password': '123456',
      }),
      throwsA(isA<AdminException>()),
    );
  });

  test('xóa khách hàng xóa luôn tài khoản', () async {
    final repo = MockAdminRepository();
    await repo.deleteCustomer(1);
    expect((await repo.listCustomers()).total, 5);
    expect((await repo.listAccounts(customerId: 1)).total, 0);
  });
}