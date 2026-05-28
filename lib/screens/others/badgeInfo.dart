import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';

class BadgeInfo extends StatelessWidget {
  const BadgeInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Padding(
                padding:  EdgeInsets.only(left: 30.w, top: 10.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  // child: Icon(
                  //   Icons.arrow_back_ios_new,
                  //   color: appTextColor3,
                  //   size: 28.w,
                  // ),
                  child:ColorFiltered(
                        colorFilter: ColorFilter.mode(appTextColor3, BlendMode.srcIn),
                        child: Image.asset(  
                          'assets/images/backarrow_icon.png',
                          width: 28.w,
                          fit: BoxFit.contain,
                         ),
                      ),
                ),
              ),
            ),
             SizedBox(height: 60.h),
            AppText(
              text: "Early Bird",
              size: 20,
              fontWeight: FontWeight.w600,
              isCentered: true,
              color: appToggleColor,
            ),
             SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/verificationgreen.png',
                  width: 150.w,
                  height: 150.h,
                  fit: BoxFit.contain,
                ),
              ],
            ),
             SizedBox(height: 30.h),
            AppText(
              text: "Your next badge is on its way!",
              size: 10,
              fontWeight: FontWeight.w400,
              isCentered: true,
              color: Colors.black,
            ),
             SizedBox(height: 20.h),
            Padding(
              padding: const EdgeInsets.only(left: 50, right: 50),
              child: gradientProgressBar(70),
            ),
             SizedBox(height: 20.h),
            AppText(
              text: "87/100",
              size: 15,
              fontWeight: FontWeight.w500,
              isCentered: true,
              color: Colors.black,
            ),
             SizedBox(height: 60.h),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 50.w),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(
                  25,
                  (index) => Image.asset(
                    'assets/images/verificationgrey.png',
                    width: 50.w,
                    height: 50.h,
                    fit: BoxFit.contain,
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gradientProgressBar(double percentage) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double clampedPercentage = percentage.clamp(0, 100);

        return Stack(
          children: [
            // Background
            Container(
              height: 10.h,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Foreground
            ClipRRect(
              borderRadius: BorderRadius.circular(5.r),
              child: Container(
                height: 10,
                width: constraints.maxWidth * (clampedPercentage / 100),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.pink],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}
