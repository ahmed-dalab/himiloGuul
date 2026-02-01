import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/role_service.dart';
import '../../providers/auth_provider.dart';

/// Modal form for creating or editing a role.
class RoleFormModal extends StatefulWidget {
  final String? roleId;
  final Map<String, dynamic>? initial;
  final bool isEdit;
  final VoidCallback onSaved;

  const RoleFormModal({
    super.key,
    this.roleId,
    this.initial,
    required this.isEdit,
    required this.onSaved,
  });

  @override
  State<RoleFormModal> createState() => _RoleFormModalState();
}

class _RoleFormModalState extends State<RoleFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _name.text = i['name'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _saving = true);
    final roleService = RoleService();
    try {
      if (widget.isEdit && widget.roleId != null) {
        await roleService.updateRole(
          token,
          widget.roleId!,
          name: _name.text.trim(),
        );
      } else {
        await roleService.createRole(
          token,
          name: _name.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'Role updated' : 'Role created')),
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
      initialChildSize: 0.35,
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
                  widget.isEdit ? 'Edit role' : 'Create role',
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
                              hintText: 'e.g. admin, seller, buyer',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.none,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
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
