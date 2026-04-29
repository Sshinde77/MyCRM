import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

import '../routes/app_routes.dart';

class RenewalMasterScreen extends StatelessWidget {
  const RenewalMasterScreen({super.key});

  static const List<_RenewalOption> _options = [
    _RenewalOption(
      title: 'Client Renewal',
      // subtitle: 'Track client renewals, dates, owners, and follow-ups.',
      icon: Icons.assignment_turned_in_outlined,
      routeName: AppRoutes.clientRenewal,
      accentColor: Color(0xFF2563EB),
    ),
    _RenewalOption(
      title: 'Vendor Renewal',
      // subtitle: 'Review vendor contracts and upcoming renewal timelines.',
      icon: Icons.inventory_2_outlined,
      routeName: AppRoutes.vendorRenewal,
      accentColor: Color(0xFF0F766E),
    ),
    // _RenewalOption(
    //   title: 'Client',
    //   subtitle: 'Open client-specific renewal records and status details.',
    //   icon: Icons.apartment_rounded,
    //   routeName: AppRoutes.renewalClient,
    //   accentColor: Color(0xFF7C3AED),
    // ),
    _RenewalOption(
      title: 'Vendor',
      // subtitle: 'Manage vendor profiles linked with renewal workflows.',
      icon: Icons.local_shipping_outlined,
      routeName: AppRoutes.renewalVendor,
      accentColor: Color(0xFFEA580C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;
    final padding = compact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEEF5FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonTopBar(
                      title: 'Renewal Master',
                      compact: compact,
                      onBack: Get.back,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 18 : 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   'Choose a renewal section',
                          //   style: AppTextStyles.style(
                          //     color: const Color(0xFF162033),
                          //     fontSize: compact ? 18 : 20,
                          //     fontWeight: FontWeight.w700,
                          //   ),
                          // ),
                          // const SizedBox(height: 8),
                          // Text(
                          //   'Open the renewal workflow you want to manage.',
                          //   style: AppTextStyles.style(
                          //     color: const Color(0xFF64748B),
                          //     fontSize: compact ? 13 : 14,
                          //     height: 1.5,
                          //   ),
                          // ),
                          const SizedBox(height: 20),
                          ..._options.map(
                            (option) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RenewalOptionCard(
                                option: option,
                                compact: compact,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RenewalDetailScreen extends StatelessWidget {
  const RenewalDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width <= 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEEF5FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonTopBar(
                      title: title,
                      compact: compact,
                      onBack: Get.back,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(icon, color: accentColor, size: 28),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: AppTextStyles.style(
                              color: const Color(0xFF162033),
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: AppTextStyles.style(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              'This screen is ready for the specific renewal form or list you want to add next.',
                              style: AppTextStyles.style(
                                color: const Color(0xFF475569),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RenewalOptionCard extends StatelessWidget {
  const _RenewalOptionCard({required this.option, required this.compact});

  final _RenewalOption option;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(option.routeName),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 16 : 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: compact ? 26 : 30,
              width: compact ? 26 : 30,
              decoration: BoxDecoration(
                color: option.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                option.icon,
                color: option.accentColor,
                size: compact ? 15 : 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTextStyles.style(
                      color: const Color(0xFF162033),
                      fontSize: compact ? 16 : 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Text(
                  //   option.subtitle,
                  //   style: AppTextStyles.style(
                  //     color: const Color(0xFF64748B),
                  //     fontSize: compact ? 12 : 13,
                  //     height: 1.5,
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _RenewalOption {
  const _RenewalOption({
    required this.title,
    // required this.subtitle,
    required this.icon,
    required this.routeName,
    required this.accentColor,
  });

  final String title;
  // final String subtitle;
  final IconData icon;
  final String routeName;
  final Color accentColor;
}
