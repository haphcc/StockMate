import 'package:equatable/equatable.dart';

class AdminStockModel extends Equatable {
  final int stockId;
  final String stockSymbol;
  final String companyName;
  final String exchange; // HOSE | HNX | UPCOM
  final String? industry;
  final int listedShares;
  final String currentPrice;
  final String referencePrice;
  final String ceilingPrice;
  final String floorPrice;
  final String priceChange;
  final String changePercent;
  final int totalVolume;
  final String status; // ACTIVE | HALTED | DELISTED

  const AdminStockModel({
    required this.stockId,
    required this.stockSymbol,
    required this.companyName,
    required this.exchange,
    this.industry,
    this.listedShares = 0,
    required this.currentPrice,
    required this.referencePrice,
    required this.ceilingPrice,
    required this.floorPrice,
    this.priceChange = '0.00',
    this.changePercent = '0.00',
    this.totalVolume = 0,
    required this.status,
  });

  /// 1 = tăng, -1 = giảm, 0 = đứng giá.
  int get trend {
    final change = num.tryParse(priceChange) ?? 0;
    if (change > 0) return 1;
    if (change < 0) return -1;
    return 0;
  }

  factory AdminStockModel.fromJson(Map<String, dynamic> json) {
    return AdminStockModel(
      stockId: json['stock_id'] ?? 0,
      stockSymbol: json['stock_symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      exchange: json['exchange'] ?? 'HOSE',
      industry: json['industry'],
      listedShares: json['listed_shares'] ?? 0,
      currentPrice: json['current_price']?.toString() ?? '0',
      referencePrice: json['reference_price']?.toString() ?? '0',
      ceilingPrice: json['ceiling_price']?.toString() ?? '0',
      floorPrice: json['floor_price']?.toString() ?? '0',
      priceChange: json['price_change']?.toString() ?? '0.00',
      changePercent: json['change_percent']?.toString() ?? '0.00',
      totalVolume: json['total_volume'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
    );
  }

  AdminStockModel copyWith({
    String? companyName,
    String? exchange,
    String? industry,
    int? listedShares,
    String? currentPrice,
    String? referencePrice,
    String? ceilingPrice,
    String? floorPrice,
    String? priceChange,
    String? changePercent,
    int? totalVolume,
    String? status,
  }) {
    return AdminStockModel(
      stockId: stockId,
      stockSymbol: stockSymbol,
      companyName: companyName ?? this.companyName,
      exchange: exchange ?? this.exchange,
      industry: industry ?? this.industry,
      listedShares: listedShares ?? this.listedShares,
      currentPrice: currentPrice ?? this.currentPrice,
      referencePrice: referencePrice ?? this.referencePrice,
      ceilingPrice: ceilingPrice ?? this.ceilingPrice,
      floorPrice: floorPrice ?? this.floorPrice,
      priceChange: priceChange ?? this.priceChange,
      changePercent: changePercent ?? this.changePercent,
      totalVolume: totalVolume ?? this.totalVolume,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        stockId,
        stockSymbol,
        companyName,
        exchange,
        industry,
        listedShares,
        currentPrice,
        referencePrice,
        ceilingPrice,
        floorPrice,
        priceChange,
        changePercent,
        totalVolume,
        status,
      ];
}