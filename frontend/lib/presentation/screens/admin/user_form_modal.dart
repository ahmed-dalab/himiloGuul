import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../providers/auth_provider.dart';

/// Modal form for creating or editing a user.
class UserFormModal extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> allRoles;
  final bool isEdit;
  final VoidCallback onSaved;

  const UserFormModal({
    super.key,
    this.userId,
    this.initial,
    required this.allRoles,
    required this.isEdit,
    required this.onSaved,
  });

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  String? _selectedRoleName;
  bool _isBanned = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _name.text = i['name'] as String? ?? '';
      _email.text = i['email'] as String? ?? '';
      _phone.text = i['phone'] as String? ?? '';
      _location.text = i['location'] as String? ?? '';
      _isBanned = i['isBanned'] == true;
      final roleObj = i['roleId'];
      if (roleObj is Map && roleObj['name'] != null) {
        _selectedRoleName = roleObj['name'] as String?;
      } else if (i['role'] != null) {
        _selectedRoleName = i['role'] as String?;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.isEdit && (_password.text.trim().length < 6)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (_selectedRoleName == null || _selectedRoleName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.isEdit && widget.userId != null) {
        final auth = context.read<AuthProvider>();
        final token = auth.token;
        if (token == null) return;
        await UserService().updateUser(
          token,
          widget.userId!,
          name: _name.text.trim().isEmpty ? null : _name.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          role: _selectedRoleName,
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
          isBanned: _isBanned,
        );
      } else {
        await AuthService().register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          role: _selectedRoleName!,
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'User updated' : 'User created')),
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
      initialChildSize: 0.6,
      maxChildSize: 0.9,
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
                  widget.isEdit ? 'Edit user' : 'Create user',
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
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            readOnly: widget.isEdit,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                          if (!widget.isEdit) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                hintText: 'Min 6 characters',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (v.trim().length < 6) return 'At least 6 characters';
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedRoleName,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(),
                            ),
                            items: widget.allRoles.map((r) {
                              final name = r['name'] as String? ?? '—';
                              return DropdownMenuItem(value: name, child: Text(name));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedRoleName = v),
                            validator: (v) => v == null || v.isEmpty ? 'Select a role' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone (optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _location,
                            decoration: const InputDecoration(
                              labelText: 'Location (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (widget.isEdit) ...[
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('Banned'),
                              value: _isBanned,
                              onChanged: (v) => setState(() => _isBanned = v),
                              activeColor: AppColors.primaryBlue,
                            ),
                          ],
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
