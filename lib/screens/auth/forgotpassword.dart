import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/forgotpassword/finduser-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/otp.dart';
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

  double _contentMaxWidth(double width, bool isWideShortPhone) {
    if (Breakpoints.isDesktop(width)) return 460;
    if (Breakpoints.isTablet(width) || isWideShortPhone) return 440;
    return double.infinity;
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter username and email")));
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final FindUserModel user = FindUserModel(username, email);
    final FindUserResponseModel response = await forgotPasswordService.findUser(
      user,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (response.status &&
        response.token != null &&
        response.token!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User found!")));
      slideRightWidget(
        newPage: Otp(token: response.token),
        context: context,
      );
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
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final horizontalPadding = isWideShortPhone
        ? 28.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final topBottomPadding = isWideShortPhone
        ? 18.0
        : isMobile
        ? 24.h
        : AppDimensions.margin(width);
    final contentMaxWidth = isWideShortPhone
        ? 380.0
        : _contentMaxWidth(width, isWideShortPhone);
    final lineGap = isWideShortPhone
        ? 4.0
        : isMobile
        ? 8.h
        : 8.0;
    final titleGap = isWideShortPhone
        ? 22.0
        : isMobile
        ? 40.h
        : 40.0;
    final fieldGap = isWideShortPhone
        ? 10.0
        : isMobile
        ? 20.h
        : 20.0;
    final buttonGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 60.h
        : 52.0;
    final fieldHeight = isWideShortPhone ? 46.0 : null;
    final buttonHeight = isWideShortPhone ? 46.0 : null;
    final bodyTextSize = isWideShortPhone ? 13.0 : 15.0;
    final fieldTextSize = isWideShortPhone
        ? 13.0
        : isMobile
        ? 16.0
        : 14.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: topBottomPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: contentMaxWidth,
                    minHeight: constraints.maxHeight - (topBottomPadding * 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        text: "Enter your username and",
                        size: bodyTextSize,
                        fontWeight: FontWeight.w400,
                        color: appTextColor2,
                        isCentered: true,
                      ),
                      SizedBox(height: lineGap),
                      AppText(
                        text: "registered email ID",
                        size: bodyTextSize,
                        fontWeight: FontWeight.w400,
                        color: appTextColor2,
                        isCentered: true,
                      ),
                      SizedBox(height: titleGap),
                      AppTextFeild(
                        text: "Username",
                        icon: Icons.person,
                        controller: _username,
                        size: fieldTextSize,
                        height: fieldHeight,
                      ),
                      SizedBox(height: fieldGap),
                      AppTextFeild(
                        text: "Email",
                        icon: Icons.mail,
                        controller: _email,
                        size: fieldTextSize,
                        height: fieldHeight,
                      ),
                      SizedBox(height: buttonGap),
                      AppButton(
                        text: isLoading ? 'Please wait...' : 'Continue',
                        onPressed: () {
                          if (!isLoading) {
                            forgotPasswordFindUser();
                          }
                        },
                        height: buttonHeight,
                        size: fieldTextSize,
                      ),
                      SizedBox(height: fieldGap),
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
