import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

/// Projects overview screen inspired by the provided mockup.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1D6FEA),
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.projects,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final horizontalPadding = isCompact ? 16.0 : 20.0;
            final maxWidth = constraints.maxWidth > 560 ? 560.0 : double.infinity;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                120,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ProjectsHeader(),
                      const SizedBox(height: 18),
                      _SummaryRow(isCompact: isCompact),
                      const SizedBox(height: 20),
                      const _TeamWorkloadSection(),
                      const SizedBox(height: 16),
                      const _SearchField(),
                      const SizedBox(height: 12),
                      const _FilterRow(),
                      const SizedBox(height: 16),
                      ..._projectCards.map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ProjectCard(data: card),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProjectsHeader extends StatelessWidget {
  const _ProjectsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects',
                style: AppTextStyles.style(
                  color: const Color(0xFF1E2A3B),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Enterprise Management System',
                style: AppTextStyles.style(
                  color: const Color(0xFF76839A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD9C4),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110F172A),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'UI',
            style: AppTextStyles.style(
              color: const Color(0xFF1E2A3B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF2D3B52), size: 22),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF4F5D74),
            value: '48',
            label: 'Total Projects',
            percent: '0%',
            accent: const Color(0xFF4F5D74),
            isCompact: isCompact,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF8B5CF6),
            value: '8',
            label: 'Planning',
            percent: '5%',
            accent: const Color(0xFF8B5CF6),
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.percent,
    required this.accent,
    required this.isCompact,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String percent;
  final Color accent;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 18,
        isCompact ? 16 : 18,
        isCompact ? 14 : 18,
        isCompact ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                percent,
                style: AppTextStyles.style(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.style(
              color: const Color(0xFF1E2A3B),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.style(
              color: const Color(0xFF7C8BA1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamWorkloadSection extends StatelessWidget {
  const _TeamWorkloadSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Team Workload',
              style: AppTextStyles.style(
                color: const Color(0xFF1E2A3B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              'View All',
              style: AppTextStyles.style(
                color: const Color(0xFF1D6FEA),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final member = _teamMembers[index];
              return _TeamMemberCard(member: member);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: _teamMembers.length,
          ),
        ),
      ],
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({required this.member});

  final _TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: member.avatarColor.withOpacity(0.18),
              child: Text(
                member.initials,
                style: AppTextStyles.style(
                  color: member.avatarColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D6FEA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  member.count.toString(),
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: member.statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          member.name,
          style: AppTextStyles.style(
            color: const Color(0xFF4C5B70),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF9AA7B7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search projects, clients...',
              style: AppTextStyles.style(
                color: const Color(0xFF8A98AD),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'Project Status',
          icon: Icons.keyboard_arrow_down_rounded,
        ),
        const SizedBox(width: 10),
        _FilterChip(
          label: 'Show: 10 entries',
          icon: Icons.keyboard_arrow_down_rounded,
        ),
        const SizedBox(width: 10),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E8F2)),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.tune_rounded, color: Color(0xFF586A82)),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF2F3D52),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: const Color(0xFF5F7087)),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.data});

  final _ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Get.toNamed(AppRoutes.projectDetail),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E9F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 170,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.title,
                              style: AppTextStyles.style(
                                color: const Color(0xFF1E2A3B),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: data.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              data.status,
                              style: AppTextStyles.style(
                                color: data.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.client,
                        style: AppTextStyles.style(
                          color: const Color(0xFF76839A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _ProjectInfoItem(
                            icon: Icons.calendar_today_rounded,
                            label: data.startDate,
                          ),
                          const SizedBox(width: 20),
                          _ProjectInfoItem(
                            icon: Icons.event_rounded,
                            label: data.deadline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Progress',
                                      style: AppTextStyles.style(
                                        color: const Color(0xFF76839A),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${(data.progress * 100).toInt()}%',
                                      style: AppTextStyles.style(
                                        color: const Color(0xFF1E2A3B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: data.progress,
                                    backgroundColor: const Color(0xFFF0F4F9),
                                    valueColor: AlwaysStoppedAnimation(data.accentColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          SizedBox(
                            height: 32,
                            width: 60,
                            child: Stack(
                              children: [
                                for (var i = 0; i < 3; i++)
                                  Positioned(
                                    left: i * 14.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: [
                                          const Color(0xFF1D6FEA),
                                          const Color(0xFF8B5CF6),
                                          const Color(0xFF10B981),
                                        ][i],
                                        child: Text(
                                          ['S', 'A', 'M'][i],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectInfoItem extends StatelessWidget {
  const _ProjectInfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9AA7B7)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF586A82),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TeamMember {
  const _TeamMember({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.statusColor,
    required this.count,
  });

  final String name;
  final String initials;
  final Color avatarColor;
  final Color statusColor;
  final int count;
}

const _teamMembers = [
  _TeamMember(
    name: 'Sarah',
    initials: 'SK',
    avatarColor: Color(0xFF1D6FEA),
    statusColor: Color(0xFF10B981),
    count: 3,
  ),
  _TeamMember(
    name: 'Alex',
    initials: 'AM',
    avatarColor: Color(0xFF8B5CF6),
    statusColor: Color(0xFF10B981),
    count: 5,
  ),
  _TeamMember(
    name: 'Mike',
    initials: 'MJ',
    avatarColor: Color(0xFFF59E0B),
    statusColor: Color(0xFFF59E0B),
    count: 2,
  ),
  _TeamMember(
    name: 'Jane',
    initials: 'JD',
    avatarColor: Color(0xFF10B981),
    statusColor: Color(0xFF10B981),
    count: 4,
  ),
];

class _ProjectCardData {
  const _ProjectCardData({
    required this.title,
    required this.client,
    required this.status,
    required this.startDate,
    required this.deadline,
    required this.progress,
    required this.accentColor,
  });

  final String title;
  final String client;
  final String status;
  final String startDate;
  final String deadline;
  final double progress;
  final Color accentColor;
}

const _projectCards = [
  _ProjectCardData(
    title: 'Acme Brand Refresh',
    client: 'Acme Corporation',
    status: 'In Progress',
    startDate: '12 Jan 2026',
    deadline: '28 Mar 2026',
    progress: 0.65,
    accentColor: Color(0xFF1D6FEA),
  ),
  _ProjectCardData(
    title: 'Mobile App Design',
    client: 'Global Tech Solutions',
    status: 'Planning',
    startDate: '05 Feb 2026',
    deadline: '15 May 2026',
    progress: 0.15,
    accentColor: Color(0xFF8B5CF6),
  ),
  _ProjectCardData(
    title: 'Website Development',
    client: 'EcoFriendly Inc.',
    status: 'On Hold',
    startDate: '20 Nov 2025',
    deadline: '10 Feb 2026',
    progress: 0.82,
    accentColor: Color(0xFFF59E0B),
  ),
];

