import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Displays authenticated user details from `/me`.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final ApiService _apiService = ApiService.instance;
  late Future<UserModel> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _apiService.getCurrentUser();
  }

  Future<void> _refresh() async {
    final next = _apiService.getCurrentUser();
    setState(() {
      _userFuture = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFEEF5FB)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<UserModel>(
            future: _userFuture,
            builder: (context, snapshot) {
              return RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    _Header(onBack: Get.back),
                    const SizedBox(height: 14),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const _LoadingCard()
                    else if (snapshot.hasError)
                      _ErrorCard(onRetry: _refresh)
                    else if (!snapshot.hasData)
                      _ErrorCard(
                        onRetry: _refresh,
                        message: 'No user data found',
                      )
                    else
                      _ProfileDetailsCard(user: snapshot.data!),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Personal Information',
            style: AppTextStyles.title(
              color: AppColors.primaryBlue,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wide = size.width >= 860;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x130F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _LeftIdentityCard(user: user)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _DetailsPanel(user: user)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LeftIdentityCard(user: user),
                const SizedBox(height: 16),
                _DetailsPanel(user: user),
              ],
            ),
    );
  }
}

class _LeftIdentityCard extends StatelessWidget {
  const _LeftIdentityCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final roleText = (user.role ?? '').trim().isEmpty
        ? 'Staff'
        : user.role!.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5FAFF), Color(0xFFEAF4FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          _ProfileAvatar(
            name: user.name,
            imageUrl: _normalizeImageUrl(user.profilePicture),
          ),
          const SizedBox(height: 14),
          Text(
            user.name.trim().isEmpty ? 'Unknown User' : user.name.trim(),
            textAlign: TextAlign.center,
            style: AppTextStyles.title(
              color: AppColors.primaryText,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            roleText,
            style: AppTextStyles.subtitle(
              color: AppColors.secondaryText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email.trim().isEmpty ? 'Not available' : user.email.trim(),
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              color: AppColors.secondaryText,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(name);
    final showImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0EA5E9), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0EA5E9),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFE6F4FF),
        backgroundImage: showImage ? NetworkImage(imageUrl!.trim()) : null,
        child: showImage
            ? null
            : Text(
                initials,
                style: AppTextStyles.title(
                  color: AppColors.primaryBlue,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _ProfileField(
          //   label: 'Profile Image',
          //   value: _normalizeImageUrl(user.profilePicture) ?? 'Not uploaded',
          //   icon: Icons.image_outlined,
          // ),
          const SizedBox(height: 12),
          _ProfileField(
            label: 'Full Name',
            value: user.name.trim().isEmpty
                ? 'Not available'
                : user.name.trim(),
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            label: 'Email',
            value: user.email.trim().isEmpty
                ? 'Not available'
                : user.email.trim(),
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 12),
          _ProfileField(
            label: 'Phone',
            value: (user.phone ?? '').trim().isEmpty
                ? 'Not available'
                : user.phone!.trim(),
            icon: Icons.call_outlined,
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.subtitle(
            color: AppColors.primaryBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.secondaryText, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.body(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const CircularProgressIndicator(color: AppColors.primaryBlue),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.onRetry,
    this.message = 'Unable to load personal information.',
  });

  final Future<void> Function() onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.dangerRed),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              color: AppColors.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => onRetry(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String? _normalizeImageUrl(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  final parsed = Uri.tryParse(value);
  if (parsed != null && parsed.hasScheme) {
    return value;
  }
  final base = Uri.parse(ApiConstants.baseUrl);
  final root = Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
  );
  final normalizedPath = value.startsWith('/') ? value : '/$value';
  return root.resolve(normalizedPath).toString();
}

String _buildInitials(String source) {
  final tokens = source
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (tokens.isEmpty) return 'U';
  if (tokens.length == 1) {
    final single = tokens.first;
    final take = single.length >= 2 ? 2 : 1;
    return single.substring(0, take).toUpperCase();
  }
  final first = tokens.first.substring(0, 1);
  final second = tokens[1].substring(0, 1);
  return '$first$second'.toUpperCase();
}
