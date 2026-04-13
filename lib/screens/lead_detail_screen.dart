import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_text_styles.dart';
import '../models/lead_model.dart';
import '../providers/lead_detail_provider.dart';
import 'add_lead_screen.dart';

class LeadDetailScreen extends StatelessWidget {
  const LeadDetailScreen({super.key});

  static const Color background = Color(0xFFF5F8FC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE3EAF3);
  static const Color title = Color(0xFF1F2A44);
  static const Color muted = Color(0xFF7D8CA3);
  static const Color link = Color(0xFF3F7EF7);
  static const Color primary = Color(0xFF3E7DED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Consumer<LeadDetailProvider>(
          builder: (context, provider, _) {
            final lead = provider.lead;

            if (provider.isLoading && lead == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && lead == null) {
              return _LeadDetailError(
                message: provider.errorMessage!,
                onRetry: () => provider.loadLead(forceRefresh: true),
              );
            }

            if (lead == null) {
              return _LeadDetailError(
                message: 'Lead details are not available.',
                onRetry: () => provider.loadLead(forceRefresh: true),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadLead(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(titleText: lead.displayName),
                    const SizedBox(height: 18),
                    _ProfileCard(
                      lead: lead,
                      onEdit: () async {
                        final updated = await Get.to<bool>(
                          () => AddLeadScreen(leadId: lead.id),
                        );
                        if (updated == true && context.mounted) {
                          await context.read<LeadDetailProvider>().loadLead(
                            forceRefresh: true,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Lead Details',
                      child: _LeadDetailsContent(lead: lead),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.titleText});

  final String titleText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF5C6B82),
            size: 28,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: LeadDetailScreen.title,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.lead, required this.onEdit});

  final LeadModel lead;
  final Future<void> Function() onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LeadDetailScreen.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LeadDetailScreen.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadAvatar(name: lead.displayName, imageUrl: lead.avatarUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead.displayName,
                            style: AppTextStyles.style(
                              color: LeadDetailScreen.title,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusChip(status: lead.displayStatus),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.displayCompany,
                      style: AppTextStyles.style(
                        color: const Color(0xFF5D6C84),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      lead.displayEmail,
                      style: AppTextStyles.style(
                        color: const Color(0xFF98A6BD),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'LEAD VALUE',
                  value: lead.displayAmount.isEmpty
                      ? 'Not available'
                      : lead.displayAmount,
                  valueColor: LeadDetailScreen.link,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricTile(
                  label: 'ASSIGNED',
                  value: lead.displayAssignedTo,
                  valueColor: LeadDetailScreen.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: LeadDetailScreen.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 19),
              label: Text(
                'Edit Lead',
                style: AppTextStyles.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LeadDetailScreen.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LeadDetailScreen.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.style(
                      color: LeadDetailScreen.title,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F4F8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LeadDetailsContent extends StatelessWidget {
  const _LeadDetailsContent({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _DetailField(label: 'Name', value: lead.displayName),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _DetailField(label: 'Company', value: lead.displayCompany),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _DetailField(
                label: 'Position',
                value: lead.displayPosition,
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _DetailField(
                label: 'Source',
                value: lead.displaySource,
                valueColor: LeadDetailScreen.link,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DetailField(label: 'Address', value: lead.displayAddress),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _DetailField(
                label: 'City / State',
                value: lead.displayLocation,
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _DetailField(label: 'Country', value: lead.displayCountry),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DetailField(
                label: 'Zip Code',
                value: lead.displayZipCode,
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags',
                    style: AppTextStyles.style(
                      color: LeadDetailScreen.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (lead.tags.isEmpty)
                    Text(
                      'No tags',
                      style: AppTextStyles.style(
                        color: LeadDetailScreen.title,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lead.tags
                          .map((tag) => _TagChip(label: tag))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DetailField(
          label: 'Created Date',
          value: _formatDateTime(lead.createdAt),
        ),
        const SizedBox(height: 18),
        _DetailField(
          label: 'Description',
          value: lead.displayDescription,
          isMultiline: true,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF7084A0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.style(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = LeadDetailScreen.title,
    this.isMultiline = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: LeadDetailScreen.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.style(
            color: valueColor,
            fontSize: 14,
            height: isMultiline ? 1.7 : 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: const Color(0xFF4B5D78),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LeadAvatar extends StatelessWidget {
  const _LeadAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim() ?? '';
    if (trimmedUrl.isNotEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD9E7FF), width: 2),
          image: DecorationImage(
            image: NetworkImage(trimmedUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 32,
      backgroundColor: const Color(0xFFDCE8F8),
      child: Text(
        _initials(name),
        style: AppTextStyles.style(
          color: const Color(0xFF2E5B9A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    Color background = const Color(0xFFF1F5F9);
    Color foreground = const Color(0xFF475569);

    if (normalized.contains('new') || normalized.contains('initial')) {
      background = const Color(0xFFE0F2FE);
      foreground = const Color(0xFF0369A1);
    } else if (normalized.contains('won') || normalized.contains('closed')) {
      background = const Color(0xFFDCFCE7);
      foreground = const Color(0xFF15803D);
    } else if (normalized.contains('progress') ||
        normalized.contains('negotiation')) {
      background = const Color(0xFFFFF7ED);
      foreground = const Color(0xFFEA580C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.style(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LeadDetailError extends StatelessWidget {
  const _LeadDetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Color(0xFFB3261E),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.style(
                color: LeadDetailScreen.title,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Not available';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${months[value.month - 1]} ${value.day}, ${value.year} | $hour:$minute $suffix';
}
