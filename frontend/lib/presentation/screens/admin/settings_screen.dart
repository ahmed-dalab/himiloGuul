import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/setting_service.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingService = SettingService();
  final _appNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _timezoneController = TextEditingController();
  bool _twoFactorEnabled = false;
  bool _systemAlertsEnabled = false;
  bool _emailNotificationsEnabled = false;
  bool _loading = true;
  bool _saving = false;
  bool _isEditing = false;
  String? _error;
  String _lastAppName = '';
  String _lastContactEmail = '';
  String _lastTimezone = 'UTC';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSettings();
    });
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _contactEmailController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Not authenticated';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _settingService.getSettings(token);
      final data = res['data'] as Map<String, dynamic>?;
      if (mounted && data != null) {
        final appName = data['appName']?.toString() ?? '';
        final contactEmail = data['contactEmail']?.toString() ?? '';
        final timezone = data['timezone']?.toString() ?? 'UTC';
        setState(() {
          _appNameController.text = appName;
          _contactEmailController.text = contactEmail;
          _timezoneController.text = timezone;
          _lastAppName = appName;
          _lastContactEmail = contactEmail;
          _lastTimezone = timezone;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
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

  Future<void> _saveSettings() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final res = await _settingService.updateSettings(
        token,
        appName: _appNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        timezone: _timezoneController.text.trim().isEmpty ? 'UTC' : _timezoneController.text.trim(),
      );
      if (mounted) {
        final data = res['data'] as Map<String, dynamic>?;
        final appName = data?['appName']?.toString() ?? _appNameController.text.trim();
        final contactEmail = data?['contactEmail']?.toString() ?? _contactEmailController.text.trim();
        final timezone = data?['timezone']?.toString() ?? _timezoneController.text.trim();
        setState(() {
          _saving = false;
          _isEditing = false;
          _lastAppName = appName;
          _lastContactEmail = contactEmail;
          _lastTimezone = timezone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() {
      _appNameController.text = _lastAppName;
      _contactEmailController.text = _lastContactEmail;
      _timezoneController.text = _lastTimezone;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: AppColors.darkGray,
          onPressed: () => context.go('/admin'),
        ),
        title: const Text(
          'HimiloGuul',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: AppColors.darkGray,
            onPressed: () => context.go('/admin'),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // General Settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'General Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                if (!_isEditing)
                  TextButton(
                    onPressed: _startEditing,
                    child: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('App Name'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _appNameController,
              hint: 'e.g., HimiloGuul',
              readOnly: !_isEditing,
            ),
            const SizedBox(height: 16),
            _buildLabel('Contact Email'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _contactEmailController,
              hint: 'e.g., support@himiloguul.com',
              keyboardType: TextInputType.emailAddress,
              readOnly: !_isEditing,
            ),
            const SizedBox(height: 16),
            _buildLabel('Timezone'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _timezoneController,
              hint: 'e.g., UTC',
              readOnly: !_isEditing,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _cancelEditing,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkGray,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _saveSettings,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            // Security
            const Text(
              'Security',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            _buildToggleRow('Two-Factor Authentication', _twoFactorEnabled, (v) {
              _showComingSoon();
            }),
            const SizedBox(height: 12),
            _buildEditRow('Password Policy', () {
              _showComingSoon();
            }),
            const SizedBox(height: 28),
            // Notifications
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            _buildToggleRow('System Alerts', _systemAlertsEnabled, (v) {
              setState(() => _systemAlertsEnabled = v);
            }),
            const SizedBox(height: 12),
            _buildToggleRow('Email Notifications', _emailNotificationsEnabled, (v) {
              setState(() => _emailNotificationsEnabled = v);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkGray,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: const TextStyle(fontSize: 16, color: AppColors.darkGray),
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.darkGray,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildEditRow(String title, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.darkGray,
          ),
        ),
        TextButton(
          onPressed: onEdit,
          child: const Text('Edit'),
        ),
      ],
    );
  }
}
