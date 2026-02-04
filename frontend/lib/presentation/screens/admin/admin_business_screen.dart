import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../core/services/admin_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

/// Status filter: all, pending, approved, rejected
enum _BusinessFilter { all, pending, approved, rejected }

class AdminBusinessScreen extends StatefulWidget {
  const AdminBusinessScreen({super.key});

  @override
  State<AdminBusinessScreen> createState() => _AdminBusinessScreenState();
}

class _AdminBusinessScreenState extends State<AdminBusinessScreen> {
  final AdminService _adminService = AdminService();
  _BusinessFilter _filter = _BusinessFilter.all;
  List<dynamic> _businesses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  String? get _statusParam {
    switch (_filter) {
      case _BusinessFilter.all:
        return null;
      case _BusinessFilter.pending:
        return 'pending';
      case _BusinessFilter.approved:
        return 'approved';
      case _BusinessFilter.rejected:
        return 'rejected';
    }
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
      final res = await _adminService.listAllBusinesses(
        token,
        status: _statusParam,
        limit: 50,
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );
      final data = res['data'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _businesses = data;
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

  Future<void> _approve(String businessId) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    try {
      await _adminService.approveBusiness(token, businessId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business approved')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _reject(String businessId) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;
    try {
      await _adminService.rejectBusiness(token, businessId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business rejected')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  void _openCreateFlow() {
    context.push(AppRoutes.createBusiness).then((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == _BusinessFilter.all,
                  onTap: () {
                    setState(() {
                      _filter = _BusinessFilter.all;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
                    });
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending Approval',
                  selected: _filter == _BusinessFilter.pending,
                  onTap: () {
                    setState(() {
                      _filter = _BusinessFilter.pending;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
                    });
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  selected: _filter == _BusinessFilter.approved,
                  onTap: () {
                    setState(() {
                      _filter = _BusinessFilter.approved;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
                    });
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rejected',
                  selected: _filter == _BusinessFilter.rejected,
                  onTap: () {
                    setState(() {
                      _filter = _BusinessFilter.rejected;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
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
                          TextButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _businesses.isEmpty
                      ? Center(
                          child: Text(
                            'No businesses in this filter.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _businesses.length,
                            itemBuilder: (context, index) {
                              final b = _businesses[index] as Map<String, dynamic>;
                              final id = b['_id'] as String? ?? '';
                              final name = b['name'] as String? ?? 'Business';
                              final status = b['status'] as String? ?? '';
                              final category = b['category'] as String?;
                              final createdAt = b['createdAt'] as String?;
                              final owner = b['owner'];
                              final ownerName = owner is Map
                                  ? (owner['name'] as String? ?? '—')
                                  : '—';
                              final isPending = status == 'pending';
                              return _BusinessCard(
                                name: name,
                                submitted: _formatDate(createdAt),
                                ownerName: ownerName,
                                category: category,
                                status: status,
                                onTap: () => context.push('/admin/business/$id'),
                                onApprove: isPending
                                    ? () => _approve(id)
                                    : null,
                                onReject: isPending
                                    ? () => _reject(id)
                                    : null,
                              );
                            },
                          ),
                        ),
        ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton(
            onPressed: _openCreateFlow,
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBlue : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final String name;
  final String submitted;
  final String ownerName;
  final String? category;
  final String status;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _BusinessCard({
    required this.name,
    required this.submitted,
    required this.ownerName,
    this.category,
    required this.status,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  Color _iconColor() {
    switch (category?.toLowerCase()) {
      case 'restaurant':
        return Colors.green.shade700;
      case 'retail':
        return Colors.orange.shade700;
      case 'technology':
        return Colors.green.shade800;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _icon() {
    switch (category?.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'retail':
        return Icons.store;
      case 'technology':
        return Icons.computer;
      case 'construction':
        return Icons.construction;
      default:
        return Icons.business_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(), color: _iconColor(), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted: $submitted',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Owner: $ownerName',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isPending && (onApprove != null || onReject != null))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onReject != null)
                    TextButton(
                      onPressed: onReject,
                      child: Text(
                        'Reject',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  if (onApprove != null)
                    OutlinedButton(
                      onPressed: onApprove,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                      ),
                      child: const Text('Approve'),
                    ),
                ],
              ),
          ],
        ),
      ),
    ));
  }
}
