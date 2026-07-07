import 'package:flutter/material.dart';
import 'package:fudiko/components/orderDonut.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/profile/customer-profile-model.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';

class Profile extends StatefulWidget {
  final String customerId;

  const Profile({super.key, required this.customerId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  CustomerProfileModel? _profile;
  final CustomerProfileService _service = CustomerProfileService();
  bool _isLoading = true;
  String? _errorMessage;
  String? _nearestPlaceName;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (widget.customerId.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Customer id is missing';
      });
      return;
    }

    try {
      final profile = await _service.getProfile(widget.customerId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
        _errorMessage = null;
      });
      await _fetchNearestPlaceName(profile);
    } catch (e) {
      debugPrint('Error fetching customer profile: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load customer profile';
      });
    }
  }

  Future<void> _fetchNearestPlaceName(CustomerProfileModel profile) async {
    final latitude = double.tryParse(profile.lat);
    final longitude = double.tryParse(profile.lng);

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (!mounted || _profile != profile || placemarks.isEmpty) return;

      final place = placemarks.first;
      final placeParts = [
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).toList();

      if (placeParts.isNotEmpty) {
        setState(() => _nearestPlaceName = placeParts.join(', '));
      }
    } catch (e) {
      // Keep the place value returned by the API when reverse geocoding fails.
      debugPrint('Unable to resolve customer place: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202020),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          final isWideShortPhone = Breakpoints.isWideShortPhone(viewport);
          final useSplitLayout =
              isLandscape &&
              (Breakpoints.isTablet(viewport.width) || isWideShortPhone);
          final panelWidth = useSplitLayout
              ? viewport.width.clamp(720.0, 960.0)
              : viewport.width >= 600
              ? 460.0
              : viewport.width;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: panelWidth),
              child: ColoredBox(
                color: Colors.white,
                child: useSplitLayout
                    ? _landscapeContent(
                        constraints: constraints,
                        panelWidth: panelWidth,
                        viewportHeight: viewport.height,
                      )
                    : _portraitContent(
                        constraints: constraints,
                        panelWidth: panelWidth,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _portraitContent({
    required BoxConstraints constraints,
    required double panelWidth,
  }) {
    final bannerHeight = (panelWidth * 0.48).clamp(170.0, 220.0);
    final avatarSize = (panelWidth * 0.34).clamp(128.0, 156.0);
    final avatarTop = bannerHeight - (avatarSize * 0.68);
    final headerHeight = bannerHeight + (avatarSize * 0.36);
    final chartSize = (panelWidth * 0.56).clamp(220.0, 260.0);
    final cardHorizontalInset = (panelWidth * 0.07).clamp(28.0, 36.0);

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          children: [
            _profileHeader(
              bannerHeight: bannerHeight,
              avatarSize: avatarSize,
              avatarTop: avatarTop,
              headerHeight: headerHeight,
            ),
            SizedBox(height: 12.h),
            _nameBlock(),
            SizedBox(height: 12.h),
            Center(child: _badgeWidget()),
            SizedBox(height: 26.h),
            _ratingChart(chartSize: chartSize),
            SizedBox(height: 36.h),
            _ratingLabel(),
            SizedBox(height: 56.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: cardHorizontalInset),
              child: _infoCard(panelWidth: panelWidth),
            ),
            SizedBox(height: 88.h),
          ],
        ),
      ),
    );
  }

  Widget _landscapeContent({
    required BoxConstraints constraints,
    required double panelWidth,
    required double viewportHeight,
  }) {
    final sidePadding = (panelWidth * 0.045).clamp(24.0, 42.0);
    final bannerHeight = (viewportHeight * 0.34).clamp(104.0, 150.0);
    final avatarSize = (viewportHeight * 0.28).clamp(92.0, 124.0);
    final avatarTop = bannerHeight - (avatarSize * 0.6);
    final headerHeight = bannerHeight + (avatarSize * 0.45);
    final chartSize = (viewportHeight * 0.44).clamp(150.0, 210.0);
    final contentWidth = panelWidth - sidePadding * 2;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sidePadding,
            vertical: 18.h,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: (contentWidth * 0.42).clamp(280.0, 360.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _profileHeader(
                      bannerHeight: bannerHeight,
                      avatarSize: avatarSize,
                      avatarTop: avatarTop,
                      headerHeight: headerHeight,
                    ),
                    SizedBox(height: 10.h),
                    _nameBlock(),
                    SizedBox(height: 10.h),
                    Center(child: _badgeWidget()),
                  ],
                ),
              ),
              SizedBox(width: 28.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ratingChart(chartSize: chartSize),
                    SizedBox(height: 18.h),
                    _ratingLabel(),
                    SizedBox(height: 22.h),
                    _infoCard(panelWidth: panelWidth * 0.48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader({
    required double bannerHeight,
    required double avatarSize,
    required double avatarTop,
    required double headerHeight,
  }) {
    return SizedBox(
      height: headerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Image.asset(
              'assets/images/banner1.png',
              height: bannerHeight,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: avatarTop,
            child: Container(
              width: avatarSize + 10.w,
              height: avatarSize + 10.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4.5),
              ),
              child: ClipOval(child: _profileImage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameBlock() {
    return AppText(
      text: _isLoading ? "Loading..." : _errorMessage ?? _profile?.name ?? "-",
      size: 22,
      fontWeight: FontWeight.w700,
      color: _errorMessage == null ? const Color(0xFF24150E) : Colors.red,
      isCentered: true,
    );
  }

  Widget _ratingChart({required double chartSize}) {
    final rating = double.tryParse(_profile?.rating.toString() ?? '') ?? 0;

    return SizedBox(
      width: chartSize,
      height: chartSize,
      child: OrderDonut(done: rating, total: 100, thickness: 25.w),
    );
  }

  Widget _ratingLabel() {
    return AppText(
      text: "Reliability Rating",
      size: 16,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFB35745),
      isCentered: true,
    );
  }

  Widget _infoCard({required double panelWidth}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (panelWidth * 0.075).clamp(24.0, 34.0),
        vertical: 26.h,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Place", _nearestPlaceName ?? _profile?.place ?? "-"),
          _infoRow("Email", _profile?.email ?? "-"),
          _infoRow("Contact Info", _profile?.contactInfo ?? "-"),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        Row(
          children: [
            AppText(
              text: label,
              size: 13,
              fontWeight: FontWeight.w700,
              color: appTextColor2,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Container(height: 0.7, color: const Color(0xFFEEC4B7)),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Padding(
          padding: EdgeInsets.only(top: 3.h, bottom: 10.h),
          child: AppText(
            text: value,
            size: 12,
            fontWeight: FontWeight.w400,
            color: appTextColor2,
          ),
        ),
        SizedBox(height: 5.h),
      ],
    );
  }

  Widget _badgeWidget() {
    final badgeImage = _profile?.currentBadge?.image ?? '';

    return SizedBox(
      width: 30.w,
      height: 30.w,
      child: badgeImage.isEmpty
          ? Image.asset('assets/images/badge.png', fit: BoxFit.contain)
          : Image.network(
              badgeImage,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/images/badge.png', fit: BoxFit.contain),
            ),
    );
  }

  Widget _profileImage() {
    final imageUrl = _profile?.profilePicture ?? '';

    if (imageUrl.isEmpty) {
      return Image.asset('assets/images/avatar2.png', fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset('assets/images/avatar2.png', fit: BoxFit.cover);
      },
    );
  }
}
