import 'package:flutter/material.dart';
import '../business/browse_business_screen.dart';

// For Buyer, we reuse the BrowseBusinessScreen but could wrap it if needed.
// For now, it just returns BrowseBusinessScreen
class BuyerLayout extends StatelessWidget {
  const BuyerLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrowseBusinessScreen();
  }
}
