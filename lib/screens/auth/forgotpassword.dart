import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/models/forgotpassword/finduser-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/changepassword.dart';
import 'package:fudiko/services/fogotpassword-service.dart';
import 'package:fudiko/utils/constants.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {

  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  bool isLoading = false;
  ForgotPasswordService forgotPasswordService = ForgotPasswordService();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> forgotPasswordFindUser() async {
    final username = _username.text.trim();
    final email = _email.text.trim();

    if (username.isEmpty || email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username and email")),
      );
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final FindUserModel user = FindUserModel(username, email);
    final FindUserResponseModel response = await forgotPasswordService.findUser(user);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (response.status && response.token != null && response.token!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User found!")),
      );
      slideRightWidget(newPage: ChangePassword(token: response.token), context: context);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ChangePassword(token: response.token),
      //   ),
      // );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? "No user found")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 30.w, right: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            AppText(
              text: "Enter your username and",
              size: 15,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
            ),
            SizedBox(height: 8.h,),
            AppText(
              text: "registered email ID",
              size: 15,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
            ),
            SizedBox(height: 40.h),
            AppTextFeild(text: "Username", icon: Icons.person,controller: _username,),
            SizedBox(height: 20.h),
            AppTextFeild(text: "Email", icon: Icons.mail, controller: _email,),
            SizedBox(height: 60.h),
            AppButton(
              text: isLoading ? 'Please wait...' : 'Continue',
              onPressed: () {
                if (!isLoading) {
                  forgotPasswordFindUser();
                }
              },
            ),
            SizedBox(height: 20.h),


          ],
        ),
      ),
    );
  }
}
