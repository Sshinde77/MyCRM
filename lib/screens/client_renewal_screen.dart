import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../core/constants/app_text_styles.dart';
import '../models/client_model.dart';
import '../models/renewal_model.dart';
import '../models/vendor_model.dart';
import '../providers/renewal_list_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class ClientRenewalScreen extends StatelessWidget {
  const ClientRenewalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RenewalListProvider>(
      create: (_) =>
          RenewalListProvider(type: RenewalType.client)..loadRenewals(),
      child: const _ClientRenewalBody(),
    );
  }
}

class ClientRenewalFormScreen extends StatelessWidget {
  const ClientRenewalFormScreen({super.key, this.initialRenewal});

  final RenewalModel? initialRenewal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: CommonScreenAppBar(
        title: (initialRenewal?.id.trim().isNotEmpty ?? false)
            ? 'Edit Service'
            : 'Add Service',
      ),
      body: _ClientRenewalFormSheet(initialRenewal: initialRenewal),
    );
  }
}

class _ClientRenewalBody extends StatefulWidget {
  const _ClientRenewalBody();

  @override
  State<_ClientRenewalBody> createState() => _ClientRenewalBodyState();
}

class _ClientRenewalBodyState extends State<_ClientRenewalBody>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshRenewals();
    }
  }

  Future<void> _refreshRenewals() async {
    if (!mounted) {
      return;
    }
    await context.read<RenewalListProvider>().loadRenewals(forceRefresh: true);
  }

  Future<void> _openServiceForm({RenewalModel? renewal}) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientRenewalFormScreen(initialRenewal: renewal),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _refreshRenewals();
    }
  }

  Future<void> _openDetail(RenewalModel renewal) async {
    await Get.toNamed(AppRoutes.clientRenewalDetail, arguments: renewal);
    if (!mounted) {
      return;
    }
    await _refreshRenewals();
  }

  Future<void> _deleteRenewal(RenewalModel renewal) async {
    final renewalId = renewal.id.trim();
    if (renewalId.isEmpty) {
      Get.snackbar(
        'Delete failed',
        'Invalid service id.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB91C1C),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Service'),
          content: Text(
            'Are you sure you want to delete "${renewal.title.trim().isEmpty ? 'this service' : renewal.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _apiService.deleteClientRenewal(renewalId);
      if (!mounted) {
        return;
      }
      await _refreshRenewals();
      if (!mounted) {
        return;
      }
      Get.snackbar(
        'Deleted',
        'Service deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF153A63),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      String message = 'Failed to delete service.';
      if (error is DioException) {
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else {
          final dioMessage = error.message?.trim() ?? '';
          if (dioMessage.isNotEmpty) {
            message = dioMessage;
          }
        }
      } else {
        final raw = error.toString().trim();
        if (raw.startsWith('Exception: ')) {
          message = raw.substring('Exception: '.length);
        } else if (raw.isNotEmpty) {
          message = raw;
        }
      }

      Get.snackbar(
        'Delete failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB91C1C),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 380;
    final side = compact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(compact: compact),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshRenewals,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        side,
                        compact ? 16 : 18,
                        side,
                        18,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              children: [
                                _FilterCard(compact: compact),
                                SizedBox(height: compact ? 16 : 18),
                                _AddServiceButton(
                                  compact: compact,
                                  onTap: () => _openServiceForm(),
                                ),
                                SizedBox(height: compact ? 16 : 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _RenewalListSection(
                      compact: compact,
                      sidePadding: side,
                      onView: (renewal) => _openDetail(renewal),
                      onEdit: (renewal) => _openServiceForm(renewal: renewal),
                      onDelete: (renewal) => _deleteRenewal(renewal),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenewalListSection extends StatelessWidget {
  const _RenewalListSection({
    required this.compact,
    required this.sidePadding,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final bool compact;
  final double sidePadding;
  final ValueChanged<RenewalModel> onView;
  final ValueChanged<RenewalModel> onEdit;
  final ValueChanged<RenewalModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Consumer<RenewalListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.renewals.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (provider.errorMessage != null && provider.renewals.isEmpty) {
          return SliverPadding(
            padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _ErrorCard(
                    compact: compact,
                    message: provider.errorMessage!,
                    onRetry: () => context
                        .read<RenewalListProvider>()
                        .loadRenewals(forceRefresh: true),
                  ),
                ),
              ),
            ),
          );
        }

        if (provider.renewals.isEmpty) {
          return SliverPadding(
            padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _EmptyCard(compact: compact),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final service = _ServiceItem.fromRenewal(
                provider.renewals[index],
              );
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: compact ? 14 : 16),
                    child: _ServiceCard(
                      service: service,
                      compact: compact,
                      onView: () => onView(service.renewal),
                      onEdit: () => onEdit(service.renewal),
                      onDelete: () => onDelete(service.renewal),
                    ),
                  ),
                ),
              );
            }, childCount: provider.renewals.length),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 68 : 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: CommonTopBar(
        title: 'Services',
        compact: compact,
        onBack: Get.back,
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: const Color(0xFF475569),
                size: compact ? 21 : 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Filter Renewal Period',
                style: AppTextStyles.style(
                  color: const Color(0xFF334155),
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 16),
          Row(
            children: [
              Expanded(
                child: _DateField(label: 'From Date', compact: compact),
              ),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: _DateField(label: 'To Date', compact: compact),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Filter',
                  filled: true,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: _ActionButton(
                  label: 'Clear',
                  filled: false,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 11 : 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(color: const Color(0xFFDCE6F2)),
          ),
          child: Text(
            'mm/dd/yyyy',
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.compact,
  });

  final String label;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 46 : 50,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF156CF1) : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(
          color: filled ? const Color(0xFF156CF1) : const Color(0xFFDCE6F2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.style(
          color: filled ? Colors.white : const Color(0xFF334155),
          fontSize: compact ? 14 : 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddServiceButton extends StatelessWidget {
  const _AddServiceButton({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: compact ? 14 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFF156CF1),
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22156CF1),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: compact ? 22 : 24,
            ),
            SizedBox(width: compact ? 10 : 12),
            Text(
              'Add New Service',
              style: AppTextStyles.style(
                color: Colors.white,
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.compact,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final _ServiceItem service;
  final bool compact;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 18,
              compact ? 16 : 18,
              compact ? 16 : 18,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SERVICE DETAILS',
                            style: AppTextStyles.style(
                              color: const Color(0xFF94A3B8),
                              fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 10),
                          Text(
                            service.title,
                            style: AppTextStyles.style(
                              color: const Color(0xFF17213A),
                              fontSize: compact ? 17 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 12,
                        vertical: compact ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        service.status,
                        style: AppTextStyles.style(
                          color: const Color(0xFF15803D),
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 16),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: 'Client: ${service.client}',
                  compact: compact,
                ),
                SizedBox(height: compact ? 10 : 12),
                _InfoRow(
                  icon: Icons.storefront_outlined,
                  text: 'Vendor: ${service.vendor}',
                  compact: compact,
                ),
                SizedBox(height: compact ? 16 : 18),
                const Divider(height: 1, color: Color(0xFFEAF0F6)),
                SizedBox(height: compact ? 12 : 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetaColumn(
                        label: 'Start',
                        value: service.startDate,
                        compact: compact,
                      ),
                    ),
                    _VerticalDivider(compact: compact),
                    Expanded(
                      child: _MetaColumn(
                        label: 'End',
                        value: service.endDate,
                        compact: compact,
                      ),
                    ),
                    _VerticalDivider(compact: compact),
                    Expanded(
                      child: _MetaColumn(
                        label: 'Billing',
                        value: service.billing,
                        compact: compact,
                      ),
                    ),
                  ],
                ),
                if (service.showExpiryAlert) ...[
                  SizedBox(height: compact ? 14 : 16),
                  const Divider(height: 1, color: Color(0xFFEAF0F6)),
                  SizedBox(height: compact ? 12 : 14),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFEF4444),
                        size: compact ? 20 : 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.expiryNote,
                          style: AppTextStyles.style(
                            color: const Color(0xFFEF4444),
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: compact ? 14 : 16),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAF0F6)),
          SizedBox(
            height: compact ? 52 : 56,
            child: Row(
              children: [
                Expanded(
                  child: _CardAction(
                    icon: Icons.remove_red_eye_outlined,
                    onTap: onView,
                  ),
                ),
                _ActionDivider(),
                Expanded(
                  child: _CardAction(icon: Icons.edit_outlined, onTap: onEdit),
                ),
                _ActionDivider(),
                const Expanded(
                  child: _CardAction(icon: Icons.mail_outline_rounded),
                ),
                _ActionDivider(),
                Expanded(
                  child: _CardAction(
                    icon: Icons.delete_outline_rounded,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.compact,
  });

  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: compact ? 23 : 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaColumn extends StatelessWidget {
  const _MetaColumn({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF94A3B8),
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.style(
            color: const Color(0xFF17213A),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 50 : 56,
      width: 1,
      color: const Color(0xFFEAF0F6),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Icon(icon, color: const Color(0xFF64748B), size: 23),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: const Color(0xFFEAF0F6));
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.compact,
    required this.message,
    required this.onRetry,
  });

  final bool compact;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 22 : 24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load client renewals',
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            message,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 12 : 14),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 22 : 24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Text(
        'No client renewals available.',
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: compact ? 14 : 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ClientRenewalFormSheet extends StatefulWidget {
  const _ClientRenewalFormSheet({this.initialRenewal});

  final RenewalModel? initialRenewal;

  @override
  State<_ClientRenewalFormSheet> createState() =>
      _ClientRenewalFormSheetState();
}

class _ClientRenewalFormSheetState extends State<_ClientRenewalFormSheet> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _serviceDetailsController =
      TextEditingController();
  final TextEditingController _remarkTextController = TextEditingController();

  List<ClientModel> _clients = const <ClientModel>[];
  List<VendorModel> _vendors = const <VendorModel>[];

  String? _renewalId;
  String? _selectedClientId;
  String? _selectedVendorId;
  String _seedClientName = '';
  String _seedVendorName = '';
  String? _selectedRemarkColor;
  String _selectedStatus = 'active';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _billingDate;

  bool _isLoadingOptions = false;
  bool _isLoadingDetail = false;
  bool _isSubmitting = false;

  bool get _isEditMode => (_renewalId ?? '').isNotEmpty;

  static const List<String> _remarkColors = <String>[
    'yellow',
    'green',
    'blue',
    'orange',
    'red',
  ];

  static const List<String> _statusValues = <String>['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    _applyRenewalSeed(widget.initialRenewal);
    _loadFormData();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceDetailsController.dispose();
    _remarkTextController.dispose();
    super.dispose();
  }

  void _applyRenewalSeed(RenewalModel? renewal) {
    if (renewal == null) {
      return;
    }

    _renewalId = renewal.id.trim().isEmpty ? null : renewal.id.trim();
    _selectedClientId = renewal.clientId.trim().isEmpty
        ? null
        : renewal.clientId.trim();
    _selectedVendorId = renewal.vendorId.trim().isEmpty
        ? null
        : renewal.vendorId.trim();
    _seedClientName = renewal.client.trim();
    _seedVendorName = renewal.vendor.trim();

    _serviceNameController.text = renewal.title.trim();
    _serviceDetailsController.text = renewal.serviceDetails.trim();
    _remarkTextController.text = renewal.remarkText.trim().isNotEmpty
        ? renewal.remarkText.trim()
        : renewal.remark.trim();
    _selectedRemarkColor = renewal.remarkColor.trim().isNotEmpty
        ? renewal.remarkColor.trim().toLowerCase()
        : null;
    _selectedStatus = _normalizeStatusForForm(renewal.status);
    _startDate = renewal.startDateValue;
    _endDate = renewal.endDateValue;
    _billingDate = renewal.billingDateValue;
  }

  String _normalizeStatusForForm(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    if (normalized.contains('inactive') || normalized == '0') {
      return 'inactive';
    }
    return 'active';
  }

  Future<void> _loadFormData() async {
    await _loadLookupData();
    if (_isEditMode) {
      await _loadRenewalDetail();
    }
  }

  Future<void> _loadLookupData() async {
    setState(() => _isLoadingOptions = true);
    try {
      final results = await Future.wait<dynamic>([
        _apiService.getClientsList(),
        _apiService.getVendorsList(),
      ]);
      _clients = (results[0] as List<ClientModel>)
          .where((client) => client.id.trim().isNotEmpty)
          .toList(growable: false);
      _vendors = (results[1] as List<VendorModel>)
          .where((vendor) => vendor.id.trim().isNotEmpty)
          .toList(growable: false);
      _syncSelectionsWithLookup();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: 'Unable to load form options',
        message: _readError(error, fallback: 'Please try again later.'),
        backgroundColor: const Color(0xFFB45309),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
      }
    }
  }

  Future<void> _loadRenewalDetail() async {
    final id = (_renewalId ?? '').trim();
    if (id.isEmpty) {
      return;
    }

    setState(() => _isLoadingDetail = true);
    try {
      final detail = await _apiService.getClientRenewalDetail(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _applyRenewalSeed(detail);
        _syncSelectionsWithLookup();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: 'Unable to load service detail',
        message: _readError(error, fallback: 'Please try again later.'),
        backgroundColor: const Color(0xFFB45309),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  String? _validate() {
    if ((_selectedClientId ?? '').trim().isEmpty) {
      return 'Client is required.';
    }
    if ((_selectedVendorId ?? '').trim().isEmpty) {
      return 'Vendor is required.';
    }
    if (_serviceNameController.text.trim().isEmpty) {
      return 'Service name is required.';
    }
    if (_startDate == null) {
      return 'Start date is required.';
    }
    if (_endDate == null) {
      return 'End date is required.';
    }
    if (_billingDate == null) {
      return 'Billing date is required.';
    }
    if (_startDate!.isAfter(_endDate!)) {
      return 'End date must be on or after start date.';
    }
    return null;
  }

  Future<void> _submit() async {
    final validationError = _validate();
    if (validationError != null) {
      _showSnack(
        title: 'Missing details',
        message: validationError,
        backgroundColor: const Color(0xFFB45309),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        await _apiService.updateClientRenewal(
          id: _renewalId!,
          clientId: _selectedClientId!,
          vendorId: _selectedVendorId!,
          serviceName: _serviceNameController.text.trim(),
          serviceDetails: _serviceDetailsController.text.trim(),
          remarkText: _remarkTextController.text.trim(),
          remarkColor: (_selectedRemarkColor ?? '').trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          billingDate: _billingDate!,
          status: _selectedStatus,
        );
      } else {
        await _apiService.createClientRenewal(
          clientId: _selectedClientId!,
          vendorId: _selectedVendorId!,
          serviceName: _serviceNameController.text.trim(),
          serviceDetails: _serviceDetailsController.text.trim(),
          remarkText: _remarkTextController.text.trim(),
          remarkColor: (_selectedRemarkColor ?? '').trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          billingDate: _billingDate!,
          status: _selectedStatus,
        );
      }

      if (!mounted) {
        return;
      }
      _showSnack(
        title: _isEditMode ? 'Service updated' : 'Service created',
        message: _isEditMode
            ? 'Client service has been updated successfully.'
            : 'Client service has been created successfully.',
        backgroundColor: const Color(0xFF153A63),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(
        title: _isEditMode ? 'Update failed' : 'Create failed',
        message: _readError(
          error,
          fallback: _isEditMode
              ? 'Failed to update service.'
              : 'Failed to create service.',
        ),
        backgroundColor: const Color(0xFFB91C1C),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetServiceFields() {
    setState(() {
      _selectedVendorId = null;
      _serviceNameController.clear();
      _serviceDetailsController.clear();
      _remarkTextController.clear();
      _selectedRemarkColor = null;
      _startDate = null;
      _endDate = null;
      _billingDate = null;
      _selectedStatus = 'active';
    });
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) {
      return;
    }
    onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'dd-mm-yyyy';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  String _normalizeLookupId(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final intValue = int.tryParse(normalized);
    if (intValue != null) {
      return intValue.toString();
    }

    final numValue = num.tryParse(normalized);
    if (numValue != null && numValue == numValue.toInt()) {
      return numValue.toInt().toString();
    }

    return normalized.toLowerCase();
  }

  void _syncSelectionsWithLookup() {
    if (_clients.isNotEmpty) {
      final candidateClientId = (_selectedClientId ?? '').trim();
      if (candidateClientId.isNotEmpty) {
        final normalized = _normalizeLookupId(candidateClientId);
        final matched = _clients.where((entry) {
          return _normalizeLookupId(entry.id) == normalized;
        });
        if (matched.isNotEmpty) {
          _selectedClientId = matched.first.id;
        }
      }

      if ((_selectedClientId ?? '').trim().isEmpty &&
          _seedClientName.isNotEmpty) {
        final matchedByName = _clients.where((entry) {
          return _clientDisplayName(entry).trim().toLowerCase() ==
              _seedClientName.toLowerCase();
        });
        if (matchedByName.isNotEmpty) {
          _selectedClientId = matchedByName.first.id;
        }
      }
    }

    if (_vendors.isNotEmpty) {
      final candidateVendorId = (_selectedVendorId ?? '').trim();
      if (candidateVendorId.isNotEmpty) {
        final normalized = _normalizeLookupId(candidateVendorId);
        final matched = _vendors.where((entry) {
          return _normalizeLookupId(entry.id) == normalized;
        });
        if (matched.isNotEmpty) {
          _selectedVendorId = matched.first.id;
        }
      }

      if ((_selectedVendorId ?? '').trim().isEmpty &&
          _seedVendorName.isNotEmpty) {
        final matchedByName = _vendors.where((entry) {
          return entry.vendorName.trim().toLowerCase() ==
              _seedVendorName.toLowerCase();
        });
        if (matchedByName.isNotEmpty) {
          _selectedVendorId = matchedByName.first.id;
        }
      }
    }
  }

  String _clientDisplayName(ClientModel client) {
    final name = client.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final contact = client.contactName.trim();
    if (contact.isNotEmpty) {
      return contact;
    }
    return 'Unnamed Client';
  }

  String _readError(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      final message = error.message?.trim() ?? '';
      if (message.isNotEmpty) {
        return message;
      }
    }
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? fallback : message;
  }

  void _showSnack({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insetBottom = MediaQuery.of(context).viewInsets.bottom;
    final compact = MediaQuery.of(context).size.width <= 440;
    final vendorName = _vendors
        .firstWhere(
          (entry) => entry.id == _selectedVendorId,
          orElse: () => const VendorModel(
            id: '',
            vendorName: 'N/A',
            email: '',
            contactNo: '',
            address: '',
            status: 'Inactive',
            createdAt: '',
            updatedAt: '',
          ),
        )
        .vendorName;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: insetBottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            14,
            compact ? 12 : 16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SERVICE FORM',
                style: AppTextStyles.style(
                  color: const Color(0xFF334155),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE6F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isEditMode ? 'Edit Service' : 'Add Services',
                            style: AppTextStyles.style(
                              color: const Color(0xFF1E293B),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_isLoadingOptions || _isLoadingDetail)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormLabel(text: 'Select Client', required: true),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value:
                          _clients.any((entry) => entry.id == _selectedClientId)
                          ? _selectedClientId
                          : null,
                      items: _clients
                          .map(
                            (client) => DropdownMenuItem<String>(
                              value: client.id,
                              child: Text(_clientDisplayName(client)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _isSubmitting
                          ? null
                          : (value) =>
                                setState(() => _selectedClientId = value),
                      decoration: _inputDecoration('Choose a client...'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Services',
                          style: AppTextStyles.style(
                            color: const Color(0xFF334155),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _isSubmitting ? null : _resetServiceFields,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Another Service'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 10 : 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDCE6F2)),
                      ),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 760;
                              final itemWidth = isWide
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Vendor',
                                      required: true,
                                      child: DropdownButtonFormField<String>(
                                        value:
                                            _vendors.any(
                                              (entry) =>
                                                  entry.id == _selectedVendorId,
                                            )
                                            ? _selectedVendorId
                                            : null,
                                        items: _vendors
                                            .map(
                                              (
                                                vendor,
                                              ) => DropdownMenuItem<String>(
                                                value: vendor.id,
                                                child: Text(
                                                  vendor.vendorName
                                                          .trim()
                                                          .isEmpty
                                                      ? 'Vendor #${vendor.id}'
                                                      : vendor.vendorName,
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                        onChanged: _isSubmitting
                                            ? null
                                            : (value) => setState(
                                                () => _selectedVendorId = value,
                                              ),
                                        decoration: _inputDecoration(
                                          'Choose a vendor...',
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Service Name',
                                      required: true,
                                      child: TextField(
                                        controller: _serviceNameController,
                                        decoration: _inputDecoration(
                                          'Enter service name',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          _LabeledField(
                            label: 'Service Details',
                            child: TextField(
                              controller: _serviceDetailsController,
                              maxLines: 4,
                              decoration: _inputDecoration(
                                'Enter detailed description of the service...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 760;
                              final itemWidth = isWide
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Remark Text',
                                      child: TextField(
                                        controller: _remarkTextController,
                                        decoration: _inputDecoration(
                                          'Example: IMP',
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Remark Color',
                                      child: DropdownButtonFormField<String>(
                                        value:
                                            _remarkColors.contains(
                                              _selectedRemarkColor,
                                            )
                                            ? _selectedRemarkColor
                                            : null,
                                        items: _remarkColors
                                            .map(
                                              (entry) =>
                                                  DropdownMenuItem<String>(
                                                    value: entry,
                                                    child: Text(
                                                      entry[0].toUpperCase() +
                                                          entry.substring(1),
                                                    ),
                                                  ),
                                            )
                                            .toList(growable: false),
                                        onChanged: _isSubmitting
                                            ? null
                                            : (value) => setState(
                                                () => _selectedRemarkColor =
                                                    value,
                                              ),
                                        decoration: _inputDecoration(
                                          'Choose a color...',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 900;
                              final itemWidth = isWide
                                  ? (constraints.maxWidth - 36) / 4
                                  : (constraints.maxWidth - 12) / 2;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Start Date',
                                      required: true,
                                      child: _DateInputField(
                                        text: _formatDate(_startDate),
                                        onTap: _isSubmitting
                                            ? null
                                            : () => _pickDate(
                                                initialDate: _startDate,
                                                onPicked: (date) => setState(
                                                  () => _startDate = date,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'End Date',
                                      required: true,
                                      child: _DateInputField(
                                        text: _formatDate(_endDate),
                                        onTap: _isSubmitting
                                            ? null
                                            : () => _pickDate(
                                                initialDate: _endDate,
                                                onPicked: (date) => setState(
                                                  () => _endDate = date,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Billing Date',
                                      required: true,
                                      child: _DateInputField(
                                        text: _formatDate(_billingDate),
                                        onTap: _isSubmitting
                                            ? null
                                            : () => _pickDate(
                                                initialDate: _billingDate,
                                                onPicked: (date) => setState(
                                                  () => _billingDate = date,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _LabeledField(
                                      label: 'Status',
                                      required: true,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedStatus,
                                        items: _statusValues
                                            .map(
                                              (entry) =>
                                                  DropdownMenuItem<String>(
                                                    value: entry,
                                                    child: Text(
                                                      entry[0].toUpperCase() +
                                                          entry.substring(1),
                                                    ),
                                                  ),
                                            )
                                            .toList(growable: false),
                                        onChanged: _isSubmitting
                                            ? null
                                            : (value) {
                                                if (value == null) return;
                                                setState(
                                                  () => _selectedStatus = value,
                                                );
                                              },
                                        decoration: _inputDecoration('Status'),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D8BFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save Services'),
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              side: const BorderSide(color: Color(0xFFDCE6F2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDCE6F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1D8BFF)),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTextStyles.style(
          color: const Color(0xFF334155),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ]
            : const [],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(text: label, required: required),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DateInputField extends StatelessWidget {
  const _DateInputField({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE6F2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.style(
                  color: text == 'dd-mm-yyyy'
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.renewal,
    required this.title,
    required this.client,
    required this.vendor,
    required this.startDate,
    required this.endDate,
    required this.billing,
    required this.status,
    required this.expiryNote,
    this.showExpiryAlert = false,
  });

  final RenewalModel renewal;
  final String title;
  final String client;
  final String vendor;
  final String startDate;
  final String endDate;
  final String billing;
  final String status;
  final String expiryNote;
  final bool showExpiryAlert;

  factory _ServiceItem.fromRenewal(RenewalModel renewal) {
    return _ServiceItem(
      renewal: renewal,
      title: renewal.title,
      client: renewal.client,
      vendor: renewal.vendor,
      startDate: _orFallback(renewal.startDate, 'N/A'),
      endDate: _orFallback(renewal.endDate, 'N/A'),
      billing: _orFallback(renewal.billing, 'N/A'),
      status: _orFallback(renewal.status, 'Unknown'),
      expiryNote: _orFallback(renewal.expiryNote, 'Renewal due soon'),
      showExpiryAlert: renewal.showExpiryAlert,
    );
  }

  static String _orFallback(String value, String fallback) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }
}
