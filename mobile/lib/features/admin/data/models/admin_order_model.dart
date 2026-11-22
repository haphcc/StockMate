import 'package:equatable/equatable.dart';

class AdminOrderModel extends Equatable {
  final int orderId;
  final int accountId;
  final String accountNumber;
  final String customerName;
  final String stockSymbol;
  final String clientOrderId;
  final String orderType; // BUY | SELL
  final String orderKind; // LO | MP | ...
  final int quantity;
  final int filledQuantity;
  final String orderPrice;
  final String orderDate;
  final String? matchedAt;
  final String status; // PENDING | PARTIAL | COMPLETED | CANCELLED | REJECTED
  final String? rejectReason;

  const AdminOrderModel({
    required this.orderId,
    required this.accountId,
    this.accountNumber = '',
    this.customerName = '',
    required this.stockSymbol,
    this.clientOrderId = '',
    required this.orderType,
    this.orderKind = 'LO',
    required this.quantity,
    this.filledQuantity = 0,
    required this.orderPrice,
    required this.orderDate,
    this.matchedAt,
    required this.status,
    this.rejectReason,
  });

  int get remainingQuantity => quantity - filledQuantity;

  /// Lệnh còn can thiệp hủy được.
  bool get canCancel => status == 'PENDING' || status == 'PARTIAL';

  /// Lệnh đã đóng và chưa có giao dịch khớp: xóa được.
  bool get canDelete => status == 'CANCELLED' || status == 'REJECTED';

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderModel(
      orderId: json['order_id'] ?? 0,
      accountId: json['account_id'] ?? 0,
      accountNumber: json['account_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      stockSymbol: json['stock_symbol'] ?? '',
      clientOrderId: json['client_order_id']?.toString() ?? '',
      orderType: json['order_type'] ?? 'BUY',
      orderKind: json['order_kind'] ?? 'LO',
      quantity: json['quantity'] ?? 0,
      filledQuantity: json['filled_quantity'] ?? 0,
      orderPrice: json['order_price']?.toString() ?? '0',
      orderDate: json['order_date']?.toString() ?? '',
      matchedAt: json['matched_at']?.toString(),
      status: json['status'] ?? 'PENDING',
      rejectReason: json['reject_reason'],
    );
  }

  AdminOrderModel copyWith({
    int? filledQuantity,
    String? matchedAt,
    String? status,
    String? rejectReason,
  }) {
    return AdminOrderModel(
      orderId: orderId,
      accountId: accountId,
      accountNumber: accountNumber,
      customerName: customerName,
      stockSymbol: stockSymbol,
      clientOrderId: clientOrderId,
      orderType: orderType,
      orderKind: orderKind,
      quantity: quantity,
      filledQuantity: filledQuantity ?? this.filledQuantity,
      orderPrice: orderPrice,
      orderDate: orderDate,
      matchedAt: matchedAt ?? this.matchedAt,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        accountId,
        accountNumber,
        customerName,
        stockSymbol,
        clientOrderId,
        orderType,
        orderKind,
        quantity,
        filledQuantity,
        orderPrice,
        orderDate,
        matchedAt,
        status,
        rejectReason,
      ];
}