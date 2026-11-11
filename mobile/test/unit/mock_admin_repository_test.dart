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

  test('cập nhật tài khoản từ chối số dư vô lý và tự tính tổng tài sản',
      () async {
    final repo = MockAdminRepository();
    expect(
      () => repo.updateAccount(1, {
        'cash_balance': '100.00',
        'blocked_balance': '999999.00',
        'total_asset_value': '50.00',
      }),
      throwsA(isA<AdminException>()),
    );

    final updated = await repo.updateAccount(1, {'cash_balance': '60000000'});
    expect(updated.totalAssetValue, '60000000.00');
  });

  test('cổ phiếu kiểm tra logic giá và tự tính lại trần/sàn khi đổi tham chiếu',
      () async {
    final repo = MockAdminRepository();
    expect(
      () => repo.updateStock(1, {
        'ceiling_price': '10000',
        'floor_price': '30000',
      }),
      throwsA(isA<AdminException>()),
    );

    final updated = await repo.updateStock(1, {
      'reference_price': '50000',
      'current_price': '51000',
    });
    expect(updated.ceilingPrice, '53500.00');
    expect(updated.floorPrice, '46500.00');
  });

  test('sổ lệnh chặn xóa lệnh đã có giao dịch và hủy được lệnh chờ', () async {
    final repo = MockAdminRepository();
    expect(() => repo.deleteOrder(101), throwsA(isA<AdminException>()));

    final cancelled = await repo.updateOrder(103, {
      'status': 'CANCELLED',
      'reject_reason': 'Admin test',
    });
    expect(cancelled.status, 'CANCELLED');
    expect(cancelled.rejectReason, 'Admin test');
  });

  test('thông báo gửi đích danh, broadcast và xóa được', () async {
    final repo = MockAdminRepository();
    final broadcast = await repo.sendNotification({
      'customer_id': null,
      'title': 'Bảo trì',
      'content': 'Nội dung bảo trì',
      'notification_type': 'SYSTEM',
    });
    expect(broadcast.customerName, '[TOÀN BỘ KHÁCH HÀNG]');

    await repo.deleteNotification(broadcast.notificationId);
  });
}