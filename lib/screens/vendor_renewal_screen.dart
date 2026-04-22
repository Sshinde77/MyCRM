import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_text_styles.dart';
import '../models/renewal_model.dart';
import '../providers/renewal_list_provider.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../screens/vendor_renewal_form_screen.dart';
import '../widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class VendorRenewalScreen extends StatelessWidget {
  const VendorRenewalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RenewalListProvider>(
      create: (_) =>
          RenewalListProvider(type: RenewalType.vendor)..loadRenewals(),
      child: const _VendorRenewalBody(),
    );
  }
}

class _VendorRenewalBody extends StatefulWidget {
  const _VendorRenewalBody();

  @override
  State<_VendorRenewalBody> createState() => _VendorRenewalBodyState();
}

class _VendorRenewalBodyState extends State<_VendorRenewalBody>
    with WidgetsBindingObserver {
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

  Future<void> _openDetail(RenewalModel renewal) async {
    await Get.toNamed(AppRoutes.vendorRenewalDetail, arguments: renewal);
    if (!mounted) {
      return;
    }
    await _refreshRenewals();
  }

  Future<void> _openServiceForm({RenewalModel? renewal}) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VendorRenewalFormScreen(initialRenewal: renewal),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _refreshRenewals();
    }
  }

  Future<void> _deleteRenewal(RenewalModel renewal) async {
    final renewalId = renewal.id.trim();
    if (kDebugMode) {
      debugPrint('Vendor renewal delete tapped: id=$renewalId');
    }
    if (renewalId.isEmpty) {
      if (kDebugMode) {
        debugPrint('Vendor renewal delete blocked: missing id');
      }
      AppSnackbar.show('Delete failed', 'Invalid vendor service id.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Vendor Service'),
          content: Text(
            'Are you sure you want to delete "${renewal.title.trim().isEmpty ? 'this vendor service' : renewal.title}"?',
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
      if (kDebugMode) {
        debugPrint('Vendor renewal delete cancelled: id=$renewalId');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('Vendor renewal delete API start: id=$renewalId');
      }
      await ApiService.instance.deleteVendorRenewal(renewalId);
      if (kDebugMode) {
        debugPrint('Vendor renewal delete API success: id=$renewalId');
      }
      if (!mounted) {
        return;
      }
      await _refreshRenewals();
      if (!mounted) {
        return;
      }
      AppSnackbar.show('Deleted', 'Vendor service deleted successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      String message = 'Failed to delete vendor service.';
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
      if (kDebugMode) {
        debugPrint('Vendor renewal delete API failed: id=$renewalId');
        debugPrint('Vendor renewal delete error: $error');
        debugPrint('Vendor renewal delete message: $message');
      }

      AppSnackbar.show('Delete failed', message);
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
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(side, compact ? 16 : 18, side, 18),
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
                        _RenewalListSection(
                          compact: compact,
                          onView: (renewal) => _openDetail(renewal),
                          onEdit: (renewal) =>
                              _openServiceForm(renewal: renewal),
                          onDelete: (renewal) => _deleteRenewal(renewal),
                        ),
                      ],
                    ),
                  ),
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
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final bool compact;
  final ValueChanged<RenewalModel> onView;
  final ValueChanged<RenewalModel> onEdit;
  final ValueChanged<RenewalModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Consumer<RenewalListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.renewals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.errorMessage != null && provider.renewals.isEmpty) {
          return _ErrorCard(
            compact: compact,
            message: provider.errorMessage!,
            onRetry: () => context.read<RenewalListProvider>().loadRenewals(
              forceRefresh: true,
            ),
          );
        }

        if (provider.renewals.isEmpty) {
          return _EmptyCard(compact: compact);
        }

        return Column(
          children: provider.renewals
              .map((renewal) => _ServiceItem.fromRenewal(renewal))
              .map(
                (service) => Padding(
                  padding: EdgeInsets.only(bottom: compact ? 14 : 16),
                  child: _ServiceCard(
                    service: service,
                    compact: compact,
                    onView: () => onView(service.renewal),
                    onEdit: () => onEdit(service.renewal),
                    onDelete: () => onDelete(service.renewal),
                  ),
                ),
              )
              .toList(growable: false),
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
        title: 'Vendor Renewal',
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
              'Add New Vendor',
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
                            'VENDOR DETAILS',
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
                  icon: Icons.storefront_outlined,
                  text: 'Vendor: ${service.vendor}',
                  compact: compact,
                ),
                SizedBox(height: compact ? 10 : 12),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: 'Client: ${service.client}',
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
            'Unable to load vendor renewals',
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
        'No vendor renewals available.',
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: compact ? 14 : 15,
          fontWeight: FontWeight.w600,
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
