import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../core/utils/app_snackbar.dart';
import '../models/team_setting_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class TeamSettingsScreen extends StatefulWidget {
  const TeamSettingsScreen({super.key});

  @override
  State<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends State<TeamSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_TeamDraft> _teams = <_TeamDraft>[];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTeamSettings();
  }

  @override
  void dispose() {
    for (final team in _teams) {
      team.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTeamSettings() async {
    setState(() => _isLoading = true);
    try {
      final records = await ApiService.instance.getTeamSettings();
      for (final item in _teams) {
        item.dispose();
      }
      _teams
        ..clear()
        ..addAll(
          records.isEmpty
              ? <_TeamDraft>[_TeamDraft.empty()]
              : records.map(_TeamDraft.fromModel),
        );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        _messageFromError(error, fallback: 'Unable to load team settings.'),
        isError: true,
      );
      if (_teams.isEmpty) {
        _teams.add(_TeamDraft.empty());
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        'Unable to load team settings.',
        isError: true,
      );
      if (_teams.isEmpty) {
        _teams.add(_TeamDraft.empty());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addTeam() {
    setState(() => _teams.add(_TeamDraft.empty()));
  }

  void _removeTeam(int index) {
    if (index < 0 || index >= _teams.length) return;
    setState(() {
      if (_teams.length == 1) {
        final item = _teams.first;
        item.nameController.clear();
        item.descriptionController.clear();
        item.existingIconPath = '';
        item.iconUrl = '';
        item.newIconPath = '';
        item.newIconBytes = null;
        return;
      }
      final removed = _teams.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickIcon(int index) async {
    if (index < 0 || index >= _teams.length) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty || !mounted) return;

    final file = picked.files.single;
    final path = file.path ?? '';
    if (path.isEmpty) {
      AppSnackbar.show(
        'Pick failed',
        'Unable to access selected file path.',
        isError: true,
      );
      return;
    }

    setState(() {
      final row = _teams[index];
      row.newIconPath = path;
      row.newIconBytes = file.bytes;
    });
  }

  Future<void> _saveTeams() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final models = _teams
        .map(
          (entry) => TeamSettingModel(
            name: entry.nameController.text.trim(),
            description: entry.descriptionController.text.trim(),
            iconUrl: entry.iconUrl,
            existingIconPath: entry.existingIconPath,
            newIconPath: entry.newIconPath,
          ),
        )
        .toList(growable: false);

    setState(() => _isSaving = true);
    try {
      final updated = await ApiService.instance.updateTeamSettings(models);
      for (final item in _teams) {
        item.dispose();
      }
      _teams
        ..clear()
        ..addAll(
          updated.isEmpty
              ? <_TeamDraft>[_TeamDraft.empty()]
              : updated.map(_TeamDraft.fromModel),
        );

      if (!mounted) return;
      setState(() {});
      AppSnackbar.show(
        'Saved',
        'Team settings saved successfully.',
        isSuccess: true,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        _messageFromError(error, fallback: 'Unable to save team settings.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Save failed',
        'Unable to save team settings.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _messageFromError(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    final message = error.message?.trim() ?? '';
    return message.isEmpty ? fallback : message;
  }

  String _iconLabel(_TeamDraft draft) {
    if (draft.newIconPath.trim().isNotEmpty) {
      return draft.newIconPath.split(RegExp(r'[\\/]')).last;
    }
    if (draft.existingIconPath.trim().isNotEmpty) {
      return draft.existingIconPath.split(RegExp(r'[\\/]')).last;
    }
    return 'No file selected';
  }

  String _resolveRemoteIcon(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final uri = Uri.parse(ApiConstants.baseUrl);
    final origin = '${uri.scheme}://${uri.authority}';
    if (value.startsWith('/')) {
      return '$origin$value';
    }
    return '$origin/$value';
  }

  Widget _buildIconPreview(_TeamDraft draft) {
    if (draft.newIconBytes != null && draft.newIconBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          draft.newIconBytes!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      );
    }

    final remote = _resolveRemoteIcon(
      draft.iconUrl.trim().isNotEmpty ? draft.iconUrl : draft.existingIconPath,
    );
    if (remote.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          remote,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.groups_rounded,
            size: 24,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return const Icon(Icons.groups_rounded, size: 24, color: Color(0xFF64748B));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonScreenAppBar(title: 'Team Settings'),
      backgroundColor: const Color(0xFFF4F8FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTeamSettings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Team Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),
                        const Text(
                          'Teams',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < _teams.length; i++) ...[
                          _buildTeamCard(i, _teams[i]),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 4),
                        const Text(
                          'These teams will appear in staff forms and client issue assignment popup.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _addTeam,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Team'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isSaving ? null : _saveTeams,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF178BEB),
                                foregroundColor: Colors.white,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save Teams'),
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
  }

  Widget _buildTeamCard(int index, _TeamDraft draft) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 860;

          final nameField = _buildTextField(
            label: 'Team Name',
            controller: draft.nameController,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Team name is required';
              }
              return null;
            },
          );

          final descriptionField = _buildTextField(
            label: 'Description',
            controller: draft.descriptionController,
          );

          final iconField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD7DFEA)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _iconLabel(draft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _pickIcon(index),
                    child: const Text('Choose File'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _removeTeam(index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                    child: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nameField,
                const SizedBox(height: 10),
                descriptionField,
                const SizedBox(height: 10),
                iconField,
                const SizedBox(height: 10),
                _buildIconPreview(draft),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nameField),
                  const SizedBox(width: 10),
                  Expanded(child: descriptionField),
                  const SizedBox(width: 10),
                  Expanded(child: iconField),
                ],
              ),
              const SizedBox(height: 10),
              _buildIconPreview(draft),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF178BEB)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamDraft {
  _TeamDraft({
    required this.nameController,
    required this.descriptionController,
    required this.iconUrl,
    required this.existingIconPath,
    required this.newIconPath,
    required this.newIconBytes,
  });

  factory _TeamDraft.empty() {
    return _TeamDraft(
      nameController: TextEditingController(),
      descriptionController: TextEditingController(),
      iconUrl: '',
      existingIconPath: '',
      newIconPath: '',
      newIconBytes: null,
    );
  }

  factory _TeamDraft.fromModel(TeamSettingModel model) {
    return _TeamDraft(
      nameController: TextEditingController(text: model.name),
      descriptionController: TextEditingController(text: model.description),
      iconUrl: model.iconUrl,
      existingIconPath: model.existingIconPath,
      newIconPath: model.newIconPath,
      newIconBytes: null,
    );
  }

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  String iconUrl;
  String existingIconPath;
  String newIconPath;
  Uint8List? newIconBytes;

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
  }
}
