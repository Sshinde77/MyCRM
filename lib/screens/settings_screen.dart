import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_strings.dart';
import '../core/constants/app_text_styles.dart';
import 'company_information_screen.dart';
import 'email_settings_screen.dart';
import 'general_settings_screen.dart';
import 'department_settings_screen.dart';
import 'renewal_settings_screen.dart';
import 'team_settings_screen.dart';
import '../widgets/common_screen_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<_SettingItem> _items = [
    // _SettingItem(title: 'General Setting', icon: Icons.settings_outlined),
    _SettingItem(title: 'Company Information', icon: Icons.apartment_outlined),
    _SettingItem(title: 'Email Setting', icon: Icons.mail_outline_rounded),
    _SettingItem(
      title: 'Renewal Setting',
      icon: Icons.notifications_none_rounded,
    ),
    _SettingItem(title: 'Teams', icon: Icons.group_outlined),
    _SettingItem(title: 'Departments', icon: Icons.work_outline_rounded),
    _SettingItem(title: 'Privacy Policy', icon: Icons.privacy_tip_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: const CommonScreenAppBar(title: 'Settings'),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _items[index];
            return _SettingTile(
              item: item,
              onTap: index == 0
                  // ? () {
                  //     Navigator.of(context).push(
                  //       MaterialPageRoute(
                  //         builder: (_) => const GeneralSettingsScreen(),
                  //       ),
                  //     );
                  //   }
                  // : index == 1
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CompanyInformationScreen(),
                        ),
                      );
                    }
                  : index == 1
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EmailSettingsScreen(),
                        ),
                      );
                    }
                  : index == 2
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RenewalSettingsScreen(),
                        ),
                      );
                    }
                  : index == 3
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TeamSettingsScreen(),
                        ),
                      );
                    }
                  : index == 4
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DepartmentSettingsScreen(),
                        ),
                      );
                    }
                  : index == 5
                  ? () => _openPrivacyPolicy(context)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.tryParse(AppStrings.privacyPolicyUrl);
    if (uri == null) {
      _showMessage(context, 'Privacy policy URL is not configured.');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showMessage(context, 'Unable to open privacy policy.');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingItem {
  const _SettingItem({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.item, this.onTap});

  final _SettingItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: const Color(0xFF1D6FEA)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTextStyles.style(
                    color: const Color(0xFF162033),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
