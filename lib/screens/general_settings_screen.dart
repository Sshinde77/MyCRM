import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../core/services/app_settings_service.dart';
import '../core/services/biometric_service.dart';
import '../widgets/common_screen_app_bar.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final AppSettingsService _appSettingsService = AppSettingsService.instance;
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = true;
  bool _faceLockEnabled = false;
  bool _darkModeEnabled = false;

  bool _isUpdatingBiometric = false;
  bool _isUpdatingFaceLock = false;
  bool _isUpdatingDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    await _authController.init();
    final faceLockEnabled = await _appSettingsService.isFaceLockEnabled();
    final darkModeEnabled = await _appSettingsService.isDarkModeEnabled();

    if (!mounted) return;
    setState(() {
      _faceLockEnabled = faceLockEnabled;
      _darkModeEnabled = darkModeEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (_isUpdatingBiometric) return;

    setState(() {
      _isUpdatingBiometric = true;
    });

    if (enable) {
      await _authController.enableBiometricLogin();
    } else {
      await _authController.disableBiometricLogin();
    }

    if (!mounted) return;
    setState(() {
      _isUpdatingBiometric = false;
    });
  }

  Future<void> _toggleFaceLock(bool enable) async {
    if (_isUpdatingFaceLock) return;

    setState(() {
      _isUpdatingFaceLock = true;
    });

    if (enable) {
      final availability = await _biometricService.checkAvailability();
      if (!availability.isUsable || !availability.hasFace) {
        if (mounted) {
          AppSnackbar.show(
            'Face lock unavailable',
            'Face authentication is not available on this device.',

          );
        }
        if (!mounted) return;
        setState(() {
          _isUpdatingFaceLock = false;
        });
        return;
      }

      final authResult = await _biometricService.authenticate(
        reason: 'Authenticate to enable face lock',
      );

      if (!authResult.isSuccess) {
        if (mounted) {
          AppSnackbar.show(
            'Face lock not enabled',
            authResult.message ?? 'Authentication failed',

          );
        }
        if (!mounted) return;
        setState(() {
          _isUpdatingFaceLock = false;
        });
        return;
      }
    }

    await _appSettingsService.setFaceLockEnabled(enable);

    if (!mounted) return;
    setState(() {
      _faceLockEnabled = enable;
      _isUpdatingFaceLock = false;
    });
  }

  Future<void> _toggleDarkMode(bool enable) async {
    if (_isUpdatingDarkMode) return;

    setState(() {
      _isUpdatingDarkMode = true;
    });

    await _appSettingsService.setDarkModeEnabled(enable);
    Get.changeThemeMode(enable ? ThemeMode.dark : ThemeMode.light);

    if (!mounted) return;
    setState(() {
      _darkModeEnabled = enable;
      _isUpdatingDarkMode = false;
    });
  }

  void _showComingSoon(String feature) {
    AppSnackbar.show(
      feature,
      'This option is added in UI and will be wired later.',

    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommonScreenAppBar(title: 'General Settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _ActionSettingTile(
                  icon: Icons.image_outlined,
                  title: 'Change Logo',
                  subtitle: 'Upload and set a new company logo',
                  onTap: () => _showComingSoon('Change Logo'),
                ),
                const SizedBox(height: 10),
                _DisabledToggleTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle: 'Email and push notifications',
                ),
                const SizedBox(height: 10),
                _ActionSettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => _showComingSoon('Change Password'),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => _ToggleSettingTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric Lock',
                    subtitle: 'Use biometrics to unlock app login',
                    value: _authController.biometricEnabled.value,
                    isBusy: _isUpdatingBiometric,
                    onChanged: _toggleBiometric,
                  ),
                ),
                const SizedBox(height: 10),
                // _ToggleSettingTile(
                //   icon: Icons.face_retouching_natural,
                //   title: 'Face Lock',
                //   subtitle: 'Require face authentication where available',
                //   value: _faceLockEnabled,
                //   isBusy: _isUpdatingFaceLock,
                //   onChanged: _toggleFaceLock,
                // ),
                const SizedBox(height: 10),
                // _ToggleSettingTile(
                //   icon: Icons.dark_mode_outlined,
                //   title: 'Dark Mode',
                //   subtitle: 'Switch app appearance to dark theme',
                //   value: _darkModeEnabled,
                //   isBusy: _isUpdatingDarkMode,
                //   onChanged: _toggleDarkMode,
                // ),
                // const SizedBox(height: 16),
                // Text(
                //   'Only biometric lock, face lock, and dark mode are active. Other options are placeholders.',
                //   style: theme.textTheme.bodyMedium?.copyWith(
                //     color: theme.colorScheme.onSurface.withOpacity(0.65),
                //   ),
                // ),
              ],
            ),
    );
  }
}

class _BaseTile extends StatelessWidget {
  const _BaseTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withOpacity(0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionSettingTile extends StatelessWidget {
  const _ActionSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _ToggleSettingTile extends StatelessWidget {
  const _ToggleSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isBusy,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: isBusy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Switch(value: value, onChanged: onChanged),
    );
  }
}

class _DisabledToggleTile extends StatelessWidget {
  const _DisabledToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Switch(value: false, onChanged: null),
    );
  }
}

