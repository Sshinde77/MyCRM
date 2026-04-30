import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_text_styles.dart';
import '../models/lead_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/common_screen_app_bar.dart';
import 'book_a_call.dart';
import 'google_ads_screen.dart';

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {
  final ApiService _apiService = ApiService.instance;

  bool _isLoading = true;
  String? _error;
  List<_LeadSummaryCardData> _cards = const <_LeadSummaryCardData>[];
  List<LeadModel> _recentLeads = const <LeadModel>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = await _apiService.getLeadsDashboard();
      final cards = <_LeadSummaryCardData>[
        _LeadSummaryCardData(
          title: 'Book a Call',
          todayCount: dashboard.bookCallsCount.todayCount,
          totalCount: dashboard.bookCallsCount.totalCount,
          icon: Icons.phone_in_talk_rounded,
          color: const Color(0xFF4F46E5),
          onTap: () {
            Get.to(() => const BookACallScreen());
          },
        ),
        _LeadSummaryCardData(
          title: 'Digital Marketing',
          todayCount: dashboard.digitalMarketingLeadsCount.todayCount,
          totalCount: dashboard.digitalMarketingLeadsCount.totalCount,
          icon: Icons.campaign_rounded,
          color: const Color(0xFF7C3AED),
          onTap: () {
            Get.to(() => const GoogleAdsScreen());
          },
        ),
        _LeadSummaryCardData(
          title: 'Web & App',
          todayCount: dashboard.webAppLeadsCount.todayCount,
          totalCount: dashboard.webAppLeadsCount.totalCount,
          icon: Icons.code_rounded,
          color: const Color(0xFF2563EB),
          onTap: () {
            Get.to(() => const GoogleAdsScreen());
          },
        ),
        _LeadSummaryCardData(
          title: 'Leads',
          todayCount: dashboard.leadsCount.todayCount,
          totalCount: dashboard.leadsCount.totalCount,
          icon: Icons.groups_rounded,
          color: const Color(0xFF4F46E5),
          onTap: () {
            Get.toNamed(AppRoutes.leads);
          },
        ),
      ];

      if (!mounted) return;
      setState(() {
        _cards = cards;
        _recentLeads = dashboard.recentLeads.take(6).toList(growable: false);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load lead overview.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sectionWidth = (width - 32).clamp(280.0, 390.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
            children: [
              const CommonTopBar(title: 'Lead'),
              const SizedBox(height: 10),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorBox(message: _error!, onRetry: _loadData)
              else ...[
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: sectionWidth,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.35,
                          ),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return _LeadSummaryCard(card: card);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Recent Leads',
                  style: AppTextStyles.style(
                    color: const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_recentLeads.isEmpty)
                  const _EmptyRecentLeads()
                else
                  ..._recentLeads.map(
                    (lead) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RecentLeadCard(lead: lead),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.leads,
      ),
    );
  }
}

class _LeadSummaryCardData {
  const _LeadSummaryCardData({
    required this.title,
    required this.todayCount,
    required this.totalCount,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int todayCount;
  final int totalCount;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _LeadSummaryCard extends StatelessWidget {
  const _LeadSummaryCard({required this.card});

  final _LeadSummaryCardData card;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: card.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E7EB)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: card.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(card.icon, color: Colors.white, size: 17),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          card.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.style(
                            color: const Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${card.todayCount} Today',
                    style: AppTextStyles.style(
                      color: const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Total: ${card.totalCount}',
                        style: AppTextStyles.style(
                          color: const Color(0xFF334155),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFF4F46E5),
                        size: 13,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentLeadCard extends StatelessWidget {
  const _RecentLeadCard({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.leadDetail, arguments: lead.id),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE8F1FF),
              child: Text(
                lead.displayName.isEmpty
                    ? '?'
                    : lead.displayName[0].toUpperCase(),
                style: AppTextStyles.style(
                  color: const Color(0xFF1D6FEA),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _RecentLeadInfoRow(
                    icon: Icons.email_outlined,
                    text: lead.displayEmail,
                  ),
                  const SizedBox(height: 2),
                  _RecentLeadInfoRow(
                    icon: Icons.phone_outlined,
                    text: lead.displayPhone,
                  ),
                  const SizedBox(height: 2),
                  _RecentLeadInfoRow(
                    icon: Icons.label_outline_rounded,
                    text: lead.displayLeadType,
                    textColor: const Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentLeadInfoRow extends StatelessWidget {
  const _RecentLeadInfoRow({
    required this.icon,
    required this.text,
    this.textColor = const Color(0xFF64748B),
    this.fontWeight = FontWeight.w500,
  });

  final IconData icon;
  final String text;
  final Color textColor;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: textColor,
              fontSize: 11,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRecentLeads extends StatelessWidget {
  const _EmptyRecentLeads();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        'No recent leads found.',
        style: AppTextStyles.style(
          color: const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTextStyles.style(
              color: const Color(0xFF9A3412),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
