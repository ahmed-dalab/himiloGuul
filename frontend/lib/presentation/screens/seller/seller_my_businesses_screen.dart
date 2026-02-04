import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class SellerMyBusinessesScreen extends StatelessWidget {
  const SellerMyBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: AppColors.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'My Businesses',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your listed businesses here.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
