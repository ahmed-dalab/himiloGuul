import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/business_provider.dart';
import '../../routes/app_routes.dart';
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
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Bar - Contact only
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      final sellerRef = business.ownerId;
                      if (sellerRef == null || sellerRef.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This business has no seller assigned')),
                        );
                        return;
                      }
                      context.push(
                        '${AppRoutes.businessDetail}/${business.id}/contact',
                        extra: {
                          'businessId': business.id,
                          'businessName': business.name,
                          'businessCategory': business.category ?? 'Business',
                          'imageUrl': business.images.isNotEmpty
                              ? business.images.first.url
                              : null,
                          'sellerRef': sellerRef,
                        },
                      );
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
                      'Contact',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
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
