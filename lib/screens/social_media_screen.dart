import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/app_error_handler.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/common_screen_app_bar.dart';

/// Social post workspace. The API deliberately remains map-based because the
/// backend response contract includes nested, role-specific fields.
class SocialMediaScreen extends StatelessWidget {
  const SocialMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = [
      ('Overview', Icons.dashboard_outlined),
      ('All Posts', Icons.article_outlined),
      ('My Assigned Posts', Icons.assignment_ind_outlined),
      ('Internal Review', Icons.fact_check_outlined),
      ('Client Approvals', Icons.task_alt_outlined),
      ('Publishing Tracker', Icons.send_outlined),
      ('Monthly Plans', Icons.event_note_outlined),
      ('Festival Master', Icons.celebration_outlined),
      ('Monthly Reports', Icons.bar_chart_outlined),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: const CommonScreenAppBar(title: 'Social Media'),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.profile,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final section = sections[index];
            return Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE0E7F1)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                minTileHeight: 58,
                leading: Icon(
                  section.$2,
                  color: const Color(0xFF176EE2),
                  size: 21,
                ),
                title: Text(
                  section.$1,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    settings: RouteSettings(
                      name: '/profile/social-media/$index',
                    ),
                    builder: (_) =>
                        _SocialSectionScreen(index: index, title: section.$1),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialSectionScreen extends StatefulWidget {
  const _SocialSectionScreen({required this.index, required this.title});

  final int index;
  final String title;

  @override
  State<_SocialSectionScreen> createState() => _SocialSectionScreenState();
}

class _SocialSectionScreenState extends State<_SocialSectionScreen> {
  final _api = ApiService.instance;
  final _search = TextEditingController();
  int get _tab => widget.index;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = [];
  Map<String, dynamic> _options = {};
  final String _status = '';
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};

  List<Map<String, dynamic>> _items(dynamic value) {
    final root = _map(value);
    dynamic data = root['data'] ?? value;
    if (data is Map) data = data['data'] ?? data['posts'] ?? data['items'];
    if (data is! List) return [];
    return data.map(_map).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get(
        ApiConstants.socialMediaPosts,
        queryParameters: {
          'month': '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
          'per_page': 100,
          if (_status.isNotEmpty) 'status': _status,
          if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _posts = _items(response.data);
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _loadError(e);
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Unable to load social media workspace.';
        });
    }
  }

  String _loadError(DioException error) {
    switch (error.response?.statusCode) {
      case 404:
        return 'Social Media is not available on the server yet. Please contact your administrator.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You don\'t have access to social media posts.';
      default:
        return AppErrorHandler.messageFromError(error);
    }
  }

