import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_text_styles.dart';
import '../core/services/permission_service.dart';
import '../models/lead_model.dart';
import '../providers/lead_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

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
    const Color textDark = Color(0xFF1E2A3B);
    const Color textLight = Color(0xFF76839A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Consumer<LeadProvider>(
          builder: (context, leadProvider, _) {
            return RefreshIndicator(
              onRefresh: () async {
                await leadProvider.loadLeads(
                  forceRefresh: true,
                  page: 1,
                  search: leadProvider.searchQuery,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 380;
                  final horizontalPadding = isCompact ? 16.0 : 20.0;
                  final leads = leadProvider.leads;
                  final totalPages = leadProvider.lastPage < 1
                      ? 1
                      : leadProvider.lastPage;
                  final safeCurrentPage = leadProvider.currentPage < 1
                      ? 1
                      : leadProvider.currentPage;

                  return ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 12,
                    ),
                    children: [
                      CommonTopBar(title: 'Leads', compact: isCompact),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Total Leads',
                              value: '${leadProvider.totalLeads}',
                              icon: Icons.groups_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'New Leads',
                              value: '${leadProvider.newLeadsCount}',
                              icon: Icons.new_label_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) async {
                                  await leadProvider.loadLeads(
                                    forceRefresh: true,
                                    page: 1,
                                    search: _searchController.text.trim(),
                                  );
                                },
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
                                          onPressed: () async {
                                            _searchController.clear();
                                            await leadProvider.loadLeads(
                                              forceRefresh: true,
                                              page: 1,
                                              search: '',
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: textLight,
                                          ),
                                        ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: leadProvider.isLoading
                                  ? null
                                  : () async {
                                      await leadProvider.loadLeads(
                                        forceRefresh: true,
                                        page: 1,
                                        search: _searchController.text.trim(),
                                      );
                                    },
                              icon: const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: leadProvider.isLoading
                                  ? null
                                  : () => leadProvider.loadLeads(
                                      forceRefresh: true,
                                      page: 1,
                                      search: leadProvider.searchQuery,
                                    ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Refresh'),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: PermissionGate(
                              permission: AppPermission.createLeads,
                              child: ElevatedButton.icon(
                                onPressed: () => Get.toNamed(AppRoutes.addLead),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Add New Lead'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2CB1FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
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
                                : () => leadProvider.loadLeads(
                                    forceRefresh: true,
                                    page: 1,
                                    search: leadProvider.searchQuery,
                                  ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Text(
                                //   'Reload',
                                //   style: AppTextStyles.style(
                                //     color: primaryBlue,
                                //     fontSize: 13,
                                //     fontWeight: FontWeight.w600,
                                //   ),
                                // ),
                                // const Icon(
                                //   Icons.arrow_forward_rounded,
                                //   size: 16,
                                //   color: primaryBlue,
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (leadProvider.isLoading &&
                          leadProvider.totalLeads == 0)
                        const _LeadListLoading()
                      else if (leadProvider.errorMessage != null &&
                          leadProvider.totalLeads == 0)
                        _LeadListError(
                          message: leadProvider.errorMessage!,
                          onRetry: () => leadProvider.loadLeads(
                            forceRefresh: true,
                            page: 1,
                            search: leadProvider.searchQuery,
                          ),
                        )
                      else if (leadProvider.leads.isEmpty)
                        _LeadListEmpty(
                          hasQuery: leadProvider.searchQuery.trim().isNotEmpty,
                        )
                      else
                        ..._buildLeadCards(
                          leadProvider: leadProvider,
                          leads: leads,
                        ),
                      if (leadProvider.leads.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PaginationBar(
                          compact: isCompact,
                          currentPage: safeCurrentPage,
                          totalPages: totalPages,
                          onPageTap: (page) => leadProvider.loadLeads(
                            forceRefresh: true,
                            page: page,
                            search: leadProvider.searchQuery,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteLead(
    BuildContext context,
    LeadProvider leadProvider,
    LeadModel lead,
  ) async {
    final id = lead.id.trim();
    if (id.isEmpty) {
      AppSnackbar.show('Delete failed', 'Lead id is missing.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Lead'),
          content: Text(
            'Delete ${lead.displayName.isEmpty ? 'this lead' : lead.displayName} permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await leadProvider.deleteLead(id);
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        'Lead deleted',
        '${lead.displayName.isEmpty ? 'Lead' : lead.displayName} was deleted successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(
        'Delete failed',
        leadProvider.errorMessage ?? error.toString(),
      );
    }
  }

  List<Widget> _buildLeadCards({
    required LeadProvider leadProvider,
    required List<LeadModel> leads,
  }) {
    return [
      for (var index = 0; index < leads.length; index++) ...[
        _LeadCard(
          lead: leads[index],
          isDeleting: leadProvider.isDeletingLead(leads[index].id),
          onDelete: () => _deleteLead(context, leadProvider, leads[index]),
        ),
        if (index != leads.length - 1) const SizedBox(height: 16),
      ],
    ];
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.compact,
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  final bool compact;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final tokens = _buildPageTokens(currentPage, totalPages);
    final canGoPrev = currentPage > 1;
    final canGoNext = currentPage < totalPages;

    return Padding(
      padding: EdgeInsets.only(top: compact ? 6 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationArrowButton(
            compact: compact,
            icon: Icons.chevron_left_rounded,
            enabled: canGoPrev,
            onTap: () => onPageTap(currentPage - 1),
          ),
          SizedBox(width: compact ? 10 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tokens
                .map((token) {
                  if (token == null) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2 : 4,
                        vertical: compact ? 8 : 9,
                      ),
                      child: Text(
                        '...',
                        style: AppTextStyles.style(
                          color: const Color(0xFF64748B),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final selected = token == currentPage;
                  return InkWell(
                    onTap: () => onPageTap(token),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: compact ? 34 : 36,
                      height: compact ? 34 : 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF122B52)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$token',
                        style: AppTextStyles.style(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF334155),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          SizedBox(width: compact ? 10 : 12),
          _PaginationArrowButton(
            compact: compact,
            icon: Icons.chevron_right_rounded,
            enabled: canGoNext,
            onTap: () => onPageTap(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<int?> _buildPageTokens(int current, int total) {
    if (total <= 7) {
      return List<int?>.generate(total, (index) => index + 1);
    }

    final tokens = <int?>[1];
    var start = current - 1;
    var end = current + 1;

    if (current <= 3) {
      start = 2;
      end = 4;
    } else if (current >= total - 2) {
      start = total - 3;
      end = total - 1;
    } else {
      start = start < 2 ? 2 : start;
      end = end > total - 1 ? total - 1 : end;
    }

    if (start > 2) {
      tokens.add(null);
    }
    for (var page = start; page <= end; page += 1) {
      tokens.add(page);
    }
    if (end < total - 1) {
      tokens.add(null);
    }
    tokens.add(total);
    return tokens;
  }
}

class _PaginationArrowButton extends StatelessWidget {
  const _PaginationArrowButton({
    required this.compact,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final bool compact;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: compact ? 34 : 40,
        height: compact ? 34 : 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE6F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: compact ? 20 : 22,
          color: enabled ? const Color(0xFF122B52) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;
        final labelFontSize = isCompact ? 10.0 : 11.0;
        final valueFontSize = isCompact ? 17.0 : 18.0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFF33A1FF), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E2A3B),
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.style(
                  color: const Color(0xFF76839A),
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.onDelete,
    this.isDeleting = false,
  });

  final LeadModel lead;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    const Color textLight = Color(0xFF76839A);
    const Color textDark = Color(0xFF1E2A3B);
    final statusColors = _statusColors(lead.displayStatus);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(AppRoutes.leadDetail, arguments: lead.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;
                  final statusBadge = Container(
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
                  );

                  final amountText = lead.displayAmount.isNotEmpty
                      ? Text(
                          lead.displayAmount,
                          style: AppTextStyles.style(
                            color: const Color(0xFF2CB1FF),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null;

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.displayName,
                          style: AppTextStyles.style(
                            color: textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lead.displayCompany,
                          style: AppTextStyles.style(
                            color: textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (amountText != null) amountText,
                            statusBadge,
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.displayName,
                              style: AppTextStyles.style(
                                color: textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              lead.displayCompany,
                              style: AppTextStyles.style(
                                color: textLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (amountText != null) ...[
                              amountText,
                              const SizedBox(height: 6),
                            ],
                            statusBadge,
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.mail_outline_rounded,
                          text: lead.displayEmail,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.language_rounded,
                          text: ((lead.source ?? '').trim().isNotEmpty)
                              ? lead.source!.trim()
                              : 'Website not available',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.call_outlined,
                          text: lead.displayPhone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.calendar_today_outlined,
                          text: _formatDate(lead.createdAt),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LeadAvatar(
                        name: lead.displayAssignedTo,
                        imageUrl: lead.avatarUrl,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned: ',
                        style: AppTextStyles.style(
                          color: textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          lead.displayAssignedTo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.style(
                            color: textDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionIcon(
                        icon: Icons.visibility_outlined,
                        onTap: () => Get.toNamed(
                          AppRoutes.leadDetail,
                          arguments: lead.id,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const PermissionGate(
                        permission: AppPermission.editLeads,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionIcon(icon: Icons.edit_outlined),
                            SizedBox(width: 10),
                          ],
                        ),
                      ),
                      PermissionGate(
                        permission: AppPermission.deleteLeads,
                        child: isDeleting
                            ? SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.red.shade400,
                                  ),
                                ),
                              )
                            : _ActionIcon(
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red.shade400,
                                onTap: onDelete,
                              ),
                      ),
                    ],
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
  const _LeadAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim() ?? '';
    if (trimmedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 10,
        backgroundImage: NetworkImage(trimmedUrl),
      );
    }

    return CircleAvatar(
      radius: 10,
      backgroundColor: const Color(0xFFDCE8F8),
      child: Text(
        _initials(name),
        style: AppTextStyles.style(
          color: const Color(0xFF2E5B9A),
          fontSize: 9,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 11,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(child: Icon(icon, size: 16, color: color)),
        ),
      ),
    );
  }
}

class _LeadListLoading extends StatelessWidget {
  const _LeadListLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [_LoadingCard(), SizedBox(height: 16), _LoadingCard()],
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
  const _LeadListError({required this.message, required this.onRetry});

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
  const _LeadStatusColors({required this.background, required this.foreground});

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
