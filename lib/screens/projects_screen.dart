import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/services/permission_service.dart';
import 'package:mycrm/models/project_model.dart';
import 'package:mycrm/services/api_service.dart';

import '../routes/app_routes.dart';
import '../screens/to_do_list.dart' as to_do;
import '../widgets/app_bottom_navigation.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

/// Projects overview screen inspired by the provided mockup.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, this.staffId, this.staffName});

  final String? staffId;
  final String? staffName;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<ProjectModel>> _projectsFuture;
  String? _deletingProjectId;
  String? _staffFilterId;
  String _staffFilterName = '';

  @override
  void initState() {
    super.initState();
    final widgetStaffId = (widget.staffId ?? '').toString().trim();
    final widgetStaffName = (widget.staffName ?? '').toString().trim();
    if (widgetStaffId.isNotEmpty) {
      _staffFilterId = widgetStaffId;
    }
    if (widgetStaffName.isNotEmpty) {
      _staffFilterName = widgetStaffName;
    }

    if ((_staffFilterId ?? '').trim().isEmpty) {
      final arguments = Get.arguments;
      if (arguments is Map) {
        final map = arguments.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final staffId = (map['staffId'] ?? '').toString().trim();
        final staffName = (map['staffName'] ?? '').toString().trim();
        if (staffId.isNotEmpty) {
          _staffFilterId = staffId;
        }
        if (_staffFilterName.trim().isEmpty && staffName.isNotEmpty) {
          _staffFilterName = staffName;
        }
      }
    }
    _projectsFuture = (_staffFilterId ?? '').trim().isNotEmpty
        ? ApiService.instance.getStaffProjectsList(_staffFilterId!)
        : ApiService.instance.getProjectsList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _projectsFuture = (_staffFilterId ?? '').trim().isNotEmpty
          ? ApiService.instance.getStaffProjectsList(_staffFilterId!)
          : ApiService.instance.getProjectsList();
    });
  }

  Future<void> _deleteProject(ProjectModel project) async {
    final projectId = project.id.trim();
    if (projectId.isEmpty) {
      AppSnackbar.show('Delete failed', 'Project id is missing.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Project',
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Delete ${project.title.isNotEmpty ? project.title : 'this project'} permanently?',
            style: AppTextStyles.style(
              color: const Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyles.style(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: AppTextStyles.style(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() => _deletingProjectId = projectId);

    try {
      await ApiService.instance.deleteProject(projectId);
      if (!mounted) return;

      AppSnackbar.show(
        'Project deleted',
        '${project.title.isNotEmpty ? project.title : 'The project'} was deleted successfully.',
      );
      _reload();
    } on DioException catch (error) {
      if (!mounted) return;

      AppSnackbar.show('Delete failed', _resolveDeleteError(error));
    } catch (error) {
      if (!mounted) return;

      AppSnackbar.show(
        'Delete failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingProjectId = null);
      }
    }
  }

  Future<void> _editProject(ProjectModel project) async {
    final result = await Get.toNamed(
      AppRoutes.addProject,
      arguments: {'id': project.id},
    );

    if (result == true && mounted) {
      _reload();
    }
  }

  String _resolveDeleteError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) {
        return message;
      }
    }

    final fallback = error.message?.trim() ?? '';
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Failed to delete project.';
  }

  List<ProjectModel> _filterProjects(List<ProjectModel> projects) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return projects;
    }

    return projects.where((project) {
      final haystack = [
        project.title,
        project.client,
        project.status,
        project.startDate,
        project.deadline,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  List<ProjectModel> _applyStaffFilter(List<ProjectModel> projects) {
    final staffId = _staffFilterId?.trim() ?? '';
    final staffName = _normalizeName(_staffFilterName);
    if (staffId.isEmpty && staffName.isEmpty) {
      return projects;
    }

    return projects.where((project) {
      return project.members.any((member) {
        final memberId = member.id.trim();
        if (staffId.isNotEmpty && memberId == staffId) {
          return true;
        }
        if (staffName.isEmpty) {
          return false;
        }
        final memberName = _normalizeName(member.name);
        if (memberName.isEmpty) {
          return false;
        }
        if (memberName == staffName) {
          return true;
        }
        if (memberName.length >= 3 &&
            staffName.length >= 3 &&
            (memberName.contains(staffName) ||
                staffName.contains(memberName))) {
          return true;
        }
        return false;
      });
    }).toList();
  }

  String _normalizeName(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(' ').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.projects,
      ),
      body: SafeArea(
        child: FutureBuilder<List<ProjectModel>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            final allProjects = snapshot.data ?? const <ProjectModel>[];
            final staffId = _staffFilterId?.trim() ?? '';
            final projects = staffId.isNotEmpty
                ? allProjects
                : _applyStaffFilter(allProjects);
            final filteredProjects = _filterProjects(projects);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 360;
                final horizontalPadding = isCompact ? 16.0 : 20.0;
                final maxWidth = constraints.maxWidth > 560
                    ? 560.0
                    : double.infinity;

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      120,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _ProjectsHeader(),
                            const SizedBox(height: 18),
                            _SummaryRow(
                              isCompact: isCompact,
                              totalProjects: projects.length,
                              planningProjects: projects
                                  .where(
                                    (project) => project.status
                                        .toLowerCase()
                                        .contains('planning'),
                                  )
                                  .length,
                            ),
                            const SizedBox(height: 20),
                            _TeamWorkloadSection(projects: projects),
                            const SizedBox(height: 18),
                            _ProjectsToolbar(
                              controller: _searchController,
                              onSearchChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            _ProjectsListSection(
                              snapshot: snapshot,
                              projects: filteredProjects,
                              hasSearch: _searchController.text
                                  .trim()
                                  .isNotEmpty,
                              deletingProjectId: _deletingProjectId,
                              onEdit: _editProject,
                              onDelete: _deleteProject,
                              onRetry: _reload,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProjectsHeader extends StatelessWidget {
  const _ProjectsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Projects',
            style: AppTextStyles.style(
              color: const Color(0xFF1E2A3B),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _HeaderIconButton(
          icon: Icons.checklist_rounded,
          onTap: () => Get.to(() => const to_do.ToDoListScreen()),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF2D3B52), size: 22),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.isCompact,
    required this.totalProjects,
    required this.planningProjects,
  });

  final bool isCompact;
  final int totalProjects;
  final int planningProjects;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF4F5D74),
                value: '$totalProjects',
                label: 'Total Projects',
                percent: 'API',
                accent: const Color(0xFF4F5D74),
                isCompact: isCompact,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricCard(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF8B5CF6),
                value: '$planningProjects',
                label: 'Planning',
                percent: 'API',
                accent: const Color(0xFF8B5CF6),
                isCompact: isCompact,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProjectsToolbar extends StatelessWidget {
  const _ProjectsToolbar({required this.controller, this.onSearchChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchField(controller: controller, onChanged: onSearchChanged),
              SizedBox(height: 12),
              const _FilterRow(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _SearchField(
                controller: controller,
                onChanged: onSearchChanged,
              ),
            ),
            SizedBox(width: 12),
            const Expanded(flex: 5, child: _FilterRow()),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.percent,
    required this.accent,
    required this.isCompact,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String percent;
  final Color accent;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 18,
        isCompact ? 16 : 18,
        isCompact ? 14 : 18,
        isCompact ? 16 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                percent,
                style: AppTextStyles.style(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.style(
              color: const Color(0xFF1E2A3B),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.style(
              color: const Color(0xFF7C8BA1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamWorkloadSection extends StatelessWidget {
  const _TeamWorkloadSection({required this.projects});

  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    final members = _buildTeamWorkload(projects);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Team Workload',
              style: AppTextStyles.style(
                color: const Color(0xFF1E2A3B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (members.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E9F2)),
            ),
            child: Text(
              'No assigned members found in the current projects.',
              style: AppTextStyles.style(
                color: const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final member = members[index];
                return _TeamMemberCard(member: member);
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: members.length,
            ),
          ),
      ],
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({required this.member});

  final _TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _AvatarCircle(
              radius: 30,
              initials: member.initials,
              avatarColor: member.avatarColor,
              profileImage: member.profileImage,
            ),
            Positioned(
              top: 0,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D6FEA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  member.count.toString(),
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: member.statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          member.name,
          style: AppTextStyles.style(
            color: const Color(0xFF4C5B70),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          icon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9AA7B7),
            size: 20,
          ),
          hintText: 'Search projects',
          hintStyle: AppTextStyles.style(
            color: const Color(0xFF8A98AD),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Expanded(
                    child: _FilterChip(
                      label: 'Project Status',
                      icon: Icons.keyboard_arrow_down_rounded,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FilterChip(
                      label: 'Show: 10 entries',
                      icon: Icons.keyboard_arrow_down_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _CreateProjectButton(),
                  SizedBox(width: 10),
                  _ViewAllButton(),
                ],
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FilterChip(
              label: 'Project Status',
              icon: Icons.keyboard_arrow_down_rounded,
            ),
            const SizedBox(width: 10),
            const _FilterChip(
              label: 'Show: 10 entries',
              icon: Icons.keyboard_arrow_down_rounded,
            ),
            const SizedBox(width: 10),
            const _ViewAllButton(),
            const SizedBox(width: 10),
            const _CreateProjectButton(),
          ],
        );
      },
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E8F2)),
          ),
          child: Text(
            'View All',
            style: AppTextStyles.style(
              color: const Color(0xFF1D6FEA),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateProjectButton extends StatelessWidget {
  const _CreateProjectButton();

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: AppPermission.createProjects,
      child: Material(
        color: const Color(0xFF1D6FEA),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.addProject),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Create Project',
                  style: AppTextStyles.style(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F2)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              color: const Color(0xFF2F3D52),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: const Color(0xFF5F7087)),
        ],
      ),
    );
  }
}

class _ProjectsListSection extends StatelessWidget {
  const _ProjectsListSection({
    required this.snapshot,
    required this.projects,
    required this.hasSearch,
    required this.deletingProjectId,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
  });

  final AsyncSnapshot<List<ProjectModel>> snapshot;
  final List<ProjectModel> projects;
  final bool hasSearch;
  final String? deletingProjectId;
  final Future<void> Function(ProjectModel project) onEdit;
  final Future<void> Function(ProjectModel project) onDelete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _ProjectsLoadingState();
    }

    if (snapshot.hasError) {
      return _ProjectsErrorState(onRetry: onRetry);
    }

    if (projects.isEmpty) {
      return _ProjectsEmptyState(hasSearch: hasSearch);
    }

    return Column(
      children: projects
          .map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ProjectCard(
                data: _toProjectCardData(project),
                isDeleting: deletingProjectId == project.id,
                onEdit: () => onEdit(project),
                onDelete: () => onDelete(project),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProjectsLoadingState extends StatelessWidget {
  const _ProjectsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E9F2)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProjectsErrorState extends StatelessWidget {
  const _ProjectsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E9F2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 34,
            color: Color(0xFFB42318),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load projects',
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or retry the request.',
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: const Color(0xFF1D6FEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Retry',
                style: AppTextStyles.style(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsEmptyState extends StatelessWidget {
  const _ProjectsEmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E9F2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.folder_off_rounded,
            size: 34,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? 'No matching projects found' : 'No projects available',
            style: AppTextStyles.style(
              color: const Color(0xFF162033),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term.'
                : 'Projects returned by the API will appear here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.data,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final _ProjectCardData data;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () =>
            Get.toNamed(AppRoutes.projectDetail, arguments: {'id': data.id}),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E9F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 170,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(22),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stackedHeader = constraints.maxWidth < 260;

                          if (stackedHeader) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.title,
                                  style: AppTextStyles.style(
                                    color: const Color(0xFF1E2A3B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _StatusChip(data: data),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data.title,
                                  style: AppTextStyles.style(
                                    color: const Color(0xFF1E2A3B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _StatusChip(data: data),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.client,
                        style: AppTextStyles.style(
                          color: const Color(0xFF76839A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _ProjectInfoItem(
                            icon: Icons.calendar_today_rounded,
                            label: data.startDate,
                          ),
                          _ProjectInfoItem(
                            icon: Icons.event_rounded,
                            label: data.deadline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 290) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ProjectProgressSection(data: data),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _ProjectAssigneeStack(
                                      members: data.members,
                                    ),
                                    _ProjectQuickActions(
                                      data: data,
                                      isDeleting: isDeleting,
                                      onEdit: onEdit,
                                      onDelete: onDelete,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _ProjectProgressSection(data: data),
                              ),
                              const SizedBox(width: 16),
                              _ProjectAssigneeStack(members: data.members),
                              const SizedBox(width: 12),
                              _ProjectQuickActions(
                                data: data,
                                isDeleting: isDeleting,
                                onEdit: onEdit,
                                onDelete: onDelete,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.data});

  final _ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: data.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        data.status,
        style: AppTextStyles.style(
          color: data.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectProgressSection extends StatelessWidget {
  const _ProjectProgressSection({required this.data});

  final _ProjectCardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: AppTextStyles.style(
                color: const Color(0xFF76839A),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${(data.progress * 100).toInt()}%',
              style: AppTextStyles.style(
                color: const Color(0xFF1E2A3B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: data.progress,
            backgroundColor: const Color(0xFFF0F4F9),
            valueColor: AlwaysStoppedAnimation(data.accentColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _ProjectAssigneeStack extends StatelessWidget {
  const _ProjectAssigneeStack({required this.members});

  final List<ProjectMemberModel> members;

  @override
  Widget build(BuildContext context) {
    final visibleMembers = members.take(3).toList();
    final extraCount = members.length - visibleMembers.length;
    final stackWidth = visibleMembers.isEmpty
        ? 32.0
        : 28.0 +
              ((visibleMembers.length - 1) * 14.0) +
              (extraCount > 0 ? 24.0 : 0.0);

    return SizedBox(
      height: 32,
      width: stackWidth,
      child: Stack(
        children: [
          for (var i = 0; i < visibleMembers.length; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _AvatarCircle(
                  radius: 14,
                  initials: _memberInitials(visibleMembers[i].name),
                  avatarColor: _memberAccentColor(
                    _memberKey(visibleMembers[i]),
                  ),
                  profileImage: visibleMembers[i].profileImage,
                ),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: visibleMembers.length * 14.0,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2E8F0),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '+$extraCount',
                  style: AppTextStyles.style(
                    color: const Color(0xFF475569),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectCardAction extends StatelessWidget {
  const _ProjectCardAction({
    required this.icon,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isDestructive
        ? const Color(0xFFB42318)
        : const Color(0xFF1D4ED8);
    final backgroundColor = isDestructive
        ? const Color(0xFFFEE4E2)
        : const Color(0xFFE8F0FE);

    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: foregroundColor, size: 18),
        ),
      ),
    );
  }
}

class _ProjectQuickActions extends StatelessWidget {
  const _ProjectQuickActions({
    required this.data,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final _ProjectCardData data;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PermissionGate(
          permission: AppPermission.editProjects,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProjectCardAction(
                icon: Icons.edit_outlined,
                onTap: isDeleting ? null : onEdit,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        PermissionGate(
          permission: AppPermission.deleteProjects,
          child: _ProjectCardAction(
            icon: Icons.delete_outline_rounded,
            isDestructive: true,
            onTap: isDeleting ? null : onDelete,
          ),
        ),
      ],
    );
  }
}

class _ProjectInfoItem extends StatelessWidget {
  const _ProjectInfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9AA7B7)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF586A82),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

_ProjectCardData _toProjectCardData(ProjectModel project) {
  return _ProjectCardData(
    id: project.id,
    title: project.title,
    client: project.client,
    status: project.status,
    startDate: project.startDate,
    deadline: project.deadline,
    progress: project.progress,
    accentColor: _projectAccentColor(project),
    members: project.members,
  );
}

Color _projectAccentColor(ProjectModel project) {
  final status = project.status.toLowerCase();

  if (status.contains('progress') || status.contains('active')) {
    return const Color(0xFF1D6FEA);
  }

  if (status.contains('planning')) {
    return const Color(0xFF8B5CF6);
  }

  if (status.contains('hold') || status.contains('pending')) {
    return const Color(0xFFF59E0B);
  }

  if (status.contains('complete') || status.contains('done')) {
    return const Color(0xFF10B981);
  }

  return const Color(0xFF4F5D74);
}

class _TeamMember {
  const _TeamMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.statusColor,
    required this.count,
    this.profileImage,
  });

  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final Color statusColor;
  final int count;
  final String? profileImage;
}

class _ProjectCardData {
  const _ProjectCardData({
    required this.id,
    required this.title,
    required this.client,
    required this.status,
    required this.startDate,
    required this.deadline,
    required this.progress,
    required this.accentColor,
    required this.members,
  });

  final String id;
  final String title;
  final String client;
  final String status;
  final String startDate;
  final String deadline;
  final double progress;
  final Color accentColor;
  final List<ProjectMemberModel> members;
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.radius,
    required this.initials,
    required this.avatarColor,
    this.profileImage,
  });

  final double radius;
  final String initials;
  final Color avatarColor;
  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profileImage?.trim() ?? '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor.withOpacity(0.18),
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isNotEmpty
          ? null
          : Text(
              initials,
              style: AppTextStyles.style(
                color: avatarColor,
                fontSize: radius <= 14 ? 10 : 13,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

List<_TeamMember> _buildTeamWorkload(List<ProjectModel> projects) {
  final membersByKey = <String, _TeamMember>{};

  for (final project in projects) {
    final seenInProject = <String>{};

    for (final member in project.members) {
      final key = _memberKey(member);
      if (key.isEmpty || !seenInProject.add(key)) {
        continue;
      }

      final existing = membersByKey[key];
      if (existing == null) {
        membersByKey[key] = _TeamMember(
          id: key,
          name: _memberFirstName(member.name),
          initials: _memberInitials(member.name),
          avatarColor: _memberAccentColor(key),
          statusColor: member.isActive
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
          count: 1,
          profileImage: member.profileImage,
        );
        continue;
      }

      membersByKey[key] = _TeamMember(
        id: existing.id,
        name: existing.name,
        initials: existing.initials,
        avatarColor: existing.avatarColor,
        statusColor: existing.statusColor,
        count: existing.count + 1,
        profileImage: existing.profileImage ?? member.profileImage,
      );
    }
  }

  final members = membersByKey.values.toList()
    ..sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) {
        return countCompare;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  return members;
}

String _memberKey(ProjectMemberModel member) {
  final normalizedId = member.id.trim();
  if (normalizedId.isNotEmpty) {
    return normalizedId;
  }
  return member.name.trim().toLowerCase();
}

String _memberInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _memberFirstName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return '';
  }

  return parts.first;
}

Color _memberAccentColor(String seed) {
  const colors = [
    Color(0xFF1D6FEA),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF0EA5E9),
  ];

  final hash = seed.codeUnits.fold<int>(0, (value, unit) => value + unit);
  return colors[hash % colors.length];
}
