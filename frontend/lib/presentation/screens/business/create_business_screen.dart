import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/business_service.dart';
import '../../../core/services/user_service.dart';
import '../../providers/auth_provider.dart';

/// Multi-step create business screen for both admin and seller.
/// Admin: step 1 includes "Select owner" (sellers only). Seller: owner = self.
class CreateBusinessScreen extends StatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  int _step = 0;
  static const int _totalSteps = 3;

  // Step 1
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String? _category;
  String? _selectedOwnerId; // admin only

  // Step 2
  final _askingPriceController = TextEditingController();
  final _annualRevenueController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Step 3
  final List<XFile> _images = [];
  static const int _minImages = 3;
  bool _termsAccepted = false;

  List<Map<String, dynamic>> _sellers = [];
  bool _loadingSellers = false;
  bool _submitting = false;

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

  bool get _isAdmin {
    return context.read<AuthProvider>().currentUser?.role == UserRole.admin;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().currentUser?.role == UserRole.admin) {
        _loadSellers();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _askingPriceController.dispose();
    _annualRevenueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSellers() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _loadingSellers = true);
    try {
      final res = await UserService().getAllUsers(
        token,
        role: 'seller',
        limit: 200,
      );
      final data = res['data'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _sellers = data
              .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList();
          _loadingSellers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSellers = false);
    }
  }

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  void _backStep() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  bool _validateStep1() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter business name')),
      );
      return false;
    }
    if (_isAdmin && (_selectedOwnerId == null || _selectedOwnerId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the business owner (seller)')),
      );
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_images.length < _minImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least $_minImages images')),
      );
      return false;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms and Conditions')),
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateStep3()) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    setState(() => _submitting = true);
    final businessService = BusinessService();
    try {
      await businessService.createBusiness(
        token,
        name: _nameController.text.trim(),
        category: _category,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        askingPrice: double.tryParse(_askingPriceController.text.trim()),
        annualRevenue: double.tryParse(_annualRevenueController.text.trim()),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        ownerId: _isAdmin ? _selectedOwnerId : null,
        imageFiles: _images.isEmpty ? null : _images,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business created. Waiting for admin approval.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      if (picked.isNotEmpty) {
        setState(() => _images.addAll(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open gallery: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: _backStep,
        ),
        title: Text(
          _step == 0
              ? 'Step 1: Basic Information'
              : _step == 1
                  ? 'Step 2: Financial Details'
                  : 'Step 3: Photos & Submit',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  Text(
                    'Step ${_step + 1} of $_totalSteps',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _totalSteps,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _step == 0
                    ? _buildStep1()
                    : _step == 1
                        ? _buildStep2()
                        : _buildStep3(),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: _step < _totalSteps - 1
                  ? Row(
                      children: [
                        if (_step > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _backStep,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.darkGray,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                        if (_step > 0) const SizedBox(width: 16),
                        Expanded(
                          flex: _step > 0 ? 1 : 1,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_step == 0 && !_validateStep1()) return;
                              _nextStep();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Listing'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Business Name',
            hintText: 'Enter your business name',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(
            labelText: 'Category',
            hintText: 'Select a category',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _category = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location',
            hintText: 'Enter your business location',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (_isAdmin) ...[
          const SizedBox(height: 24),
          const Text(
            'Owner (Seller)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          _loadingSellers
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedOwnerId,
                  decoration: const InputDecoration(
                    labelText: 'Select owner',
                    hintText: 'Select a seller',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _sellers
                      .map((u) {
                        final id = u['_id'] as String?;
                        final name = u['name'] as String? ?? '—';
                        final email = u['email'] as String? ?? '';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text('$name ($email)'),
                        );
                      })
                      .toList(),
                  onChanged: (v) => setState(() => _selectedOwnerId = v),
                ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        TextFormField(
          controller: _askingPriceController,
          decoration: const InputDecoration(
            labelText: 'Asking Price',
            hintText: 'Enter asking price',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _annualRevenueController,
          decoration: const InputDecoration(
            labelText: 'Annual Revenue',
            hintText: 'Enter annual revenue',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your business',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: [
              const Text(
                'Upload Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Showcase your business with high-quality photos. Add at least $_minImages images.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_images.length, (i) {
                    final x = _images[i];
                    final path = x.path;
                    final file = path.isNotEmpty ? File(path) : null;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: file != null && file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : ColoredBox(
                                    color: Colors.grey.shade300,
                                    child: Icon(Icons.image, color: Colors.grey.shade600),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_images.length} image(s)${_images.length < _minImages ? " (min $_minImages)" : ""}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                activeColor: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'I agree to the Terms and Conditions',
                    style: TextStyle(fontSize: 14, color: AppColors.darkGray),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
