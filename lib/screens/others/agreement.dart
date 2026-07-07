import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';

class AgreementPage extends StatelessWidget {
  const AgreementPage({super.key});

  bool _isWideShortPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isWideShortPhone(size);
  }

  double _contentMaxWidth(Size size, bool isWideShortPhone) {
    if (Breakpoints.isDesktop(size.width)) return 760;
    if (Breakpoints.isTabletDevice(size) || isWideShortPhone) return 680;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final pagePadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final bodyPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 20.w
        : AppDimensions.padding(width);
    final backTopPadding = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 28.0;
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 28.w
        : 28.0;
    final titleTopGap = isWideShortPhone
        ? 22.0
        : isMobile
        ? 30.h
        : 32.0;
    final bodyTopGap = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.h
        : 24.0;
    final paragraphGap = isWideShortPhone
        ? 10.0
        : isMobile
        ? 12.h
        : 14.0;
    final bottomGap = isWideShortPhone
        ? 20.0
        : isMobile
        ? 40.h
        : 32.0;
    final scrollRadius = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.r
        : 10.0;
    final bodyTextSize = isWideShortPhone
        ? 14.0
        : isMobile
        ? 15.sp
        : 15.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: EdgeInsets.only(
          top: (isTablet || isWideShortPhone) ? 12.0 : 0.0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Scrollbar(
              thumbVisibility: true,
              radius: Radius.circular(scrollRadius),
              thickness: 3,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: pagePadding,
                            right: pagePadding,
                            top: backTopPadding,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                appTextColor3,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/backarrow_icon.png',
                                width: backIconSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: titleTopGap),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: pagePadding),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: _contentMaxWidth(
                                size,
                                isWideShortPhone,
                              ),
                            ),
                            child: AppText(
                              text: 'Agreement',
                              size: isMobile ? 18.sp : 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              isCentered: true,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: bodyTopGap),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: _contentMaxWidth(size, isWideShortPhone),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: bodyPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  softWrap: true,
                                  size: bodyTextSize,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                  text:
                                      'By registering on the Fudikoo Vendor App, you agree to enter into a partnership with Fudikoo under the terms and conditions outlined in this Agreement.',
                                ),
                                SizedBox(height: paragraphGap),
                                AppText(
                                  softWrap: true,
                                  size: bodyTextSize,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                  text:
                                      'Fudikoo provides a platform that allows restaurants and food vendors to publish special offers, manage banquet bookings, accept takeaway orders, and connect with customers efficiently. As a vendor, you are responsible for accurately publishing offers, fulfilling customer orders, responding to banquet inquiries, and maintaining high-quality service standards. You agree to keep your business legal, operational licenses, and food safety certifications updated at all times.',
                                ),
                                SizedBox(height: paragraphGap),
                                AppText(
                                  softWrap: true,
                                  size: bodyTextSize,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                  text:
                                      'Fudikoo will offer you access to powerful tools to promote your restaurant, manage orders, and communicate with customers. Based on your activity and performance, you will be eligible to earn badges that highlight your strengths, such as Early Bird, Restoday, Rainbow, and more. Upon achieving certain badges, you may receive special rewards from Fudikoo, including appreciation certificates, city trips, free promotions, and other exciting benefits. Fudikoo reserves the right to verify your achievements before distributing any rewards.',
                                ),
                                SizedBox(height: paragraphGap),
                                AppText(
                                  softWrap: true,
                                  size: bodyTextSize,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                  text:
                                      'Vendors acknowledge that Fudikoo may charge service fees or commissions for completed orders or banquet deals, and vendors are responsible for providing accurate settlement details. Any concerns regarding payments must be reported within seven (7) days. Vendors who achieve high standards may also receive additional visibility through free or paid promotions within the app.',
                                ),
                                SizedBox(height: bottomGap),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
