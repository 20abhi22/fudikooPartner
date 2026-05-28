import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/models/login/login-model.dart';
import 'package:fudiko/models/login/login-response-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/forgotpassword.dart';
import 'package:fudiko/screens/auth/registration.dart';
import 'package:fudiko/screens/others/infoPage.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/services/login-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tokens.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  LoginAuthService loginService = LoginAuthService();
  bool isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
    });
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    if (password.length < 6) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
        ),
      );
      return;
    }

    final user = UserLoginModel(username: email, password: password);

    LoginResponseModel response = await loginService.loginUser(user);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (response.status) {
      await saveToken(response.token!);
      if (!mounted) return;
      pushWidgetWhileRemove(newPage: MainNavPage(), context: context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => MainNavPage()),
      // );
      print(response.token);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 30.w, right: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logofudikoo.png',
              width: 250.w,
              fit: BoxFit.contain,
            ),
            AppText(text: "PARTNER APP", size: 20, fontWeight: FontWeight.w600),
            SizedBox(height: 65.h),
            AppTextFeild(
              text: "Username",
              isTextCenter: true,
              icon: Icons.person,
              controller: _email,
            ),
            SizedBox(height: 15.h),
            AppTextFeild(
              text: "Password",
              isTextCenter: true,
              icon: Icons.lock,
              isObscure: true,
              controller: _password,
            ),
            SizedBox(height: 30.h),
            AppButton(
              text: isLoading ? 'Please wait...' : 'Login',
              onPressed: () {
                isLoading ? null : loginUser();
              },
            ),
            SizedBox(height: 15.h),
            GestureDetector(
              onTap: () {
                slideRightWidget(newPage: const ForgotPassword(), context: context);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => ForgotPassword()),
                // );
              },
              child: AppText(
                text: "Forget Password?",
                size: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 100.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  text: "Dont have an Account?  ",
                  size: 15,
                  fontWeight: FontWeight.normal,
                  color: appTextColor2,
                ),
                GestureDetector(
                  onTap: () {
                    slideRightWidget(newPage: const Register(), context: context);
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => Register()),
                    // );
                  },
                  child: AppText(
                    text: "Sign Up",
                    size: 15,
                    fontWeight: FontWeight.normal,
                    color: appTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
