import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/screens/to_do_list.dart' as to_do;

class CommonScreenAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CommonScreenAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showTodoButton = true,
  });

  final String title;
  final bool showBackButton;
  final bool showTodoButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        _TopBarCalendarBadge(date: now, compact: true),
        const SizedBox(width: 8),
        if (showTodoButton)
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            onPressed: () => Get.to(() => const to_do.ToDoListScreen()),
          ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {},
        ),
      ],
    );
  }
}

class CommonTopBar extends StatelessWidget {
  const CommonTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.showTodoButton = true,
    this.compact = false,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showTodoButton;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 38.0 : 42.0;
    final now = DateTime.now();
    return Row(
      children: [
        _TopBarIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          size: iconSize,
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF1E293B),
              fontSize: compact ? 20 : 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _TopBarCalendarBadge(date: now, compact: compact),
        SizedBox(width: compact ? 8 : 10),
        if (showTodoButton) ...[
          _TopBarIconButton(
            icon: Icons.checklist_rounded,
            size: iconSize,
            onTap: () => Get.to(() => const to_do.ToDoListScreen()),
          ),
          SizedBox(width: compact ? 8 : 10),
        ],
        // _TopBarIconButton(
        //   icon: Icons.notifications_none_rounded,
        //   size: iconSize,
        //   onTap: () {},
        // ),
      ],
    );
  }
}

class _TopBarCalendarBadge extends StatelessWidget {
  const _TopBarCalendarBadge({required this.date, required this.compact});

  final DateTime date;
  final bool compact;

  static const List<String> _months = <String>[
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
  ];

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    final dateLabel = '$day $month ${date.year}';
    final weekdayLabel = _weekdays[date.weekday - 1];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 22 : 24,
            height: compact ? 22 : 24,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF4F46E5),
              size: 14,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  color: const Color(0xFF4F46E5),
                  fontSize: compact ? 9.8 : 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                weekdayLabel,
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: compact ? 9 : 9.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
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
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF475569), size: size * 0.45),
        ),
      ),
    );
  }
}
