import 'package:equatable/equatable.dart';

class AdminTransactionModel extends Equatable {
  final int transactionId;
  final int orderId;
  final int accountId;
  final String accountNumber;
  final String stockSymbol;
  final String transactionType; // BUY | SELL
  final int quantity;
  final String price;
  final String totalAmount;
  final String transactionFee;
  final String taxAmount;
  final String netAmount;
  final String transactionDate;
  final String? settlementDate;

  const AdminTransactionModel({
    required this.transactionId,
    required this.orderId,
    required this.accountId,
    this.accountNumber = '',
    required this.stockSymbol,
    required this.transactionType,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.transactionFee,
    required this.taxAmount,
    required this.netAmount,
    required this.transactionDate,
    this.settlementDate,
  });

  factory AdminTransactionModel.fromJson(Map<String, dynamic> json) {
    return AdminTransactionModel(
      transactionId: json['transaction_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      accountId: json['account_id'] ?? 0,
      accountNumber: json['account_number'] ?? '',
      stockSymbol: json['stock_symbol'] ?? '',
      transactionType: json['transaction_type'] ?? 'BUY',
      quantity: json['quantity'] ?? 0,
      price: json['price']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? '0',
      transactionFee: json['transaction_fee']?.toString() ?? '0',
      taxAmount: json['tax_amount']?.toString() ?? '0',
      netAmount: json['net_amount']?.toString() ?? '0',
      transactionDate: json['transaction_date']?.toString() ?? '',
      settlementDate: json['settlement_date']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        transactionId,
        orderId,
        accountId,
        accountNumber,
        stockSymbol,
        transactionType,
        quantity,
        price,
        totalAmount,
        transactionFee,
        taxAmount,
        netAmount,
        transactionDate,
        settlementDate,
      ];
}