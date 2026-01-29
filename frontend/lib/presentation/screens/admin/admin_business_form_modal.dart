import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/business_service.dart';
import '../../providers/auth_provider.dart';

/// Modal form for creating or editing a business (used by admin business list and detail).
class AdminBusinessFormModal extends StatefulWidget {
  final String? businessId;
  final Map<String, dynamic>? initial;
  final bool isEdit;
  final VoidCallback onSaved;

  const AdminBusinessFormModal({
    super.key,
    this.businessId,
    this.initial,
    required this.isEdit,
    required this.onSaved,
  });

  @override
  State<AdminBusinessFormModal> createState() => _AdminBusinessFormModalState();
}

class _AdminBusinessFormModalState extends State<AdminBusinessFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _description = TextEditingController();
  final _askingPrice = TextEditingController();
  final _location = TextEditingController();
  String? _category;
  bool _saving = false;

  static const _categories = [
    'restaurant',
    'retail',
    'service',
    'technology',
    'healthcare',
    'education',
    'real-estate',
    'hospitality',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _name.text = i['name'] as String? ?? '';
      _address.text = i['address'] as String? ?? '';
      _phone.text = i['phone'] as String? ?? '';
      _email.text = i['email'] as String? ?? '';
      _website.text = i['website'] as String? ?? '';
      _description.text = i['description'] as String? ?? '';
      _location.text = i['location'] as String? ?? '';
      if (i['askingPrice'] != null) _askingPrice.text = '${i['askingPrice']}';
      _category = i['category'] as String?;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _description.dispose();
    _askingPrice.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _saving = true);
    final businessService = BusinessService();
    try {
      if (widget.isEdit && widget.businessId != null) {
        await businessService.updateBusiness(
          token,
          widget.businessId!,
          name: _name.text.trim().isEmpty ? null : _name.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          website: _website.text.trim().isEmpty ? null : _website.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          category: _category,
          askingPrice: double.tryParse(_askingPrice.text.trim()),
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        );
      } else {
        await businessService.createBusiness(
          token,
          name: _name.text.trim(),
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          website: _website.text.trim().isEmpty ? null : _website.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          category: _category,
          askingPrice: double.tryParse(_askingPrice.text.trim()),
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? 'Business updated' : 'Business created')),
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
      initialChildSize: 0.9,
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
                  widget.isEdit ? 'Edit business' : 'Register business',
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
                          _field(_name, 'Name', required: true),
                          _field(_address, 'Address', required: true),
                          _field(_phone, 'Phone', required: true),
                          _field(_email, 'Email', required: true),
                          _field(_website, 'Website'),
                          _field(_location, 'Location'),
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setState(() => _category = v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _askingPrice,
                            decoration: const InputDecoration(
                              labelText: 'Asking price',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _description,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
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

  Widget _field(TextEditingController c, String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                return null;
              }
            : null,
      ),
    );
  }
}
