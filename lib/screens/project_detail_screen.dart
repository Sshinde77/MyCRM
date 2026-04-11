import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key});

  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE1E8F2);
  static const Color title = Color(0xFF1E2740);
  static const Color muted = Color(0xFF6E7F98);
  static const Color blue = Color(0xFF3F7EF7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(),
              const SizedBox(height: 22),
              const _HeroCard(),
              const SizedBox(height: 24),
              const _ProgressCard(),
              const SizedBox(height: 22),
              const _StatsRow(),
              const SizedBox(height: 22),
              const _DescriptionCard(),
              const SizedBox(height: 22),
              const _ClientInfoCard(),
              const SizedBox(height: 20),
              const _SectionTabs(),
              const SizedBox(height: 22),
              const _EmployeeCard(
                name: 'Philip Hartman',
                role: 'Design Team • Lead',
                totalTime: '0h',
                avatarUrl: '',
                fallbackColor: Color(0xFF131B19),
              ),
              const SizedBox(height: 18),
              const _EmployeeCard(
                name: 'Sarah Jenkins',
                role: 'Dev Team • Backend',
                totalTime: '2.5h',
                avatarUrl: 'https://i.pravatar.cc/200?img=47',
                fallbackColor: Color(0xFFE6D2B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF5E6E86), size: 30),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Project Details',
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.notifications_none_rounded, color: Color(0xFF5E6E86), size: 29),
        const SizedBox(width: 14),
        const Icon(Icons.more_vert_rounded, color: Color(0xFF5E6E86), size: 29),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final compact = screenWidth < 400;

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: compact ? 8 : 10,
                  runSpacing: compact ? 8 : 10,
                  children: [
                    _Badge(
                      label: 'HIGH PRIORITY',
                      bgColor: const Color(0xFFFFE3E1),
                      fgColor: const Color(0xFFFF3B30),
                      compact: compact,
                    ),
                    _Badge(
                      label: 'IN PROGRESS',
                      bgColor: const Color(0xFFDDEBFF),
                      fgColor: const Color(0xFF2965F1),
                      compact: compact,
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Container(
                width: compact ? 50 : 62,
                height: compact ? 50 : 62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/200?img=12'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Laith Barrera',
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: compact ? 19 : 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFEDF2F7), height: 1),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(child: _DateBlock(label: 'Start Date', value: 'Oct 30, 1980')),
              SizedBox(width: 18),
              Expanded(child: _DateBlock(label: 'End Date', value: 'Mar 04, 2026')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Overall Progress',
                  style: AppTextStyles.style(
                    color: ProjectDetailScreen.title,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '75%',
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.75,
              minHeight: 14,
              backgroundColor: Color(0xFFE9EEF5),
              valueColor: AlwaysStoppedAnimation(Color(0xFF4A86F7)),
            ),
          ),
          const SizedBox(height: 36),
          const Row(
            children: [
              Expanded(child: _MiniStat(value: '15', label: 'DONE', bgColor: Color(0xFFEAFBF1), fgColor: Color(0xFF1DA95B))),
              SizedBox(width: 16),
              Expanded(child: _MiniStat(value: '5', label: 'ACTIVE', bgColor: Color(0xFFFFF4E8), fgColor: Color(0xFFF26A22))),
              SizedBox(width: 16),
              Expanded(child: _MiniStat(value: '2', label: 'LATE', bgColor: Color(0xFFFFEFF0), fgColor: Color(0xFFE03131))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return Row(
          children: [
            Expanded(
              child: _MetricInfoCard(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFF4A86F7),
                label: 'Time Spent',
                value: '4.1h',
                compact: compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricInfoCard(
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF22C55E),
                label: 'Income',
                value: 'Rs50,000',
                compact: compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricInfoCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFE03131),
                label: 'Loss',
                value: 'Rs3,200',
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Description',
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Full-scale digital transformation including performance-driven SEO strategies and a custom web application built with a modern tech stack.',
            style: AppTextStyles.style(
              color: ProjectDetailScreen.muted,
              fontSize: 14,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TechChip(label: 'Development'),
              _TechChip(label: 'SEO'),
              _TechChip(label: 'Vue.js', accent: true),
              _TechChip(label: 'Laravel', accent: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  const _ClientInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF4281F4), size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client Information',
                    style: AppTextStyles.style(
                      color: ProjectDetailScreen.title,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'ARNAV',
                    style: AppTextStyles.style(
                      color: ProjectDetailScreen.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          const _InfoRow(label: 'Contact Person', value: 'Arnav Singh'),
          const SizedBox(height: 18),
          const _InfoRow(label: 'Email', value: 'arnav@example.com'),
          const SizedBox(height: 18),
          const _InfoRow(label: 'Phone', value: '+91 98765 43210'),
          const SizedBox(height: 18),
          const _InfoRow(label: 'Address', value: 'B-402, Business Park,\nMumbai, MH'),
        ],
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tab('Employees', true),
          _tab('Tasks', false),
          _tab('Files', false),
          _tab('Usage', false),
          _tab('Milestones', false),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(right: 26),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: active ? ProjectDetailScreen.blue : const Color(0xFF62748D),
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: active ? 74 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: active ? ProjectDetailScreen.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final String name;
  final String role;
  final String totalTime;
  final String avatarUrl;
  final Color fallbackColor;

  const _EmployeeCard({
    required this.name,
    required this.role,
    required this.totalTime,
    required this.avatarUrl,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: fallbackColor,
              shape: BoxShape.circle,
              image: avatarUrl.isEmpty
                  ? null
                  : DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.style(
                    color: ProjectDetailScreen.title,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  role,
                  style: AppTextStyles.style(
                    color: ProjectDetailScreen.muted,
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
              Text(
                totalTime,
                style: AppTextStyles.style(
                  color: ProjectDetailScreen.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'TOTAL TIME',
                style: AppTextStyles.style(
                  color: const Color(0xFFA1AEC0),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color fgColor;
  final bool compact;

  const _Badge({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: fgColor,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  final String label;
  final String value;

  const _DateBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.style(
            color: ProjectDetailScreen.title,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color bgColor;
  final Color fgColor;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: fgColor.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.style(
              color: fgColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.style(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool compact;

  const _MetricInfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: compact ? 24 : 30),
          SizedBox(height: compact ? 14 : 18),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: ProjectDetailScreen.muted,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: compact ? 13 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  final bool accent;

  const _TechChip({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFEAF1FF) : const Color(0xFFF2F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: accent ? ProjectDetailScreen.blue : const Color(0xFF53657E),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.style(
              color: ProjectDetailScreen.muted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.style(
              color: ProjectDetailScreen.title,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: ProjectDetailScreen.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: ProjectDetailScreen.border),
    boxShadow: const [
      BoxShadow(
        color: Color(0x120F172A),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  );
}

