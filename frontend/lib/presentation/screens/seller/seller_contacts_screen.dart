import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class SellerContactsScreen extends StatelessWidget {
  const SellerContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts, size: 64, color: AppColors.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'Contacts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGray),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage your buyer contacts and inquiries.',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
