import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';
import '../widgets/app_bottom_navigation.dart';

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
      bottomNavigationBar: MagicBottomNavigation(
        items: const [
          MagicNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
          MagicNavItem(label: 'Leads', icon: Icons.person_outline_rounded),
          MagicNavItem(label: 'Tasks', icon: Icons.task_alt_rounded),
          MagicNavItem(label: 'Settings', icon: Icons.settings_outlined),
        ],
        initialIndex: 1,
        onChanged: (index) {
          if (index == 1) return;
          if (index == 0) Get.toNamed(AppRoutes.dashboard);
          if (index == 2) Get.toNamed(AppRoutes.tasks);
          if (index == 3) Get.toNamed(AppRoutes.settings);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 18),
              const _ProfileCard(),
              const SizedBox(height: 20),
              const _QuickActionsCard(),
              const SizedBox(height: 20),
              const _SectionCard(
                title: 'Lead Details',
                trailing: Icon(Icons.info_outline, color: Color(0xFF91A3BF), size: 26),
                child: _LeadDetailsContent(),
              ),
              const SizedBox(height: 20),
              const _SectionCard(
                title: 'Activity History',
                actionLabel: 'VIEW ALL',
                child: _ActivityHistoryContent(),
              ),
              const SizedBox(height: 20),
              const _SectionCard(
                title: 'Notes',
                trailing: Icon(Icons.more_horiz, color: Color(0xFF91A3BF)),
                child: _NotesContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF5C6B82), size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Lead Profile',
            style: GoogleFonts.poppins(
              color: title,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.search_rounded, color: Color(0xFF5C6B82), size: 28),
        const SizedBox(width: 18),
        const Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_rounded, color: Color(0xFF5C6B82), size: 28),
            Positioned(
              right: 1,
              top: 1,
              child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFFF5A5A)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD9E7FF), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/200?img=47'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Chastity Potts',
                            style: GoogleFonts.poppins(
                              color: LeadDetailScreen.title,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0B3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Contacted',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF9D6B00),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cruz and Keller Trading',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5D6C84),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'kenihap@mailinator.com',
                      style: GoogleFonts.poppins(
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
          const Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'LEAD VALUE',
                  value: '\$57.00',
                  valueColor: LeadDetailScreen.link,
                ),
              ),
              SizedBox(width: 14),
              Expanded(child: _StatusTile()),
            ],
          ),
          const SizedBox(height: 18),
          const _ContactRow(icon: Icons.call_outlined, text: '+1 (565) 564-5044'),
          const SizedBox(height: 12),
          const _ContactRow(
            icon: Icons.language_rounded,
            text: 'https://www.wor.com',
            textColor: LeadDetailScreen.link,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: LeadDetailScreen.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.edit_outlined, size: 19),
              label: Text(
                'Edit Lead',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: LeadDetailScreen.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LeadDetailScreen.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickAction(icon: Icons.call_outlined, label: 'CALL', bgColor: Color(0xFFDDF8E6), fgColor: Color(0xFF17A34A)),
          _QuickAction(icon: Icons.mail_outline_rounded, label: 'EMAIL', bgColor: Color(0xFFDCEAFF), fgColor: Color(0xFF346DFF)),
          _QuickAction(icon: Icons.note_add_outlined, label: 'NOTE', bgColor: Color(0xFFF0E1FF), fgColor: Color(0xFF8A38F5)),
          _QuickAction(icon: Icons.calendar_today_outlined, label: 'FOLLOW-UP', bgColor: Color(0xFFFFE9D4), fgColor: Color(0xFFF97316)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final String? actionLabel;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LeadDetailScreen.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LeadDetailScreen.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
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
                    style: GoogleFonts.poppins(
                      color: LeadDetailScreen.title,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actionLabel != null)
                  Text(
                    actionLabel!,
                    style: GoogleFonts.poppins(
                      color: LeadDetailScreen.link,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else if (trailing != null)
                  trailing!,
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
  const _LeadDetailsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(child: _DetailField(label: 'Name', value: 'Chastity Potts')),
            SizedBox(width: 22),
            Expanded(child: _DetailField(label: 'Company', value: 'Cruz and Keller')),
          ],
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(child: _DetailField(label: 'Position', value: 'Account Manager')),
            SizedBox(width: 22),
            Expanded(
              child: _DetailField(label: 'Source', value: 'LinkedIn', valueColor: LeadDetailScreen.link),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _DetailField(label: 'Address', value: '842 Business Plaza, Suite 400'),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(child: _DetailField(label: 'City / State', value: 'Denver, CO')),
            SizedBox(width: 22),
            Expanded(child: _DetailField(label: 'Country', value: 'United States')),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _DetailField(label: 'Zip Code', value: '80202')),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags',
                    style: GoogleFonts.poppins(
                      color: LeadDetailScreen.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TagChip(label: 'VIP'),
                      _TagChip(label: 'TECH'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _DetailField(label: 'Created Date', value: 'Oct 12, 2023 | 10:45 AM'),
        const SizedBox(height: 18),
        const _DetailField(
          label: 'Description',
          value: 'Interested in enterprise licensing for the next fiscal year. Needs a demo scheduled for the engineering team by end of month.',
          isMultiline: true,
        ),
      ],
    );
  }
}

class _ActivityHistoryContent extends StatelessWidget {
  const _ActivityHistoryContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TimelineEntry(
          color: Color(0xFF22C55E),
          title: 'Lead Contacted',
          subtitle: 'Successfully reached out via phone.',
          time: 'TODAY, 2:30 PM',
          isFirst: true,
        ),
        _TimelineEntry(
          color: Color(0xFF3F7EF7),
          title: 'Email Sent',
          subtitle: 'Introductory brochure sent to kenihap@mail...',
          time: 'YESTERDAY, 11:15 AM',
        ),
        _TimelineEntry(
          color: Color(0xFFF97316),
          title: 'Follow-up Scheduled',
          subtitle: 'Calendar invite sent for initial demo.',
          time: 'OCT 14, 2023',
          isLast: true,
        ),
      ],
    );
  }
}

