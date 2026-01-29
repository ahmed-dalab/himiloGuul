import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

/// Deals page with dummy data (no backend yet).
class AdminDealsScreen extends StatelessWidget {
  const AdminDealsScreen({super.key});

  static const _summary = (
    totalDealsValue: 2400000.0,
    activeNegotiations: 12,
    completedToday: 3,
  );

  static final List<Map<String, dynamic>> _dummyDeals = [
    {
      'title': 'Xamar Cadey Restaurant',
      'price': 150000,
      'buyer': 'Amina Hassan',
      'seller': 'Omar Farah',
      'iconColor': Color(0xFF6B8E6B), // olive green
      'icon': Icons.restaurant,
    },
    {
      'title': 'Banaadir Construction',
      'price': 800000,
      'buyer': 'Leila Ali',
      'seller': 'Ahmed Mohamed',
      'iconColor': Color(0xFF455A64), // dark grey
      'icon': Icons.construction,
    },
    {
      'title': 'Hargeisa Fashion House',
      'price': 300000,
      'buyer': 'Safiya Ahmed',
      'seller': 'Abdi Ibrahim',
      'iconColor': Color(0xFFE8A87C), // peach
      'icon': Icons.checkroom,
    },
    {
      'title': 'Kismayo Tech Solutions',
      'price': 650000,
      'buyer': 'Naima Yusuf',
      'seller': 'Halima Yusuf',
      'iconColor': Color(0xFF4A6B4A), // dark green
      'icon': Icons.computer,
    },
    {
      'title': 'Bosaso Import & Export',
      'price': 500000,
      'buyer': 'Aisha Hassan',
      'seller': 'Mohamed Ali',
      'iconColor': Color(0xFF37474F), // dark grey
      'icon': Icons.local_shipping,
    },
  ];

  static String _formatCurrency(num value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k';
    }
    return '\$$value';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Deals Value',
                  value: _formatCurrency(_summary.totalDealsValue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Active Negotiations',
                  value: '${_summary.activeNegotiations}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Completed Today',
            value: '${_summary.completedToday}',
            fullWidth: true,
          ),
          const SizedBox(height: 24),
          const Text(
            'Deals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ..._dummyDeals.map((deal) => _DealCard(
                title: deal['title'] as String,
                price: deal['price'] as int,
                buyer: deal['buyer'] as String,
                seller: deal['seller'] as String,
                iconColor: deal['iconColor'] as Color,
                icon: deal['icon'] as IconData,
              )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final bool fullWidth;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final String title;
  final int price;
  final String buyer;
  final String seller;
  final Color iconColor;
  final IconData icon;

  const _DealCard({
    required this.title,
    required this.price,
    required this.buyer,
    required this.seller,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: ${AdminDealsScreen._formatCurrency(price)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Buyer: $buyer, Seller: $seller',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
