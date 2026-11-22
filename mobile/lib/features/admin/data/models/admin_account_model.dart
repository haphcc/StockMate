import 'package:equatable/equatable.dart';

class AdminAccountModel extends Equatable {
  final int accountId;
  final int customerId;
  final String customerName;
  final String customerEmail;
  final String accountNumber;
  final String accountType; // CASH | MARGIN
  final String cashBalance; // chuỗi, ví dụ "50000000.00"
  final String blockedBalance;
  final String totalAssetValue;
  final String marginLimit;
  final String status; // ACTIVE | SUSPENDED | CLOSED

  const AdminAccountModel({
    required this.accountId,
    required this.customerId,
    this.customerName = '',
    this.customerEmail = '',
    required this.accountNumber,
    required this.accountType,
    required this.cashBalance,
    this.blockedBalance = '0.00',
    required this.totalAssetValue,
    this.marginLimit = '0.00',
    required this.status,
  });

  factory AdminAccountModel.fromJson(Map<String, dynamic> json) {
    return AdminAccountModel(
      accountId: json['account_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountType: json['account_type'] ?? 'CASH',
      cashBalance: json['cash_balance']?.toString() ?? '0',
      blockedBalance: json['blocked_balance']?.toString() ?? '0',
      totalAssetValue: json['total_asset_value']?.toString() ?? '0',
      marginLimit: json['margin_limit']?.toString() ?? '0',
      status: json['status'] ?? 'ACTIVE',
    );
  }

  AdminAccountModel copyWith({
    String? customerName,
    String? customerEmail,
    String? accountType,
    String? cashBalance,
    String? blockedBalance,
    String? totalAssetValue,
    String? marginLimit,
    String? status,
  }) {
    return AdminAccountModel(
      accountId: accountId,
      customerId: customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      accountNumber: accountNumber,
      accountType: accountType ?? this.accountType,
      cashBalance: cashBalance ?? this.cashBalance,
      blockedBalance: blockedBalance ?? this.blockedBalance,
      totalAssetValue: totalAssetValue ?? this.totalAssetValue,
      marginLimit: marginLimit ?? this.marginLimit,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        accountId,
        customerId,
        customerName,
        customerEmail,
        accountNumber,
        accountType,
        cashBalance,
        blockedBalance,
        totalAssetValue,
        marginLimit,
        status,
      ];
}