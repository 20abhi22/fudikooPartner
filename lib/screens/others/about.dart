import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: EdgeInsets.only(left: 30.w, top: 10.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      appTextColor3,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/backarrow_icon.png',
                      width: 28.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
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
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 50.h),
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 4,
                  radius: Radius.circular(10.r),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Replaces Text.rich — bold lead + normal continuation
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15.sp,
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
                        SizedBox(height: 12.h),
                        AppText(
                          text:
                              'With Fudikoo Partner App, you can also manage banquet requests from customers. When a customer sends their party or event requirements, you can directly send a customized quotation to them through the app. This helps you fill your banquet slots faster and increases your revenue by offering competitive packages.',
                          size: 15,
                          fontWeight: FontWeight.normal,
                          color: appTextColor2,
                          lineSpacing: 1.6,
                          softWrap: true,
                        ),
                        SizedBox(height: 12.h),
                        AppText(
                          text:
                              'The app also includes an easy-to-manage takeaway option. You can accept and manage takeaway orders without any hassle, making it simple for customers to place orders and pick them up at their convenience.',
                          size: 15,
                          fontWeight: FontWeight.normal,
                          color: appTextColor2,
                          lineSpacing: 1.6,
                          softWrap: true,
                        ),
                        SizedBox(height: 12.h),
                        AppText(
                          text:
                              'As you actively use the app and provide great service, your restaurant can earn different badges that highlight your achievements. These badges increase your visibility and build trust among customers looking for the best dining experiences.',
                          size: 15,
                          fontWeight: FontWeight.normal,
                          color: appTextColor2,
                          lineSpacing: 1.6,
                          softWrap: true,
                        ),
                        SizedBox(height: 12.h),
                        AppText(
                          text:
                              'Fudikoo Partner App is designed to create more opportunities for your restaurant, helping you to maximize your sales and improve customer relationships. Join Fudikoo today and make every opportunity count!',
                          size: 15,
                          fontWeight: FontWeight.normal,
                          color: appTextColor2,
                          lineSpacing: 1.6,
                          softWrap: true,
                        ),
                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 50.h),
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
