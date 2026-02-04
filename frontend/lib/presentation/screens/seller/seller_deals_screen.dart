import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class SellerDealsScreen extends StatelessWidget {
  const SellerDealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, size: 64, color: AppColors.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'Deals',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGray),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage your deals and inquiries.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
