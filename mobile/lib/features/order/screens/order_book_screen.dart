import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stockmate_brand.dart';

class OrderBookScreen extends StatelessWidget {
  const OrderBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Sổ lệnh'),
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
          // Filter Tabs
          Row(
            children: [
              _buildFilterPill('Hôm nay', true),
              const SizedBox(width: 8),
              _buildFilterPill('Chờ khớp', false),
              const SizedBox(width: 8),
              _buildFilterPill('Đã khớp', false),
              const SizedBox(width: 8),
              _buildFilterPill('Đã hủy', false),
            ],
          ),
          const SizedBox(height: 20),

          // Order Items
          _buildOrderItem(
            symbol: 'MWG',
            company: 'Thế Giới Di Động',
            type: 'MUA',
            isBuy: true,
            status: 'Đã khớp',
            statusColor: AppColors.primary,
            price: '64.5',
            quantity: '1,000 / 1,000',
            time: '14:25:02',
          ),
          const SizedBox(height: 12),
          _buildOrderItem(
            symbol: 'FPT',
            company: 'Tập đoàn FPT',
            type: 'MUA',
            isBuy: true,
            status: 'Chờ khớp',
            statusColor: AppColors.priceRef,
            price: '135.0',
            quantity: '0 / 500',
            time: '14:15:30',
          ),
          const SizedBox(height: 12),
          _buildOrderItem(
            symbol: 'HPG',
            company: 'Tập đoàn Hòa Phát',
            type: 'BÁN',
            isBuy: false,
            status: 'Đã khớp',
            statusColor: AppColors.primary,
            price: '29.0',
            quantity: '2,000 / 2,000',
            time: '10:32:15',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.darkCardBorder,
          width: 0.8,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF032617) : Colors.white,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOrderItem({
    required String symbol,
    required String company,
    required String type,
    required bool isBuy,
    required String status,
    required Color statusColor,
    required String price,
    required String quantity,
    required String time,
  }) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isBuy ? AppColors.primary.withValues(alpha: 0.15) : AppColors.priceDown.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isBuy ? AppColors.primary : AppColors.priceDown,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá: $price', style: const TextStyle(color: Colors.white, fontSize: 13)),
              Text('Khối lượng: $quantity', style: const TextStyle(color: Colors.white, fontSize: 13)),
              Text(time, style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
