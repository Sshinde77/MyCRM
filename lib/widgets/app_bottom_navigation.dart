import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MagicNavItem {
  const MagicNavItem({
    required this.label,
    required this.icon,
    this.activeColor = const Color(0xFF1D6FEA),
  });

  final String label;
  final IconData icon;
  final Color activeColor;
}

/// Reusable "magic navigation menu" style bottom bar.
/// - Manages its own selected index (StatefulWidget).
/// - Animated floating indicator moves to the selected tab.
class MagicBottomNavigation extends StatefulWidget {
  const MagicBottomNavigation({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onChanged,
  });

  final List<MagicNavItem> items;
  final int initialIndex;
  final ValueChanged<int>? onChanged;

  @override
  State<MagicBottomNavigation> createState() => _MagicBottomNavigationState();
}

class _MagicBottomNavigationState extends State<MagicBottomNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
  }

  void _handleTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    widget.onChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalMargin = width < 360 ? 12.0 : 16.0;
          final barWidth = width - (horizontalMargin * 2);
          final itemWidth = (barWidth - 16) / widget.items.length;
          final barHeight = width < 360 ? 60.0 : 66.0;
          final bubbleSize = (itemWidth * 0.7).clamp(40.0, 54.0);
          final labelFontSize = width < 360 ? 9.5 : 10.5;
          final activeColor = widget.items[_currentIndex].activeColor;

          return SizedBox(
            height: barHeight + 26,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: barHeight,
                  margin: EdgeInsets.symmetric(
                    horizontal: horizontalMargin,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFE6ECF3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0F172A),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: horizontalMargin + 
                  8 +
                      (itemWidth * _currentIndex) +
                      (itemWidth - bubbleSize) / 2,
                  top: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: bubbleSize,
                    height: bubbleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: activeColor, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A0F172A),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      scale: 1.05,
                      child: Icon(
                        widget.items[_currentIndex].icon,
                        color: activeColor,
                        size: bubbleSize * 0.45,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: horizontalMargin,
                  right: horizontalMargin,
                  bottom: 6,
                  child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: List.generate(widget.items.length, (index) {
                      final item = widget.items[index];
                      final isActive = index == _currentIndex;
                      return Expanded(
                        child: InkWell(
                          onTap: () => _handleTap(index),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 220),
                                  opacity: isActive ? 0.0 : 1.0,
                                  child: Icon(
                                    item.icon,
                                    size: 18,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 220),
                                    style: TextStyle(
                                      color: isActive
                                          ? activeColor
                                          : const Color(0xFF94A3B8),
                                      fontSize: labelFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    child: Text(
                                      item.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
