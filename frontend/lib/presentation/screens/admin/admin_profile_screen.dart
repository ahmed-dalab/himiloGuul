import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

/// Profile page using GET /api/users/profile (get me) for the logged-in user.
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchMe();
    });
  }

  Future<void> _fetchMe() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _userService.getUserProfile(token);
      final user = res['user'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _profile = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  static const _options = [
    (title: 'Account Security', icon: Icons.security),
    (title: 'Notification Preferences', icon: Icons.notifications_outlined),
    (title: 'System Logs', icon: Icons.description_outlined),
    (title: 'Platform Settings', icon: Icons.settings_outlined),
    (title: 'Help & Support', icon: Icons.help_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = _profile?['name'] as String? ?? auth.currentUser?.name ?? 'User';
    final email = _profile?['email'] as String? ?? auth.currentUser?.email ?? '';
    final profilePicture = _profile?['profilePicture'] as String?;

    if (_loading && _profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMe,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.lightTeal,
              backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture == null || profilePicture.isEmpty
                  ? const Icon(Icons.person, size: 56, color: AppColors.primaryBlue)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              'Using cached profile. Pull down to refresh.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          ..._options.map((opt) => _ProfileOptionTile(
                title: opt.title,
                icon: opt.icon,
                onTap: () {
                  // Placeholder: could navigate to settings sub-screens later
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${opt.title} — coming soon')),
                  );
                },
              )),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                auth.logout();
                context.go(AppRoutes.welcome);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ));
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkGray,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade600),
      onTap: onTap,
    );
  }
}
