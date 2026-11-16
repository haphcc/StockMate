import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';

class AccountModel extends Equatable {
  final int accountId;
  final String accountNumber;
  final String accountType;
  final String status;

  const AccountModel({
    required this.accountId,
    required this.accountNumber,
    required this.accountType,
    required this.status,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      accountId: json['account_id'] ?? 0,
      accountNumber: json['account_number']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? 'CASH',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'account_number': accountNumber,
      'account_type': accountType,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [accountId, accountNumber, accountType, status];
}

class AssetModel extends Equatable {
  final int accountId;
  final String accountNumber;
  final String accountType;
  final String status;
  final Money cashBalance;
  final Money blockedBalance;
  final Money stockValue;
  final Money totalAssetValue;
  final Money totalProfitLoss;
  final Money? profitLossPercent;

  const AssetModel({
    required this.accountId,
    required this.accountNumber,
    required this.accountType,
    required this.status,
    required this.cashBalance,
    required this.blockedBalance,
    required this.stockValue,
    required this.totalAssetValue,
    required this.totalProfitLoss,
    required this.profitLossPercent,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
        accountId: json['account_id'] ?? 0,
        accountNumber: json['account_number']?.toString() ?? '',
        accountType: json['account_type']?.toString() ?? 'CASH',
        status: json['status']?.toString() ?? 'ACTIVE',
        cashBalance: Money.parse(json['cash_balance']),
        blockedBalance: Money.parse(json['blocked_balance']),
        stockValue: Money.parse(json['stock_value']),
        totalAssetValue: Money.parse(json['total_asset_value']),
        totalProfitLoss: Money.parse(json['total_profit_loss']),
        profitLossPercent: json['profit_loss_percent'] == null
            ? null
            : Money.parse(json['profit_loss_percent']),
      );

  @override
  List<Object?> get props => [
        accountId,
        accountNumber,
        accountType,
        status,
        cashBalance,
        blockedBalance,
        stockValue,
        totalAssetValue,
        totalProfitLoss,
        profitLossPercent,
      ];
}
