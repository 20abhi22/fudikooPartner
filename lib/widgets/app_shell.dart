import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/bottomnav.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/core/responsive/responsive_builder.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/screens/auth/changepassword.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/screens/others/about.dart';
import 'package:fudiko/screens/others/agreement.dart';
import 'package:fudiko/screens/others/badgeInfo.dart';
import 'package:fudiko/screens/others/contact.dart';
import 'package:fudiko/screens/others/languages.dart';
import 'package:fudiko/screens/others/nav/banquet.dart';
import 'package:fudiko/screens/others/nav/catering.dart';
import 'package:fudiko/screens/others/nav/offers/offers.dart';
import 'package:fudiko/screens/others/nav/reservation.dart';
import 'package:fudiko/screens/others/nav/takeaway.dart';
import 'package:fudiko/screens/others/notification.dart';
import 'package:fudiko/screens/others/restaurantProfile.dart';
import 'package:fudiko/screens/others/scanner.dart';
import 'package:fudiko/screens/others/scanner2.dart';
import 'package:fudiko/screens/others/services.dart';
import 'package:fudiko/screens/others/totalOrders.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tab_back_handler.dart';
import 'package:fudiko/utils/tokens.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;
  bool isDrawerOpen = false;
  DateTime? _lastBackPressedAt;
  PartnerProfileModel? _partnerProfile;

  final PartnerService _partnerService = PartnerService();
  final List<GlobalKey<State<StatefulWidget>>> _tabKeys = List.generate(
    5,
    (_) => GlobalKey<State<StatefulWidget>>(),
  );

  bool _banquetEnabled = true;
  bool _cateringEnabled = true;
  bool _takeawayEnabled = true;

  static const List<_ShellTab> _tabs = [
    _ShellTab(label: 'Reservation', icon: Icons.event_note_outlined),
    _ShellTab(label: 'Banquet', icon: Icons.celebration_outlined),
    _ShellTab(label: 'Offers', icon: Icons.local_offer_outlined),
    _ShellTab(label: 'Catering', icon: Icons.room_service_outlined),
    _ShellTab(label: 'Take Away', icon: Icons.shopping_bag_outlined),
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: ResponsiveBuilder(
        mobile: (context, constraints) => _mobileShell(),
        tablet: (context, constraints) => _tabletShell(),
        desktop: (context, constraints) =>
            _desktopShell(width: constraints.maxWidth),
      ),
    );
  }

  Widget _mobileShell() {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: _stackedContent(showBottomNav: true),
    );
  }

  Widget _tabletShell() {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: _stackedContent(showBottomNav: true),
    );
  }

  Widget _desktopShell({required double width}) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            Flexible(flex: 1, child: _permanentDrawer(width)),
            Expanded(
              flex: 4,
              child: IndexedStack(index: currentIndex, children: _screens()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stackedContent({required bool showBottomNav}) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                child: IndexedStack(index: currentIndex, children: _screens()),
              ),
            ),
            if (showBottomNav)
              ColoredBox(
                color: appSecondaryBackgroundColor,
                child: SafeArea(
                  top: false,
                  child: Bottomnav(
                    selectedIndex: currentIndex,
                    onTabSelected: onTabChanged,
                    banquetEnabled: _banquetEnabled,
                    cateringEnabled: _cateringEnabled,
                    takeawayEnabled: _takeawayEnabled,
                  ),
                ),
              ),
          ],
        ),
        if (!isDrawerOpen && currentIndex != 2) _scannerButtonPositioned(),
        if (isDrawerOpen) _drawerScrim(),
        _slideOutDrawer(),
      ],
    );
  }

  List<Widget> _screens() {
    return [
      Reservation(
        key: _tabKeys[0],
        onDrawerTap: _toggleDrawer,
        partnerProfile: _partnerProfile,
      ),
      Banquet(
        key: _tabKeys[1],
        onDrawerTap: _toggleDrawer,
        partnerProfile: _partnerProfile,
      ),
      Offers(
        key: _tabKeys[2],
        onDrawerTap: _toggleDrawer,
        partnerProfile: _partnerProfile,
      ),
      Catering(
        key: _tabKeys[3],
        onDrawerTap: _toggleDrawer,
        partnerProfile: _partnerProfile,
      ),
      TakeAway(
        key: _tabKeys[4],
        onDrawerTap: _toggleDrawer,
        partnerProfile: _partnerProfile,
      ),
    ];
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _partnerService.getProfile();
      if (!mounted) return;
      setState(() {
        _partnerProfile = profile;
        _banquetEnabled = profile.banquetService == 1;
        _cateringEnabled = profile.cateringService == 1;
        _takeawayEnabled = profile.takeawayService == 1;
        if (!_isTabEnabled(currentIndex)) currentIndex = 0;
      });
      await _fetchServiceSettings();
    } catch (_) {
      await _fetchServiceSettings();
    }
  }

  Future<void> _fetchServiceSettings() async {
    try {
      final token = await getToken();
      final response = await DioClient.dio.get(
        '/partner/services',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data is Map<String, dynamic>
          ? response.data['data'] as Map<String, dynamic>?
          : null;
      if (data == null || !mounted) return;

      setState(() {
        _banquetEnabled = (data['banquet_service'] ?? 0) == 1;
        _cateringEnabled = (data['catering_service'] ?? 0) == 1;
        _takeawayEnabled = (data['takeaway_service'] ?? 0) == 1;
        if (!_isTabEnabled(currentIndex)) currentIndex = 0;
      });
    } catch (_) {
      // Keep profile/default values if service settings fail to load.
    }
  }

  void onTabChanged(int index) {
    if (!_isTabEnabled(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_tabLabel(index)} is disabled in Services')),
      );
      return;
    }

    setState(() {
      currentIndex = index;
      isDrawerOpen = false;
      _lastBackPressedAt = null;
    });
  }

  bool _isTabEnabled(int index) {
    if (index == 1) return _banquetEnabled;
    if (index == 3) return _cateringEnabled;
    if (index == 4) return _takeawayEnabled;
    return true;
  }

  String _tabLabel(int index) {
    switch (index) {
      case 1:
        return 'Banquet';
      case 3:
        return 'Catering';
      case 4:
        return 'Take Away';
      default:
        return 'This tab';
    }
  }

  void _toggleDrawer() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
    });
  }

  void _handleBackNavigation() {
    if (isDrawerOpen) {
      setState(() {
        isDrawerOpen = false;
        _lastBackPressedAt = null;
      });
      return;
    }

    final currentTabState = _tabKeys[currentIndex].currentState;
    final handledByTab = currentTabState is TabBackHandler
        ? (currentTabState as TabBackHandler).handleBack()
        : false;
    if (handledByTab) {
      _lastBackPressedAt = null;
      return;
    }

    if (currentIndex != 0) {
      setState(() {
        currentIndex = 0;
        _lastBackPressedAt = null;
      });
      return;
    }

    final now = DateTime.now();
    final shouldExit =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);

    if (shouldExit) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Press back again to exit')));
  }

  // Widget _scannerButtonPositioned() {
  //   return Positioned(
  //     left: MediaQuery.of(context).size.width * .7,
  //     right: 0,
  //     bottom: 80.h,
  //     child: Center(child: _scannerButton()),
  //   );
  // }

  // Widget _scannerButton() {
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => Scanner(scannerType: _scannerType),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       height: 60.h,
  //       width: 60.w,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(20.r),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withValues(alpha: 0.5),
  //             blurRadius: 10,
  //             offset: const Offset(4, 4),
  //           ),
  //         ],
  //       ),
  //       child: Center(
  //         child: Padding(
  //           padding: const EdgeInsets.only(left: 3),
  //           child: Image.asset(
  //             'assets/images/scanner2.png',
  //             height: 56.h,
  //             width: 60.w,
  //             fit: BoxFit.contain,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _scannerButtonPositioned() {
    final size = MediaQuery.sizeOf(context);
    final isMobile = Breakpoints.isMobileDevice(size);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isCompact = size.width < 390;
    final bottomNavHeight = isWideShortPhone
        ? 68.0
        : isMobile
        ? 80.0
        : 90.0;

    final double right = isMobile ? (isCompact ? 24.0 : 30.0) : 36.0;
    final double bottom =
        bottomNavHeight +
        (isWideShortPhone
            ? 12.0
            : isMobile
            ? 18.0
            : 24.0);

    return Positioned(right: right, bottom: bottom, child: _scannerButton());
  }

  Widget _scannerButton() {
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = Breakpoints.isMobileDevice(screenSize);
    final isCompact = screenSize.width < 390;
    final isWideShortPhone = Breakpoints.isWideShortPhone(screenSize);
    final isTablet = Breakpoints.isTabletDevice(screenSize);

    final double buttonSize;
    if (isWideShortPhone) {
      buttonSize = 46.0;
    } else if (isMobile) {
      buttonSize = isCompact ? 46.0 : 54.0;
    } else if (isTablet) {
      buttonSize = 58.0;
    } else {
      buttonSize = 56.0;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scanner(scannerType: _scannerType),
          ),
        );
      },
      child: Container(
        width: buttonSize + 8,
        height: buttonSize + 8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(buttonSize * 0.35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(buttonSize * 0.015),
        child: Image.asset('assets/images/scanner2.png', fit: BoxFit.cover),
      ),
    );
  }

  ScannerType get _scannerType {
    if (currentIndex == 1) return ScannerType.banquet;
    if (currentIndex == 3) return ScannerType.catering;
    return ScannerType.restaurant;
  }

  Widget _drawerScrim() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isDrawerOpen = false;
          });
        },
        child: Container(color: Colors.black.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _slideOutDrawer() {
    final size = MediaQuery.sizeOf(context);
    final drawerWidth = _drawerWidth(size);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: 0,
      bottom: 0,
      right: isDrawerOpen ? 0 : -drawerWidth,
      child: SizedBox(
        width: drawerWidth,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(-4, 0),
              ),
            ],
          ),
          child: SafeArea(child: _drawerContent()),
        ),
      ),
    );
  }

  double _drawerWidth(Size size) {
    final width = size.width;
    if (Breakpoints.isTabletDevice(size)) {
      return (width * 0.42).clamp(320.0, 380.0);
    }
    if (Breakpoints.isWideShortPhone(size)) {
      return (width * 0.58).clamp(320.0, 420.0);
    }

    return width * 0.75;
  }

  Widget _drawerContent() {
    final size = MediaQuery.sizeOf(context);
    final isMobile = Breakpoints.isMobileDevice(size);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final horizontalPadding = isMobile ? 20.w : 22.0;
    final sideInset = isMobile ? 10.w : 8.0;
    final topGap = isWideShortPhone
        ? 20.0
        : isMobile
        ? 50.h
        : 32.0;
    final largeGap = isWideShortPhone
        ? 18.0
        : isMobile
        ? 50.h
        : 30.0;
    final smallGap = isWideShortPhone
        ? 6.0
        : isMobile
        ? 10.h
        : 8.0;
    final titleSize = isMobile ? 15.0 : 13.5;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topGap),
            Divider(thickness: 1, color: Colors.grey, height: 1),
            SizedBox(height: smallGap),
            _drawerItem('Profile', drawerProfileIcon, RestaurantProfile()),
            SizedBox(height: smallGap),
            Divider(thickness: 1, color: Colors.grey, height: 1),
            SizedBox(height: largeGap),
            AppText(
              text: 'Settings',
              size: titleSize,
              fontWeight: FontWeight.w600,
              color: appTextColor2,
            ),
            SizedBox(height: smallGap),
            Divider(thickness: 1, color: Colors.grey, height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sideInset),
              child: Column(
                children: [
                  SizedBox(height: smallGap),
                  _drawerItem(
                    'Change Password',
                    drawerChangePasswordIcon,
                    ChangePassword(),
                  ),
                  _drawerDivider(),
                  _drawerItem(
                    'Notifications',
                    drawerNotificationIcon,
                    NotificationPage(),
                  ),
                  _drawerDivider(),
                  _drawerItem('Languages', drawerTranslateIcon, Languages()),
                  _drawerDivider(),
                  _drawerItem('Analytics', drawerAnalyticsIcon, TotalOrders()),
                  _drawerDivider(),
                  _drawerItem('Service', drawerServiceIcon, ServicePage()),
                  _drawerDivider(),
                  _drawerItem('Promotions', drawerPromotionIcon),
                  _drawerDivider(),
                ],
              ),
            ),
            SizedBox(height: largeGap),
            AppText(
              text: 'Information',
              size: titleSize,
              fontWeight: FontWeight.w600,
              color: appTextColor2,
            ),
            SizedBox(height: smallGap),
            Divider(thickness: 1, color: Colors.grey, height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sideInset),
              child: Column(
                children: [
                  SizedBox(height: smallGap),
                  _drawerItem('About the App', drawerAboutIcon, AboutPage()),
                  _drawerDivider(),
                  _drawerItem('Badge Earnings', drawerHelpIcon, BadgeInfo()),
                  _drawerDivider(),
                  _drawerItem(
                    'Documentation',
                    drawerDocumentIcon,
                    AgreementPage(),
                  ),
                  _drawerDivider(),
                  _drawerItem('Support', drawerCustomerIcon, ContactPage()),
                  _drawerDivider(),
                ],
              ),
            ),
            SizedBox(height: largeGap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sideInset),
              child: Column(
                children: [
                  Divider(thickness: 1, color: Color(0xFFFA2929), height: 1),
                  SizedBox(height: smallGap),
                  _drawerItem(
                    'Log Out',
                    drawerLogoutIcon,
                    const Login(),
                    Color(0xFFFA2929),
                  ),
                  SizedBox(height: smallGap),
                  Divider(thickness: 1, color: Color(0xFFFA2929), height: 1),
                  SizedBox(height: smallGap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerDivider() {
    final size = MediaQuery.sizeOf(context);
    final isMobile = Breakpoints.isMobileDevice(size);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final gap = isWideShortPhone
        ? 6.0
        : isMobile
        ? 10.h
        : 8.0;

    return Column(
      children: [
        SizedBox(height: gap),
        Divider(thickness: 1, color: Colors.grey, height: 1),
        SizedBox(height: gap),
      ],
    );
  }

  Widget _drawerItem(
    String text,
    String iconPath, [
    Widget? routeWidget,
    Color? color,
  ]) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = Breakpoints.isMobileDevice(size);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final iconSize = isMobile ? 22.w : 17.0;
    final rowGap = isMobile ? 10.w : 10.0;
    final textSize = isMobile ? 15.0 : 13.5;
    final verticalPadding = isWideShortPhone
        ? 3.0
        : isMobile
        ? 0.0
        : 5.0;
    final horizontalPadding = isMobile ? 0.0 : 4.0;
    final itemRadius = isMobile ? 0.0 : 8.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          isDrawerOpen = false;
        });

        Future.delayed(const Duration(milliseconds: 100), () async {
          if (routeWidget == null) {
            onTabChanged(2);
            return;
          }

          if (routeWidget is Login) {
            await _logout();
            return;
          }

          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => routeWidget),
          );
          if (routeWidget is ServicePage) {
            await _fetchServiceSettings();
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(itemRadius),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: iconSize,
              height: iconSize,
              color: color ?? appTextColor5,
              fit: BoxFit.contain,
            ),
            SizedBox(width: rowGap),
            Expanded(
              child: AppText(
                text: text,
                size: textSize,
                fontWeight: FontWeight.w500,
                color: color ?? appTextColor2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permanentDrawer(double width) {
    return NavigationDrawer(
      selectedIndex: currentIndex,
      onDestinationSelected: onTabChanged,
      children: [
        Padding(
          padding: EdgeInsets.all(AppDimensions.padding(width)),
          child: Text(
            'Fudiko Partner',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ..._tabs.map(
          (tab) => NavigationDrawerDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(_selectedIcon(tab.icon)),
            label: Text(tab.label),
          ),
        ),
        const Divider(),
        _drawerActionTile(
          icon: Icons.person_outline,
          label: 'Profile',
          page: RestaurantProfile(),
        ),
        _drawerActionTile(
          icon: Icons.lock_outline,
          label: 'Change Password',
          page: ChangePassword(),
        ),
        _drawerActionTile(
          icon: Icons.notifications_none,
          label: 'Notifications',
          page: NotificationPage(),
        ),
        _drawerActionTile(
          icon: Icons.translate,
          label: 'Languages',
          page: Languages(),
        ),
        _drawerActionTile(
          icon: Icons.analytics_outlined,
          label: 'Analytics',
          page: TotalOrders(),
        ),
        _drawerActionTile(
          icon: Icons.miscellaneous_services_outlined,
          label: 'Service',
          page: ServicePage(),
          refreshServices: true,
        ),
        const Divider(),
        _drawerActionTile(
          icon: Icons.info_outline,
          label: 'About the App',
          page: AboutPage(),
        ),
        _drawerActionTile(
          icon: Icons.workspace_premium_outlined,
          label: 'Badge Earnings',
          page: BadgeInfo(),
        ),
        _drawerActionTile(
          icon: Icons.description_outlined,
          label: 'Documentation',
          page: AgreementPage(),
        ),
        _drawerActionTile(
          icon: Icons.support_agent,
          label: 'Support',
          page: ContactPage(),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Color(0xFFFA2929)),
          title: const Text(
            'Log Out',
            style: TextStyle(color: Color(0xFFFA2929)),
          ),
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _drawerActionTile({
    required IconData icon,
    required String label,
    required Widget page,
    bool refreshServices = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
        if (refreshServices) {
          await _fetchServiceSettings();
        }
      },
    );
  }

  Future<void> _logout() async {
    await removeToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  IconData _selectedIcon(IconData icon) {
    if (icon == Icons.event_note_outlined) return Icons.event_note;
    if (icon == Icons.celebration_outlined) return Icons.celebration;
    if (icon == Icons.local_offer_outlined) return Icons.local_offer;
    if (icon == Icons.room_service_outlined) return Icons.room_service;
    if (icon == Icons.shopping_bag_outlined) return Icons.shopping_bag;
    return icon;
  }
}

class _ShellTab {
  final String label;
  final IconData icon;

  const _ShellTab({required this.label, required this.icon});
}
