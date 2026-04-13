import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../screens/to_do_list.dart' as to_do;
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';

/// Main CRM dashboard shown after a successful login.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService.instance;
  final List<_Appointment> _appointments = [
    _Appointment(
      title: 'Quarterly Review',
      description: 'With Microsoft Marketing Team',
      date: DateTime(2026, 3, 16),
      time: const TimeOfDay(hour: 9, minute: 30),
      emailRecipients: 'alex@mycrm.com',
      whatsappRecipients: '+919876543210',
    ),
    _Appointment(
      title: 'Contract Signing',
      description: 'Stripe Integration Services',
      date: DateTime(2026, 3, 16),
      time: const TimeOfDay(hour: 14, minute: 0),
      emailRecipients: 'contracts@mycrm.com',
      whatsappRecipients: '+919876543211',
    ),
  ];

  UserModel? _currentUser;
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final storedUser = await _apiService.getStoredUser();
    if (!mounted) {
      return;
    }

    if (storedUser != null) {
      setState(() {
        _currentUser = storedUser;
      });
    }

    try {
      final user = await _apiService.getCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
      });
    } on DioException {
      // Keep showing the cached user if profile refresh fails.
    } catch (_) {
      // Ignore non-critical profile refresh failures on dashboard load.
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBackground = Color(0xFFF5F7FB);
    const textSecondary = Color(0xFF74839D);
    const blue = Color(0xFF1769F3);
    const navy = Color(0xFF141C33);

    return Scaffold(
      backgroundColor: pageBackground,
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.dashboard,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderSection(user: _currentUser),
                  const SizedBox(height: 18),
                  const _AlertBanner(),
                  const SizedBox(height: 20),
                  const _SectionCard(
                    padding: EdgeInsets.fromLTRB(18, 20, 18, 16),
                    child: _RenewalSection(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: _ProjectSummarySection(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, 20),
                    child: _TaskSummarySection(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: _SupportTicketsSection(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 360;

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "Today's Calendar",
                                  style: AppTextStyles.style(
                                    color: Colors.white,
                                    fontSize: isCompact ? 15 : 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _showAddAppointmentDialog,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.08,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 10 : 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.add_rounded,
                                    size: isCompact ? 16 : 18,
                                  ),
                                  label: Text(
                                    'Add Appointment',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.style(
                                      color: Colors.white,
                                      fontSize: isCompact ? 11 : 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.white.withOpacity(0.72),
                                  size: isCompact ? 18 : 20,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        for (var i = 0; i < _appointments.length; i++) ...[
                          _CalendarItem(appointment: _appointments[i]),
                          if (i != _appointments.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dashboard preview closely follows the provided mockup with local sample data.',
                    style: AppTextStyles.style(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddAppointmentDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final emailController = TextEditingController();
    final whatsappController = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final saved = await showDialog<_Appointment>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) {
                setModalState(() => selectedDate = picked);
              }
            }

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime:
                    selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
              );
              if (picked != null) {
                setModalState(() => selectedTime = picked);
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Add Calendar Appointments',
                                style: AppTextStyles.style(
                                  color: const Color(0xFF3A4656),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFE5EAF3)),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF5FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD5E4FF),
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.style(
                                  color: const Color(0xFF48617D),
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Notification Flow: ',
                                    style: TextStyle(
                                      color: Color(0xFF234B92),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'WhatsApp template message automatically at selected meeting time.\n'
                                        'Note: Same day meetings require at least 30 minutes gap between time slots.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AppointmentFormField(
                            label: 'Title',
                            requiredMark: true,
                            child: TextFormField(
                              controller: titleController,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Please enter a title'
                                  : null,
                              decoration: _appointmentInputDecoration(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AppointmentFormField(
                            label: 'Description',
                            child: TextFormField(
                              controller: descriptionController,
                              minLines: 3,
                              maxLines: 4,
                              decoration: _appointmentInputDecoration(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _AppointmentFormField(
                                  label: 'Date',
                                  requiredMark: true,
                                  child: TextFormField(
                                    readOnly: true,
                                    onTap: pickDate,
                                    controller: TextEditingController(
                                      text: selectedDate == null
                                          ? ''
                                          : _formatDate(selectedDate!),
                                    ),
                                    validator: (_) => selectedDate == null
                                        ? 'Select a date'
                                        : null,
                                    decoration: _appointmentInputDecoration(
                                      hintText: 'dd-mm-yyyy',
                                      suffixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _AppointmentFormField(
                                  label: 'Time',
                                  requiredMark: true,
                                  child: TextFormField(
                                    readOnly: true,
                                    onTap: pickTime,
                                    controller: TextEditingController(
                                      text: selectedTime == null
                                          ? ''
                                          : _formatTime(selectedTime!),
                                    ),
                                    validator: (_) => selectedTime == null
                                        ? 'Select time'
                                        : null,
                                    decoration: _appointmentInputDecoration(
                                      hintText: '--:--',
                                      suffixIcon: const Icon(
                                        Icons.access_time_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _AppointmentFormField(
                            label: 'Email Recipients (Optional)',
                            helperText:
                                'Comma-separated emails. You can keep this empty if WhatsApp numbers are added.',
                            child: TextFormField(
                              controller: emailController,
                              decoration: _appointmentInputDecoration(
                                hintText:
                                    'email1@example.com, email2@example.com',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AppointmentFormField(
                            label: 'WhatsApp Recipients (Phone Numbers)',
                            requiredMark: true,
                            helperText:
                                'Use international format. Multiple numbers comma separated.',
                            child: TextFormField(
                              controller: whatsappController,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Please enter at least one WhatsApp number'
                                  : null,
                              decoration: _appointmentInputDecoration(
                                hintText: '919876543210, 919876543211',
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF6F7782),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Close',
                                  style: AppTextStyles.style(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  Navigator.of(context).pop(
                                    _Appointment(
                                      title: titleController.text.trim(),
                                      description:
                                          descriptionController.text
                                              .trim()
                                              .isEmpty
                                          ? 'New calendar appointment'
                                          : descriptionController.text.trim(),
                                      date: selectedDate!,
                                      time: selectedTime!,
                                      emailRecipients: emailController.text
                                          .trim(),
                                      whatsappRecipients: whatsappController
                                          .text
                                          .trim(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1683F2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Save Appointment',
                                  style: AppTextStyles.style(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != null) {
      setState(() {
        _appointments.add(saved);
        _appointments.sort((a, b) {
          final aDate = DateTime(
            a.date.year,
            a.date.month,
            a.date.day,
            a.time.hour,
            a.time.minute,
          );
          final bDate = DateTime(
            b.date.year,
            b.date.month,
            b.date.day,
            b.time.hour,
            b.time.minute,
          );
          return aDate.compareTo(bDate);
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment added to calendar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'MyCRM User';
    final role = user?.role?.trim().isNotEmpty == true
        ? user!.role!.trim()
        : 'Team Member';
    final avatarLetter = displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : 'M';

    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF8),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFB9C7DA),
            child: Text(
              avatarLetter,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTextStyles.style(
                  color: const Color(0xFF1B2237),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: AppTextStyles.style(
                  color: const Color(0xFF7F90A9),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _HeaderActionButton(
              icon: Icons.checklist_rounded,
              size: 24,
              onTap: () => Get.to(() => const to_do.ToDoListScreen()),
            ),
            const SizedBox(width: 10),
            _HeaderActionButton(
              icon: Icons.notifications_none_rounded,
              size: 25,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F3F9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: const Color(0xFF61728F), size: size),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE82626),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40E82626),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0x33FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overdue Renewals',
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '8 accounts require immediate action',
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '08',
            style: AppTextStyles.style(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7ECF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RenewalSection extends StatelessWidget {
  const _RenewalSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveSectionHeader(
          title: 'Upcoming Renewals',
          forceInline: true,
          trailing: _SectionActionLabel(
            label: 'View All',
            onTap: () => Get.toNamed(AppRoutes.dashboardRenewals),
          ),
        ),
        const SizedBox(height: 18),
        const _RenewalTile(
          initials: 'AE',
          company: 'Acme Corporation',
          amount: '₹12,500',
          date: 'Oct 15, 2023',
          tagLabel: '7 DAYS LEFT',
          tagColor: Color(0xFFF5A623),
          logoColor: Color(0xFFB9B899),
        ),
        const SizedBox(height: 14),
        const _RenewalTile(
          initials: 'GT',
          company: 'Global Tech Solut',
          amount: '₹12,500',
          date: 'Oct 15, 2023',
          tagLabel: 'EARLY BIRD',
          tagColor: Color(0xFF20BF7A),
          logoColor: Color(0xFF102B3B),
        ),
        const SizedBox(height: 14),
        const _RenewalTile(
          initials: 'NX',
          company: 'Acme Corporation',
          amount: '₹12,500',
          date: 'Oct 15, 2023',
          tagLabel: '7 DAYS LEFT',
          tagColor: Color(0xFFF5A623),
          logoColor: Color(0xFF63AFA8),
        ),
      ],
    );
  }
}

class _SectionActionLabel extends StatelessWidget {
  const _SectionActionLabel({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.style(
        color: const Color(0xFF1769F3),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

    if (onTap == null) {
      return text;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: text,
        ),
      ),
    );
  }
}

class _RenewalTile extends StatelessWidget {
  const _RenewalTile({
    required this.initials,
    required this.company,
    required this.amount,
    required this.date,
    required this.tagLabel,
    required this.tagColor,
    required this.logoColor,
  });

  final String initials;
  final String company;
  final String amount;
  final String date;
  final String tagLabel;
  final Color tagColor;
  final Color logoColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;

        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9EEF6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isCompact ? 48 : 52,
                height: isCompact ? 48 : 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: isCompact ? 32 : 36,
                  height: isCompact ? 32 : 36,
                  decoration: BoxDecoration(
                    color: logoColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTextStyles.style(
                      color: Colors.white,
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact) ...[
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E263B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amount,
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E263B),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.style(
                                color: const Color(0xFF1E263B),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              amount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.style(
                                color: const Color(0xFF1E263B),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Color(0xFF91A2BD),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              date,
                              style: AppTextStyles.style(
                                color: const Color(0xFF7587A3),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 7, color: tagColor),
                              const SizedBox(width: 4),
                              Text(
                                tagLabel,
                                style: AppTextStyles.style(
                                  color: tagColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
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
            ],
          ),
        );
      },
    );
  }
}

class _ProjectSummarySection extends StatelessWidget {
  const _ProjectSummarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ResponsiveSectionHeader(
          title: 'Projects Summary',
          trailing: _SectionMenuButton(),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(
              child: _ProjectMetricCard(
                title: 'Projects',
                value: '02',
                accentColor: Color(0xFF2D9CDB),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ProjectMetricCard(
                title: 'Tasks',
                value: '13',
                accentColor: Color(0xFFFFB020),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EBF4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _ChartLegendChip(
                      label: 'Projects',
                      color: Color(0xFF2D9CDB),
                    ),
                    const _ChartLegendChip(
                      label: 'Tasks',
                      color: Color(0xFFFFB020),
                    ),
                    _CurrentMonthBadge(
                      label: 'Current: ${_monthShortLabel(DateTime.now())}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _LineChartMock(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineChartMock extends StatelessWidget {
  const _LineChartMock();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.55,
      child: const CustomPaint(painter: _ChartPainter()),
    );
  }
}

class _TaskSummarySection extends StatelessWidget {
  const _TaskSummarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle(title: 'Task Summary'),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.tasks),
              child: const _SectionActionLabel(label: 'View All'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _TaskSummaryChart(),
      ],
    );
  }
}

class _TaskSummaryChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const taskItems = [
      ('Not Started', 0, Color(0xFF6C778D)),
      ('In Progress', 6, Color(0xFF1769F3)),
      ('On Hold', 1, Color(0xFFF5B71F)),
      ('Completed', 6, Color(0xFF20D39B)),
      ('Cancelled', 0, Color(0xFFFF4D6D)),
    ];
    final total = taskItems.fold<int>(0, (sum, item) => sum + item.$2);

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _TaskDonutPainter(
                segments: const [
                  _TaskDonutSegment(value: 6, color: Color(0xFF1769F3)),
                  _TaskDonutSegment(value: 1, color: Color(0xFFF95A2C)),
                  _TaskDonutSegment(value: 6, color: Color(0xFF20D39B)),
                ],
                backgroundColor: const Color(0xFFEAF0F8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: AppTextStyles.style(
                        color: const Color(0xFF1B2237),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total Tasks',
                      style: AppTextStyles.style(
                        color: const Color(0xFF8A99AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in taskItems)
              _TaskStatusRow(label: item.$1, value: item.$2, color: item.$3),
          ],
        ),
      ],
    );
  }
}

class _SupportTicketsSection extends StatelessWidget {
  const _SupportTicketsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle(title: 'Support Tickets'),
            const Spacer(),
            const _SectionMenuButton(),
            const SizedBox(width: 10),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(flex: 7, child: ColoredBox(color: Color(0xFF1769F3))),
                Expanded(flex: 11, child: ColoredBox(color: Color(0xFFF5B71F))),
                Expanded(flex: 6, child: ColoredBox(color: Color(0xFF39D0A0))),
              ],
            ),
          ),
        ),
        const _SupportTicketPreviewCard(),
      ],
    );
  }
}

class _SupportTicketPreviewCard extends StatelessWidget {
  const _SupportTicketPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Satyam Tiwari',
                  style: AppTextStyles.style(
                    color: const Color(0xFF6C7D96),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F8FE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Low',
                  style: AppTextStyles.style(
                    color: const Color(0xFF1DB8E9),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ddhrh',
            style: AppTextStyles.style(
              color: const Color(0xFF1B2237),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Crackteck',
                style: AppTextStyles.style(
                  color: const Color(0xFF73839B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Open',
                  style: AppTextStyles.style(
                    color: const Color(0xFFFF4D6D),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF73839B),
              ),
              const SizedBox(width: 6),
              Text(
                'Mar 14, 2026 10:39',
                style: AppTextStyles.style(
                  color: const Color(0xFF73839B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarItem extends StatelessWidget {
  const _CalendarItem({required this.appointment});

  final _Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF273046),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTimeNumber(appointment.time),
                  style: AppTextStyles.style(
                    color: const Color(0xFF1769F3),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  appointment.time.period == DayPeriod.am ? 'AM' : 'PM',
                  style: AppTextStyles.style(
                    color: const Color(0xFFAAB5C6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  appointment.description,
                  style: AppTextStyles.style(
                    color: const Color(0xFFAAB5C6),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
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

class _AppointmentFormField extends StatelessWidget {
  const _AppointmentFormField({
    required this.label,
    required this.child,
    this.requiredMark = false,
    this.helperText,
  });

  final String label;
  final Widget child;
  final bool requiredMark;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.style(
              color: const Color(0xFF59677A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(text: label),
              if (requiredMark)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFD93025)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: AppTextStyles.style(
              color: const Color(0xFF7A8798),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _Appointment {
  const _Appointment({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.emailRecipients,
    required this.whatsappRecipients,
  });

  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final String emailRecipients;
  final String whatsappRecipients;
}

InputDecoration _appointmentInputDecoration({
  String? hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.style(
      color: const Color(0xFFB2BDCC),
      fontSize: 14,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1683F2), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD93025)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD93025), width: 1.5),
    ),
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

String _formatTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

String _formatTimeNumber(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF6E7F99),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TaskStatusRow extends StatelessWidget {
  const _TaskStatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.style(
                color: const Color(0xFF1C2438),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: AppTextStyles.style(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionMenuButton extends StatelessWidget {
  const _SectionMenuButton();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'More actions',
        color: Colors.white,
        padding: EdgeInsets.zero,
        offset: const Offset(0, 38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (value) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$value clicked'),
              behavior: SnackPosition.BOTTOM == null
                  ? SnackBarBehavior.fixed
                  : SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1200),
            ),
          );
        },
        itemBuilder: (context) => const [
          PopupMenuItem<String>(
            value: 'Refresh',
            child: _SectionMenuItem(
              icon: Icons.refresh_rounded,
              label: 'Refresh',
            ),
          ),
          PopupMenuItem<String>(
            value: 'Export',
            child: _SectionMenuItem(
              icon: Icons.file_download_outlined,
              label: 'Export',
            ),
          ),
          PopupMenuItem<String>(
            value: 'View All',
            child: _SectionMenuItem(
              icon: Icons.visibility_outlined,
              label: 'View All',
            ),
          ),
        ],
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.more_horiz_rounded,
            color: Color(0xFF7D8CA3),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _SectionMenuItem extends StatelessWidget {
  const _SectionMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF607089)),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF1C2438),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ChartLegendChip extends StatelessWidget {
  const _ChartLegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7E1EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF1C2438),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMetricCard extends StatelessWidget {
  const _ProjectMetricCard({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final String title;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.style(
                  color: const Color(0xFF70819A),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.style(
                  color: const Color(0xFF1C2438),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentMonthBadge extends StatelessWidget {
  const _CurrentMonthBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7E1EE)),
      ),
      child: Text(
        label,
        style: AppTextStyles.style(
          color: const Color(0xFF667891),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _monthShortLabel(DateTime date) {
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
  return months[date.month - 1];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.style(
        color: const Color(0xFF1C2438),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ResponsiveSectionHeader extends StatelessWidget {
  const _ResponsiveSectionHeader({
    required this.title,
    required this.trailing,
    this.forceInline = false,
  });

  final String title;
  final Widget trailing;
  final bool forceInline;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320 && !forceInline;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: title),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: trailing),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _SectionTitle(title: title)),
            const SizedBox(width: 12),
            trailing,
          ],
        );
      },
    );
  }
}

class _TaskDonutSegment {
  const _TaskDonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

class _TaskDonutPainter extends CustomPainter {
  _TaskDonutPainter({required this.segments, required this.backgroundColor});

  final List<_TaskDonutSegment> segments;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 22.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    if (total <= 0) {
      return;
    }

    var startAngle = -1.5708;
    const gapAngle = 0.03;

    for (final segment in segments) {
      if (segment.value <= 0) {
        continue;
      }

      final sweepAngle = (6.2831 * (segment.value / total)) - gapAngle;
      final segmentPaint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _TaskDonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = 28.0;
    final chartBottom = size.height - 28;
    final chartTop = 18.0;
    final chartRight = size.width - 10;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final labelStyle = AppTextStyles.style(
      color: const Color(0xFF6E7B90),
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = const Color(0xFFF0F4F9)
      ..strokeWidth = 1;

    const maxValue = 14;
    final months = List.generate(6, (index) {
      final now = DateTime.now();
      final monthDate = DateTime(now.year, now.month - 5 + index, 1);
      return _monthShortLabel(monthDate);
    });
    const projectValues = [1, 2, 1, 3, 2, 2];
    const taskValues = [4, 6, 5, 8, 7, 13];

    for (var i = 0; i <= maxValue; i += 2) {
      final y = chartBottom - (chartHeight * i / maxValue);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      textPainter.text = TextSpan(text: '$i', style: labelStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    final groupWidth = chartWidth / months.length;
    for (var i = 0; i <= months.length; i++) {
      final x = chartLeft + (groupWidth * i);
      if (i < months.length) {
        canvas.drawLine(
          Offset(x, chartTop),
          Offset(x, chartBottom),
          Paint()
            ..color = const Color(0xFFF6F8FC)
            ..strokeWidth = 0.8,
        );
      }
    }

    for (var i = 0; i < months.length; i++) {
      final xCenter = chartLeft + (groupWidth * i) + groupWidth / 2;
      textPainter.text = TextSpan(text: months[i], style: labelStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xCenter - textPainter.width / 2, chartBottom + 8),
      );

      final projectHeight = chartHeight * (projectValues[i] / maxValue);
      final taskHeight = chartHeight * (taskValues[i] / maxValue);
      final projectRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          xCenter - 16,
          chartBottom - projectHeight,
          14,
          projectHeight,
        ),
        const Radius.circular(8),
      );
      final taskRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xCenter + 2, chartBottom - taskHeight, 14, taskHeight),
        const Radius.circular(8),
      );

      canvas.drawRRect(projectRect, Paint()..color = const Color(0xFF2D9CDB));
      canvas.drawRRect(
        taskRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFFFC83A), Color(0xFFFF8A50)],
          ).createShader(taskRect.outerRect),
      );
    }

    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      Paint()
        ..color = const Color(0xFFC9D4E3)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
