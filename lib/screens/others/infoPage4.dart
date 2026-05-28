
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/utils/constants.dart';

class InfoPage4 extends StatefulWidget {
  const InfoPage4({super.key});

  @override
  State<InfoPage4> createState() => _InfoPage4State();
}

class _InfoPage4State extends State<InfoPage4> {

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 8), () {
      pushWidgetWhileRemove(newPage: MainNavPage(), context: context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const MainNavPage()),
      // );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/checked.png',
              width: 100.w,
              height: 100.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20),
            AppText(text: "You're all set!", size: 25, fontWeight: FontWeight.bold),
            SizedBox(height: 10),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 40.w),
              child: AppText(text: "Your details are under review.\nOnce approved, you’ll be able to manage \nyour orders, reach more food lovers.", size: 15, fontWeight: FontWeight.w400,color: appTextColor2,isCentered: true,lineSpacing: 1.2,),
            ),
          ],
        ),
      ),
    );
  }
}