  String _value(
    Map<String, dynamic> p,
    List<String> keys, [
    String fallback = '',
  ]) {
    for (final key in keys) {
      final v = p[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  String _statusOf(Map<String, dynamic> p) =>
      _value(p, ['status', 'post_status'], 'planned');
  String _titleOf(Map<String, dynamic> p) =>
      _value(p, ['title', 'name'], 'Untitled post');
  String _dateOf(Map<String, dynamic> p) =>
      _value(p, ['planned_at', 'planned_date', 'scheduled_at'], 'Date not set');

  Future<void> _openPost(Map<String, dynamic> post) async {
    final id = _value(post, ['id', 'post_id']);
    if (id.isEmpty) return;
    try {
      final response = await _api.get(
        ApiConstants.socialMediaPost.replaceFirst('{id}', id),
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PostDetailSheet(
          post: _map(response.data)['data'] ?? response.data,
          api: _api,
          onChanged: _load,
        ),
      );
      _load();
    } catch (_) {
      if (mounted)
        AppSnackbar.show(
          'Social Media',
          'Could not open this post.',
          isError: true,
        );
    }
  }

  Future<void> _createPost() async {
    try {
      final response = await _api.get(ApiConstants.socialMediaOptions);
      if (!mounted) return;
      final body = _map(response.data);
      _options = body['data'] is Map ? _map(body['data']) : body;
    } on DioException catch (error) {
      if (mounted)
        AppSnackbar.show('Social Media', _loadError(error), isError: true);
      return;
    } catch (_) {
      if (mounted)
        AppSnackbar.show(
          'Social Media',
          'Unable to load post form options. Please try again.',
          isError: true,
        );
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _CreatePostSheet(api: _api, options: _options, onSaved: _load),
    );
  }

  List<Map<String, dynamic>> get _visiblePosts {
    final role = _tab == 2
        ? 'assigned'
        : _tab == 3
        ? 'internal_review'
        : _tab == 4
        ? 'pending_client_approval'
        : '';
    if (role.isEmpty) return _posts;
    return _posts.where((p) => _statusOf(p) == role).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: CommonScreenAppBar(title: widget.title),
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.profile,
      ),
      floatingActionButton: _tab == 0 || _tab == 1
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF176EE2),
              onPressed: _createPost,
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Refresh',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _empty(_error!, Icons.cloud_off_rounded),
                        OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_tab == 0)
                SliverToBoxAdapter(child: _overview())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: _postsSliver(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overview() {
    final counts = <String, int>{};
    for (final p in _posts)
      counts[_statusOf(p)] = (counts[_statusOf(p)] ?? 0) + 1;
    final cards = [
      ('Planned', 'planned', Colors.blueGrey),
      ('In Design', 'in_progress', Colors.blue),
      ('Internal Review', 'internal_review', Colors.orange),
      ('Client Approvals', 'pending_client_approval', Colors.cyan),
      ('Scheduled', 'scheduled', Colors.deepPurple),
      ('Published', 'published', Colors.green),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  );
                  _load();
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () {
                  setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  );
                  _load();
                },
                icon: const Icon(Icons.chevron_right),
              ),
              const Spacer(),
              Text(
                '${_posts.length} posts',
                style: const TextStyle(color: Color(0xFF6C7A91)),
              ),
            ],
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: cards
                .map((c) => _metric(c.$1, counts[c.$2] ?? 0, c.$3))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent posts',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 8),
          ..._posts.take(5).map(_postCard),
        ],
      ),
    );
  }

  Widget _metric(String label, int count, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8EEF7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172B4D),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6C7A91)),
        ),
      ],
    ),
  );

  Widget _postsSliver() {
    final list = _visiblePosts;
    if (list.isEmpty)
      return SliverFillRemaining(
        child: _empty('No posts in this queue.', Icons.campaign_outlined),
      );
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _postCard(list[i]),
        childCount: list.length,
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8EEF7)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () => _openPost(p),
        title: Text(
          _titleOf(p),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF172B4D),
          ),
        ),
        subtitle: Text(
          '${_dateOf(p)}\n${_value(p, ['client_name', 'client', 'client_id'], 'No client')}',
          maxLines: 2,
        ),
        trailing: _badge(_statusOf(p)),
      ),
    );
  }

  Widget _badge(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: _statusColor(value).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value.replaceAll('_', ' '),
      style: TextStyle(
        color: _statusColor(value),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Color _statusColor(String s) => s.contains('review') || s.contains('changes')
      ? Colors.orange
      : s.contains('approval')
      ? Colors.cyan
      : s == 'published'
      ? Colors.green
      : s == 'scheduled'
      ? Colors.deepPurple
      : s == 'in_progress'
      ? Colors.blue
      : Colors.blueGrey;
  Widget _empty(String text, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: const Color(0xFF9AA8BC)),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6C7A91)),
          ),
        ],
      ),
    ),
  );
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({
    required this.api,
    required this.options,
    required this.onSaved,
  });
  final ApiService api;
  final Map<String, dynamic> options;
  final VoidCallback onSaved;
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _title = TextEditingController(),
      _brief = TextEditingController(),
      _caption = TextEditingController(),
      _hashtags = TextEditingController();
  String _type = 'image';
  bool _draft = true, _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _brief.dispose();
    _caption.dispose();
    _hashtags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      AppSnackbar.show('Social Media', 'Title is required.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.post(
        ApiConstants.socialMediaPosts,
        data: {
          'title': _title.text.trim(),
          'post_type': _type,
          'creative_brief': _brief.text.trim(),
          'caption': _caption.text.trim(),
          'hashtags': _hashtags.text.trim(),
          'save_as_draft': _draft,
        },
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        AppSnackbar.show(
          'Social Media',
          'Post created successfully.',
          isSuccess: true,
        );
      }
    } catch (_) {
      if (mounted)
        AppSnackbar.show(
          'Social Media',
          'Could not create post.',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Post',
                  style: AppTextStyles.style(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 18),
                _field('Title', _title),
                _field('Creative brief', _brief, maxLines: 3),
                _field('Caption', _caption, maxLines: 3),
                _field('Hashtags', _hashtags),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Post type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['image', 'video', 'carousel', 'text']
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'image'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save as draft'),
                  value: _draft,
                  onChanged: (v) => setState(() => _draft = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}

class _PostDetailSheet extends StatefulWidget {
  const _PostDetailSheet({
    required this.post,
    required this.api,
    required this.onChanged,
  });
  final dynamic post;
  final ApiService api;
  final VoidCallback onChanged;
  @override
  State<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<_PostDetailSheet> {
  bool _working = false;
  final _comment = TextEditingController();
  Map<String, dynamic> get p =>
      widget.post is Map ? Map<String, dynamic>.from(widget.post as Map) : {};
  String v(List<String> keys, [String fallback = '']) {
    for (final k in keys)
      if (p[k] != null && p[k].toString().isNotEmpty) return p[k].toString();
    return fallback;
  }

  Future<void> _action(String path, Map<String, dynamic> data) async {
    setState(() => _working = true);
    try {
      await widget.api.post(
        path.replaceFirst('{id}', v(['id', 'post_id'])),
        data: data,
      );
      widget.onChanged();
      if (mounted)
        AppSnackbar.show('Social Media', 'Post updated.', isSuccess: true);
    } catch (_) {
      if (mounted)
        AppSnackbar.show(
          'Social Media',
          'Action could not be completed.',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = v(['status'], 'planned');
    return SafeArea(
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v(['title'], 'Post detail'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172B4D),
                      ),
                    ),
                  ),
                  _badge(status),
                ],
              ),
              const SizedBox(height: 18),
              _info('Client', v(['client_name', 'client', 'client_id'], '—')),
              _info('Planned date', v(['planned_at', 'planned_date'], '—')),
              _info('Caption', v(['caption'], 'No caption')),
              _info('Creative brief', v(['creative_brief'], 'No brief')),
              const Divider(height: 28),
              Text(
                'Workflow',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _button(
                    'Start work',
                    status == 'assigned'
                        ? () => _action(ApiConstants.socialMediaStart, {})
                        : null,
                  ),
                  _button(
                    'Internal approve',
                    status == 'internal_review'
                        ? () => _action(
                            ApiConstants.socialMediaInternalDecision,
                            {'decision': 'approved'},
                          )
                        : null,
                  ),
                  _button(
                    'Request changes',
                    status == 'internal_review' ||
                            status == 'pending_client_approval'
                        ? () => _action(
                            status == 'internal_review'
                                ? ApiConstants.socialMediaInternalDecision
                                : ApiConstants.socialMediaClientDecision,
                            {
                              'decision': 'changes_requested',
                              'comment': 'Please revise the creative.',
                            },
                          )
                        : null,
                  ),
                  _button(
                    'Client approve',
                    status == 'pending_client_approval'
                        ? () => _action(
                            ApiConstants.socialMediaClientDecision,
                            {'decision': 'approved'},
                          )
                        : null,
                  ),
                  _button(
                    'Publish',
                    status == 'scheduled'
                        ? () => _action(ApiConstants.socialMediaPublish, {
                            'actual_published_at': DateTime.now()
                                .toIso8601String(),
                          })
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _comment,
                decoration: InputDecoration(
                  labelText: 'Add comment',
                  suffixIcon: IconButton(
                    onPressed: _comment.text.trim().isEmpty
                        ? null
                        : () async {
                            await _action(ApiConstants.socialMediaComments, {
                              'comment': _comment.text.trim(),
                              'is_internal': false,
                            });
                            _comment.clear();
                          },
                    icon: const Icon(Icons.send),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_working)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF6C7A91), fontSize: 13),
          children: [
            TextSpan(
              text: '$label\n',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Color(0xFF172B4D)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback? onTap) =>
      FilledButton(onPressed: onTap, child: Text(label));
  Widget _badge(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.blue.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      s.replaceAll('_', ' '),
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF176EE2),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
