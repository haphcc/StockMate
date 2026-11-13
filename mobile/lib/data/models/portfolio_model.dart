import 'package:equatable/equatable.dart';
import '../../core/utils/money.dart';

class PortfolioModel extends Equatable {
  final int portfolioId;
  final int accountId;
  final int stockId;
  final String stockSymbol;
  final String companyName;
  final String exchange;
  final int quantity;
  final int availableQuantity;
  final int blockedQuantity;
  final int pendingQuantity;
  final Money averagePrice;
  final Money marketPrice;
  final Money currentValue;
  final Money profitLoss;
  final Money? profitLossPercent;

  const PortfolioModel({
    required this.portfolioId,
    required this.accountId,
    required this.stockId,
    required this.stockSymbol,
    required this.companyName,
    required this.exchange,
    required this.quantity,
    required this.availableQuantity,
    required this.blockedQuantity,
    required this.pendingQuantity,
    required this.averagePrice,
    required this.marketPrice,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercent,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      portfolioId: json['portfolio_id'] ?? 0,
      accountId: json['account_id'] ?? 0,
      stockId: json['stock_id'] ?? 0,
      stockSymbol: json['stock_symbol']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      exchange: json['exchange']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      blockedQuantity: json['blocked_quantity'] ?? 0,
      pendingQuantity: json['pending_quantity'] ?? 0,
      averagePrice: Money.parse(json['average_price']),
      marketPrice: Money.parse(json['market_price']),
      currentValue: Money.parse(json['current_value']),
      profitLoss: Money.parse(json['profit_loss']),
      profitLossPercent: json['profit_loss_percent'] == null
          ? null
          : Money.parse(json['profit_loss_percent']),
    );
  }

  @override
  List<Object?> get props => [portfolioId, accountId, stockId, quantity, averagePrice];
}
