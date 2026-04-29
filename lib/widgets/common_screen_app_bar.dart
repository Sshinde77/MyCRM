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
        if (showTodoButton)
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            onPressed: () => Get.to(() => const to_do.ToDoListScreen()),
          ),
        // IconButton(
        //   icon: const Icon(Icons.notifications_none_rounded),
        //   onPressed: () {},
        // ),
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
