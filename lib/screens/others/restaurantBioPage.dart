import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/descriptionBox.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/screens/others/restaurantProfile.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';

class RestaurantBioEditPage extends StatefulWidget {
  final String establishmentName;
  final String establishmentType;
  final String location;
  final double lat;
  final double lng;
  final String description;
  final String availableDishes;
  final String phone;

  const RestaurantBioEditPage({
    super.key,
    required this.establishmentName,
    required this.establishmentType,
    required this.location,
    required this.lat,
    required this.lng,
    this.description = '',
    this.availableDishes = '',
    this.phone = '',
  });

  @override
  State<RestaurantBioEditPage> createState() => _RestaurantBioEditPageState();
}

class _RestaurantBioEditPageState extends State<RestaurantBioEditPage> {
  late TextEditingController _descriptionController;
  late TextEditingController _availableDishesController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  bool _isUpdating = false;
  final PartnerService _partnerService = PartnerService();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.description);
    _availableDishesController = TextEditingController(
      text: widget.availableDishes,
    );
    _addressController = TextEditingController(text: widget.location);

    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _availableDishesController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_descriptionController.text.isEmpty ||
        _availableDishesController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final response = await _partnerService.updateProfile(
        name: widget.establishmentName,
        type: widget.establishmentType,
        address: _addressController.text,
        phone: _phoneController.text,
        lat: widget.lat,
        lng: widget.lng,
        description: _descriptionController.text,
        availableDishes: _availableDishesController.text,
        restaurantType: widget.establishmentType,
      );

      if (!mounted) return;

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Profile updated successfully',
            ),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RestaurantProfile()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update profile'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  double _contentMaxWidth(Size size) {
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 460;
    if (Breakpoints.isTabletDevice(size) ||
        Breakpoints.isWideShortPhone(size)) {
      return 440;
    }
    return double.infinity;
  }

  EdgeInsets _contentPadding(Size size) {
    final width = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    return EdgeInsets.symmetric(
      horizontal: isWideShortPhone
          ? 24.0
          : isMobile
          ? 30.w
          : AppDimensions.padding(width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final isTabletLandscape =
        Breakpoints.isTabletDevice(size) && screenWidth > size.height;
    final bannerHeight = isWideShortPhone
        ? 120.0
        : isTabletLandscape
        ? 130.0
        : isMobile
        ? 150.h
        : 160.0;
    final headerPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(screenWidth);
    final backSize = isMobile ? 28.w : 26.0;
    final topGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 50.h
        : 44.0;
    final fieldGap = isMobile ? 20.h : 18.0;
    final bottomGap = isWideShortPhone
        ? 28.0
        : isMobile
        ? 50.h
        : 42.0;
    final fieldRadius = isMobile ? 20.r : 18.0;
    final fieldTextSize = isMobile ? 16.0 : 14.0;
    final buttonWidth = isMobile ? 160.w : 160.0;
    final buttonHeight = isMobile ? 50.h : 48.0;

    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/banner1.png',
                  height: bannerHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.all(headerPadding),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    // child: Icon(
                    //   Icons.arrow_back_ios_outlined,
                    //   size: 30.w,
                    //   color: Colors.white,
                    child: Image.asset(
                      backWhite,
                      width: backSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: topGap),
            Padding(
              padding: _contentPadding(size),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _contentMaxWidth(size)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DescriptionTextArea(
                      hintText:
                          "Describe your shop in a short and clear way so customers quickly know your food and theme.",
                      maxLength: 450,
                      iconImagePath: listMenuIcon,
                      iconColor: Color(0xFFD68541),
                      borderRadius: fieldRadius,
                      controller: _descriptionController,
                    ),
                    SizedBox(height: fieldGap),
                    AppTextFeild(
                      text: "Available dishes",
                      iconImagePath: dishesIcon,
                      iconColor: appTextColor,
                      controller: _availableDishesController,
                      fieldBorderRadius: fieldRadius,
                      size: fieldTextSize,
                    ),
                    SizedBox(height: fieldGap),
                    AppTextFeild(
                      text: "Address",
                      iconImagePath: addressPinIcon,
                      iconColor: appTextColor,
                      controller: _addressController,
                      fieldBorderRadius: fieldRadius,
                      size: fieldTextSize,
                    ),
                    SizedBox(height: fieldGap),
                    AppTextFeild(
                      text: "Contact number",
                      iconImagePath: landPhoneIcon,
                      iconColor: appTextColor,
                      controller: _phoneController,
                      fieldBorderRadius: fieldRadius,
                      size: fieldTextSize,
                    ),

                    SizedBox(height: bottomGap),
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: AppButton(
                        text: _isUpdating ? 'Updating...' : 'Update',
                        onPressed: _isUpdating ? () {} : _updateProfile,
                        size: 15,
                      ),
                    ),
                    SizedBox(height: bottomGap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