class _NotesContent extends StatelessWidget {
  const _NotesContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE7F3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"Spoke with her briefly, she mentioned their current contract expires in January. Very keen on our reporting features."',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF53627B),
                  fontSize: 13,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const CircleAvatar(radius: 11, backgroundColor: Color(0xFFD3DDEA)),
                  const SizedBox(width: 10),
                  Text(
                    'ADDED BY YOU | 3H AGO',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF89A0C2),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: LeadDetailScreen.link,
              side: const BorderSide(color: Color(0xFFD6E2F4), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Note',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

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
            style: GoogleFonts.poppins(
              color: const Color(0xFF7084A0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
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

class _StatusTile extends StatelessWidget {
  const _StatusTile();

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
            'STATUS',
            style: GoogleFonts.poppins(
              color: const Color(0xFF7084A0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const CircleAvatar(radius: 4, backgroundColor: Color(0xFFEAB308)),
              const SizedBox(width: 8),
              Text(
                'Warm Lead',
                style: GoogleFonts.poppins(
                  color: LeadDetailScreen.title,
                  fontSize: 15,
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

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;

  const _ContactRow({
    required this.icon,
    required this.text,
    this.textColor = const Color(0xFF5D6C84),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8CA0BF), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: fgColor, size: 27),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF6C7D95),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isMultiline;

  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = LeadDetailScreen.title,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: LeadDetailScreen.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
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
  final String label;

  const _TagChip({required this.label});

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
        style: GoogleFonts.poppins(
          color: const Color(0xFF4B5D78),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final bool isFirst;
  final bool isLast;

  const _TimelineEntry({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : const Color(0xFFE7EEF6),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : const Color(0xFFE7EEF6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: LeadDetailScreen.title,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF71829A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF92A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
