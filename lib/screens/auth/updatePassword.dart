import 'package:flutter/material.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/utils/constants.dart';

class UpdatePassword extends StatelessWidget {
  const UpdatePassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 30, right: 30),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_back_ios_outlined,
                    size: 30,
                    color: appTextColor3,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                AppText(
                  text: "Set your new password",
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                ),

                SizedBox(height: 40),
                AppTextFeild(text: "Old Password", icon: Icons.lock),
                SizedBox(height: 20),
                AppTextFeild(text: "New Password", icon: Icons.lock),
                SizedBox(height: 20),
                AppTextFeild(text: "Confirm Password", icon: Icons.lock),
                SizedBox(height: 60),
                AppButton(text: 'Update', onPressed: () {}),
                SizedBox(height: 20),
                AppText(text: "Forgot Password?", size: 14, fontWeight: FontWeight.w400)
              ],
            ),
          ],
        ),
      ),
    );
  }
}
