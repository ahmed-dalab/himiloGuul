import 'package:flutter/material.dart';
import '../../core/models/business.dart';
import '../../config/app_colors.dart';

class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const BusinessCard({
    super.key,
    required this.business,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: business.images.isNotEmpty
                    ? Image.network(
                        business.images.first.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price and Location
                  Text(
                    'Price: \$${_formatPrice(business.askingPrice)} | Location: ${business.location ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.lightGray,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                   // Age (Mocked as it's not in the model yet, or calculated from createdAt)
                  Text(
                    'Age: ${_calculateAge(business.createdAt)} Years',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.lightGray,
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // View Button
                  SizedBox(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                         width: 100,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('View', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Image.network(
      'https://placehold.co/600x400?text=Business+Image',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if network placeholder fails
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.business,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
      },
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
     // Just a rough estimation for "Age" based on createdAt or mocking it if age refers to business age
     // If business age is not in DB, we might defaulting to 1 or calculating from creation date
     // For now, let's use a simple year diff from createdAt, or default to 1 if < 1 year
     final years = (difference / 365).floor();
     return years < 1 ? '1' : years.toString();
  }
}
