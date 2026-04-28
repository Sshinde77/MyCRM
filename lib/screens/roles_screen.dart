import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/models/role_model.dart';
import 'package:mycrm/providers/role_provider.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:provider/provider.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  bool _hasRequestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasRequestedLoad) {
      return;
    }

    _hasRequestedLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<RoleProvider>().loadRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CommonScreenAppBar(title: 'Roles'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: Consumer<RoleProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.loadRoles(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'TOTAL ROLES',
                          count: provider.totalRoles.toString(),
                          icon: Icons.people_outline_rounded,
                          backgroundColor: const Color(0xFFEFF6FF),
                          accentColor: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'ACTIVE',
                          count: provider.activeRoles.toString(),
                          icon: Icons.check_circle_outline_rounded,
                          backgroundColor: const Color(0xFFF0FDF4),
                          accentColor: const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'PERMISSIONS',
                          count: provider.permissionsCount.toString(),
                          icon: Icons.lock_outline_rounded,
                          backgroundColor: const Color(0xFFFFFBEB),
                          accentColor: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _RoleSearchField(
                    initialValue: provider.searchQuery,
                    onChanged: provider.updateSearchQuery,
                  ),
                  const SizedBox(height: 24),
                  if (provider.isLoading && provider.totalRoles == 0)
                    const _RolesLoadingState()
                  else if (provider.errorMessage != null &&
                      provider.totalRoles == 0)
                    _RolesErrorState(
                      message: provider.errorMessage!,
                      onRetry: () => provider.loadRoles(forceRefresh: true),
                    )
                  else if (provider.roles.isEmpty)
                    const _RolesEmptyState()
                  else
                    ..._buildRoleCards(provider.roles),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildRoleCards(List<RoleModel> roles) {
    final children = <Widget>[];
    for (var index = 0; index < roles.length; index++) {
      final role = roles[index];
      children.add(
        _RoleCard(
          title: role.displayName,
          description: role.displayDescription,
          permissions: role.permissionsCount,
          status: role.displayStatus,
          isActive: role.isActive,
        ),
      );
      if (index != roles.length - 1) {
        children.add(const SizedBox(height: 16));
      }
    }
    return children;
  }
}

class _RoleSearchField extends StatelessWidget {
  const _RoleSearchField({required this.initialValue, required this.onChanged});

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search roles by name...',
          hintStyle: AppTextStyles.style(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _RolesLoadingState extends StatelessWidget {
  const _RolesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
    );
  }
}

class _RolesErrorState extends StatelessWidget {
  const _RolesErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _RolesEmptyState extends StatelessWidget {
  const _RolesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            color: Color(0xFF94A3B8),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'No roles found.',
            style: AppTextStyles.style(
              color: const Color(0xFF475569),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: AppTextStyles.style(
              color: const Color(0xFF1E293B),
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: accentColor.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.permissions,
    required this.status,
    required this.isActive,
  });

  final String title;
  final String description;
  final int permissions;
  final String status;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.style(
                  color: const Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.style(
                    color: isActive
                        ? const Color(0xFF166534)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, color: Color(0xFF64748B), size: 16),
                const SizedBox(width: 6),
                Text(
                  '$permissions Permissions',
                  style: AppTextStyles.style(
                    color: const Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // _ActionButton(
              //   icon: Icons.edit_outlined,
              //   color: const Color(0xFF3B82F6),
              //   backgroundColor: const Color(0xFFEFF6FF),
              //   onTap: () {},
              // ),
              // const SizedBox(width: 12),
              // _ActionButton(
              //   icon: Icons.delete_outline_rounded,
              //   color: const Color(0xFFEF4444),
              //   backgroundColor: const Color(0xFFFEF2F2),
              //   onTap: () {},
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
