import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/registration/complete-registration.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/agreement.dart';
import 'package:fudiko/screens/others/infoPage4.dart';
import 'package:fudiko/services/map-service.dart';
import 'package:fudiko/services/registration-service.dart';
import 'package:fudiko/utils/constants.dart';

class InfoPage3 extends StatefulWidget {
  final String establishmentName;
  final String establishmentType;
  final String locationId;
  final String description;
  final String dishes;
  final String address;
  final String contact;
  final File? profileImage;

  const InfoPage3({
    super.key,
    required this.establishmentName,
    required this.establishmentType,
    required this.locationId,
    required this.description,
    required this.dishes,
    required this.address,
    required this.contact,
    this.profileImage,
  });

  @override
  State<InfoPage3> createState() => _InfoPage3State();
}

class _InfoPage3State extends State<InfoPage3> {
  bool banquetToggle = false;
  TextEditingController banquetServiceController = TextEditingController();
  TextEditingController cateringServiceController = TextEditingController();

  double _screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

  double _contentMaxWidth(double width) {
    if (Breakpoints.isDesktop(width)) return 620;
    if (Breakpoints.isTablet(width)) return 560;
    return double.infinity;
  }

  EdgeInsetsGeometry _pagePadding(Size size) {
    final width = size.width;
    final isMobile = Breakpoints.isMobileDevice(size);
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 20.w : AppDimensions.padding(width),
    );
  }

  @override
  void initState() {
    banquetServiceController.text = "0";
    takeawayController.text = "1";
    cateringServiceController.text = "0";
    deliveryServiceController.text = "1";
    distanceController.text = selectedDistance?.split(' ')[2] ?? '';
    typeOfRestaurantController.text = selectedRestaurantType;
    super.initState();
  }

  @override
  void dispose() {
    banquetServiceController.dispose();
    takeawayController.dispose();
    cateringServiceController.dispose();
    deliveryServiceController.dispose();
    distanceController.dispose();
    typeOfRestaurantController.dispose();
    super.dispose();
  }

  MapService mapService = MapService();
  RegistrationAuthService registrationAuthService = RegistrationAuthService();
  final List<String> distances = [
    'Up to 1 km',
    'Up to 2 km',
    'Up to 3 km',
    'Up to 4 km',
    'Up to 5 km',
    'Up to 6 km',
    'Up to 7 km',
    'Up to 8 km',
    'Up to 9 km',
    'Up to 10 km',
    'More than 10 km',
  ];
  String selectedRestaurantType = 'Pure Vegetarian';
  String? selectedDistance = 'Up to 1 km';
  TextEditingController takeawayController = TextEditingController();
  TextEditingController deliveryServiceController = TextEditingController();
  TextEditingController distanceController = TextEditingController();
  TextEditingController typeOfRestaurantController = TextEditingController();

  Future<void> complteRegistration() async {
    if (takeawayController.text.isEmpty ||
        deliveryServiceController.text.isEmpty ||
        distanceController.text.isEmpty ||
        typeOfRestaurantController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    } else {
      final parts = widget.locationId.split(',');
      final lat = parts[0];
      final lng = parts[1];

      CompleteRegistrationModel details = CompleteRegistrationModel(
        name: widget.establishmentName,
        type: widget.establishmentType,
        address: widget.address,
        phone: widget.contact,
        lat: lat,
        lng: lng,
        description: widget.description,
        availableDishes: widget.dishes,
        banquetService: banquetServiceController.text,
        takeawayService: takeawayController.text,
        cateringService: cateringServiceController.text,
        deliveryService: deliveryServiceController.text,
        deliveryServiceArea: distanceController.text,
        restaurantTypw: typeOfRestaurantController.text,
        image: widget.profileImage,
      );
      CompleteRegistrationModelResponse response = await registrationAuthService
          .completeRegistration(details);
      if (response.status) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        slideRightWidget(newPage: InfoPage4(), context: context);
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => InfoPage4()),
        // );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isMobile = Breakpoints.isMobileDevice(size);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final shouldCenterContent = isWideShortPhone || isTablet;
    final contentMaxWidth = isWideShortPhone
        ? 380.0
        : isTablet
        ? 600.0
        : _contentMaxWidth(width);
    final horizontalPadding = isWideShortPhone
        ? 28.0
        : isTablet
        ? 64.0
        : 0.0;
    final verticalPadding = isWideShortPhone
        ? 18.0
        : isTablet
        ? 32.0
        : 0.0;
    final topGap = isWideShortPhone
        ? 12.0
        : isMobile
        ? 20.h
        : 24.0;
    final dividerHeight = isWideShortPhone
        ? 14.0
        : isMobile
        ? 20.0
        : 18.0;
    final rowVerticalPadding = isWideShortPhone
        ? 2.0
        : isMobile
        ? 5.h
        : 12.0;
    final sectionGap = isWideShortPhone
        ? 10.0
        : isTablet
        ? 20.0
        : isMobile
        ? 16.h
        : 18.0;
    final restaurantHorizontalPadding = isWideShortPhone
        ? 28.0
        : isMobile
        ? 60.w
        : AppDimensions.padding(width);
    final termsHorizontalPadding = isWideShortPhone
        ? 26.0
        : isMobile
        ? 50.w
        : AppDimensions.padding(width);
    final smallGap = isWideShortPhone
        ? 3.0
        : isMobile
        ? 5.h
        : 6.0;
    final defaultGap = isWideShortPhone
        ? 12.0
        : isMobile
        ? 20.h
        : 22.0;
    final buttonHeight = isWideShortPhone
        ? 46.0
        : isTablet
        ? 64.0
        : null;
    final buttonTextSize = isWideShortPhone
        ? 13.0
        : isTablet
        ? 17.0
        : null;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: shouldCenterContent
                    ? (constraints.maxHeight - (verticalPadding * 2))
                          .clamp(0.0, double.infinity)
                          .toDouble()
                    : 0,
              ),
              child: Align(
                alignment: shouldCenterContent
                    ? Alignment.center
                    : Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    children: [
                      SizedBox(height: topGap),
                      Divider(
                        color: appTextColor,
                        thickness: 1,
                        height: dividerHeight,
                      ),
                      Padding(
                        padding: _pagePadding(size).add(
                          EdgeInsets.symmetric(vertical: rowVerticalPadding),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                text: "Banquet",
                                size: 14,
                                fontWeight: FontWeight.w500,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: AppDimensions.gap(width)),
                            AppSwitch(
                              initialValue: false,
                              onToggle: (val) {
                                setState(() {
                                  banquetToggle = val;
                                  banquetServiceController.text = val
                                      ? "1"
                                      : "0";
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: appTextColor,
                        thickness: 1,
                        height: dividerHeight,
                      ),
                      Padding(
                        padding: _pagePadding(size).add(
                          EdgeInsets.symmetric(vertical: rowVerticalPadding),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                text: "Catering",
                                size: 14,
                                fontWeight: FontWeight.w500,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: AppDimensions.gap(width)),
                            AppSwitch(
                              initialValue: false,
                              onToggle: (val) {
                                setState(() {
                                  cateringServiceController.text = val
                                      ? "1"
                                      : "0";
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: appTextColor,
                        thickness: 1,
                        height: dividerHeight,
                      ),
                      Padding(
                        padding: _pagePadding(size).add(
                          EdgeInsets.symmetric(vertical: rowVerticalPadding),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                text: "Takeaway service",
                                size: 14,
                                fontWeight: FontWeight.w500,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: AppDimensions.gap(width)),
                            AppSwitch(
                              initialValue: true,
                              onToggle: (val) {
                                setState(() {
                                  takeawayController.text = val == true
                                      ? "1"
                                      : "0";
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: appTextColor,
                        thickness: 1,
                        height: dividerHeight,
                      ),
                      Padding(
                        padding: _pagePadding(size).add(
                          EdgeInsets.symmetric(vertical: rowVerticalPadding),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                text: "Delivery service",
                                size: 14,
                                fontWeight: FontWeight.w500,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: AppDimensions.gap(width)),
                            AppSwitch(
                              initialValue: true,
                              onToggle: (val) {
                                setState(() {
                                  deliveryServiceController.text = val == true
                                      ? "1"
                                      : "0";
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      Padding(
                        padding: _pagePadding(size),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: contentMaxWidth,
                            ),
                            child: _buildDistanceGrid(),
                          ),
                        ),
                      ),
                      Divider(
                        color: appTextColor,
                        thickness: 1,
                        height: dividerHeight,
                      ),
                      Padding(
                        padding: _pagePadding(size).add(
                          EdgeInsets.symmetric(vertical: rowVerticalPadding),
                        ),
                        child: Row(
                          children: [
                            AppText(
                              text: "Type of restaurant ",
                              size: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
            
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: restaurantHorizontalPadding,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        text: "Pure Vegetarian",
                                        size: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Checkbox(
                                      value:
                                          selectedRestaurantType ==
                                          'Pure Vegetarian',
                                      onChanged: (bool? value) {
                                        setState(() {
                                          selectedRestaurantType =
                                              'Pure Vegetarian';
                                          typeOfRestaurantController.text =
                                              selectedRestaurantType;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: const BorderSide(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                      checkColor: Colors.white,
                                      activeColor: appToggleColor,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        text: "Non Vegetarian",
                                        size: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Checkbox(
                                      value:
                                          selectedRestaurantType ==
                                          'Non Vegetarian',
                                      onChanged: (bool? value) {
                                        setState(() {
                                          selectedRestaurantType =
                                              'Non Vegetarian';
                                          typeOfRestaurantController.text =
                                              selectedRestaurantType;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: const BorderSide(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                      checkColor: Colors.white,
                                      activeColor: appToggleColor,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        text: "Both Veg & Non-Veg",
                                        size: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Checkbox(
                                      value:
                                          selectedRestaurantType ==
                                          'Both Veg & Non-Veg',
                                      onChanged: (bool? value) {
                                        setState(() {
                                          selectedRestaurantType =
                                              'Both Veg & Non-Veg';
                                          typeOfRestaurantController.text =
                                              selectedRestaurantType;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: const BorderSide(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                      checkColor: Colors.white,
                                      activeColor: appToggleColor,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
            
                      Divider(
                        color: appTextColor,
                        thickness: 1,
                        height: dividerHeight,
                      ),
                      SizedBox(height: defaultGap),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: termsHorizontalPadding,
                            ),
                            child: Column(
                              children: [
                                AppText(
                                  text:
                                      "By proceeding, you confirm that you have read,",
                                  size: 11,
                                  fontWeight: FontWeight.w400,
                                  color: appLinkColor,
                                  isCentered: true,
                                ),
                                AppText(
                                  text:
                                      "understood, and agreed to our Terms and Conditions, Privacy Policy, and Vendor Agreement.",
                                  size: 11,
                                  fontWeight: FontWeight.w400,
                                  color: appLinkColor,
                                  isCentered: true,
                                ),
                                SizedBox(height: smallGap),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AgreementPage(),
                                      ),
                                    );
                                  },
                                  child: AppText(
                                    text: "View Agreement",
                                    size: 11,
                                    fontWeight: FontWeight.bold,
                                    color: appLinkColor,
                                    isCentered: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: defaultGap),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: Padding(
                            padding: _pagePadding(size),
                            child: AppButton(
                              text: 'Proceed',
                              onPressed: () {
                                complteRegistration();
                              },
                              height: buttonHeight,
                              size: buttonTextSize,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: defaultGap),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceGrid() {
    final width = _screenWidth(context);
    final isMobile = Breakpoints.isMobileDevice(MediaQuery.sizeOf(context));
    final left = distances.sublist(0, 5);
    final right = distances.sublist(5, 10);
    final last = distances[10];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: left.map(_buildCheckboxRow).toList(),
              ),
            ),
            SizedBox(width: isMobile ? 0 : AppDimensions.gap(width)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: right.map(_buildCheckboxRow).toList(),
              ),
            ),
          ],
        ),
        _buildCheckboxRow(last),
      ],
    );
  }

  Widget _buildCheckboxRow(String text) {
    final isMobile = Breakpoints.isMobileDevice(MediaQuery.sizeOf(context));
    final verticalPadding = isMobile ? 4.r : 5.0;
    final textSize = isMobile ? 14.sp : 14.0;
    final checkboxGap = isMobile ? 15.w : 12.0;
    final boxSize = isMobile ? 20.w : 20.0;
    final boxRadius = isMobile ? 6.r : 6.0;
    final checkRadius = isMobile ? 4.r : 4.0;
    final isChecked = selectedDistance == text;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: textSize, color: appTextColor2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: checkboxGap),
          Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: isChecked ? appToggleColor : Colors.transparent,
              borderRadius: BorderRadius.circular(boxRadius),
              border: Border.all(color: appToggleColor, width: 2),
            ),
            child: Checkbox(
              value: isChecked,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedDistance = text;
                    distanceController.text = text.split(' ')[2];
                  } else {
                    selectedDistance = null;
                    distanceController.text = '';
                  }
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(checkRadius),
              ),
              side: BorderSide.none,
              checkColor: Colors.white,
              activeColor: appToggleColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
