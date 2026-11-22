import 'package:equatable/equatable.dart';

class AdminPortfolioModel extends Equatable {
  final int portfolioId;
  final int accountId;
  final String accountNumber;
  final String customerName;
  final String stockSymbol;
  final String companyName;
  final int quantity;
  final int availableQuantity;
  final int blockedQuantity;
  final String averagePrice;
  final String currentValue;
  final String profitLoss;
  final String profitLossPercent;

  const AdminPortfolioModel({
    required this.portfolioId,
    required this.accountId,
    this.accountNumber = '',
    this.customerName = '',
    required this.stockSymbol,
    this.companyName = '',
    required this.quantity,
    required this.availableQuantity,
    this.blockedQuantity = 0,
    required this.averagePrice,
    this.currentValue = '0.00',
    this.profitLoss = '0.00',
    this.profitLossPercent = '0.00',
  });

  /// 1 = lãi, -1 = lỗ, 0 = hòa vốn.
  int get trend {
    final value = num.tryParse(profitLoss) ?? 0;
    if (value > 0) return 1;
    if (value < 0) return -1;
    return 0;
  }

  factory AdminPortfolioModel.fromJson(Map<String, dynamic> json) {
    return AdminPortfolioModel(
      portfolioId: json['portfolio_id'] ?? 0,
      accountId: json['account_id'] ?? 0,
      accountNumber: json['account_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      stockSymbol: json['stock_symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      blockedQuantity: json['blocked_quantity'] ?? 0,
      averagePrice: json['average_price']?.toString() ?? '0',
      currentValue: json['current_value']?.toString() ?? '0',
      profitLoss: json['profit_loss']?.toString() ?? '0',
      profitLossPercent: json['profit_loss_percent']?.toString() ?? '0.00',
    );
  }

  AdminPortfolioModel copyWith({
    int? quantity,
    int? availableQuantity,
    int? blockedQuantity,
    String? averagePrice,
    String? currentValue,
    String? profitLoss,
    String? profitLossPercent,
  }) {
    return AdminPortfolioModel(
      portfolioId: portfolioId,
      accountId: accountId,
      accountNumber: accountNumber,
      customerName: customerName,
      stockSymbol: stockSymbol,
      companyName: companyName,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      blockedQuantity: blockedQuantity ?? this.blockedQuantity,
      averagePrice: averagePrice ?? this.averagePrice,
      currentValue: currentValue ?? this.currentValue,
      profitLoss: profitLoss ?? this.profitLoss,
      profitLossPercent: profitLossPercent ?? this.profitLossPercent,
    );
  }

  @override
  List<Object?> get props => [
        portfolioId,
        accountId,
        accountNumber,
        customerName,
        stockSymbol,
        companyName,
        quantity,
        availableQuantity,
        blockedQuantity,
        averagePrice,
        currentValue,
        profitLoss,
        profitLossPercent,
      ];
}