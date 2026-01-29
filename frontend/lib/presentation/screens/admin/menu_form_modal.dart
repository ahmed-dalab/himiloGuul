import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/menu_service.dart';
import '../../providers/auth_provider.dart';

/// Modal form for creating or editing a menu.
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
          includeParentId: true,
        );
      } else {
        await menuService.createMenu(
          token,
          name: _name.text.trim(),
          path: _path.text.trim(),
          parentId: _parentId?.isEmpty == true ? null : _parentId,
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
      list.add(m);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.isEdit ? 'Edit menu' : 'Create menu',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _path,
                            decoration: const InputDecoration(
                              labelText: 'Path',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _parentId,
                            decoration: const InputDecoration(
                              labelText: 'Parent menu',
                              border: OutlineInputBorder(),
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
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(widget.isEdit ? 'Save' : 'Create'),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
