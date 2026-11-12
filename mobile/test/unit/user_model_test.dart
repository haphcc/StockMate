import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/data/models/user_model.dart';
import 'package:stockmate/data/repositories/mock_auth_repository.dart';

void main() {
  group('UserModel.role', () {
    final base = {
      'customer_id': 7,
      'full_name': 'A',
      'email': 'a@b.vn',
      'phone_number': '0912345678',
      'status': 'ACTIVE',
    };

    test('fromJson đọc role ADMIN', () {
      final user = UserModel.fromJson({...base, 'role': 'ADMIN'});
      expect(user.role, 'ADMIN');
      expect(user.isAdmin, isTrue);
    });

    test('thiếu role thì mặc định CUSTOMER', () {
      final user = UserModel.fromJson(base);
      expect(user.role, 'CUSTOMER');
      expect(user.isAdmin, isFalse);
    });

    test('toJson giữ role', () {
      final user = UserModel.fromJson({...base, 'role': 'ADMIN'});
      expect(user.toJson()['role'], 'ADMIN');
    });
  });

  group('MockAuthRepository', () {
    test('email admin nhận role ADMIN', () async {
      final user = await MockAuthRepository().login('an.nguyen@gmail.com', 'x');
      expect(user.isAdmin, isTrue);
    });

    test('email khác nhận role CUSTOMER', () async {
      final user = await MockAuthRepository().login('khach@gmail.com', 'x');
      expect(user.isAdmin, isFalse);
    });
  });
}