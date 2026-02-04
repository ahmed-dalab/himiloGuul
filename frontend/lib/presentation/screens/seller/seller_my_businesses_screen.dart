import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../routes/app_routes.dart';

class SellerMyBusinessesScreen extends StatelessWidget {
  const SellerMyBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.createBusiness),
                icon: const Icon(Icons.add_business),
                label: const Text('Create Business'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
