import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/permission_service.dart';
import '../../providers/auth_provider.dart';

/// Modal form for creating or editing a permission.
class PermissionFormModal extends StatefulWidget {
  final String? permissionId;
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> allMenus;
  final bool isEdit;
  final VoidCallback onSaved;

  const PermissionFormModal({
    super.key,
    this.permissionId,
    this.initial,
    required this.allMenus,
    required this.isEdit,
    required this.onSaved,
  });

  @override
  State<PermissionFormModal> createState() => _PermissionFormModalState();
}

class _PermissionFormModalState extends State<PermissionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _menuId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _name.text = i['name'] as String? ?? '';
      final m = i['menuId'];
      _menuId = m is Map ? (m['_id'] ?? m['id']) as String? : m?.toString();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_menuId == null || _menuId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a menu')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _saving = true);
    final permissionService = PermissionService();
    try {
      if (widget.isEdit && widget.permissionId != null) {
        await permissionService.updatePermission(
          token,
          widget.permissionId!,
          name: _name.text.trim().isEmpty ? null : _name.text.trim(),
          menuId: _menuId,
        );
      } else {
        await permissionService.createPermission(
          token,
          name: _name.text.trim(),
          menuId: _menuId!,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'Permission updated' : 'Permission created')),
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
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
                  widget.isEdit ? 'Edit permission' : 'Create permission',
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
                          DropdownButtonFormField<String>(
                            value: _menuId,
                            decoration: const InputDecoration(
                              labelText: 'Menu',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              return null;
                            },
                            items: widget.allMenus
                                .map((m) {
                                  final id = m['_id'] as String? ?? m['id'] as String? ?? '';
                                  final name = m['name'] as String? ?? id;
                                  return DropdownMenuItem(
                                    value: id,
                                    child: Text(name),
                                  );
                                })
                                .toList(),
                            onChanged: (v) => setState(() => _menuId = v),
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
