import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' as getx;
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../core/services/permission_service.dart';
import '../core/utils/app_snackbar.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

/// Full-page Social Media Post Detail & Lifecycle Management Screen.
class SocialPostDetailScreen extends StatefulWidget {
  const SocialPostDetailScreen({
    super.key,
    required this.postId,
    this.initialData,
  });

  final String postId;
  final Map<String, dynamic>? initialData;

  @override
  State<SocialPostDetailScreen> createState() => _SocialPostDetailScreenState();
}

class _SocialPostDetailScreenState extends State<SocialPostDetailScreen> {
  final ApiService _api = ApiService.instance;
  final TextEditingController _commentController = TextEditingController();
  bool _isCommentInternal = false;

  bool _isLoading = true;
  bool _isSubmittingAction = false;
  String? _errorMessage;
  Map<String, dynamic> _post = {};
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _post = Map<String, dynamic>.from(widget.initialData!);
      _isLoading = false;
    }
    _loadUserAndPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndPost() async {
    final user = await PermissionService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
    await _loadPostDetails();
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List) {
      return value.map(_map).toList();
    }
    return <Map<String, dynamic>>[];
  }

  String _val(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final v = _post[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return fallback;
  }

  String get _currentStatus => _val(['status'], 'planned').toLowerCase();

  // ===================== ROLE & PERMISSION CHECKS =====================

  /// Whether current user is an external client.
  bool get _isClient {
    final role = (_currentUser?.role ?? '').trim().toLowerCase();
    if (role == 'client') return true;

    final clientId = _val(['client_id', 'clientId']);
    final currentUserId = (_currentUser?.id ?? '').trim();
    if (clientId.isNotEmpty && currentUserId.isNotEmpty && clientId == currentUserId) {
      return true;
    }
    return false;
  }

  /// Whether current user is explicitly assigned to this specific post.
  bool get _isAssigned {
    final currentUserId = (_currentUser?.id ?? '').trim();
    if (currentUserId.isEmpty) return false;

    // 1. Check assignments list: $post->assignments->contains('user_id', auth()->id())
    final assignments = _list(_post['assignments'] ?? _post['social_post_assignments']);
    for (final a in assignments) {
      final uid = (a['user_id'] ?? a['staff_id'] ?? a['id'])?.toString().trim();
      if (uid == currentUserId) return true;
    }

    // 2. Check direct assigned staff fields
    final assignedStaffId = _val([
      'assigned_staff_id',
      'staff_id',
      'assigned_to',
      'assigned_user_id',
    ]);
    if (assignedStaffId.isNotEmpty && assignedStaffId == currentUserId) {
      return true;
    }

    // 3. Check assigned staff array
    final assignedStaff = _post['assigned_staff'] ?? _post['assigned_users'];
    if (assignedStaff is List) {
      for (final s in assignedStaff) {
        if (s is Map) {
          final uid = (s['id'] ?? s['user_id'])?.toString().trim();
          if (uid == currentUserId) return true;
        } else if (s.toString().trim() == currentUserId) {
          return true;
        }
      }
    }

    return false;
  }

  /// Whether user is allowed to view the creative brief, caption, hashtags, and media gallery.
  /// Staff/Admin: Always sees creative.
  /// Client: Only visible from `pending_client_approval` onwards.
  bool get _canSeeCreative {
    if (!_isClient) return true;
    return const [
      'pending_client_approval',
      'client_approved',
      'client_changes_requested',
      'ready_for_publishing',
      'scheduled',
      'published',
    ].contains(_currentStatus);
  }

  String _formatClient(dynamic clientRaw) {
    if (clientRaw == null) return _val(['client_name'], '—');
    if (clientRaw is Map) {
      final map = _map(clientRaw);
      final first = map['first_name']?.toString().trim() ?? '';
      final last = map['last_name']?.toString().trim() ?? '';
      final fullName = '$first $last'.trim();
      if (fullName.isNotEmpty) return fullName;
      final company = map['company_name']?.toString().trim() ?? '';
      if (company.isNotEmpty) return company;
      final name = map['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
      final email = map['email']?.toString().trim() ?? '';
      if (email.isNotEmpty) return email;
      return 'Client #${map['id'] ?? ''}'.trim();
    }
    return clientRaw.toString();
  }

  String _formatDate(String raw) {
    if (raw.isEmpty || raw == '—') return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hour:$minute $ampm';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _loadPostDetails() async {
    final id = widget.postId.trim();
    if (id.isEmpty) return;

    try {
      final endpoint = ApiConstants.socialMediaPost.replaceFirst('{id}', id);
      final response = await _api.get(endpoint);
      final rawData = response.data;
      final dataMap = _map(rawData);
      final resolvedPost = dataMap['data'] is Map ? _map(dataMap['data']) : dataMap;

      if (mounted) {
        setState(() {
          _post = resolvedPost;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_post.isEmpty) {
            _errorMessage = 'Failed to load post details. Please try again.';
          }
        });
      }
    }
  }

  Future<void> _executeWorkflowAction(
    String endpointPath,
    dynamic payload, {
    String? successMessage,
    bool isMultipart = false,
  }) async {
    setState(() => _isSubmittingAction = true);
    final id = widget.postId;
    final resolvedUrl = endpointPath.replaceFirst('{id}', id);

    try {
      if (isMultipart && payload is FormData) {
        await _api.postForm(resolvedUrl, data: payload);
      } else {
        await _api.post(resolvedUrl, data: payload);
      }

      if (mounted) {
        AppSnackbar.show(
          'Social Media',
          successMessage ?? 'Action completed successfully.',
          isSuccess: true,
        );
      }
      await _loadPostDetails();
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          'Social Media',
          'Failed to perform action: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingAction = false);
      }
    }
  }

  // ===================== ACTION DIALOGS =====================

  void _showStartWorkConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Work?'),
        content: const Text(
          'This will transition the post status to "In Progress" and log your start in the activity history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF176EE2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeWorkflowAction(
                ApiConstants.socialMediaStart,
                {},
                successMessage: 'Work started! You can now upload creative versions.',
              );
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start Work'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadVersionModal() async {
    final noteController = TextEditingController();
    List<PlatformFile> pickedFiles = [];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upload Creative Version',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172B4D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Submit files for internal review. The post will move to "Internal Review".',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6C7A91)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Version Notes (Optional)',
                        hintText: 'e.g. Added motion graphics, fixed captions...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(
                        pickedFiles.isEmpty
                            ? 'Select Files (Images, Videos, PDFs)'
                            : '${pickedFiles.length} file(s) selected',
                      ),
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          type: FileType.any,
                        );
                        if (res != null && res.files.isNotEmpty) {
                          setModalState(() {
                            pickedFiles = res.files;
                          });
                        }
                      },
                    ),
                    if (pickedFiles.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: pickedFiles.map((f) {
                          return Chip(
                            label: Text(
                              f.name,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setModalState(() {
                                pickedFiles.remove(f);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF176EE2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final formData = FormData();
                          if (noteController.text.trim().isNotEmpty) {
                            formData.fields.add(MapEntry('note', noteController.text.trim()));
                          }
                          for (final file in pickedFiles) {
                            if (file.path != null && file.path!.isNotEmpty) {
                              formData.files.add(
                                MapEntry(
                                  'files[]',
                                  await MultipartFile.fromFile(
                                    file.path!,
                                    filename: file.name,
                                  ),
                                ),
                              );
                            }
                          }
                          _executeWorkflowAction(
                            ApiConstants.socialMediaVersions,
                            formData,
                            isMultipart: true,
                            successMessage: 'Version uploaded and submitted for internal review!',
                          );
                        },
                        child: const Text(
                          'Submit for Internal Review',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
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

  void _showInternalReviewDialog() {
    final commentCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Internal Review Decision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review the creative draft and choose whether to approve for client review or request modifications.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6C7A91)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Review Comments',
                hintText: 'e.g. Approved layout. Ready for client.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C),
              side: const BorderSide(color: Color(0xFFEA580C)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeWorkflowAction(
                ApiConstants.socialMediaInternalDecision,
                {
                  'decision': 'changes_requested',
                  'comment': commentCtrl.text.trim().isEmpty
                      ? 'Please make the requested changes.'
                      : commentCtrl.text.trim(),
                },
                successMessage: 'Internal changes requested. Assigned staff has been notified.',
              );
            },
            child: const Text('Request Changes'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeWorkflowAction(
                ApiConstants.socialMediaInternalDecision,
                {
                  'decision': 'approved',
                  'comment': commentCtrl.text.trim(),
                },
                successMessage: 'Approved & sent to client for final approval!',
              );
            },
            child: const Text('Approve & Send Client'),
          ),
        ],
      ),
    );
  }

  void _showClientDecisionDialog() {
    final commentCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Client Approval Decision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record your decision on this creative.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6C7A91)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Comments (Required for changes / reject)',
                hintText: 'e.g. Please update the logo size / Approved.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (commentCtrl.text.trim().isEmpty) {
                AppSnackbar.show('Notice', 'Please provide a comment when rejecting.', isError: true);
                return;
              }
              Navigator.of(ctx).pop();
              _executeWorkflowAction(
                ApiConstants.socialMediaClientDecision,
                {
                  'decision': 'rejected',
                  'comment': commentCtrl.text.trim(),
                },
                successMessage: 'Post marked as Rejected.',
              );
            },
            child: const Text('Reject'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C),
              side: const BorderSide(color: Color(0xFFEA580C)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (commentCtrl.text.trim().isEmpty) {
                AppSnackbar.show('Notice', 'Please provide a comment when requesting changes.', isError: true);
                return;
              }
              Navigator.of(ctx).pop();
              _executeWorkflowAction(
                ApiConstants.socialMediaClientDecision,
                {
                  'decision': 'changes_requested',
                  'comment': commentCtrl.text.trim(),
                },
                successMessage: 'Changes requested. Team has been notified.',
              );
            },
            child: const Text('Request Changes'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeWorkflowAction(
                ApiConstants.socialMediaClientDecision,
                {
                  'decision': 'approved',
                  'comment': commentCtrl.text.trim(),
                },
                successMessage: 'Post approved! Team will prepare for publishing.',
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSchedulePublishDialog() async {
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 2));

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Schedule Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set the date and time when this post is scheduled to go live.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6C7A91)),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_rounded, color: Color(0xFF176EE2)),
                title: Text(_formatDate(selectedDateTime.toIso8601String())),
                subtitle: const Text('Tap to change date & time'),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (pickedTime != null) {
                      setDialogState(() {
                        selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF176EE2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _executeWorkflowAction(
                  ApiConstants.socialMediaSchedule,
                  {'scheduled_at': selectedDateTime.toIso8601String()},
                  successMessage: 'Post scheduled successfully!',
                );
              },
              child: const Text('Confirm Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmPublishedDialog() async {
    final urlCtrl = TextEditingController();
    DateTime actualPublishedAt = DateTime.now();
    PlatformFile? proofFile;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Confirm Post Published',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172B4D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mark this post as live and provide the published link or proof screenshot.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6C7A91)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: urlCtrl,
                      decoration: InputDecoration(
                        labelText: 'Published Post URL',
                        hintText: 'https://instagram.com/p/...',
                        prefixIcon: const Icon(Icons.link_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF059669)),
                      title: Text('Published At: ${_formatDate(actualPublishedAt.toIso8601String())}'),
                      subtitle: const Text('Tap to change'),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: actualPublishedAt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (d != null) {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(actualPublishedAt),
                          );
                          if (t != null) {
                            setModalState(() {
                              actualPublishedAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(proofFile == null ? 'Attach Proof / Screenshot (Optional)' : 'Proof: ${proofFile!.name}'),
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (res != null && res.files.isNotEmpty) {
                          setModalState(() {
                            proofFile = res.files.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final formData = FormData();
                          formData.fields.add(MapEntry('actual_published_at', actualPublishedAt.toIso8601String()));
                          if (urlCtrl.text.trim().isNotEmpty) {
                            formData.fields.add(MapEntry('published_url', urlCtrl.text.trim()));
                          }
                          if (proofFile?.path != null) {
                            formData.files.add(
                              MapEntry(
                                'proof',
                                await MultipartFile.fromFile(
                                  proofFile!.path!,
                                  filename: proofFile!.name,
                                ),
                              ),
                            );
                          }
                          _executeWorkflowAction(
                            ApiConstants.socialMediaPublish,
                            formData,
                            isMultipart: true,
                            successMessage: 'Post marked as Published!',
                          );
                        },
                        child: const Text('Confirm Published', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _showEditPostModal() async {
    final titleCtrl = TextEditingController(text: _val(['title']));
    final briefCtrl = TextEditingController(text: _val(['creative_brief', 'brief']));
    final captionCtrl = TextEditingController(text: _val(['caption']));
    final hashtagsCtrl = TextEditingController(text: _val(['hashtags']));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Post Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: briefCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Creative Brief',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: captionCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Caption',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hashtagsCtrl,
                    decoration: InputDecoration(
                      labelText: 'Hashtags',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF176EE2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _executeWorkflowAction(
                          ApiConstants.socialMediaPost,
                          {
                            '_method': 'PUT',
                            'title': titleCtrl.text.trim(),
                            'creative_brief': briefCtrl.text.trim(),
                            'caption': captionCtrl.text.trim(),
                            'hashtags': hashtagsCtrl.text.trim(),
                          },
                          successMessage: 'Post updated successfully.',
                        );
                      },
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    _commentController.clear();

    await _executeWorkflowAction(
      ApiConstants.socialMediaComments,
      {
        'comment': text,
        // Clients can never post internal comments
        'is_internal': _isClient ? false : _isCommentInternal,
      },
      successMessage: 'Comment posted.',
    );
  }

  // ===================== UI HELPERS =====================

  Color _statusColor(String status) {
    switch (status) {
      case 'planned':
      case 'draft':
        return const Color(0xFF64748B);
      case 'assigned':
        return const Color(0xFF2563EB);
      case 'in_progress':
        return const Color(0xFFD97706);
      case 'internal_review':
        return const Color(0xFF7C3AED);
      case 'internal_changes_requested':
        return const Color(0xFFEA580C);
      case 'pending_client_approval':
        return const Color(0xFF4F46E5);
      case 'client_approved':
        return const Color(0xFF0D9488);
      case 'client_changes_requested':
        return const Color(0xFFE11D48);
      case 'ready_for_publishing':
      case 'scheduled':
        return const Color(0xFF0284C7);
      case 'published':
        return const Color(0xFF059669);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _statusLabel(String status) {
    return status.replaceAll('_', ' ').capitalizeFirst ?? status;
  }

  int _calculateMilestoneStep(String status) {
    switch (status) {
      case 'planned':
      case 'assigned':
        return 0;
      case 'in_progress':
        return 1;
      case 'internal_review':
      case 'internal_changes_requested':
        return 2;
      case 'pending_client_approval':
      case 'client_changes_requested':
      case 'client_approved':
        return 3;
      case 'scheduled':
      case 'ready_for_publishing':
        return 4;
      case 'published':
        return 5;
      default:
        return 0;
    }
  }

  // ===================== WIDGET BUILDERS =====================

  Widget _buildMilestoneStepper(String status, bool compact) {
    const milestones = [
      'Plan & Assign',
      'Create',
      'Internal Review',
      'Client Approval',
      'Schedule',
      'Published',
    ];
    final currentStep = _calculateMilestoneStep(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, size: 18, color: Color(0xFF176EE2)),
              const SizedBox(width: 8),
              Text(
                'Lifecycle Progress (Step ${currentStep + 1} of 6)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(milestones.length * 2 - 1, (index) {
                if (index.isOdd) {
                  final stepBefore = index ~/ 2;
                  final isPassed = stepBefore < currentStep;
                  return Container(
                    width: compact ? 22 : 36,
                    height: 3,
                    color: isPassed ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  );
                }

                final step = index ~/ 2;
                final isPassed = step < currentStep;
                final isCurrent = step == currentStep;
                final color = isPassed
                    ? const Color(0xFF059669)
                    : isCurrent
                        ? const Color(0xFF176EE2)
                        : const Color(0xFFCBD5E1);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 26 : 30,
                      height: compact ? 26 : 30,
                      decoration: BoxDecoration(
                        color: isPassed || isCurrent ? color : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Center(
                        child: isPassed
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                '${step + 1}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: compact ? 68 : 80,
                      child: Text(
                        milestones[step],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent ? const Color(0xFF172B4D) : const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowActionCard(String status) {
    // 1. "Start Work": Assigned Staff only (the specific user assigned) in waiting statuses
    final canStartWork = !_isClient &&
        _isAssigned &&
        const [
          'planned',
          'assigned',
          'internal_changes_requested',
          'client_changes_requested',
        ].contains(status);

    // 2. "Submit for Internal Review" (Upload version): Staff / Admin / Assigned Team, not published
    final canUploadVersion = !_isClient && status != 'published';

    // 3. "Internal Review Decisions": Reviewer / Admin / Manager, only internal_review
    final canInternalReview = !_isClient && status == 'internal_review';

    // 4. "Client Approval Decisions": Client ONLY, strictly pending_client_approval
    final canClientDecision = _isClient && status == 'pending_client_approval';

    // 5. "Publishing Actions" (Schedule & Confirm Published): Publishing staff / Admin
    final canPublishOrSchedule = !_isClient &&
        const [
          'client_approved',
          'ready_for_publishing',
          'scheduled',
        ].contains(status);

    // 6. "Edit" Button: Non-clients
    final canEdit = !_isClient;

    final hasAnyAction = canStartWork ||
        canUploadVersion ||
        canInternalReview ||
        canClientDecision ||
        canPublishOrSchedule ||
        canEdit;

    // If staff is looking at post waiting for client approval, show informative banner
    if (!_isClient && status == 'pending_client_approval' && !canUploadVersion && !canEdit) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFF16A34A), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Awaiting Client Approval: Waiting for the client to review and make a decision.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!hasAnyAction) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF176EE2)),
              const SizedBox(width: 8),
              Text(
                _isClient ? 'Your Action Required' : 'Workflow Actions',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172B4D),
                ),
              ),
              const Spacer(),
              if (_isSubmittingAction)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // --- START WORK (Assigned staff only) ---
              if (canStartWork)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF176EE2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start Work'),
                  onPressed: _isSubmittingAction ? null : _showStartWorkConfirmation,
                ),

              // --- UPLOAD VERSION / SUBMIT INTERNAL REVIEW (Staff/Admin) ---
              if (canUploadVersion)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF176EE2),
                    side: const BorderSide(color: Color(0xFF176EE2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload Creative Version'),
                  onPressed: _isSubmittingAction ? null : _showUploadVersionModal,
                ),

              // --- INTERNAL REVIEW DECISIONS (Reviewer / Admin / Manager) ---
              if (canInternalReview) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.rate_review_rounded, size: 18),
                  label: const Text('Internal Review Decision'),
                  onPressed: _isSubmittingAction ? null : _showInternalReviewDialog,
                ),
              ],

              // --- CLIENT DECISIONS (Client ONLY) ---
              if (canClientDecision) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Approve Post'),
                  onPressed: _isSubmittingAction ? null : _showClientDecisionDialog,
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEA580C),
                    side: const BorderSide(color: Color(0xFFEA580C)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Request Changes / Reject'),
                  onPressed: _isSubmittingAction ? null : _showClientDecisionDialog,
                ),
              ],

              // --- PUBLISHING ACTIONS (Publishing staff / Admin) ---
              if (canPublishOrSchedule) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: const Text('Schedule'),
                  onPressed: _isSubmittingAction ? null : _showSchedulePublishDialog,
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Confirm Published'),
                  onPressed: _isSubmittingAction ? null : _showConfirmPublishedDialog,
                ),
              ],

              // --- EDIT BUTTON (Staff / Admin) ---
              if (canEdit)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Details'),
                  onPressed: _isSubmittingAction ? null : _showEditPostModal,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeContentCard() {
    final title = _val(['title'], 'Untitled Post');
    final clientName = _formatClient(_post['client'] ?? _post['client_name']);
    final plannedDate = _formatDate(_val(['planned_at', 'planned_date']));
    final deadline = _formatDate(_val(['approval_deadline', 'deadline']));
    final priority = _val(['priority'], 'Medium');
    final caption = _val(['caption']);
    final brief = _val(['creative_brief', 'brief']);
    final hashtags = _val(['hashtags']);
    final rawPlatforms = _post['platforms'] ?? _post['target_platforms'];
    List<String> platforms = [];
    if (rawPlatforms is List) {
      platforms = rawPlatforms.map((e) => e.toString()).toList();
    } else if (rawPlatforms is String && rawPlatforms.isNotEmpty) {
      platforms = rawPlatforms.split(',').map((e) => e.trim()).toList();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
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
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172B4D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(_currentStatus).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(_currentStatus),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(_currentStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoItem(Icons.person_outline_rounded, 'Client', clientName)),
              Expanded(child: _infoItem(Icons.event_note_rounded, 'Planned Date', plannedDate)),
            ],
          ),
          if (deadline != '—' || priority.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (deadline != '—')
                  Expanded(child: _infoItem(Icons.timer_outlined, 'Approval Deadline', deadline)),
                Expanded(child: _infoItem(Icons.flag_outlined, 'Priority', priority.capitalizeFirst ?? priority)),
              ],
            ),
          ],
          if (platforms.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Target Platforms',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: platforms.map((p) {
                return Chip(
                  avatar: Icon(_platformIcon(p), size: 16, color: const Color(0xFF176EE2)),
                  label: Text(p.capitalizeFirst ?? p, style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],

          // --- CREATIVE CONTENT VISIBILITY CHECK ($canSeeCreative) ---
          if (!_canSeeCreative) ...[
            const Divider(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: Color(0xFF64748B), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This post is in planning. The creative will be visible once it is sent to you for approval.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (brief.isNotEmpty) ...[
              const Divider(height: 28),
              const Text(
                'Creative Brief',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(brief, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155))),
              ),
            ],
            if (caption.isNotEmpty) ...[
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Post Caption',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)),
                  ),
                  IconButton(
                    tooltip: 'Copy caption',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: caption));
                      AppSnackbar.show('Caption', 'Caption copied to clipboard.', isSuccess: true);
                    },
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  caption,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
                ),
              ),
            ],
            if (hashtags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hashtags,
                style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF172B4D)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _platformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('instagram')) return Icons.camera_alt_outlined;
    if (p.contains('facebook')) return Icons.facebook_rounded;
    if (p.contains('linkedin')) return Icons.business_center_outlined;
    if (p.contains('twitter') || p.contains('x')) return Icons.alternate_email_rounded;
    if (p.contains('youtube')) return Icons.play_circle_outline_rounded;
    return Icons.public_rounded;
  }

  Widget _buildVersionsGalleryCard() {
    // Only visible when $canSeeCreative is true
    if (!_canSeeCreative) return const SizedBox.shrink();

    final versions = _list(_post['versions'] ?? _post['creative_versions']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, size: 20, color: Color(0xFF176EE2)),
                  const SizedBox(width: 8),
                  Text(
                    'Creative Versions (${versions.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)),
                  ),
                ],
              ),
              // Clients can never upload versions
              if (!_isClient && _currentStatus != 'published')
                TextButton.icon(
                  onPressed: _showUploadVersionModal,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Version'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (versions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.perm_media_outlined, size: 40, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 8),
                  const Text('No creative versions submitted yet.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  if (!_isClient && _currentStatus != 'published') ...[
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: _showUploadVersionModal,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Upload V1'),
                    ),
                  ],
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: versions.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, idx) {
                final ver = versions[idx];
                final vNum = ver['version_number'] ?? (versions.length - idx);
                final note = ver['note']?.toString() ?? '';
                final createdAt = _formatDate(ver['created_at']?.toString() ?? '');
                final files = _list(ver['files']);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text('V$vNum', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8), fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            note.isNotEmpty ? note : 'Creative version $vNum',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF172B4D)),
                          ),
                        ),
                        Text(createdAt, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    if (files.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: files.map((file) {
                          final fileName = file['file_name'] ?? file['original_name'] ?? 'File';
                          final fileUrl = file['preview_url'] ?? file['download_url'] ?? file['file_path'] ?? '';
                          return ActionChip(
                            avatar: const Icon(Icons.attachment_rounded, size: 16, color: Color(0xFF176EE2)),
                            label: Text(fileName.toString(), style: const TextStyle(fontSize: 12)),
                            onPressed: () async {
                              if (fileUrl.isNotEmpty) {
                                final uri = Uri.tryParse(fileUrl);
                                if (uri != null) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDiscussionCard() {
    final allComments = _list(_post['comments'] ?? _post['discussion']);
    // Clients only see public comments; Staff/Admins see both public and internal
    final comments = _isClient
        ? allComments.where((c) {
            final isInternal = c['is_internal'] == true || c['is_internal'] == 1 || c['is_internal'] == '1';
            return !isInternal;
          }).toList()
        : allComments;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, size: 20, color: Color(0xFF176EE2)),
              const SizedBox(width: 8),
              Text(
                'Discussion / Comments (${comments.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No comments yet. Start the conversation below.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const Divider(height: 18),
              itemBuilder: (context, idx) {
                final c = comments[idx];
                final commentText = c['comment']?.toString() ?? '';
                final isInternal = c['is_internal'] == true || c['is_internal'] == 1 || c['is_internal'] == '1';
                final author = c['user'] is Map ? (c['user']['name'] ?? 'User') : (c['author'] ?? 'User');
                final time = _formatDate(c['created_at']?.toString() ?? '');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: Text(
                            author.toString().isNotEmpty ? author.toString().substring(0, 1).toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(author.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF172B4D))),
                        if (isInternal) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Internal', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                          ),
                        ],
                        const Spacer(),
                        Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(commentText, style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF334155))),
                    ),
                  ],
                );
              },
            ),
          const Divider(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Checkbox is strictly shown to Staff/Admin (never to Clients)
              if (!_isClient) ...[
                Checkbox(
                  value: _isCommentInternal,
                  onChanged: (val) {
                    setState(() => _isCommentInternal = val ?? false);
                  },
                ),
                const Text('Internal only (client cannot see)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF176EE2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send'),
                onPressed: _isSubmittingAction ? null : _sendComment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHistoryCard() {
    // Clients do not see internal audit logs
    if (_isClient) return const SizedBox.shrink();

    final history = _list(_post['status_history'] ?? _post['history'] ?? _post['activities']);
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 20, color: Color(0xFF176EE2)),
              SizedBox(width: 8),
              Text(
                'Activity Log / Status History',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final h = history[idx];
              final toStatus = h['to_status']?.toString() ?? '';
              final author = h['user'] is Map ? (h['user']['name'] ?? 'System') : (h['author'] ?? 'System');
              final comment = h['comment']?.toString() ?? '';
              final time = _formatDate(h['created_at']?.toString() ?? '');

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF176EE2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              author.toString(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)),
                            ),
                            if (toStatus.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text('➔ ${_statusLabel(toStatus)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                            ],
                            const Spacer(),
                            Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          ],
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(comment, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: compact ? 8 : 10),
              CommonTopBar(
                title: 'Post Details',
                compact: compact,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(height: compact ? 12 : 16),
              Expanded(
                child: _isLoading && _post.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null && _post.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text(_errorMessage!, style: const TextStyle(color: Color(0xFF64748B))),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _loadPostDetails,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try Again'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPostDetails,
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 30),
                              children: [
                                _buildMilestoneStepper(_currentStatus, compact),
                                const SizedBox(height: 14),
                                _buildWorkflowActionCard(_currentStatus),
                                const SizedBox(height: 14),
                                _buildCreativeContentCard(),
                                const SizedBox(height: 14),
                                _buildVersionsGalleryCard(),
                                const SizedBox(height: 14),
                                _buildDiscussionCard(),
                                const SizedBox(height: 14),
                                _buildActivityHistoryCard(),
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
