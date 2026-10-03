import 'package:equatable/equatable.dart';

class AccountModel extends Equatable {
  final int accountId;
  final String accountNumber;
  final int cashBalance; // int đồng
  final int totalAssetValue;

  const AccountModel({
    required this.accountId,
    required this.accountNumber,
    required this.cashBalance,
    required this.totalAssetValue,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      accountId: json['account_id'] ?? 0,
      accountNumber: json['account_number'] ?? '',
      cashBalance: (json['cash_balance'] as num).toInt(),
      totalAssetValue: (json['total_asset_value'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'account_number': accountNumber,
      'cash_balance': cashBalance,
      'total_asset_value': totalAssetValue,
    };
  }

  @override
  List<Object?> get props => [accountId, accountNumber, cashBalance, totalAssetValue];
}
