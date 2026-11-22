class AdminConstants {
  static const List<String> customerRoles = ['CUSTOMER', 'ADMIN'];
  static const List<String> customerAuthProviders = ['LOCAL', 'GOOGLE'];
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
  static const List<String> notificationTypes = [
    'SYSTEM',
    'NEWS',
    'ORDER',
    'TRANSACTION',
    'PRICE_ALERT',
    'CASH',
  ];
static const List<String> orderStatuses = [
  'PENDING',
  'PARTIAL',
  'COMPLETED',
  'CANCELLED',
  'REJECTED',
];
static const List<String> orderTypes = ['BUY', 'SELL'];

  static const Map<String, String> _labelsVi = {
    'CUSTOMER': 'Khách hàng',
    'ADMIN': 'Quản trị viên',
    'GOOGLE': 'Google',
    'LOCAL': 'Email / Mật khẩu',
    'PENDING': 'Chờ duyệt',
    'ACTIVE': 'Hoạt động',
    'LOCKED': 'Đã khóa',
    'SUSPENDED': 'Tạm ngưng',
    'CLOSED': 'Đã đóng',
    'CASH': 'Tiền mặt',
    'MARGIN': 'Ký quỹ',
    'HALTED': 'Tạm dừng',
    'DELISTED': 'Hủy niêm yết',
    'SYSTEM': 'Hệ thống',
    'NEWS': 'Tin tức',
    'ORDER': 'Lệnh',
    'TRANSACTION': 'Giao dịch',
    'PRICE_ALERT': 'Cảnh báo giá',
    'BUY': 'Mua',
    'SELL': 'Bán',
    'PARTIAL': 'Khớp một phần',
    'COMPLETED': 'Đã khớp',
    'CANCELLED': 'Đã hủy',
    'REJECTED': 'Bị từ chối',
    'LO': 'Lệnh giới hạn',
    'MP': 'Lệnh thị trường',
  };

  static const Map<String, String> _labelsEn = {
    'CUSTOMER': 'Customer',
    'ADMIN': 'Administrator',
    'GOOGLE': 'Google',
    'LOCAL': 'Email / Password',
    'PENDING': 'Pending',
    'ACTIVE': 'Active',
    'LOCKED': 'Locked',
    'SUSPENDED': 'Suspended',
    'CLOSED': 'Closed',
    'CASH': 'Cash',
    'MARGIN': 'Margin',
    'HALTED': 'Halted',
    'DELISTED': 'Delisted',
    'SYSTEM': 'System',
    'NEWS': 'News',
    'ORDER': 'Order',
    'TRANSACTION': 'Transaction',
    'PRICE_ALERT': 'Price Alert',
    'BUY': 'Buy',
    'SELL': 'Sell',
    'PARTIAL': 'Partially Filled',
    'COMPLETED': 'Completed',
    'CANCELLED': 'Cancelled',
    'REJECTED': 'Rejected',
    'LO': 'Limit Order (LO)',
    'MP': 'Market Order (MP)',
  };

  /// Trả về nhãn tiếng Việt hoặc tiếng Anh; không có thì trả lại đúng mã gốc.
  static String label(String code, [bool isVietnamese = true]) {
    final map = isVietnamese ? _labelsVi : _labelsEn;
    return map[code] ?? _labelsVi[code] ?? code;
  }

  /// Tính bước giá và biên độ trần/sàn khớp với trigger PostgreSQL fn_set_price_limits.
  static (num ceiling, num floor) computeStockLimits(
    String exchange,
    num reference,
  ) {
    final ex = exchange.toUpperCase();
    final band = ex == 'HNX' ? 0.10 : (ex == 'UPCOM' ? 0.15 : 0.07);
    final num tick;
    if (ex != 'HOSE') {
      tick = 100;
    } else if (reference < 10000) {
      tick = 10;
    } else if (reference < 50000) {
      tick = 50;
    } else {
      tick = 100;
    }
    final ceil = (reference * (1 + band) / tick).floor() * tick;
    var floor = (reference * (1 - band) / tick).ceil() * tick;
    if (reference > 0 && floor < tick) floor = tick;
    return (ceil, floor);
  }

  /// Trả về thông báo lỗi nếu bộ giá không hợp lệ, ngược lại trả null.
  static String? validateStockPrices({
    num? reference,
    num? current,
    num? ceiling,
    num? floor,
    bool isVietnamese = true,
  }) {
    if (reference != null && ceiling != null && ceiling < reference) {
      return isVietnamese
          ? 'Giá trần phải lớn hơn hoặc bằng giá tham chiếu.'
          : 'Ceiling price must be greater than or equal to reference price.';
    }
    if (reference != null && floor != null && floor > reference) {
      return isVietnamese
          ? 'Giá sàn phải nhỏ hơn hoặc bằng giá tham chiếu.'
          : 'Floor price must be less than or equal to reference price.';
    }
    if (ceiling != null && floor != null && floor > ceiling) {
      return isVietnamese
          ? 'Giá sàn không được lớn hơn giá trần.'
          : 'Floor price cannot be greater than ceiling price.';
    }
    if (current != null && ceiling != null && current > ceiling) {
      return isVietnamese
          ? 'Giá hiện tại vượt giá trần.'
          : 'Current price exceeds ceiling price.';
    }
    if (current != null && floor != null && current < floor) {
      return isVietnamese
          ? 'Giá hiện tại thấp hơn giá sàn.'
          : 'Current price is lower than floor price.';
    }
    return null;
  }
}