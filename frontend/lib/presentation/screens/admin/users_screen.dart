import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/role_service.dart';
import '../../../core/services/user_service.dart';
import '../../providers/auth_provider.dart';
import 'user_form_modal.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  final RoleService _roleService = RoleService();
  List<dynamic> _users = [];
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
      final usersRes = await _userService.getAllUsers(token, limit: 100);
      final rolesRes = await _roleService.getAllRoles(token);
      final userList = (usersRes['data'] as List<dynamic>?) ?? [];
      final roleList = (rolesRes['data'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _users = userList;
          _roles = roleList;
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
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load roles first')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => UserFormModal(
        allRoles: _roles.cast<Map<String, dynamic>>(),
        isEdit: false,
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  void _openEditModal(Map<String, dynamic> user) {
    final id = user['_id'] as String? ?? user['id'] as String? ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => UserFormModal(
        userId: id,
        initial: user,
        allRoles: _roles.cast<Map<String, dynamic>>(),
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
        title: const Text('Delete user?'),
        content: Text(
          'Delete "$name"? Users with associated businesses must have them deleted or reassigned first.',
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
      await _userService.deleteUser(token, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
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

  String _roleName(dynamic user) {
    final roleId = user['roleId'];
    if (roleId is Map && roleId['name'] != null) return roleId['name'] as String;
    if (user['role'] != null) return user['role'] as String;
    return '—';
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
        title: const Text('Users Management'),
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
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        'No users yet. Tap + to create one.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final u = _users[index] as Map<String, dynamic>;
                          final id = u['_id'] as String? ?? u['id'] as String? ?? '';
                          final name = u['name'] as String? ?? '—';
                          final email = u['email'] as String? ?? '—';
                          final roleName = _roleName(u);
                          final isBanned = u['isBanned'] == true;
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
                                  Icons.person_outline,
                                  color: AppColors.primaryBlue,
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkGray,
                                      ),
                                    ),
                                  ),
                                  if (isBanned)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Banned',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.red.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '$email · $roleName',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                                    onPressed: () => _openEditModal(u),
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
