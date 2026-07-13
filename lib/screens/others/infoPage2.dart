import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/descriptionBox.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/infoPage3.dart';
import 'package:fudiko/utils/constants.dart';

class InfoPage2 extends StatefulWidget {
  final String establishmentName;
  final String establishmentType;
  final String locationId;
  final File? profileImage;
   final String? authToken;
  const InfoPage2({
    super.key,
    required this.establishmentName,
    required this.establishmentType,
    required this.locationId,
    this.profileImage,
    this.authToken,
  });

  @override
  State<InfoPage2> createState() => _InfoPage2State();
}

class _InfoPage2State extends State<InfoPage2> {
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dishesController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController contactController = TextEditingController();

  double _contentMaxWidth(double width) {
    if (Breakpoints.isDesktop(width)) return 460;
    if (Breakpoints.isTablet(width)) return 440;
    return double.infinity;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    dishesController.dispose();
    addressController.dispose();
    contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isMobile = Breakpoints.isMobileDevice(size);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final shouldCenterContent = isWideShortPhone || isTablet;
    final horizontalPadding = isWideShortPhone
        ? 28.0
        : isTablet
        ? 64.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final topPadding = isWideShortPhone
        ? 18.0
        : isTablet
        ? 32.0
        : isMobile
        ? 60.h
        : 48.0;
    final bottomPadding = isWideShortPhone
        ? 18.0
        : isTablet
        ? 32.0
        : isMobile
        ? 40.h
        : AppDimensions.margin(width);
    final contentMaxWidth = isWideShortPhone
        ? 380.0
        : isTablet
        ? 600.0
        : _contentMaxWidth(width);
    final fieldGap = isWideShortPhone
        ? 10.0
        : isTablet
        ? 20.0
        : isMobile
        ? 20.h
        : 20.0;
    final buttonGap = isWideShortPhone
        ? 32.0
        : isTablet
        ? 40.0
        : isMobile
        ? 150.h
        : 80.0;
    final fieldHeight = isWideShortPhone
        ? 46.0
        : isTablet
        ? 64.0
        : null;
    final buttonHeight = isWideShortPhone
        ? 46.0
        : isTablet
        ? 64.0
        : null;
    final fieldTextSize = isWideShortPhone
        ? 13.0
        : isTablet
        ? 17.0
        : isMobile
        ? 16.0
        : 14.0;
    final buttonTextSize = isWideShortPhone
        ? 13.0
        : isTablet
        ? 17.0
        : null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: shouldCenterContent
                    ? (constraints.maxHeight - (topPadding + bottomPadding))
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DescriptionTextArea(
                        hintText:
                            "Describe your shop in a short and clear way so customers quickly know your food and theme.",

                        maxLength: 450,
                        maxLines: isWideShortPhone
                            ? 3
                            : isTablet
                            ? 4
                            : null,
                        borderRadius: isWideShortPhone ? 14.0 : null,
                        // icon: Icons.list,
                        iconImagePath: listMenuIcon,
                        iconColor: appTextColor,

                        onChanged: (value) {
                          setState(() {
                            descriptionController.text = value;
                          });
                        },
                      ),
                      SizedBox(height: fieldGap),
                      AppTextFeild(
                        text: "Available dishes",
                        // icon: Icons.fastfood,
                        iconImagePath: dishesIcon,
                        iconColor: appTextColor,
                        controller: dishesController,
                        size: fieldTextSize,
                        height: fieldHeight,
                      ),
                      SizedBox(height: fieldGap),
                      AppTextFeild(
                        text: "Address",
                        // icon: Icons.home,
                        iconImagePath: addressPinIcon,
                        iconColor: appTextColor,
                        controller: addressController,
                        size: fieldTextSize,
                        height: fieldHeight,
                      ),
                      SizedBox(height: fieldGap),
                      AppTextFeild(
                        text: "Contact number",
                        // icon: Icons.phone,
                        iconImagePath: landPhoneIcon,
                        iconColor: appTextColor,
                        controller: contactController,
                        size: fieldTextSize,
                        height: fieldHeight,
                      ),

                      SizedBox(height: buttonGap),
                      AppButton(
                        text: 'Continue',
                        onPressed: () {
                          if (descriptionController.text.isNotEmpty &&
                              dishesController.text.isNotEmpty &&
                              addressController.text.isNotEmpty &&
                              contactController.text.isNotEmpty) {
                            slideRightWidget(
                              newPage: InfoPage3(
                                establishmentName: widget.establishmentName,
                                establishmentType: widget.establishmentType,
                                locationId: widget.locationId,
                                description: descriptionController.text,
                                dishes: dishesController.text,
                                address: addressController.text,
                                contact: contactController.text,
                                profileImage: widget.profileImage,
                                authToken: widget.authToken,
                              ),
                              context: context,
                            );

                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(builder: (context) => InfoPage3(
                            //       establishmentName: widget.establishmentName,
                            //       establishmentType: widget.establishmentType,
                            //       locationId: widget.locationId,
                            //       description: descriptionController.text,
                            //       dishes: dishesController.text,
                            //       address: addressController.text,
                            //       contact: contactController.text,
                            //       profileImage: widget.profileImage,
                            //     )),
                            //   );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all the fields'),
                              ),
                            );
                          }
                        },
                        height: buttonHeight,
                        size: buttonTextSize,
                      ),
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
}
