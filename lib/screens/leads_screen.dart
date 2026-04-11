import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_text_styles.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../routes/app_routes.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<LeadProvider>().searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1D6FEA);
    const Color lightBlue = Color(0xFFE3F2FD);
    const Color textDark = Color(0xFF1E2A3B);
    const Color textLight = Color(0xFF76839A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Consumer<LeadProvider>(
          builder: (context, leadProvider, _) {
            return RefreshIndicator(
              onRefresh: () => leadProvider.loadLeads(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?u=shubham',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leads',
                              style: AppTextStyles.style(
                                color: textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Enterprise Dashboard',
                              style: AppTextStyles.style(
                                color: textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Stack(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: primaryBlue,
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Total Leads',
                          value: '${leadProvider.totalLeads}',
                          caption: 'Live records',
                          icon: Icons.groups_outlined,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          label: 'New Leads',
                          value: '${leadProvider.newLeadsCount}',
                          caption: 'Today or fresh status',
                          icon: Icons.new_label_outlined,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: leadProvider.updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search leads by name or ID...',
                        hintStyle: AppTextStyles.style(
                          color: textLight,
                          fontSize: 14,
                        ),
                        icon: const Icon(Icons.search, color: textLight),
                        suffixIcon: leadProvider.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  leadProvider.updateSearchQuery('');
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: textLight,
                                ),
                              ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: leadProvider.isLoading
                              ? null
                              : () => leadProvider.loadLeads(forceRefresh: true),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: const Text('Add New Lead'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2CB1FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT LEADS',
                        style: AppTextStyles.style(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      TextButton(
                        onPressed: leadProvider.isLoading
                            ? null
                            : () => leadProvider.loadLeads(forceRefresh: true),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Reload',
                              style: AppTextStyles.style(
                                color: primaryBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (leadProvider.isLoading && leadProvider.totalLeads == 0)
                    const _LeadListLoading()
                  else if (leadProvider.errorMessage != null &&
                      leadProvider.totalLeads == 0)
                    _LeadListError(
                      message: leadProvider.errorMessage!,
                      onRetry: () => leadProvider.loadLeads(forceRefresh: true),
                    )
                  else if (leadProvider.leads.isEmpty)
                    _LeadListEmpty(
                      hasQuery: leadProvider.searchQuery.trim().isNotEmpty,
                    )
                  else
                    ..._buildLeadCards(leadProvider.leads),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildLeadCards(List<LeadModel> leads) {
    return [
      for (var index = 0; index < leads.length; index++) ...[
        _LeadCard(lead: leads[index]),
        if (index != leads.length - 1) const SizedBox(height: 16),
      ],
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFF33A1FF), size: 24),
              Text(
                caption,
                textAlign: TextAlign.end,
                style: AppTextStyles.style(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF76839A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.style(
              color: const Color(0xFF1E2A3B),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    const Color textLight = Color(0xFF76839A);
    const Color textDark = Color(0xFF1E2A3B);
    final statusColors = _statusColors(lead.displayStatus);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Get.toNamed(AppRoutes.leadDetail, arguments: lead.id),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          lead.displayId,
                          style: AppTextStyles.style(
                            color: const Color(0xFF2CB1FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead.displayName,
                          style: AppTextStyles.style(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          lead.displayCompany,
                          style: AppTextStyles.style(
                            color: textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (lead.displayAmount.isNotEmpty) ...[
                        Text(
                          lead.displayAmount,
                          style: AppTextStyles.style(
                            color: const Color(0xFF2CB1FF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lead.displayStatus.toUpperCase(),
                          style: AppTextStyles.style(
                            color: statusColors.foreground,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _IconInfoRow(
                      icon: Icons.mail_outline_rounded,
                      text: lead.displayEmail,
                    ),
                  ),
                  Expanded(
                    child: _IconInfoRow(
                      icon: Icons.share_outlined,
                      text: ((lead.source ?? '').trim().isNotEmpty)
                          ? lead.source!.trim()
                          : 'Source not available',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _IconInfoRow(
                      icon: Icons.call_outlined,
                      text: lead.displayPhone,
                    ),
                  ),
                  Expanded(
                    child: _IconInfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: _formatDate(lead.createdAt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _LeadAvatar(
                    name: lead.displayAssignedTo,
                    imageUrl: lead.avatarUrl,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned: ',
                    style: AppTextStyles.style(
                      color: textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lead.displayAssignedTo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.style(
                        color: textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _ActionIcon(
                    icon: Icons.visibility_outlined,
                    onTap: () => Get.toNamed(AppRoutes.leadDetail, arguments: lead.id),
                  ),
                  const SizedBox(width: 12),
                  const _ActionIcon(icon: Icons.edit_outlined),
                  const SizedBox(width: 12),
                  _ActionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _LeadStatusColors _statusColors(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('won') || normalized.contains('closed')) {
      return const _LeadStatusColors(
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF15803D),
      );
    }
    if (normalized.contains('new') || normalized.contains('initial')) {
      return const _LeadStatusColors(
        background: Color(0xFFE0F2FE),
        foreground: Color(0xFF0369A1),
      );
    }
    if (normalized.contains('negotiation') || normalized.contains('progress')) {
      return const _LeadStatusColors(
        background: Color(0xFFFFF7ED),
        foreground: Color(0xFFEA580C),
      );
    }
    return const _LeadStatusColors(
      background: Color(0xFFF1F5F9),
      foreground: Color(0xFF475569),
    );
  }
}

class _LeadAvatar extends StatelessWidget {
  const _LeadAvatar({
    required this.name,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim() ?? '';
    if (trimmedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(trimmedUrl),
      );
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: const Color(0xFFDCE8F8),
      child: Text(
        _initials(name),
        style: AppTextStyles.style(
          color: const Color(0xFF2E5B9A),
          fontSize: 10,
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

class _IconInfoRow extends StatelessWidget {
  const _IconInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    this.color = const Color(0xFF64748B),
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _LeadListLoading extends StatelessWidget {
  const _LeadListLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LoadingCard(),
        SizedBox(height: 16),
        _LoadingCard(),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _LeadListError extends StatelessWidget {
  const _LeadListError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: Color(0xFFB3261E),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load leads',
            style: AppTextStyles.style(
              color: const Color(0xFF1E2A3B),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2CB1FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LeadListEmpty extends StatelessWidget {
  const _LeadListEmpty({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_search_rounded,
            size: 36,
            color: Color(0xFF2CB1FF),
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery ? 'No matching leads' : 'No leads found',
            style: AppTextStyles.style(
              color: const Color(0xFF1E2A3B),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery
                ? 'Try a different name, id, or company search.'
                : 'The API returned an empty lead list for this account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadStatusColors {
  const _LeadStatusColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return 'Date not available';
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

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
