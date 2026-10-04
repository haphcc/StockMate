import 'package:equatable/equatable.dart';
import 'stock_model.dart';

class PortfolioModel extends Equatable {
  final int portfolioId;
  final StockModel stock;
  final int quantity;
  final int availableQuantity;
  final int averagePrice;
  final int currentValue;
  final int profitLoss;

  const PortfolioModel({
    required this.portfolioId,
    required this.stock,
    required this.quantity,
    required this.availableQuantity,
    required this.averagePrice,
    required this.currentValue,
    required this.profitLoss,
  });
  
  double get profitLossPercent => (averagePrice * quantity) > 0 
      ? (profitLoss / (averagePrice * quantity)) * 100 
      : 0;

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      portfolioId: json['portfolio_id'] ?? 0,
      stock: StockModel.fromJson(json['stock'] ?? {}),
      quantity: json['quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      averagePrice: (json['average_price'] as num).toInt(),
      currentValue: (json['current_value'] as num).toInt(),
      profitLoss: (json['profit_loss'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [portfolioId, stock, quantity, averagePrice];
}
