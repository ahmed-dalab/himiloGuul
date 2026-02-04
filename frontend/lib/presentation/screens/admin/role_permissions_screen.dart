import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/role_permission_service.dart';
import '../../../core/services/role_service.dart';
import '../../providers/auth_provider.dart';

class RolePermissionsScreen extends StatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  State<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends State<RolePermissionsScreen> {
  final RolePermissionService _rolePermissionService = RolePermissionService();
  final RoleService _roleService = RoleService();
  final PermissionService _permissionService = PermissionService();

  List<dynamic> _assignments = [];
  List<dynamic> _roles = [];
  List<dynamic> _permissions = [];
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
      final res = await _rolePermissionService.getAllRolePermissions(
        token,
        limit: 500,
      );
      final list = (res['data'] as List<dynamic>?) ?? [];
      if (!mounted) return;
      setState(() {
        _assignments = list;
        _loading = false;
        _error = null;
      });
      _loadRolesAndPermissions(token);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadRolesAndPermissions(String token) async {
    try {
      final rolesRes = await _roleService.getAllRoles(token);
      final rolesList = (rolesRes['data'] as List<dynamic>?) ?? [];
      final permRes = await _permissionService.getAllPermissions(token, limit: 500);
      final permList = (permRes['data'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _roles = rolesList;
          _permissions = permList;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _roles = _roles;
          _permissions = _permissions;
        });
      }
    }
  }

  void _openAssignModal() {
    if (_roles.isEmpty || _permissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Load roles and permissions first. Pull to refresh if you just added them.',
          ),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AssignRolePermissionModal(
        roles: _roles,
        permissions: _permissions,
        existingAssignments: _assignments,
        onAssign: (roleId, permissionId) async {
          final auth = context.read<AuthProvider>();
          final token = auth.token;
          if (token == null) return;
          try {
            await _rolePermissionService.createRolePermission(
              token,
              roleId: roleId,
              permissionId: permissionId,
            );
            if (mounted) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permission assigned to role')),
              );
              _load();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _removeAssignment(String roleId, String permissionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove assignment?'),
        content: const Text(
          'This will remove the permission from the role. You can assign it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    try {
      await _rolePermissionService.deleteRolePermissionByRoleAndPermission(
        token,
        roleId,
        permissionId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment removed')),
        );
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

  static String _getId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) return (value['_id'] ?? value['id'])?.toString() ?? '';
    return '';
  }

  static String _getRoleName(dynamic rp) {
    final role = rp['roleId'];
    if (role is Map) return role['name']?.toString() ?? '—';
    return '—';
  }

  static String _getPermissionName(dynamic rp) {
    final perm = rp['permissionId'];
    if (perm is Map) return perm['name']?.toString() ?? '—';
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
        title: const Text('Role Permissions'),
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
              : _assignments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No role-permission assignments yet.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to assign a permission to a role.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _assignments.length,
                        itemBuilder: (context, index) {
                          final rp = _assignments[index] as Map<String, dynamic>;
                          final roleId = _getId(rp['roleId']);
                          final permissionId = _getId(rp['permissionId']);
                          final roleName = _getRoleName(rp);
                          final permissionName = _getPermissionName(rp);
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
                                  Icons.link,
                                  color: AppColors.primaryBlue,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                roleName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              subtitle: Text(
                                permissionName,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeAssignment(roleId, permissionId),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAssignModal,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _AssignRolePermissionModal extends StatefulWidget {
  final List<dynamic> roles;
  final List<dynamic> permissions;
  final List<dynamic> existingAssignments;
  final Future<void> Function(String roleId, String permissionId) onAssign;

  const _AssignRolePermissionModal({
    required this.roles,
    required this.permissions,
    required this.existingAssignments,
    required this.onAssign,
  });

  @override
  State<_AssignRolePermissionModal> createState() => _AssignRolePermissionModalState();
}

class _AssignRolePermissionModalState extends State<_AssignRolePermissionModal> {
  String? _selectedRoleId;
  String? _selectedPermissionId;
  bool _saving = false;

  static String _getId(dynamic item) {
    if (item == null) return '';
    if (item is String) return item;
    final m = item is Map<String, dynamic> ? item : null;
    if (m != null) return (m['_id'] ?? m['id'])?.toString() ?? '';
    return '';
  }

  static String _getName(dynamic item) {
    if (item is Map) return item['name']?.toString() ?? '—';
    return '—';
  }

  bool _isAlreadyAssigned(String roleId, String permissionId) {
    for (final rp in widget.existingAssignments) {
      if (rp is! Map<String, dynamic>) continue;
      final rId = _getId(rp['roleId']);
      final pId = _getId(rp['permissionId']);
      if (rId == roleId && pId == permissionId) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final alreadyAssigned = _selectedRoleId != null &&
        _selectedPermissionId != null &&
        _isAlreadyAssigned(_selectedRoleId!, _selectedPermissionId!);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Assign permission to role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRoleId,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: widget.roles.map((r) {
                  final id = _getId(r);
                  return DropdownMenuItem(value: id, child: Text(_getName(r)));
                }).toList(),
                onChanged: (v) => setState(() => _selectedRoleId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPermissionId,
                decoration: const InputDecoration(
                  labelText: 'Permission',
                  border: OutlineInputBorder(),
                ),
                items: widget.permissions.map((p) {
                  final id = _getId(p);
                  return DropdownMenuItem(value: id, child: Text(_getName(p)));
                }).toList(),
                onChanged: (v) => setState(() => _selectedPermissionId = v),
              ),
              if (alreadyAssigned)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'This role already has this permission.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ||
                            _selectedRoleId == null ||
                            _selectedPermissionId == null ||
                            alreadyAssigned
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            await widget.onAssign(_selectedRoleId!, _selectedPermissionId!);
                            setState(() => _saving = false);
                          },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Assign'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
