import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

import '../models/client_detail_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, this.clientId});

  final String? clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Future<ClientDetailModel> _clientFuture;
  String? _clientId;

  @override
  void initState() {
    super.initState();
    _clientId = widget.clientId ?? _extractClientId(Get.arguments);
    _clientFuture = _clientId == null || _clientId!.isEmpty
        ? Future.error('Client id missing')
        : ApiService.instance.getClientDetail(_clientId!);
  }

  void _reload() {
    if (_clientId == null || _clientId!.isEmpty) return;
    setState(() {
      _clientFuture = ApiService.instance.getClientDetail(_clientId!);
    });
  }

  String? _extractClientId(dynamic args) {
    if (args == null) return null;
    if (args is String) return args;
    if (args is int) return args.toString();
    if (args is Map) {
      final raw = args['id'] ?? args['clientId'] ?? args['client_id'];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        return raw.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF7FAFF);
    const textMain = Color(0xFF141C33);
    const textSec = Color(0xFF74839D);
    const blue = Color(0xFF1769F3);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Client Details',
          style: AppTextStyles.style(
            color: textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: textSec),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: textSec),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: MagicBottomNavigation(
        items: const [
          MagicNavItem(label: 'Home', icon: Icons.home_outlined),
          MagicNavItem(label: 'Clients', icon: Icons.people_outline),
          MagicNavItem(label: 'Projects', icon: Icons.folder_open_outlined),
          MagicNavItem(label: 'Tasks', icon: Icons.check_box_outlined),
          MagicNavItem(label: 'More', icon: Icons.menu_rounded),
        ],
        initialIndex: 1,
        onChanged: (index) {
          if (index == 0) Get.toNamed(AppRoutes.dashboard);
          if (index == 1) Get.toNamed(AppRoutes.clients);
          if (index == 2) Get.toNamed(AppRoutes.projects);
          if (index == 3) Get.toNamed(AppRoutes.tasks);
          if (index == 4) Get.toNamed(AppRoutes.profile);
        },
      ),
      body: FutureBuilder<ClientDetailModel>(
        future: _clientFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: AppTextStyles.style(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D6FEA),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final client = snapshot.data;
          if (client == null) {
            return const Center(child: Text('Client not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _ProfileHeader(client: client),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              icon: Icons.folder_open,
                              value: '1',
                              label: 'Total Projects',
                              color: Color(0xFFE0E7FF),
                              iconColor: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              icon: Icons.assignment_outlined,
                              value: '1',
                              label: 'Active Tasks',
                              color: Color(0xFFFEF3C7),
                              iconColor: Colors.orange,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              icon: Icons.error_outline,
                              value: '1',
                              label: 'Open Issues',
                              color: Color(0xFFFEE2E2),
                              iconColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ClientInfoCard(client: client),
                      const SizedBox(height: 20),
                      const _SectionHeader(title: 'Projects', showViewAll: true),
                      const SizedBox(height: 12),
                      const _ProjectCard(),
                      const SizedBox(height: 20),
                      const _SectionHeader(title: 'Recent Tasks'),
                      const SizedBox(height: 12),
                      const _TaskCard(),
                      const SizedBox(height: 20),
                      const _SectionHeader(title: 'Open Issues', count: 1),
                      const SizedBox(height: 12),
                      const _IssueCard(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.client});

  final ClientDetailModel client;

  @override
  Widget build(BuildContext context) {
    final displayName = client.name.isNotEmpty ? client.name : 'Client';
    final company = client.companyName.isNotEmpty ? client.companyName : 'No company';
    final email = client.email.isNotEmpty ? client.email : 'No email';
    final phone = client.phone.isNotEmpty ? client.phone : 'No phone';
    final website = client.website.isNotEmpty ? client.website : 'No website';
    final manager = client.managerName.isNotEmpty ? client.managerName : 'Unassigned Manager';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: AppTextStyles.style(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF141C33),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: client.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            client.isActive ? 'ACTIVE CLIENT' : 'INACTIVE CLIENT',
                            style: AppTextStyles.style(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: client.isActive ? const Color(0xFF059669) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      company,
                      style: AppTextStyles.style(
                        fontSize: 14,
                        color: const Color(0xFF74839D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.email_outlined, email),
          _infoRow(Icons.phone_outlined, phone),
          _infoRow(Icons.language_outlined, website, isLink: true),
          _infoRow(Icons.person_outline, manager),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF74839D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.style(
                fontSize: 13,
                color: isLink ? const Color(0xFF1769F3) : const Color(0xFF141C33),
                fontWeight: isLink ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color iconColor;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.style(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141C33),
            ),
          ),
          Text(
            label,
            style: AppTextStyles.style(
              fontSize: 10,
              color: const Color(0xFF74839D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  const _ClientInfoCard({required this.client});

  final ClientDetailModel client;

  @override
  Widget build(BuildContext context) {
    final contactPerson = client.contactPerson.isNotEmpty ? client.contactPerson : 'Not specified';
    final clientType = client.clientType.isNotEmpty ? client.clientType : 'Not specified';
    final industry = client.industry.isNotEmpty ? client.industry : 'Not specified';
    final priority = client.priorityLevel.isNotEmpty ? client.priorityLevel : 'Not specified';
    final billingType = client.billingType.isNotEmpty ? client.billingType : 'Not specified';
    final dueDays = client.dueDays.isNotEmpty ? client.dueDays : 'Not specified';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Client Information',
                style: AppTextStyles.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141C33),
                ),
              ),
              const Icon(Icons.info_outline, color: Color(0xFF74839D), size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _InfoField(label: 'CONTACT PERSON', value: contactPerson)),
              Expanded(child: _InfoField(label: 'CLIENT TYPE', value: clientType)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _InfoField(label: 'INDUSTRY', value: industry)),
              Expanded(
                child: _InfoField(
                  label: 'PRIORITY LEVEL',
                  value: priority,
                  valueColor: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _InfoField(
            label: 'ADDRESS DETAILS',
            value: client.addressSummary,
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: _InfoField(label: 'BILLING TYPE', value: billingType)),
              Expanded(child: _InfoField(label: 'DUE DAYS', value: dueDays)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoField({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF74839D),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.style(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF141C33),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showViewAll;
  final int? count;

  const _SectionHeader({required this.title, this.showViewAll = false, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.style(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141C33),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        if (showViewAll)
          Text(
            'View All',
            style: AppTextStyles.style(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1769F3),
            ),
          ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Laith Barrera',
                style: AppTextStyles.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141C33),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'In Progress',
                  style: AppTextStyles.style(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1769F3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF74839D)),
              const SizedBox(width: 4),
              Text('01 Jan', style: AppTextStyles.style(fontSize: 12, color: const Color(0xFF74839D))),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF74839D)),
              const SizedBox(width: 4),
              Text('30 Jun', style: AppTextStyles.style(fontSize: 12, color: const Color(0xFF74839D))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HIGH PRIORITY',
                  style: AppTextStyles.style(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.projectDetail);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'View Project Details',
                style: AppTextStyles.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF141C33),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ut voluptatem conseq',
                      style: AppTextStyles.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF141C33),
                      ),
                    ),
                    Text(
                      'Project: Laith Barrera',
                      style: AppTextStyles.style(
                        fontSize: 12,
                        color: const Color(0xFF74839D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Not Started',
                  style: AppTextStyles.style(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF74839D),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Due: 24 May',
                style: AppTextStyles.style(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.toNamed(AppRoutes.issueDetail);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bug_report_outlined, size: 20, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Issue #1',
                            style: AppTextStyles.style(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF141C33),
                            ),
                          ),
                          Text(
                            'OPEN',
                            style: AppTextStyles.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Laith Barrera • Web App Interface',
                        style: AppTextStyles.style(
                          fontSize: 12,
                          color: const Color(0xFF74839D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The navigation bar on mobile view gets cut off when scrolling horizontally...',
                        style: AppTextStyles.style(
                          fontSize: 12,
                          color: const Color(0xFF74839D),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CRITICAL',
                    style: AppTextStyles.style(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ),
                Text(
                  'Added: 18 May',
                  style: AppTextStyles.style(
                    fontSize: 11,
                    color: const Color(0xFF74839D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
