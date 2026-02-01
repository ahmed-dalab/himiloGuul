import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/role_service.dart';
import '../../providers/auth_provider.dart';
import 'role_form_modal.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final RoleService _roleService = RoleService();
  List<dynamic> _roles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _roleService.getAllRoles(token);
      final list = (res['data'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _roles = list;
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

  void _openCreateModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => RoleFormModal(
        isEdit: false,
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  void _openEditModal(Map<String, dynamic> role) {
    final id = role['_id'] as String? ?? role['id'] as String? ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => RoleFormModal(
        roleId: id,
        initial: role,
        isEdit: true,
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text(
          'Delete "$name"? Roles that are assigned to users cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    try {
      await _roleService.deleteRole(token, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.darkGray,
          onPressed: () => context.go('/admin'),
        ),
        title: const Text('Roles Management'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
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
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _roles.isEmpty
                  ? Center(
                      child: Text(
                        'No roles yet. Tap + to create one.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _roles.length,
                        itemBuilder: (context, index) {
                          final r = _roles[index] as Map<String, dynamic>;
                          final id = r['_id'] as String? ?? r['id'] as String? ?? '';
                          final name = r['name'] as String? ?? '—';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: AppColors.primaryBlue,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                                    onPressed: () => _openEditModal(r),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _delete(id, name),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateModal,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
