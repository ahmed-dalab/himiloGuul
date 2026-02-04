import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/models/menu_model.dart';
import '../../../core/services/menu_service.dart';
import '../../providers/auth_provider.dart';
import 'menu_form_modal.dart';

class MenusScreen extends StatefulWidget {
  const MenusScreen({super.key});

  @override
  State<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends State<MenusScreen> {
  final MenuService _menuService = MenuService();
  List<dynamic> _menus = [];
  bool _loading = true;
  String? _error;
  /// Local toggle state: menuId -> isActive (only for menus that were toggled)
  final Map<String, bool> _activeOverrides = {};
  bool _saving = false;

  List<dynamic> get _mainMenus {
    return _menus.where((m) {
      final parent = m['parentId'];
      return parent == null || parent.toString() == 'null';
    }).toList();
  }

  List<dynamic> get _subMenus {
    return _menus.where((m) {
      final parent = m['parentId'];
      return parent != null && parent.toString() != 'null';
    }).toList();
  }

  bool _isActive(Map<String, dynamic> menu) {
    final id = menu['_id']?.toString() ?? menu['id']?.toString() ?? '';
    if (_activeOverrides.containsKey(id)) return _activeOverrides[id]!;
    return menu['isActive'] != false;
  }

  void _setActive(String menuId, bool value) {
    setState(() {
      _activeOverrides[menuId] = value;
    });
  }

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
      _activeOverrides.clear();
    });
    try {
      final res = await _menuService.getAllMenus(token: token);
      final list = res['menus'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _menus = list;
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
      builder: (ctx) => MenuFormModal(
        allMenus: _menus.map((m) => m is Map<String, dynamic> ? m : <String, dynamic>{}).toList(),
        isEdit: false,
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
          context.read<AuthProvider>().refreshMenus();
        },
      ),
    );
  }

  void _openEditModal(Map<String, dynamic> menu) {
    final id = menu['_id'] as String? ?? menu['id'] as String? ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => MenuFormModal(
        menuId: id,
        initial: menu,
        allMenus: _menus.map((m) => m is Map<String, dynamic> ? m : <String, dynamic>{}).toList(),
        isEdit: true,
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
          context.read<AuthProvider>().refreshMenus();
        },
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete menu?'),
        content: Text('Delete "$name"? Menus with children must be deleted or reassigned first.'),
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
      await _menuService.deleteMenu(token, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu deleted')));
        _load();
        context.read<AuthProvider>().refreshMenus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _updateMenuStructure() async {
    if (_activeOverrides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _saving = true);
    try {
      for (final entry in _activeOverrides.entries) {
        await _menuService.updateMenu(token, entry.key, isActive: entry.value);
      }
      if (mounted) {
        setState(() {
          _activeOverrides.clear();
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu structure updated')),
        );
        _load();
        context.read<AuthProvider>().refreshMenus();
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

  Widget _buildMenuRow(Map<String, dynamic> menu) {
    final id = menu['_id']?.toString() ?? menu['id']?.toString() ?? '';
    final name = menu['name'] as String? ?? '—';
    final path = menu['path'] as String? ?? '—';
    final icon = AppMenu.getIconForPath(path);
    final isActive = _isActive(menu);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openEditModal(menu),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.darkGray, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _openEditModal(menu),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    path,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (value) => _setActive(id, value),
            activeColor: AppColors.primaryBlue,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'edit') _openEditModal(menu);
              if (value == 'delete') _delete(id, name);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
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
        title: const Text(
          'Menu Configuration',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _loading ? null : _openCreateModal,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Menu'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_mainMenus.isNotEmpty) ...[
                          const Text(
                            'Main Menu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...(_mainMenus.map((m) => _buildMenuRow(m as Map<String, dynamic>))),
                          const SizedBox(height: 24),
                        ],
                        if (_subMenus.isNotEmpty) ...[
                          const Text(
                            'Sub-menus',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...(_subMenus.map((m) => _buildMenuRow(m as Map<String, dynamic>))),
                          const SizedBox(height: 24),
                        ],
                        if (_menus.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No menus yet. Tap "+ Add Menu" to create one.',
                                style: TextStyle(color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _menus.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving || _activeOverrides.isEmpty ? null : _updateMenuStructure,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update Menu Structure'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
