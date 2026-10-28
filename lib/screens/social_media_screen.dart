import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/app_error_handler.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/common_screen_app_bar.dart';
import 'social_post_detail_screen.dart';

/// Social post workspace. The API deliberately remains map-based because the
/// backend response contract includes nested, role-specific fields.
class SocialMediaScreen extends StatelessWidget {
  const SocialMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;
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
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.profile,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: compact ? 8 : 10),
              CommonTopBar(
                title: 'Social Media',
                compact: compact,
              ),
              SizedBox(height: compact ? 12 : 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
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
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
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
                            builder: (_) => _SocialSectionScreen(
                              index: index,
                              title: section.$1,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
  String _dateOf(Map<String, dynamic> p) {
    final raw = _value(
      p,
      ['actual_published_at', 'planned_at', 'planned_date', 'scheduled_at'],
      'Date not set',
    );
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final date = parsed.toLocal();
    final month = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][date.month - 1];
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')} $month ${date.year}, '
        '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _clientOf(Map<String, dynamic> p) {
    final client = p['client'];
    if (client is Map) {
      final first = client['first_name']?.toString().trim() ?? '';
      final last = client['last_name']?.toString().trim() ?? '';
      final name = '$first $last'.trim();
      if (name.isNotEmpty) return name;
      final nestedName = client['name']?.toString().trim() ?? '';
      if (nestedName.isNotEmpty) return nestedName;
    }
    return _value(p, ['client_name', 'client_id'], 'No client');
  }

  String _statusLabel(String value) => value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');

  Future<void> _openPost(Map<String, dynamic> post) async {
    final id = _value(post, ['id', 'post_id']);
    if (id.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: RouteSettings(name: '/profile/social-media/posts/$id'),
        builder: (_) => SocialPostDetailScreen(
          postId: id,
          initialData: post,
        ),
      ),
    );
    _load();
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
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
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 12 : 16,
                    compact ? 8 : 10,
                    compact ? 12 : 16,
                    0,
                  ),
                  child: CommonTopBar(
                    title: widget.title,
                    compact: compact,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: compact ? 12 : 16),
                    child: IconButton(
                      tooltip: 'Refresh',
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
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
    for (final p in _posts) {
      counts[_statusOf(p)] = (counts[_statusOf(p)] ?? 0) + 1;
    }
    final cards = [
      ('Planned', 'planned', const Color(0xFF64748B), Icons.event_note_rounded),
      ('In Design', 'in_progress', const Color(0xFF2563EB), Icons.palette_rounded),
      ('Internal Review', 'internal_review', const Color(0xFFF59E0B), Icons.rate_review_rounded),
      ('Client Approval', 'pending_client_approval', const Color(0xFF0891B2), Icons.verified_user_rounded),
      ('Scheduled', 'scheduled', const Color(0xFF7C3AED), Icons.schedule_send_rounded),
      ('Published', 'published', const Color(0xFF16A34A), Icons.check_circle_rounded),
    ];
    final published = counts['published'] ?? 0;
    final scheduled = counts['scheduled'] ?? 0;
    final completion = _posts.isEmpty
        ? 0.0
        : (published / _posts.length).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _overviewHero(
            completion: completion,
            scheduled: scheduled,
          ),
          const SizedBox(height: 18),
          const Text(
            'Content pipeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: cards
                .map((c) => _metric(c.$1, counts[c.$2] ?? 0, c.$3, c.$4))
                .toList(),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Recent posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkNavy,
                ),
              ),
              Text(
                '${_posts.length} total',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_posts.isEmpty)
            _empty('No recent posts for this month.', Icons.article_outlined)
          else
            ..._posts.take(5).map(
              (post) => _postCard(post, interactive: false),
            ),
        ],
      ),
    );
  }

  Widget _overviewHero({required double completion, required int scheduled}) {
    final monthLabel = _monthName(_month.month);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF122B52), Color(0xFF1D4F91)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Social media overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _monthButton(
                Icons.chevron_left,
                () {
                  setState(() => _month = DateTime(_month.year, _month.month - 1));
                  _load();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$monthLabel ${_month.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _monthButton(
                Icons.chevron_right,
                () {
                  setState(() => _month = DateTime(_month.year, _month.month + 1));
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                '${_posts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'posts in your\ncontent pipeline',
                style: TextStyle(
                  color: Color(0xFFD7E7FF),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              _heroStat(Icons.schedule_rounded, '$scheduled', 'scheduled'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Published progress',
                  style: TextStyle(
                    color: Color(0xFFD7E7FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(completion * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7DD3FC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthButton(IconData icon, VoidCallback onPressed) => InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _heroStat(IconData icon, String value, String label) => Row(
        children: [
          Icon(icon, color: const Color(0xFF7DD3FC), size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xFFD7E7FF), fontSize: 10),
              ),
            ],
          ),
        ],
      );

  Widget _metric(String label, int count, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              height: 3,
              width: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );

  String _monthName(int month) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month - 1];

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

  Widget _postCard(Map<String, dynamic> p, {bool interactive = true}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8EEF7)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: interactive ? () => _openPost(p) : null,
        title: Text(
          _titleOf(p),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF172B4D),
          ),
        ),
        subtitle: Text(
          '${_dateOf(p)}\n${_clientOf(p)}',
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
      _statusLabel(value),
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

