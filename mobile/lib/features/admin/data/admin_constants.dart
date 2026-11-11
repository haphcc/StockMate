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
  static const List<String> exchanges = ['HOSE', 'HNX', 'UPCOM'];
  static const List<String> stockStatuses = ['ACTIVE', 'HALTED', 'DELISTED'];

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
    'HALTED': 'Tạm dừng',
    'DELISTED': 'Hủy niêm yết',
  };

  /// Trả về nhãn tiếng Việt; không có thì trả lại đúng mã gốc.
  static String label(String code) => _labels[code] ?? code;
}