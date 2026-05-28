
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/donutPercentage.dart';
import 'package:fudiko/models/profile/customer-profile-model.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  CustomerProfileModel? _profile;
  final CustomerProfileService _service = CustomerProfileService();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _service.getProfile();
      setState(() => _profile = profile);
    } catch (e) {
      print('Error fetching customer profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/banner1.png',
                  height: 150.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            SizedBox(height: 0),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 150.w,
                    height: 150.w,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar2.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8.w,
                    right: 8.w,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.r),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Image.asset(
                          'assets/images/badge.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            AppText(
              text: _profile?.name ?? "Loading...",
              size: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              isCentered: true,
            ),
            SizedBox(height: 10.h),
            Center(
              child: SizedBox(
                width: 250.w,
                height: 250.h,
                child: DonutChart(
                  percentage: (_profile?.rating ?? 0) / 100,
                ),
              ),
            ),
            AppText(
              text: "Reliability Rating",
              size: 15,
              fontWeight: FontWeight.w600,
              color: appTextColor3,
              isCentered: true,
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: 20.h,
              ),
              child: Container(
                padding: EdgeInsets.all(30.w),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.r),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Place", _profile?.place ?? "-"),
                    _infoRow("Email", _profile?.email ?? "-"),
                    _infoRow("Contact Info", _profile?.contactInfo ?? "-"),
                    // _infoRow("Badge", _profile?.badge ?? "-"),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            AppText(text: label, size: 12, fontWeight: FontWeight.w600, color: appTextColor2),
            SizedBox(width: 15.w),
            Expanded(child: Container(height: 0.5, color: appTextColor3)),
          ],
        ),
        SizedBox(height: 5.h),
        Padding(
          padding: EdgeInsets.only(top: 5.h, right: 10.w, left: 30.w, bottom: 5.h),
          child: AppText(text: value, size: 12, fontWeight: FontWeight.w400, color: appTextColor2),
        ),
        SizedBox(height: 5.h),
      ],
    );
  }
}























// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudiko/components/apptext.dart';
// import 'package:fudiko/components/donutPercentage.dart';
// import 'package:fudiko/utils/constants.dart';

// class Profile extends StatelessWidget {
//   const Profile({super.key});

//   @override
//   Widget build(BuildContext context) {

//     double screenWidth = MediaQuery.of(context).size.width.w;

//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Image.asset(
//                   'assets/images/banner1.png',
//                   height: 150.h,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               ],
//             ),
//             SizedBox(height: 0),
//             Center(
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   SizedBox(
//                     width: 150.w,
//                     height: 150.w,
//                     child: ClipOval(
//                       child: Image.asset(
//                         'assets/images/avatar2.png',
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 8.w,
//                     right: 8.w,
//                     child: Container(
//                       width: 40.w,
//                       height: 40.w,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.white,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 4.r,
//                             offset: Offset(0, 2.r),
//                           ),
//                         ],
//                       ),
//                       child: Padding(
//                         padding: EdgeInsets.all(4.w),
//                         child: Image.asset(
//                           'assets/images/badge.png',
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20.h),
//             AppText(text: "John Abraham", size: 20, fontWeight: FontWeight.w600, color: Colors.black, isCentered: true,),
//             SizedBox(height: 10.h,),
//             Center(
//               child: SizedBox(
//                 width: 250.w,
//                 height: 250.h,
//                 child: DonutChart(percentage: 72/100),
//               ),
//             ),
//             AppText(text: "Reliability Rating", size: 15, fontWeight: FontWeight.w600, color: appTextColor3, isCentered: true,),
//             Padding(
//               padding:  EdgeInsets.only(
//                 left: 20.w,
//                 right: 20.w,
//                 top: 20.h,
//                 bottom: 20.h,
//               ),
//               child: Container(
//                 padding:  EdgeInsets.all(30.w),
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20.r),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       blurRadius: 10.r,
//                       offset:  Offset(0, 4.r),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(height: 10.h,),
//                     Row(
//                       children: [
//                         AppText(text: "Place", size: 12, fontWeight: FontWeight.w600, color: appTextColor2,),
//                         SizedBox(width:15.w,),
//                         Expanded(
//                           child: Container(height: 0.5, color: appTextColor3),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 5.h),

//                     Padding(
//                       padding:  EdgeInsets.only(
//                         top: 5.h,
//                         right: 10.w,
//                         left: 30.w,
//                         bottom: 5.h,
//                       ),
//                       child: AppText(
//                         text: "Tulskaya",
//                         size: 12,
//                         fontWeight: FontWeight.w400,
//                         color: appTextColor2,
//                       ),
//                     ),
//                     SizedBox(height: 5.h  ),

//                     Row(
//                       children: [
//                         AppText(
//                           text: "Email",
//                           size: 12,
//                           fontWeight: FontWeight.w600,
//                           color: appTextColor2,
//                         ),
//                         SizedBox(width: 15.w),
//                         Expanded(
//                           child: Container(height: 0.5, color: appTextColor3),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 5.h),

//                     Padding(
//                       padding:  EdgeInsets.only(
//                         top: 5.h,
//                         right: 10.w,
//                         left: 30.w,
//                         bottom: 5.h,
//                       ),
//                       child: AppText(
//                         text: "abcdefg@gmai.com",
//                         size: 12,
//                         fontWeight: FontWeight.w400,
//                         color: appTextColor2,
//                       ),
//                     ),
//                     SizedBox(height: 5.h),

//                     Row(
//                       children: [
//                         AppText(
//                           text: "Contact Info",
//                           size: 12,
//                           fontWeight: FontWeight.w600,
//                           color: appTextColor2,
//                         ),
//                         SizedBox(width: 15.w),
//                         Expanded(
//                           child: Container(height: 0.5, color: appTextColor3),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 5.h),

//                     Padding(
//                       padding:  EdgeInsets.only(
//                         top: 5.h,
//                         right: 10.w,
//                         left: 30.w,
//                         bottom: 5.h,
//                       ),
//                       child: AppText(
//                         text:
//                             "+7 9856412878    +7 895624158",
//                         size: 12,
//                         fontWeight: FontWeight.w400,
//                         color: appTextColor2,
//                       ),
//                     ),
//                     SizedBox(height: 5.h),

//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
