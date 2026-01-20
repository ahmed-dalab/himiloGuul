import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/business_provider.dart';
import '../../widgets/business_card.dart';
import '../../../config/app_colors.dart';
import '../../routes/app_routes.dart';

class BrowseBusinessScreen extends StatefulWidget {
  const BrowseBusinessScreen({super.key});

  @override
  State<BrowseBusinessScreen> createState() => _BrowseBusinessScreenState();
}

class _BrowseBusinessScreenState extends State<BrowseBusinessScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Technology',
    'Restaurant',
    'Retail',
    'Healthcare',
    'Education',
    'Real Estate',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch businesses on init
    Future.microtask(() {
      if (mounted) {
        context.read<BusinessProvider>().fetchBusinesses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category == 'All' ? null : category.toLowerCase();
    });
    context.read<BusinessProvider>().fetchBusinesses(
          category: _selectedCategory,
          search: _searchController.text,
        );
  }

  void _onSearch(String value) {
     context.read<BusinessProvider>().fetchBusinesses(
          category: _selectedCategory,
          search: value,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'HimiloGuul',
          style: TextStyle(
            color: AppColors.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                context.push(AppRoutes.login);
              },
              icon: const Icon(Icons.login, size: 20),
              label: const Text('Login'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                final isSelected = (category == 'All' && _selectedCategory == null) ||
                    (category.toLowerCase() == _selectedCategory);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (bool selected) {
                       if (selected) {
                         _onCategorySelected(category);
                       }
                    },
                    backgroundColor: Colors.grey[100],
                    selectedColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryBlue : AppColors.darkGray,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide.none,
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Business List
          Expanded(
            child: Consumer<BusinessProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${provider.error}'),
                        ElevatedButton(
                          onPressed: () => provider.fetchBusinesses(
                            category: _selectedCategory,
                            search: _searchController.text,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.businesses.isEmpty) {
                  return const Center(child: Text('No businesses found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.businesses.length,
                  itemBuilder: (context, index) {
                    final business = provider.businesses[index];
                    return BusinessCard(
                      business: business,
                      onTap: () {
                        // Navigate to details
                         context.push('${AppRoutes.businessDetail}/${business.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
