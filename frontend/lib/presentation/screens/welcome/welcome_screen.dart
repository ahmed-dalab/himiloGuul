import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../core/widgets/abstract_header_painter.dart';
import '../../../core/widgets/feature_illustration.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Graphic Section
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: CustomPaint(
                  painter: AbstractHeaderPainter(),
                  child: Container(),
                ),
              ),

              const SizedBox(height: 20),

              // Welcome Message Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Text(
                      'Welcome to HimiloGuul',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Find your next business venture or connect with\npotential buyers.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.lightGray,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Feature Sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildFeatureSection(
                      title: 'Verified Listings',
                      description: 'Browse businesses that have been\nvetted for authenticity.',
                      illustration: const FeatureIllustration(type: 0),
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureSection(
                      title: 'Direct Messaging',
                      description: 'Communicate directly with buyers\nand sellers within the app.',
                      illustration: const FeatureIllustration(type: 1),
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureSection(
                      title: 'Secure Deals',
                      description: 'Ensure secure transactions and\nagreements through our platform.',
                      illustration: const FeatureIllustration(type: 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to browse business screen
                      context.push('/browse-business');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSection({
    required String title,
    required String description,
    required Widget illustration,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.lightGray,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        illustration,
      ],
    );
  }
}
