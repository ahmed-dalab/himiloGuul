import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final List<XFile> _newImages = [];
  static const int _maxImages = 10;

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

  List<Map<String, dynamic>> get _existingImages {
    final i = widget.initial;
    if (i == null) return [];
    final imgs = i['images'];
    if (imgs is! List) return [];
    return imgs
        .where((e) => e is Map && (e['url'] != null || e['publicId'] != null))
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _pickImages() async {
    if (!mounted) return;
    final current = _existingImages.length + _newImages.length;
    if (current >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImages images allowed')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening gallery...'), duration: Duration(seconds: 1)),
    );

    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      if (picked.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No images selected')),
        );
        return;
      }
      final remaining = _maxImages - current;
      final toAdd = picked.length > remaining ? picked.take(remaining).toList() : picked;
      setState(() => _newImages.addAll(toAdd));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${toAdd.length} image(s)')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open gallery: ${e.toString()}')),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _reorderNewImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _newImages.removeAt(oldIndex);
      _newImages.insert(newIndex, item);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _saving = true);
    final businessService = BusinessService();
    final imageFiles = _newImages.isEmpty ? null : _newImages;
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
          imageFiles: imageFiles,
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
          imageFiles: imageFiles,
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
              // Images section OUTSIDE ListView so the Add button tap is never stolen by scroll
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildImagesSection(),
              ),
              const SizedBox(height: 8),
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

  Widget _buildImagesSection() {
    final existing = _existingImages;
    final total = existing.length + _newImages.length;
    final canAdd = total < _maxImages;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Business images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '$total / $_maxImages',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Use ElevatedButton so the tap is always received (not stolen by ListView scroll)
          if (canAdd)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate, size: 24),
                label: const Text('Tap to add photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
                  foregroundColor: AppColors.primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primaryBlue, width: 2),
                  ),
                ),
              ),
            ),
          if (canAdd) const SizedBox(height: 12),
          // Drop zone hint when we have room (for drag-and-drop on supported platforms)
          if (canAdd)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Or drag images here to add',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          // Existing images (horizontal)
          if (existing.isNotEmpty) ...[
            const Text('Uploaded', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            SizedBox(
              height: 88,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: existing.length,
                itemBuilder: (context, i) {
                  final url = existing[i]['url'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: url.isNotEmpty
                            ? Image.network(url, fit: BoxFit.cover)
                            : ColoredBox(
                                color: Colors.grey.shade300,
                                child: Icon(Icons.broken_image, color: Colors.grey.shade600),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          // New images: reorderable list (drag to reorder)
          if (_newImages.isNotEmpty) ...[
            Text(
              'New (drag to reorder)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 96,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _newImages.length,
                onReorder: _reorderNewImages,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final x = _newImages[index];
                  final path = x.path;
                  final file = path.isNotEmpty ? File(path) : null;
                  return Padding(
                    key: ValueKey('${x.path}_$index'),
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 88,
                            height: 88,
                            child: file != null && file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : ColoredBox(
                                    color: Colors.grey.shade300,
                                    child: Icon(Icons.image, color: Colors.grey.shade600),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeNewImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.drag_handle, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
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
