import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/bottomnav.dart';
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
import 'package:fudiko/screens/others/services.dart';
import 'package:fudiko/screens/others/totalOrders.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';
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
      print('Error fetching profile: $e');
      print(stack);
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
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      Banquet(
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      Offers(
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      Catering(
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      TakeAway(
        onDrawerTap: () {
          setState(() {
            isDrawerOpen = !isDrawerOpen;
          });
        },
        partnerProfile: _partnerProfile,
      ),
      // Profile(),
    ];
    return Scaffold(
      floatingActionButton:
          isDrawerOpen || currentIndex == 2 || currentIndex == 4
          ? null
          : GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Scanner()),
                );
              },
              child: Container(
                height: 60.h,
                width: 60.02.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3.0),
                    child: Image.asset(
                      'assets/images/scanner2.png',
                      height: 56.h,
                      width: 60.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: screens[currentIndex]),
              Bottomnav(
                selectedIndex: currentIndex,
                onTabSelected: onTabChanged,
                banquetEnabled: _banquetEnabled,
                cateringEnabled: _cateringEnabled,
                takeawayEnabled: _takeawayEnabled,
              ),
            ],
          ),
          if (isDrawerOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isDrawerOpen = false;
                  });
                },
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: 0,
            bottom: 0,
            right: isDrawerOpen ? 0 : -MediaQuery.of(context).size.width * 0.75,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
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
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 50.h),
                        Divider(thickness: 1, color: Colors.grey, height: 1),
                        SizedBox(height: 10.h),
                        _drawerItem(
                          "Profile",
                          drawerProfileIcon,
                          RestaurantProfile(),
                          // color: Color(0xFF333333)
                        ),
                        SizedBox(height: 10.h),
                        Divider(thickness: 1, color: Colors.grey, height: 1),
                        SizedBox(height: 50.h),
                        AppText(
                          text: "Settings",
                          size: 15,
                          fontWeight: FontWeight.w600,
                          color: appTextColor2,
                        ),
                        SizedBox(height: 10.h),
                        Divider(thickness: 1, color: Colors.grey, height: 1),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Column(
                            children: [
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Change Password",
                                drawerChangePasswordIcon,
                                ChangePassword(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Notifications",
                                drawerNotificationIcon,
                                NotificationPage(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Languages",
                                drawerTranslateIcon,
                                Languages(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Analytics",
                                drawerAnalyticsIcon,
                                TotalOrders(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Service",
                                drawerServiceIcon,
                                ServicePage(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem("Promotions", drawerPromotionIcon),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 50.h),
                        AppText(
                          text: "Information",
                          size: 15,
                          fontWeight: FontWeight.w600,
                          color: appTextColor2,
                        ),
                        SizedBox(height: 10.h),
                        Divider(thickness: 1, color: Colors.grey, height: 1),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Column(
                            children: [
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "About the App",
                                drawerAboutIcon,
                                AboutPage(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Badge Earnings",
                                drawerHelpIcon,
                                BadgeInfo(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Documentation",
                                drawerDocumentIcon,
                                AgreementPage(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Support",
                                drawerCustomerIcon,
                                ContactPage(),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey,
                                height: 1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 50.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.h),
                          child: Column(
                            children: [
                              Divider(
                                thickness: 1,
                                color: Color(0xFFFA2929),
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
                              _drawerItem(
                                "Log Out",
                                drawerLogoutIcon,
                                Login(),
                                Color(0xFFFA2929),
                              ),
                              SizedBox(height: 10.h),
                              Divider(
                                thickness: 1,
                                color: Color(0xFFFA2929),
                                height: 1,
                              ),
                              SizedBox(height: 10.h),
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
    );
  }

  Widget _drawerItem(
    String text,
    String iconPath, [
    Widget? routeWidget,
    Color? color,
  ]) {
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
            width: 22.w,
            height: 22.w,
            color: color ?? appTextColor5,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 10.w),
          AppText(
            text: text,
            size: 15,
            fontWeight: FontWeight.w500,
            color: color ?? appTextColor2,
          ),
        ],
      ),
    );
  }
}
