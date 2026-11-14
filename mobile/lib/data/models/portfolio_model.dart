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
    int amount(String key) =>
        (json[key] as num?)?.toInt() ??
        int.tryParse('${json[key]}'.split('.').first) ??
        0;
    final stock = json['stock'] is Map
        ? StockModel.fromJson(Map<String, dynamic>.from(json['stock'] as Map))
        : StockModel(
            id: (json['stock_id'] as num?)?.toInt() ?? 0,
            symbol: json['stock_symbol'] as String? ?? '',
            companyName: json['company_name'] as String? ?? '',
            exchange: json['exchange'] as String? ?? 'HOSE',
            currentPrice: amount('market_price'),
            referencePrice: amount('market_price'),
            ceilingPrice: amount('market_price'),
            floorPrice: amount('market_price'),
            totalVolume: 0,
          );
    return PortfolioModel(
      portfolioId: json['portfolio_id'] ?? 0,
      stock: stock,
      quantity: json['quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      averagePrice: amount('average_price'),
      currentValue: amount('current_value'),
      profitLoss: amount('profit_loss'),
    );
  }

  @override
  List<Object?> get props => [portfolioId, stock, quantity, averagePrice];
}
