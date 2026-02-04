import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront, size: 64, color: AppColors.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'Seller Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Overview of your shops and activity.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
