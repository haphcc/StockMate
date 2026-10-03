import 'market_repository.dart';
import '../models/stock_model.dart';
import '../models/account_model.dart';
import '../models/portfolio_model.dart';

class MockMarketRepository implements MarketRepository {
  @override
  Future<List<StockModel>> getMarketBoard({String exchange = 'HOSE'}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Dữ liệu giả lập, giá x1000 đồng
    return [
      const StockModel(
        id: 1, symbol: 'MWG', companyName: 'Thế Giới Di Động', exchange: 'HOSE',
        currentPrice: 64500, referencePrice: 60300, ceilingPrice: 64500, floorPrice: 56100, totalVolume: 8900000,
      ),
      const StockModel(
        id: 2, symbol: 'FPT', companyName: 'Tập đoàn FPT', exchange: 'HOSE',
        currentPrice: 135200, referencePrice: 130400, ceilingPrice: 139500, floorPrice: 121300, totalVolume: 4200000,
      ),
      const StockModel(
        id: 3, symbol: 'SSI', companyName: 'Chứng khoán SSI', exchange: 'HOSE',
        currentPrice: 34600, referencePrice: 33400, ceilingPrice: 35700, floorPrice: 31100, totalVolume: 12100000,
      ),
      const StockModel(
        id: 4, symbol: 'HPG', companyName: 'Tập đoàn Hòa Phát', exchange: 'HOSE',
        currentPrice: 28900, referencePrice: 29300, ceilingPrice: 31300, floorPrice: 27200, totalVolume: 15700000,
      ),
      const StockModel(
        id: 5, symbol: 'VCB', companyName: 'NHTMCP Ngoại thương VN', exchange: 'HOSE',
        currentPrice: 91500, referencePrice: 90000, ceilingPrice: 96300, floorPrice: 83700, totalVolume: 1250000,
      ),
    ];
  }

  @override
  Future<AccountModel> getAccountSummary(int userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const AccountModel(
      accountId: 1,
      accountNumber: '086C123456',
      cashBalance: 1000000000,
      totalAssetValue: 1000000000,
    );
  }

  @override
  Future<List<PortfolioModel>> getPortfolio(int accountId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      const PortfolioModel(
        portfolioId: 1,
        stock: StockModel(
          id: 2, symbol: 'FPT', companyName: 'CTCP FPT', exchange: 'HOSE',
          currentPrice: 112000, referencePrice: 110000, ceilingPrice: 117700, floorPrice: 102300, totalVolume: 2500000,
        ),
        quantity: 1000,
        availableQuantity: 1000,
        averagePrice: 100000,
        currentValue: 112000000,
        profitLoss: 12000000, // +12%
      ),
      const PortfolioModel(
        portfolioId: 2,
        stock: StockModel(
          id: 3, symbol: 'HPG', companyName: 'CTCP Tập đoàn Hòa Phát', exchange: 'HOSE',
          currentPrice: 28500, referencePrice: 29000, ceilingPrice: 31000, floorPrice: 27000, totalVolume: 15400000,
        ),
        quantity: 3000,
        availableQuantity: 3000,
        averagePrice: 30000,
        currentValue: 85500000,
        profitLoss: -4500000, // -5%
      ),
    ];
  }
}
