import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import '../widgets/app_bottom_navigation.dart';
import '../routes/app_routes.dart';

class StaffDetailScreen extends StatelessWidget {
  const StaffDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'User Profile',
          style: AppTextStyles.style(
            color: const Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFEDD5),
              child: Icon(Icons.person_rounded, color: Color(0xFFF97316), size: 20),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MagicBottomNavigation(
        items: const [
          MagicNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
          MagicNavItem(label: 'Leads', icon: Icons.person_outline_rounded),
          MagicNavItem(label: 'Projects', icon: Icons.assignment_rounded),
          MagicNavItem(label: 'Tasks', icon: Icons.check_circle_outline_rounded),
          MagicNavItem(label: 'Profile', icon: Icons.person_rounded),
        ],
        initialIndex: 4,
        onChanged: (index) {
          if (index == 4) return;
          _handleBottomNavigation(index);
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _ProfileHeaderCard(),
            const SizedBox(height: 24),

            _SectionTitle(title: 'ACTIVITY TIME SUMMARY'),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: _TimeCard(title: 'Total Logged', time: '02:41', icon: Icons.history_rounded, color: Color(0xFF3B82F6))),
                SizedBox(width: 12),
                Expanded(child: _TimeCard(title: 'Last Month', time: '00:00', icon: Icons.calendar_month_rounded, color: Color(0xFF64748B))),
                SizedBox(width: 12),
                Expanded(child: _TimeCard(title: 'This Week', time: '02:41', icon: Icons.timer_outlined, color: Color(0xFF22C55E))),
              ],
            ),
            const SizedBox(height: 24),

            // Edit Profile Form
            _EditProfileForm(),
            const SizedBox(height: 24),

            Row(
              children: const [
                Expanded(child: _StatsCard(value: '12', label: 'Projects Completed', color: Color(0xFF3B82F6))),
                SizedBox(width: 16),
                Expanded(child: _StatsCard(value: '84', label: 'Tasks Completed', color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 24),

            _ChartPlaceholder(title: 'MONTHLY PERFORMANCE TREND'),
            const SizedBox(height: 24),

            _PriorityBreakdownCard(),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(title: 'RECENT PROJECTS'),
                Text(
                  'View All',
                  style: AppTextStyles.style(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProjectCard(
              title: 'Liaith Baeres',
              subtitle: 'CRM Redesign & Mobile App',
              status: 'INPROGRESS',
              statusColor: Color(0xFFDBEAFE),
              statusTextColor: Color(0xFF1D4ED8),
              startDate: 'Oct 18, 2023',
              deadline: 'Dec 29, 2023',
            ),
            const SizedBox(height: 12),
            _ProjectCard(
              title: 'Fintech Dashboard',
              subtitle: 'Web Development',
              status: 'COMPLETED',
              statusColor: Color(0xFFDCFCE7),
              statusTextColor: Color(0xFF166534),
              startDate: 'Aug 05, 2023',
              deadline: 'Sep 30, 2023',
            ),
            const SizedBox(height: 24),

            _SectionTitle(title: 'RECENT TASKS'),
            const SizedBox(height: 12),
            _EmptyStateCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _handleBottomNavigation(int index) {
    if (index == 0) {
      Get.toNamed(AppRoutes.dashboard);
    } else if (index == 1) {
      Get.toNamed(AppRoutes.leads);
    } else if (index == 2) {
      Get.toNamed(AppRoutes.projects);
    } else if (index == 3) {
      Get.toNamed(AppRoutes.tasks);
    }
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=philip'),
              ),
              Positioned(
                bottom: 0,
                right: 5,
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Philip Hartman',
            style: AppTextStyles.style(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          Text(
            'Client • Web Developers',
            style: AppTextStyles.style(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.email_outlined, text: 'socuf@mailinator.com'),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.phone_outlined, text: '+1 (706) 992-4898'),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.groups_outlined, text: 'Team: N/A'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.style(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  const _TimeCard({required this.title, required this.time, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.style(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          Text(time, style: AppTextStyles.style(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _EditProfileForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Profile Details', style: AppTextStyles.style(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _InputField(label: 'First Name', initialValue: 'Philip')),
              const SizedBox(width: 12),
              Expanded(child: _InputField(label: 'Last Name', initialValue: 'Hartman')),
            ],
          ),
          const SizedBox(height: 16),
          _InputField(label: 'Email Address', initialValue: 'socuf@mailinator.com'),
          const SizedBox(height: 16),
          _InputField(label: 'Phone', initialValue: '+1 (706) 992-4898'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _DropdownField(label: 'Role', value: 'Client')),
              const SizedBox(width: 12),
              Expanded(child: _DropdownField(label: 'Status', value: 'Active')),
            ],
          ),
          const SizedBox(height: 20),
          Text('TEAM SELECTION', style: AppTextStyles.style(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          _CheckboxItem(label: 'Web Developers', value: true),
          _CheckboxItem(label: 'Design and Graphics', value: false),
          _CheckboxItem(label: 'SEO Developer', value: false),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Save Changes', style: AppTextStyles.style(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String initialValue;
  const _InputField({required this.label, required this.initialValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.style(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          style: AppTextStyles.style(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  const _DropdownField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.style(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: AppTextStyles.style(fontSize: 14, color: Color(0xFF1E293B))),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckboxItem extends StatelessWidget {
  final String label;
  final bool value;
  const _CheckboxItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF3B82F6) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: value ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0)),
            ),
            child: value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.style(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatsCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.style(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.style(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final String title;
  const _ChartPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          const SizedBox(height: 60),
          Center(
            child: Text('Chart Placeholder', style: AppTextStyles.style(color: Color(0xFF94A3B8))),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(height: 8, width: 8, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Performance %', style: AppTextStyles.style(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityBreakdownCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'TASK PRIORITY BREAKDOWN'),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: Color(0xFFFB923C),
                  backgroundColor: Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  children: [
                    _PriorityItem(label: 'High Priority', percent: '85%', color: Color(0xFF3B82F6)),
                    const SizedBox(height: 8),
                    _PriorityItem(label: 'Medium', percent: '70%', color: Color(0xFFFB923C)),
                    const SizedBox(height: 8),
                    _PriorityItem(label: 'Low', percent: '15%', color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityItem extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;
  const _PriorityItem({required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(height: 8, width: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.style(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500))),
        Text(percent, style: AppTextStyles.style(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final Color statusTextColor;
  final String startDate;
  final String deadline;

  const _ProjectCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
    required this.startDate,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.style(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    Text(subtitle, style: AppTextStyles.style(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: AppTextStyles.style(fontSize: 10, fontWeight: FontWeight.w700, color: statusTextColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _DateColumn(label: 'START DATE', date: startDate)),
              Expanded(child: _DateColumn(label: 'DEADLINE', date: deadline, isDeadline: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  final String label;
  final String date;
  final bool isDeadline;
  const _DateColumn({required this.label, required this.date, this.isDeadline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.style(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(date, style: AppTextStyles.style(fontSize: 13, fontWeight: FontWeight.w600, color: isDeadline ? Color(0xFFEF4444) : Color(0xFF475569))),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
            child: const Icon(Icons.assignment_outlined, color: Color(0xFFCBD5E1), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found for this staff member.',
            style: AppTextStyles.style(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: Text('+ Create Task', style: AppTextStyles.style(fontSize: 14, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.style(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
    );
  }
}

