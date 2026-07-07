import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/bottomnav.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/screens/auth/changepassword.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/screens/auth/updatePassword.dart';
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

class MainNavPage extends StatefulWidget {
  final int initialIndex;

  const MainNavPage({super.key, this.initialIndex = 0});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  int currentIndex = 0;
  bool isDrawerOpen = false;
  late List<Widget> screens;
  DateTime? _lastBackPressedAt;
  final List<GlobalKey<State<StatefulWidget>>> _tabKeys = List.generate(
    5,
    (_) => GlobalKey<State<StatefulWidget>>(),
  );
  PartnerProfileModel? _partnerProfile;
  final PartnerService _partnerService = PartnerService();
  bool _banquetEnabled = true;
  bool _cateringEnabled = true;
  bool _takeawayEnabled = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _fetchProfile();
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
      _lastBackPressedAt = null;
    });
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
    } catch (e, stack) {
      debugPrint('Error fetching profile: $e');
      debugPrintStack(stackTrace: stack);
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

  @override
  Widget build(BuildContext context) {
    screens = [
      Reservation(
        key: _tabKeys[0],
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      Banquet(
        key: _tabKeys[1],
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      Offers(
        key: _tabKeys[2],
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      Catering(
        key: _tabKeys[3],
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      TakeAway(
        key: _tabKeys[4],
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      // Profile(),
    ];
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final isWideShortPhone = _isWideShortPhone(
      screenWidth,
      screenSize.height,
    );
    final usesTabletLayout =
        Breakpoints.isTablet(screenWidth) || isWideShortPhone;
    final drawerWidth = _drawerWidth(screenWidth, screenSize.height);
    final drawerHorizontalPadding = _scaled(
      20,
      screenWidth,
      screenSize.height,
    );
    final drawerInnerPadding = _scaled(
      10,
      screenWidth,
      screenSize.height,
    );
    final drawerSmallGap = isWideShortPhone
        ? 8.0
        : _scaled(10, screenWidth, screenSize.height);
    final drawerLargeGap = isWideShortPhone
        ? 24.0
        : _scaled(50, screenWidth, screenSize.height);
    final drawerSectionTitleSize = isWideShortPhone
        ? 15.0
        : usesTabletLayout
        ? 17.0
        : 15.0;
    final scannerOffset = _scannerOffset(screenWidth);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: IndexedStack(index: currentIndex, children: screens),
                  ),
                  Bottomnav(
                    selectedIndex: currentIndex,
                    onTabSelected: onTabChanged,
                    banquetEnabled: _banquetEnabled,
                    cateringEnabled: _cateringEnabled,
                    takeawayEnabled: _takeawayEnabled,
                  ),
                ],
              ),
              // if (!isDrawerOpen && currentIndex != 2)
              //   Positioned(
              //     right: scannerOffset.$1,
              //     bottom: scannerOffset.$2,
              //     child: Center(child: _scannerButton()),
              //   ),
              if (isDrawerOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isDrawerOpen = false;
                      });
                    },
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: 0,
                bottom: 0,
                right: isDrawerOpen ? 0 : -drawerWidth,
                child: Container(
                  width: drawerWidth,
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
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: drawerHorizontalPadding,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: drawerLargeGap),
                            Divider(
                              thickness: 1,
                              color: Colors.grey,
                              height: 1,
                            ),
                            SizedBox(height: drawerSmallGap),
                            _drawerItem(
                              "Profile",
                              drawerProfileIcon,
                              RestaurantProfile(),
                              // color: Color(0xFF333333)
                            ),
                            SizedBox(height: drawerSmallGap),
                            Divider(
                              thickness: 1,
                              color: Colors.grey,
                              height: 1,
                            ),
                            SizedBox(height: drawerLargeGap),
                            AppText(
                              text: "Settings",
                              size: drawerSectionTitleSize,
                              fontWeight: FontWeight.w600,
                              color: appTextColor2,
                            ),
                            SizedBox(height: drawerSmallGap),
                            Divider(
                              thickness: 1,
                              color: Colors.grey,
                              height: 1,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: drawerInnerPadding,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Change Password",
                                    drawerChangePasswordIcon,
                                    // ChangePassword(),
                                    UpdatePassword(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Notifications",
                                    drawerNotificationIcon,
                                    NotificationPage(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Languages",
                                    drawerTranslateIcon,
                                    Languages(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Analytics",
                                    drawerAnalyticsIcon,
                                    TotalOrders(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Service",
                                    drawerServiceIcon,
                                    ServicePage(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Promotions",
                                    drawerPromotionIcon,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: drawerLargeGap),
                            AppText(
                              text: "Information",
                              size: drawerSectionTitleSize,
                              fontWeight: FontWeight.w600,
                              color: appTextColor2,
                            ),
                            SizedBox(height: drawerSmallGap),
                            Divider(
                              thickness: 1,
                              color: Colors.grey,
                              height: 1,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: drawerInnerPadding,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "About the App",
                                    drawerAboutIcon,
                                    AboutPage(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Badge Earnings",
                                    drawerHelpIcon,
                                    BadgeInfo(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Documentation",
                                    drawerDocumentIcon,
                                    AgreementPage(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Support",
                                    drawerCustomerIcon,
                                    ContactPage(),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: drawerLargeGap),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: drawerInnerPadding,
                              ),
                              child: Column(
                                children: [
                                  Divider(
                                    thickness: 1,
                                    color: Color(0xFFFA2929),
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  _drawerItem(
                                    "Log Out",
                                    drawerLogoutIcon,
                                    Login(),
                                    Color(0xFFFA2929),
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                  Divider(
                                    thickness: 1,
                                    color: Color(0xFFFA2929),
                                    height: 1,
                                  ),
                                  SizedBox(height: drawerSmallGap),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // (double, double) _scannerOffset(double width) {
  //   final bottomNavHeight = _bottomNavEstimatedHeight(width);

  //   if (Breakpoints.isMobile(width)) {
  //     if (_isCompactMobile(width)) {
  //       return (14.w, bottomNavHeight + 8.h);
  //     }

  //     return ((width * 0.055).clamp(20.0, 28.0), bottomNavHeight + 12.h);
  //   }

  //   if (Breakpoints.isTablet(width)) {
  //     final right = (width * 0.055).clamp(32.0, 56.0);
  //     return (right, bottomNavHeight + 18.0);
  //   }

  //   return (40.0, bottomNavHeight + 16.0);
  // }
  (double, double) _scannerOffset(double width) {
  final bottomNavHeight = _bottomNavEstimatedHeight(width);

  if (Breakpoints.isMobile(width)) {
    return (_isCompactMobile(width) ? 14.0 : 20.0, bottomNavHeight + 10.0);
  }

  if (Breakpoints.isTablet(width)) {
    return (28.0, bottomNavHeight + 16.0);
  }

  return (32.0, bottomNavHeight + 16.0);
}

  double _bottomNavEstimatedHeight(double width) {
    final compact = _isCompactMobile(width);
    final verticalPadding = Breakpoints.isMobile(width) ? 8.0 : 10.0;
    final tileVerticalPadding = compact ? 2.0 : 4.0;
    final topGap = compact ? 4.0 : 6.0;
    final iconSize = Breakpoints.isTablet(width)
        ? 32.0
        : compact
        ? 24.0
        : 28.0;
    final iconLabelGap = compact ? 3.0 : 4.0;
    final labelSize = compact ? 10.0 : 11.0;

    return (verticalPadding * 2) +
        (tileVerticalPadding * 2) +
        topGap +
        iconSize +
        iconLabelGap +
        (labelSize * 1.25);
  }

//   Widget _scannerButton() {
//     final screenWidth = MediaQuery.sizeOf(context).width;
//     final isMobile = Breakpoints.isMobile(screenWidth);
//     final compactPhone = _isCompactMobile(screenWidth);
//     // final imageSize = isMobile
//     //     ? (compactPhone ? 48.w : 56.w)
//     //     : Breakpoints.isTablet(screenWidth)
//     //     ? 64.0
//     //     : 62.0;
//     // final buttonSize = isMobile
//     //     ? (compactPhone ? 56.w : 66.w)
//     //     : Breakpoints.isTablet(screenWidth)
//     //     ? 74.0
//     //     : 72.0;
//     // final radius = isMobile
//     //     ? (compactPhone ? 18.r : 20.r)
//     //     : Breakpoints.isTablet(screenWidth)
//     //     ? 22.0
//     //     : 20.0;
//    final buttonSize = isMobile
//     ? (compactPhone ? 56.w : 66.w)
//     : Breakpoints.isTablet(screenWidth)
//         ? screenWidth * 0.075  // ~7.5% of tablet width
//         : screenWidth * 0.05;  // desktop
// final imageSize = buttonSize * 0.65;
// final radius = buttonSize * 0.30;
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Scanner(scannerType: _scannerType),
//           ),
//         );
//       },
//       child: SizedBox(
//         height: buttonSize,
//         width: buttonSize,
//         child: DecoratedBox(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(radius),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.5),
//                 blurRadius: 10,
//                 offset: const Offset(4, 4),
//               ),
//             ],
//           ),
//           child: Center(
//             child: Padding(
//               // padding: EdgeInsets.only(left: isMobile ? 3 : 4),
//               padding: EdgeInsets.only(left: buttonSize * 0.045),
//               child: Image.asset(
//                 'assets/images/scanner2.png',
//                 height: imageSize,
//                 width: imageSize,
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

Widget _scannerButton() {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isMobile = Breakpoints.isMobile(screenWidth);
  final isTablet = Breakpoints.isTablet(screenWidth);
  final compactPhone = _isCompactMobile(screenWidth);

  final double imageSize;
  if (isMobile) {
    imageSize = compactPhone ? 32.0 : 38.0;
  } else if (isTablet) {
    imageSize = 36.0;
  } else {
    imageSize = 38.0;
  }

  final double padding = isMobile ? (compactPhone ? 7.0 : 8.0) : 8.0;
  final radius = (imageSize + padding * 2) * 0.18;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scanner(scannerType: _scannerType),
        ),
      );
    },
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          'assets/images/scanner2.png',
          // height: imageSize,
          // width: imageSize,
          fit: BoxFit.contain,
        ),
      ),
    ),
  );
}
  ScannerType get _scannerType {
    if (currentIndex == 1) return ScannerType.banquet;
    if (currentIndex == 3) return ScannerType.catering;
    return ScannerType.restaurant;
  }

  bool _isCompactMobile(double width) => width < 390;

  Widget _drawerItem(
    String text,
    String iconPath, [
    Widget? routeWidget,
    Color? color,
  ]) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isWideShortPhone = _isWideShortPhone(screenWidth, size.height);
    final isTablet = Breakpoints.isTablet(screenWidth);
    final iconSize = isWideShortPhone
        ? 22.0
        : Breakpoints.isMobile(screenWidth)
        ? 22.w
        : isTablet
        ? 26.0
        : 24.0;
    final gap = isWideShortPhone
        ? 10.0
        : Breakpoints.isMobile(screenWidth)
        ? 10.w
        : isTablet
        ? 14.0
        : 12.0;
    final textSize = isWideShortPhone ? 15.0 : isTablet ? 17.0 : 15.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          isDrawerOpen = false;
        });

        Future.delayed(Duration(milliseconds: 100), () async {
          if (routeWidget != null) {
            if (routeWidget is Login) {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => routeWidget),
              );
              await removeToken();
            } else {
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => routeWidget),
              );
              if (routeWidget is ServicePage) {
                await _fetchServiceSettings();
              }
            }
          }
        });
      },
      child: Row(
        children: [
          Image.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
            color: color ?? appTextColor5,
            fit: BoxFit.cover,
          ),
          SizedBox(width: gap),
          AppText(
            text: text,
            size: textSize,
            fontWeight: FontWeight.w500,
            color: color ?? appTextColor2,
          ),
        ],
      ),
    );
  }

  bool _isWideShortPhone(double width, double height) =>
      Breakpoints.isMobile(width) && width >= 500 && height <= 760;

  double _drawerWidth(double width, double height) {
    if (_isWideShortPhone(width, height)) return width.clamp(360.0, 430.0);
    if (Breakpoints.isMobile(width)) return width * 0.75;
    if (Breakpoints.isTablet(width)) return width.clamp(360.0, 430.0);
    return 380.0;
  }

  double _scaled(double value, double width, double height) {
    if (Breakpoints.isMobile(width) && !_isWideShortPhone(width, height)) {
      return value.w;
    }
    return value;
  }
}
