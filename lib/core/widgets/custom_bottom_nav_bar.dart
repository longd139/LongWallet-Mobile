import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomNavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  final Color activeHaloColor;

  const CustomNavItem({
    required this.icon,
    required this.label,
    this.activeColor = const Color(0xFF10B981), // Emerald
    this.activeHaloColor = const Color(0x3D10B981), // Glowing Emerald
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CustomNavItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155).withOpacity(0.9)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              if (isDark) ...[
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, -2),
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: _AnimatedNavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends StatefulWidget {
  final CustomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _pressController.forward();
    _pressController.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSelected = widget.isSelected;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with animated offset halo
            SizedBox(
              height: 40,
              width: 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Animated Offset Circular Halo
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    top: isSelected ? 2 : 8,
                    left: isSelected ? 3 : 8,
                    child: AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.activeHaloColor,
                            boxShadow: [
                              BoxShadow(
                                color: item.activeColor.withOpacity(0.25),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Foreground Icon with smooth color transition
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      item.icon,
                      key: ValueKey<bool>(isSelected),
                      size: isSelected ? 26 : 24,
                      color: isSelected
                          ? item.activeColor
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Animated Label with smooth color & weight
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: isSelected ? 12.5 : 12.0,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                letterSpacing: -0.2,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
