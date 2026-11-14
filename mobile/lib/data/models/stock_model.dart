import 'package:equatable/equatable.dart';
import '../../core/theme/price_colors.dart';

class StockModel extends Equatable {
  final int id;
  final String symbol;
  final String companyName;
  final String exchange; // HOSE, HNX, UPCOM
  final int currentPrice; // int - đồng
  final int referencePrice;
  final int ceilingPrice;
  final int floorPrice;
  final int totalVolume;

  const StockModel({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.exchange,
    required this.currentPrice,
    required this.referencePrice,
    required this.ceilingPrice,
    required this.floorPrice,
    required this.totalVolume,
  });

  // Derived properties
  int get changeAmount => currentPrice - referencePrice;
  double get changePercent =>
      referencePrice > 0 ? (changeAmount / referencePrice) * 100 : 0;

  PriceState get priceState {
    if (currentPrice >= ceilingPrice) return PriceState.ceiling;
    if (currentPrice <= floorPrice) return PriceState.floor;
    if (currentPrice > referencePrice) return PriceState.up;
    if (currentPrice < referencePrice) return PriceState.down;
    return PriceState.reference;
  }

  factory StockModel.fromJson(Map<String, dynamic> json) {
    int price(String key) =>
        (json[key] as num?)?.toInt() ??
        int.tryParse('${json[key]}'.split('.').first) ??
        0;
    return StockModel(
      id: json['stock_id'] ?? 0,
      symbol: json['stock_symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      exchange: json['exchange'] ?? 'HOSE',
      currentPrice: price('current_price'),
      referencePrice: price('reference_price'),
      ceilingPrice: price('ceiling_price'),
      floorPrice: price('floor_price'),
      totalVolume: json['total_volume'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock_id': id,
      'stock_symbol': symbol,
      'company_name': companyName,
      'exchange': exchange,
      'current_price': currentPrice,
      'reference_price': referencePrice,
      'ceiling_price': ceilingPrice,
      'floor_price': floorPrice,
      'total_volume': totalVolume,
    };
  }

  @override
  List<Object?> get props => [id, symbol, currentPrice, totalVolume];
}
