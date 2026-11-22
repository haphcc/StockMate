import '../../../data/models/stock_model.dart';

/// Local preview data follows the quote fields returned by GET /api/market/board.
const marketStocks = <StockModel>[
  StockModel(
    id: 1,
    symbol: 'FPT',
    companyName: 'Công ty Cổ phần FPT',
    exchange: 'HOSE',
    currentPrice: 135200,
    referencePrice: 130400,
    ceilingPrice: 139500,
    floorPrice: 121300,
    totalVolume: 4200000,
  ),
  StockModel(
    id: 2,
    symbol: 'MWG',
    companyName: 'Đầu tư Thế Giới Di Động',
    exchange: 'HOSE',
    currentPrice: 64500,
    referencePrice: 60300,
    ceilingPrice: 64500,
    floorPrice: 56100,
    totalVolume: 8900000,
  ),
  StockModel(
    id: 3,
    symbol: 'SSI',
    companyName: 'Chứng khoán SSI',
    exchange: 'HOSE',
    currentPrice: 34600,
    referencePrice: 33400,
    ceilingPrice: 35700,
    floorPrice: 31100,
    totalVolume: 12100000,
  ),
  StockModel(
    id: 4,
    symbol: 'HPG',
    companyName: 'Tập đoàn Hòa Phát',
    exchange: 'HOSE',
    currentPrice: 28900,
    referencePrice: 29300,
    ceilingPrice: 31300,
    floorPrice: 27200,
    totalVolume: 15700000,
  ),
  StockModel(
    id: 5,
    symbol: 'VCB',
    companyName: 'Ngân hàng TMCP Ngoại thương',
    exchange: 'HOSE',
    currentPrice: 91500,
    referencePrice: 90000,
    ceilingPrice: 96300,
    floorPrice: 83700,
    totalVolume: 1250000,
  ),
  StockModel(
    id: 6,
    symbol: 'VNM',
    companyName: 'Sữa Việt Nam',
    exchange: 'HOSE',
    currentPrice: 68200,
    referencePrice: 68500,
    ceilingPrice: 73100,
    floorPrice: 63900,
    totalVolume: 2150000,
  ),
];

StockModel stockFor(String symbol) => marketStocks.firstWhere(
  (stock) => stock.symbol == symbol.toUpperCase(),
  orElse: () => marketStocks.first,
);

String formatBoardPrice(int dong) {
  final k = dong / 1000.0;
  if ((dong % 100) != 0) {
    return k.toStringAsFixed(2);
  }
  return k.toStringAsFixed(1);
}

String formatVolume(int volume) {
  if (volume >= 1000000) return '${(volume / 1000000).toStringAsFixed(1)} tr';
  if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(0)} N';
  return volume.toString();
}
