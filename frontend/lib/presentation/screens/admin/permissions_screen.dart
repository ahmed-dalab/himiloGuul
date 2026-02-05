import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/permission_service.dart';
import '../../providers/auth_provider.dart';
import 'permission_form_modal.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionService _permissionService = PermissionService();
  final MenuService _menuService = MenuService();
  List<dynamic> _permissions = [];
  List<dynamic> _menus = [];
  String? _filterMenuId; // Filter by menu (each permission has one menuId)
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
      // Load menus first (for filter dropdown and create/edit)
      List<dynamic> menuList = [];
      try {
        final menuRes = await _menuService.getAllMenus(token: token);
        menuList = (menuRes['menus'] as List<dynamic>?) ?? [];
        if (mounted) setState(() => _menus = menuList);
      } catch (_) {
        if (mounted) setState(() => _menus = []);
      }
      // Load permissions (optional filter by menuId - backend: each permission has one menu)
      final permRes = await _permissionService.getAllPermissions(
        token,
        limit: 100,
        menuId: _filterMenuId,
      );
      final permList = (permRes['data'] as List<dynamic>?) ?? [];
      if (!mounted) return;
      setState(() {
        _permissions = permList;
        _loading = false;
        _error = null;
      });
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
    if (_menus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No menus loaded. Create a menu first (Menus page), then pull to refresh.'),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => PermissionFormModal(
        allMenus: _menus.map((m) => m is Map<String, dynamic> ? m : <String, dynamic>{}).toList(),
        isEdit: false,
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  void _openEditModal(Map<String, dynamic> permission) {
    final id = permission['_id'] as String? ?? permission['id'] as String? ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => PermissionFormModal(
        permissionId: id,
        initial: permission,
        allMenus: _menus.map((m) => m is Map<String, dynamic> ? m : <String, dynamic>{}).toList(),
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
        title: const Text('Delete permission?'),
        content: Text('Delete "$name"?'),
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
      await _permissionService.deletePermission(token, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission deleted')));
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
        title: const Text('Permissions Management'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter by menu (each permission belongs to one menu)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButtonFormField<String?>(
              value: _filterMenuId,
              decoration: const InputDecoration(
                labelText: 'Filter by menu',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All menus'),
                ),
                ..._menus.map<DropdownMenuItem<String?>>((m) {
                  final id = m['_id'] as String? ?? m['id'] as String? ?? '';
                  final name = m['name'] as String? ?? m['path'] as String? ?? id;
                  return DropdownMenuItem<String?>(
                    value: id.isEmpty ? null : id,
                    child: Text(name),
                  );
                }).where((e) => e.value != null),
              ],
              onChanged: (v) {
                setState(() {
                  _filterMenuId = v;
                  _loading = true;
                });
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
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
                    : _permissions.isEmpty
                        ? Center(
                            child: Text(
                              _filterMenuId != null
                                  ? 'No permissions for this menu.'
                                  : 'No permissions yet. Tap + to create one.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _permissions.length,
                        itemBuilder: (context, index) {
                          final p = _permissions[index] as Map<String, dynamic>;
                          final id = p['_id'] as String? ?? p['id'] as String? ?? '';
                          final name = p['name'] as String? ?? '—';
                          final menu = p['menuId'];
                          final menuName = menu is Map
                              ? (menu['name'] as String? ?? menu['path'] as String? ?? '—')
                              : '—';
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
                                  Icons.lock_outline,
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
                              subtitle: Text(
                                'Menu: $menuName',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                                    onPressed: () => _openEditModal(p),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateModal,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
