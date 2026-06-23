import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Global key so the first-run coachmark tour can spotlight the whole nav.
final GlobalKey kBottomNavKey = GlobalKey();

/// Per-tab keys so the tour can spotlight each destination individually.
final GlobalKey kNavHomeKey = GlobalKey();
final GlobalKey kNavExploreKey = GlobalKey();
final GlobalKey kNavStudioKey = GlobalKey();
final GlobalKey kNavAgentKey = GlobalKey();

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Main pill with 3 buttons
          Container(
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, -4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavItem(
                  key: kNavHomeKey,
                  icon: Iconsax.home_15,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavIconOnly(
                  key: kNavExploreKey,
                  label: 'Explore',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                  isSvg: true,
                  svgPath: 'assets/images/discover_icon.svg',
                ),
                _NavIconOnly(
                  key: kNavStudioKey,
                  label: 'Visual Studio',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                  isSvg: true,
                  svgPath: 'assets/images/smart_cursor_icon.svg',
                ),
              ],
            ),
          ),

          // AI Agent button
          GestureDetector(
            key: kNavAgentKey,
            onTap: () => onTap(3),
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SvgPicture.asset(
                'assets/images/ai_icon.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF2A2A2A) : Colors.white70,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2A2A2A),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavIconOnly extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isSvg;
  final String? svgPath;

  const _NavIconOnly({
    super.key,
    this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isSvg = false,
    this.svgPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSvg && svgPath != null)
              SvgPicture.asset(
                svgPath!,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  isActive ? const Color(0xFF2A2A2A) : Colors.white70,
                  BlendMode.srcIn,
                ),
              )
            else
              Icon(
                icon,
                color: isActive ? const Color(0xFF2A2A2A) : Colors.white70,
                size: 22,
              ),
            if (isActive) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2A2A2A),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
