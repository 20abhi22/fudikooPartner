import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  double _contentMaxWidth(Size size, bool isWideShortPhone) {
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 760;
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
    final titleGap = isWideShortPhone
        ? 28.0
        : isMobile
        ? 40.h
        : 42.0;
    final bodyVerticalPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 50.h
        : 40.0;
    final paragraphGap = isWideShortPhone
        ? 10.0
        : isMobile
        ? 12.h
        : 14.0;
    final bottomTextPadding = isWideShortPhone
        ? 20.0
        : isMobile
        ? 50.h
        : 32.0;
    final scrollbarRadius = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.r
        : 10.0;
    final contentBottomGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 50.h
        : 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: EdgeInsets.only(
          top: (isTablet || isWideShortPhone) ? 12.0 : 0.0,
        ),
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
            SizedBox(height: titleGap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _contentMaxWidth(size, isWideShortPhone),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      text: 'About the App',
                      size: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _contentMaxWidth(size, isWideShortPhone),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: bodyPadding,
                      vertical: bodyVerticalPadding,
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      thickness: 4,
                      radius: Radius.circular(scrollbarRadius),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Replaces Text.rich — bold lead + normal continuation
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: isMobile ? 15.sp : 15.0,
                                  height: 1.6,
                                  color: appTextColor,
                                ),
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: AppText(
                                      text: 'Fudikoo Partner App ',
                                      size: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      lineSpacing: 1.6,
                                      softWrap: true,
                                    ),
                                  ),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: AppText(
                                      text:
                                          'is the ultimate app for restaurant owners who want to grow their business smartly and efficiently. It helps you publish special offers during specific times, dates, or when customer flow is low. You can easily attract more customers by providing real-time offers and exclusive deals through the app.',
                                      size: 15,
                                      fontWeight: FontWeight.normal,
                                      color: appTextColor2,
                                      lineSpacing: 1.6,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: paragraphGap),
                            AppText(
                              text:
                                  'With Fudikoo Partner App, you can also manage banquet requests from customers. When a customer sends their party or event requirements, you can directly send a customized quotation to them through the app. This helps you fill your banquet slots faster and increases your revenue by offering competitive packages.',
                              size: 15,
                              fontWeight: FontWeight.normal,
                              color: appTextColor2,
                              lineSpacing: 1.6,
                              softWrap: true,
                            ),
                            SizedBox(height: paragraphGap),
                            AppText(
                              text:
                                  'The app also includes an easy-to-manage takeaway option. You can accept and manage takeaway orders without any hassle, making it simple for customers to place orders and pick them up at their convenience.',
                              size: 15,
                              fontWeight: FontWeight.normal,
                              color: appTextColor2,
                              lineSpacing: 1.6,
                              softWrap: true,
                            ),
                            SizedBox(height: paragraphGap),
                            AppText(
                              text:
                                  'As you actively use the app and provide great service, your restaurant can earn different badges that highlight your achievements. These badges increase your visibility and build trust among customers looking for the best dining experiences.',
                              size: 15,
                              fontWeight: FontWeight.normal,
                              color: appTextColor2,
                              lineSpacing: 1.6,
                              softWrap: true,
                            ),
                            SizedBox(height: paragraphGap),
                            AppText(
                              text:
                                  'Fudikoo Partner App is designed to create more opportunities for your restaurant, helping you to maximize your sales and improve customer relationships. Join Fudikoo today and make every opportunity count!',
                              size: 15,
                              fontWeight: FontWeight.normal,
                              color: appTextColor2,
                              lineSpacing: 1.6,
                              softWrap: true,
                            ),
                            SizedBox(height: contentBottomGap),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: bottomTextPadding),
              child: AppText(
                text: 'Version 2504.01',
                size: 13,
                fontWeight: FontWeight.normal,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
