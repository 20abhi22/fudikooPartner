import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/services/notification-badges-service.dart';
import 'package:fudiko/services/badge_controller.dart';

// Colors used by the bottom navigation
const Color _activeColor = Color(0xFFC95F05);
const Color _inactiveColor = Color.fromARGB(255, 70, 68, 68);

class Bottomnav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool banquetEnabled;
  final bool cateringEnabled;
  final bool takeawayEnabled;

  const Bottomnav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.banquetEnabled = true,
    this.cateringEnabled = true,
    this.takeawayEnabled = true,
  });

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  final NotificationBadgesService _badgesService = NotificationBadgesService();
  Map<String, int> _badges = {};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchBadges();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchBadges(),
    );
    // Listen for explicit refresh requests from other parts of the app
    BadgeController.instance.addListener(_fetchBadges);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    BadgeController.instance.removeListener(_fetchBadges);
    super.dispose();
  }

  Future<void> _fetchBadges() async {
    try {
      final data = await _badgesService.getBadges();
      if (!mounted) return;
      setState(() => _badges = data);
    } catch (_) {
      // ignore network errors silently for now
    }
  }
  // ...existing code...

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final screenSize = MediaQuery.sizeOf(context);
        final isMobileDevice = Breakpoints.isMobileDevice(screenSize);
        final isWideShortPhone = Breakpoints.isWideShortPhone(screenSize);
        final usesTabletLayout =
            Breakpoints.isTabletDevice(screenSize) || isWideShortPhone;
        final items = _items();
        final horizontalPadding = usesTabletLayout
            ? 6.0
            : AppDimensions.padding(width) * 0.25;
        final verticalPadding = usesTabletLayout
            ? isWideShortPhone
                  ? 4.0
                  : 10.0
            : isMobileDevice
            ? 8.0
            : 10.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                offset: const Offset(0, -2),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Row(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Expanded(
                  child: _BottomNavTile(
                    item: item,
                    isSelected: index == widget.selectedIndex,
                    width: width,
                    onTap: () => widget.onTabSelected(index),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  List<_BottomNavItem> _items() {
    return [
      _BottomNavItem(
        label: 'Reservation',
        iconPath: 'assets/icons/tabs/reservation_icon.png',
        badge: _badges['reservation'] ?? 0,
      ),
      _BottomNavItem(
        label: 'Banquet',
        iconPath: 'assets/icons/tabs/banquet_icon.png',
        badge: _badges['enquiries'] ?? 0,
        isEnabled: widget.banquetEnabled,
      ),
      const _BottomNavItem(
        label: 'Offers',
        iconPath: 'assets/icons/tabs/offers_icon.png',
      ),
      _BottomNavItem(
        label: 'Catering',
        iconPath: 'assets/icons/tabs/catering_icon.png',
        badge: _badges['catering'] ?? 0,
        isEnabled: widget.cateringEnabled,
      ),
      _BottomNavItem(
        label: 'Take Away',
        iconPath: 'assets/icons/tabs/takeaway_icon.png',
        isEnabled: widget.takeawayEnabled,
      ),
    ];
  }
}

class _BottomNavTile extends StatelessWidget {
  final _BottomNavItem item;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const _BottomNavTile({
    required this.item,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = width < 360;
    final screenSize = MediaQuery.sizeOf(context);
    final isWideShortPhone = Breakpoints.isWideShortPhone(screenSize);
    final usesTabletLayout =
        Breakpoints.isTabletDevice(screenSize) || isWideShortPhone;
    final iconSize = isWideShortPhone
        ? 24.0
        : usesTabletLayout
        ? 32.0
        : compact
        ? 24.0
        : 28.0;
    final iconBoxSize = iconSize;
    final labelSize = isWideShortPhone
        ? 9.5
        : usesTabletLayout
        ? 11.0
        : compact
        ? 10.0
        : 11.0;
    final color = !item.isEnabled
        ? Colors.grey.shade300
        : isSelected
        ? _activeColor
        : _inactiveColor;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: item.isEnabled,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isWideShortPhone
                ? 1
                : usesTabletLayout
                ? 4
                : compact
                ? 2
                : 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SizedBox(
              //   height: 3,
              //   child: AnimatedContainer(
              //     duration: const Duration(milliseconds: 180),
              //     width: isSelected ? 22 : 0,
              //     decoration: BoxDecoration(
              //       color: item.isEnabled
              //           ? Colors.transparent
              //           : Colors.transparent,
              //       borderRadius: BorderRadius.circular(99),
              //     ),
              //   ),
              // ),
              SizedBox(
                height: isWideShortPhone
                    ? 2
                    : usesTabletLayout
                    ? 6
                    : compact
                    ? 4
                    : 6,
              ),
              SizedBox(
                width: iconBoxSize,
                height: iconBoxSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        child: Image.asset(
                          item.iconPath,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (item.isEnabled && item.badge > 0)
                      _Badge(count: item.badge, width: width),
                  ],
                ),
              ),
              SizedBox(
                height: isWideShortPhone
                    ? 2
                    : usesTabletLayout
                    ? 4
                    : compact
                    ? 3
                    : 4,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AppText(
                  text: item.label,
                  size: labelSize,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final double width;

  const _Badge({required this.count, required this.width});

  @override
  Widget build(BuildContext context) {
    final compact = width < 360;
    final size = compact ? 17.0 : 19.0;

    return Positioned(
      top: -6,
      right: -7,
      child: Container(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 5),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: AppText(
          text: '$count',
          size: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          lineSpacing: 1,
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String label;
  final String iconPath;
  final int badge;
  final bool isEnabled;

  const _BottomNavItem({
    required this.label,
    required this.iconPath,
    this.badge = 0,
    this.isEnabled = true,
  });
}
