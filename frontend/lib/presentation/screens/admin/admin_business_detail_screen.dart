import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/business_service.dart';
import '../../providers/auth_provider.dart';
import 'admin_business_form_modal.dart';

class AdminBusinessDetailScreen extends StatefulWidget {
  final String businessId;

  const AdminBusinessDetailScreen({super.key, required this.businessId});

  @override
  State<AdminBusinessDetailScreen> createState() => _AdminBusinessDetailScreenState();
}

class _AdminBusinessDetailScreenState extends State<AdminBusinessDetailScreen> {
  final BusinessService _businessService = BusinessService();
  Map<String, dynamic>? _business;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
      final res = await _businessService.getBusinessById(widget.businessId, token: token);
      final data = res['data'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _business = data;
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete business?'),
        content: const Text('This action cannot be undone.'),
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
      await _businessService.deleteBusiness(token, widget.businessId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business deleted')));
        context.go('/admin');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  void _openEdit() {
    if (_business == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => AdminBusinessFormModal(
        businessId: widget.businessId,
        initial: _business!,
        isEdit: true,
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _business == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin'),
          ),
          title: const Text('Business'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkGray,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }
    if (_error != null && _business == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin'),
          ),
          title: const Text('Business'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkGray,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final b = _business!;
    final owner = b['owner'];
    final ownerName = owner is Map ? (owner['name'] as String? ?? '—') : '—';
    final ownerEmail = owner is Map ? (owner['email'] as String? ?? '—') : '—';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        title: Text(b['name'] as String? ?? 'Business'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGray,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
            onPressed: _openEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_businessImages(b).isNotEmpty) ...[
              const Text(
                'Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _businessImages(b).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final url = _businessImages(b)[i]['url'] as String? ?? '';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url.isNotEmpty
                          ? Image.network(url, width: 120, height: 120, fit: BoxFit.cover)
                          : Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.broken_image, color: Colors.grey.shade600),
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            _DetailRow(label: 'Status', value: (b['status'] as String?) ?? '—'),
            _DetailRow(label: 'Category', value: (b['category'] as String?) ?? '—'),
            _DetailRow(label: 'Address', value: (b['address'] as String?) ?? '—'),
            _DetailRow(label: 'Phone', value: (b['phone'] as String?) ?? '—'),
            _DetailRow(label: 'Email', value: (b['email'] as String?) ?? '—'),
            _DetailRow(label: 'Website', value: (b['website'] as String?) ?? '—'),
            _DetailRow(label: 'Location', value: (b['location'] as String?) ?? '—'),
            if (b['askingPrice'] != null)
              _DetailRow(
                label: 'Asking price',
                value: '\$${(_parseNum(b['askingPrice'])).toStringAsFixed(0)}',
              ),
            if ((b['description'] as String?)?.isNotEmpty == true)
              _DetailRow(label: 'Description', value: (b['description'] as String?) ?? ''),
            const SizedBox(height: 16),
            const Text(
              'Owner',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 4),
            Text('$ownerName — $ownerEmail', style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  double _parseNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> _businessImages(Map<String, dynamic> b) {
    final imgs = b['images'];
    if (imgs is! List) return [];
    return imgs
        .where((e) => e is Map && (e['url'] != null || e['publicId'] != null))
        .cast<Map<String, dynamic>>()
        .toList();
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: AppColors.darkGray),
          ),
        ],
      ),
    );
  }
}
