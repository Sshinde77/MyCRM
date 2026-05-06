import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_text_styles.dart';
import '../core/utils/app_snackbar.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final ApiService _api = ApiService.instance;
  List<_NotificationItem> _items = const <_NotificationItem>[];
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPage(page: 1);
  }

  Future<void> _loadPage({int page = 1}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await _api.getNotificationsPage(page: page, perPage: 20);
      final items = result.items.map(_NotificationItem.fromJson).toList();
      if (!mounted) return;

      setState(() {
        _items = items;
        _currentPage = result.currentPage;
        _lastPage = result.lastPage < 1 ? 1 : result.lastPage;
        _total = result.total;
        _unreadCount = result.unreadCount;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _readError(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load notifications.';
      });
    }
  }

  Future<void> _markOneAsRead(_NotificationItem item) async {
    if (item.isRead) return;

    try {
      await _api.markNotificationAsRead(item.id);
      await _loadPage(page: _currentPage);
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show('Mark read failed', _readError(error));
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount <= 0 || _isMarkingAll) return;

    setState(() => _isMarkingAll = true);
    try {
      await _api.markAllNotificationsAsRead();
      await _loadPage(page: _currentPage);
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show('Mark all failed', _readError(error));
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  String _readError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return error.message?.trim().isNotEmpty == true
        ? error.message!.trim()
        : 'Failed to load notifications.';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            12,
            compact ? 12 : 16,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTopBar(
                title: 'Notifications',
                compact: compact,
                showNotificationButton: false,
              ),
              const SizedBox(height: 10),
              _TopActions(
                unreadCount: _unreadCount,
                total: _total,
                isMarkingAll: _isMarkingAll,
                onMarkAll: _markAllAsRead,
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildBody(compact)),
              if (_lastPage > 1) ...[
                const SizedBox(height: 8),
                _PaginationBar(
                  currentPage: _currentPage,
                  lastPage: _lastPage,
                  onPageTap: (page) => _loadPage(page: page),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool compact) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.style(
                color: const Color(0xFFB42318),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _loadPage(page: _currentPage),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No notifications found.',
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _NotificationCard(
          item: item,
          compact: compact,
          onTap: () => _markOneAsRead(item),
        );
      },
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions({
    required this.unreadCount,
    required this.total,
    required this.isMarkingAll,
    required this.onMarkAll,
  });

  final int unreadCount;
  final int total;
  final bool isMarkingAll;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$total total • $unreadCount unread',
            style: AppTextStyles.style(
              color: const Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: unreadCount > 0 && !isMarkingAll ? onMarkAll : null,
          child: Text(isMarkingAll ? 'Marking...' : 'Mark all read'),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.compact,
    required this.onTap,
  });

  final _NotificationItem item;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = _colorForType(item.type);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 36 : 40,
              height: compact ? 36 : 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.isRead
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_rounded,
                color: accentColor,
                size: compact ? 18 : 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.style(
                            color: const Color(0xFF162033),
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: AppTextStyles.style(
                      color: const Color(0xFF64748B),
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(item.createdAt),
                    style: AppTextStyles.style(
                      color: const Color(0xFF94A3B8),
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.lastPage,
    required this.onPageTap,
  });

  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPageTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: currentPage > 1 ? () => onPageTap(currentPage - 1) : null,
          child: const Text('Prev'),
        ),
        Text(
          'Page $currentPage of $lastPage',
          style: AppTextStyles.style(
            color: const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: currentPage < lastPage
              ? () => onPageTap(currentPage + 1)
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory _NotificationItem.fromJson(Map<String, dynamic> json) {
    return _NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      body: (json['body'] ?? '').toString(),
      type: (json['type'] ?? '').toString().trim().toLowerCase(),
      createdAt: _tryParseDate(json['created_at']),
      readAt: _tryParseDate(json['read_at']),
    );
  }
}

DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return DateTime.tryParse(text);
}

Color _colorForType(String type) {
  switch (type) {
    case 'staff':
      return const Color(0xFF2563EB);
    case 'task':
      return const Color(0xFFF59E0B);
    case 'project':
      return const Color(0xFF0EA5E9);
    case 'renewal':
      return const Color(0xFF10B981);
    default:
      return const Color(0xFF64748B);
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Unknown time';
  final local = value.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day-$month-$year $hour:$minute';
}
