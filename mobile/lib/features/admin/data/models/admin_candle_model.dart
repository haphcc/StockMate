import 'package:equatable/equatable.dart';

class AdminCandleModel extends Equatable {
  final int candleId;
  final int stockId;
  final String stockSymbol;
  final String recordedDate; // yyyy-MM-dd
  final String openPrice;
  final String closePrice;
  final String highestPrice;
  final String lowestPrice;
  final int tradingVolume;
  final String tradingValue;

  const AdminCandleModel({
    required this.candleId,
    required this.stockId,
    required this.stockSymbol,
    required this.recordedDate,
    required this.openPrice,
    required this.closePrice,
    required this.highestPrice,
    required this.lowestPrice,
    this.tradingVolume = 0,
    this.tradingValue = '0.00',
  });

  /// Nến tăng (đóng cửa lớn hơn hoặc bằng mở cửa).
  bool get isUp =>
      (num.tryParse(closePrice) ?? 0) >= (num.tryParse(openPrice) ?? 0);

  /// "2026-11-10" thành "10/11/2026".
  String get displayDate {
    final parts = recordedDate.split('-');
    if (parts.length != 3) return recordedDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  factory AdminCandleModel.fromJson(Map<String, dynamic> json) {
    return AdminCandleModel(
      candleId: json['price_history_id'] ?? 0,
      stockId: json['stock_id'] ?? 0,
      stockSymbol: json['stock_symbol'] ?? '',
      recordedDate: json['recorded_date']?.toString() ?? '',
      openPrice: json['open_price']?.toString() ?? '0',
      closePrice: json['close_price']?.toString() ?? '0',
      highestPrice: json['highest_price']?.toString() ?? '0',
      lowestPrice: json['lowest_price']?.toString() ?? '0',
      tradingVolume: json['trading_volume'] ?? 0,
      tradingValue: json['trading_value']?.toString() ?? '0',
    );
  }

  AdminCandleModel copyWith({
    String? openPrice,
    String? closePrice,
    String? highestPrice,
    String? lowestPrice,
    int? tradingVolume,
    String? tradingValue,
  }) {
    return AdminCandleModel(
      candleId: candleId,
      stockId: stockId,
      stockSymbol: stockSymbol,
      recordedDate: recordedDate,
      openPrice: openPrice ?? this.openPrice,
      closePrice: closePrice ?? this.closePrice,
      highestPrice: highestPrice ?? this.highestPrice,
      lowestPrice: lowestPrice ?? this.lowestPrice,
      tradingVolume: tradingVolume ?? this.tradingVolume,
      tradingValue: tradingValue ?? this.tradingValue,
    );
  }

  @override
  List<Object?> get props => [
        candleId,
        stockId,
        stockSymbol,
        recordedDate,
        openPrice,
        closePrice,
        highestPrice,
        lowestPrice,
        tradingVolume,
        tradingValue,
      ];
}