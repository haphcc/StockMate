class AdminConstants {
  static const List<String> customerRoles = ['CUSTOMER', 'ADMIN'];
  static const List<String> customerStatuses = [
    'PENDING',
    'ACTIVE',
    'LOCKED',
    'CLOSED',
  ];
  static const List<String> accountTypes = ['CASH', 'MARGIN'];
  static const List<String> accountStatuses = ['ACTIVE', 'SUSPENDED', 'CLOSED'];

  static const Map<String, String> _labels = {
    'CUSTOMER': 'Khách hàng',
    'ADMIN': 'Quản trị viên',
    'PENDING': 'Chờ duyệt',
    'ACTIVE': 'Hoạt động',
    'LOCKED': 'Đã khóa',
    'SUSPENDED': 'Tạm ngưng',
    'CLOSED': 'Đã đóng',
    'CASH': 'Tiền mặt',
    'MARGIN': 'Ký quỹ',
  };

  /// Trả về nhãn tiếng Việt; không có thì trả lại đúng mã gốc.
  static String label(String code) => _labels[code] ?? code;
}