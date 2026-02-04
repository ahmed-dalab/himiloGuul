import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: AppColors.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'Seller Profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Edit your seller account and preferences.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
