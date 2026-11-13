import 'market_repository.dart';
import '../models/stock_model.dart';
import '../models/account_model.dart';
import '../models/portfolio_model.dart';
import '../../core/utils/money.dart';

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
      accountType: 'CASH',
      status: 'ACTIVE',
    );
  }

  @override
  Future<List<PortfolioModel>> getPortfolio(int accountId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      const PortfolioModel(
        portfolioId: 1,
        accountId: 1,
        stockId: 2,
        stockSymbol: 'FPT',
        companyName: 'CTCP FPT',
        exchange: 'HOSE',
        quantity: 1000,
        availableQuantity: 1000,
        blockedQuantity: 0,
        pendingQuantity: 0,
        averagePrice: Money.fromCents(10000000),
        marketPrice: Money.fromCents(11200000),
        currentValue: Money.fromCents(11200000000),
        profitLoss: Money.fromCents(1200000000), // +12%
        profitLossPercent: Money.fromCents(1200),
      ),
      const PortfolioModel(
        portfolioId: 2,
        accountId: 1,
        stockId: 3,
        stockSymbol: 'HPG',
        companyName: 'CTCP Tập đoàn Hòa Phát',
        exchange: 'HOSE',
        quantity: 3000,
        availableQuantity: 3000,
        blockedQuantity: 0,
        pendingQuantity: 0,
        averagePrice: Money.fromCents(3000000),
        marketPrice: Money.fromCents(2850000),
        currentValue: Money.fromCents(8550000000),
        profitLoss: Money.fromCents(-450000000), // -5%
        profitLossPercent: Money.fromCents(-500),
      ),
    ];
  }
}
