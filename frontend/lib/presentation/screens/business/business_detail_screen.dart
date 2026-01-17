import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/business_provider.dart';
import '../../../config/app_colors.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
        if (mounted) {
          context.read<BusinessProvider>().fetchBusinessById(widget.businessId);
        }
    });
  }

  @override
  void dispose() {
    // Clear selection on exit to avoid showing stale data next time
    // But we can't call context.read inside dispose easily in all cases if widget is unmounted.
    // However, Future.microtask or post frame callback works, but here it's cleaner to let the new screen load fresh data
    // and maybe show loading. InitState handles the fetch.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => context.pop(),
        ),
        actions: [
            IconButton(
            icon: const Icon(Icons.search, color: AppColors.darkGray),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
        title: const Text(
          'HimiloGuul',
          style: TextStyle(
            color: AppColors.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final business = provider.selectedBusiness;
          if (business == null) {
            return const Center(child: Text('Business not found'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Image
                      Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[200],
                        child: business.images.isNotEmpty
                            ? Image.network(
                                business.images.first.url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.business, size: 64, color: Colors.grey),
                              )
                            : Image.network(
                                'https://placehold.co/600x400?text=Business+Image',
                                fit: BoxFit.cover,
                              ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Company Name
                            Text(
                              business.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Info Cards Row 1
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    label: 'Asking Price',
                                    value: '\$${_formatPrice(business.askingPrice)}',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoCard(
                                    label: 'Location',
                                    value: business.location ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Info Cards Row 2 - Years in Business
                             _buildInfoCard(
                                label: 'Years in Business',
                                value: '${_calculateAge(business.createdAt)} Years',
                                fullWidth: true,
                              ),
                            
                            const SizedBox(height: 32),
                            
                            // Overview
                            const Text(
                              'Overview',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              business.description ?? 'No description available.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.lightGray,
                                height: 1.5,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                             // Financials (Static Placeholder as requested by design)
                            const Text(
                              'Financials',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray,
                              ),
                            ),
                             const SizedBox(height: 12),
                            const Text(
                              'The company\'s financials are robust, with a steady increase in annual revenue. Detailed financial statements are available upon request for serious inquiries.',
                               style: TextStyle(
                                fontSize: 16,
                                color: AppColors.lightGray,
                                height: 1.5,
                              ),
                            ),

                             const SizedBox(height: 24),
                            
                             // Reason for Sale (Static Placeholder)
                            const Text(
                              'Reason for Sale',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray,
                              ),
                            ),
                             const SizedBox(height: 12),
                            const Text(
                              'The current owner is seeking to retire and is looking for a suitable buyer to continue the company\'s legacy and growth trajectory.',
                               style: TextStyle(
                                fontSize: 16,
                                color: AppColors.lightGray,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Bar
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                             // TODO: Implement contact seller
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact Seller clicked')));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Contact Seller',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                             // TODO: Implement inquire now
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inquire Now clicked')));
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: AppColors.darkGray,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Inquire Now',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String label, required String value, bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100], // Using a light grey background as per design
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGray, 
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
  
    String _formatPrice(double? price) {
    if (price == null) return 'N/A';
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return price.toStringAsFixed(0);
  }

  String _calculateAge(DateTime createdAt) {
     final now = DateTime.now();
     final difference = now.difference(createdAt).inDays;
     final years = (difference / 365).floor();
     return years < 1 ? '1' : years.toString();
  }
}
