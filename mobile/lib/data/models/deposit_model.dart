import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';

class DepositModel extends Equatable {
  final int orderCode;
  final Money amount;
  final String checkoutUrl;
  final String qrCode;
  final String status;
  final int accountId;

  const DepositModel({
    required this.orderCode,
    required this.amount,
    required this.checkoutUrl,
    required this.qrCode,
    required this.status,
    required this.accountId,
  });

  factory DepositModel.fromJson(Map<String, dynamic> json) => DepositModel(
        orderCode: json['order_code'] ?? 0,
        amount: Money.parse(json['amount']),
        checkoutUrl: json['checkout_url']?.toString() ?? '',
        qrCode: json['qr_code']?.toString() ?? '',
        status: json['status']?.toString() ?? 'PENDING',
        accountId: json['account_id'] ?? 0,
      );

  @override
  List<Object?> get props => [orderCode, amount, checkoutUrl, qrCode, status, accountId];
}
