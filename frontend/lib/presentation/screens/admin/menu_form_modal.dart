import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/menu_service.dart';
import '../../providers/auth_provider.dart';

/// Icon option for the create/edit menu form (key sent to backend, label for UI).
class _IconOption {
  final String key;
  final String label;
  final IconData icon;

  const _IconOption({required this.key, required this.label, required this.icon});
}

const List<_IconOption> _iconOptions = [
  _IconOption(key: 'file', label: 'File', icon: Icons.description),
  _IconOption(key: 'folder', label: 'Folder', icon: Icons.folder),
  _IconOption(key: 'chart_line', label: 'ChartLine', icon: Icons.show_chart),
  _IconOption(key: 'chart_bar', label: 'ChartBar', icon: Icons.bar_chart),
  _IconOption(key: 'list', label: 'List', icon: Icons.list),
  _IconOption(key: 'grid_four', label: 'GridFour', icon: Icons.grid_view),
  _IconOption(key: 'bell', label: 'Bell', icon: Icons.notifications),
  _IconOption(key: 'gear', label: 'Gear', icon: Icons.settings),
];

/// Modal form for creating or editing a menu (Create Menu Item design).
class MenuFormModal extends StatefulWidget {
  final String? menuId;
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> allMenus;
  final bool isEdit;
  final VoidCallback onSaved;

  const MenuFormModal({
    super.key,
    this.menuId,
    this.initial,
    required this.allMenus,
    required this.isEdit,
    required this.onSaved,
  });

  @override
  State<MenuFormModal> createState() => _MenuFormModalState();
}

class _MenuFormModalState extends State<MenuFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _path = TextEditingController();
  String? _parentId;
  String? _selectedIconKey;
  bool _visibleOnSidebar = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _name.text = i['name'] as String? ?? '';
      _path.text = i['path'] as String? ?? '';
      final p = i['parentId'];
      _parentId = p is Map ? (p['_id'] ?? p['id']) as String? : p?.toString();
      _visibleOnSidebar = i['isActive'] != false;
      final icon = i['icon'] as String?;
      if (icon != null && icon.isNotEmpty) _selectedIconKey = icon;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _path.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _saving = true);
    final menuService = MenuService();
    try {
      if (widget.isEdit && widget.menuId != null) {
        await menuService.updateMenu(
          token,
          widget.menuId!,
          name: _name.text.trim().isEmpty ? null : _name.text.trim(),
          path: _path.text.trim().isEmpty ? null : _path.text.trim(),
          parentId: _parentId,
          isActive: _visibleOnSidebar,
          icon: _selectedIconKey,
          includeParentId: true,
        );
      } else {
        await menuService.createMenu(
          token,
          name: _name.text.trim(),
          path: _path.text.trim(),
          parentId: _parentId?.isEmpty == true ? null : _parentId,
          isActive: _visibleOnSidebar,
          icon: _selectedIconKey,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'Menu updated' : 'Menu created')),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> get _parentOptions {
    final list = <Map<String, dynamic>>[];
    for (final m in widget.allMenus) {
      final id = m['_id'] as String? ?? m['id'] as String?;
      if (widget.isEdit && widget.menuId != null && id == widget.menuId) continue;
      list.add(Map<String, dynamic>.from(m));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: back arrow + title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.darkGray,
                  ),
                  Expanded(
                    child: Text(
                      widget.isEdit ? 'Edit Menu Item' : 'Create Menu Item',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Menu Name
                      const Text(
                        'Menu Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _name,
                        decoration: InputDecoration(
                          hintText: 'e.g., Reports',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Navigation Path
                      const Text(
                        'Navigation Path',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _path,
                        decoration: InputDecoration(
                          hintText: 'e.g., /reports',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Icon
                      const Text(
                        'Icon',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        children: _iconOptions.map((opt) {
                          final selected = _selectedIconKey == opt.key;
                          return InkWell(
                            onTap: () => setState(() => _selectedIconKey = opt.key),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primaryBlue.withOpacity(0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    opt.icon,
                                    size: 28,
                                    color: selected ? AppColors.primaryBlue : AppColors.darkGray,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    opt.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selected ? AppColors.primaryBlue : Colors.grey.shade700,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Visible on Sidebar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Visible on Sidebar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkGray,
                            ),
                          ),
                          Switch(
                            value: _visibleOnSidebar,
                            onChanged: (v) => setState(() => _visibleOnSidebar = v),
                            activeColor: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Parent Menu
                      const Text(
                        'Parent Menu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _parentId,
                        decoration: InputDecoration(
                          hintText: 'Select',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._parentOptions.map((m) {
                            final id = m['_id'] as String? ?? m['id'] as String? ?? '';
                            final name = m['name'] as String? ?? id;
                            return DropdownMenuItem(
                              value: id,
                              child: Text(name),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _parentId = v),
                      ),
                      const SizedBox(height: 32),
                      // Create Menu / Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _saving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(widget.isEdit ? 'Save Menu' : 'Create Menu'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
