import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stockmate_brand.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Danh mục đầu tư'),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: StockMateBrand(iconSize: 24, fontSize: 16),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Asset Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF162232), Color(0xFF131926)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng tài sản ròng', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                const Text(
                  '1,000,000,000 đ',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAssetStat('Lãi / Lỗ', '+7,500,000 đ (+3.8%)', AppColors.primary),
                    _buildAssetStat('Sức mua', '500,000,000 đ', Colors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'DANH MỤC NẮM GIỮ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '2 mã',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Holding 1: FPT
          _buildHoldingItem(
            symbol: 'FPT',
            name: 'Tập đoàn FPT',
            quantity: '1,000',
            avgPrice: '120.0',
            curPrice: '135.2',
            gainLoss: '+15,200,000 đ',
            gainLossPercent: '+12.67%',
            isGain: true,
          ),
          const SizedBox(height: 12),

          // Holding 2: HPG
          _buildHoldingItem(
            symbol: 'HPG',
            name: 'Tập đoàn Hòa Phát',
            quantity: '3,000',
            avgPrice: '30.0',
            curPrice: '28.9',
            gainLoss: '-3,300,000 đ',
            gainLossPercent: '-3.67%',
            isGain: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAssetStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHoldingItem({
    required String symbol,
    required String name,
    required String quantity,
    required String avgPrice,
    required String curPrice,
    required String gainLoss,
    required String gainLossPercent,
    required bool isGain,
  }) {
    final color = isGain ? AppColors.primary : AppColors.priceDown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(name, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(gainLoss, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(gainLossPercent, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.darkCardBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Khối lượng: $quantity', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
              Text('Giá vốn: $avgPrice', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
              Text('Giá hiện tại: $curPrice', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
