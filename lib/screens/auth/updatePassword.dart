import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/forgotpassword/changepassword-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/forgotpassword.dart';
import 'package:fudiko/services/fogotpassword-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/snackbar.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final TextEditingController _oldPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final ForgotPasswordService _forgotPasswordService = ForgotPasswordService();

  bool _obscureOldPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (isLoading) return;

    final oldPassword = _oldPassword.text.trim();
    final newPassword = _newPassword.text.trim();
    final confirmPassword = _confirmPassword.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      showErrorSnack(context, "Please fill all fields");
      return;
    }

    if (newPassword.length < 6) {
      showErrorSnack(context, "Password must be at least 6 characters");
      return;
    }

    if (newPassword != confirmPassword) {
      showErrorSnack(context, "Passwords do not match");
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await _forgotPasswordService.updatePassword(
        UpdatePasswordModel(
          currentPassword: oldPassword,
          newPassword: newPassword,
        ),
      );
      if (!mounted) return;

      showStatusSnack(context, response.status, response.message);

      if (response.status) {
        _oldPassword.clear();
        _newPassword.clear();
        _confirmPassword.clear();
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  double _contentMaxWidth(double width, bool isWideShortPhone) {
    if (Breakpoints.isDesktop(width)) return 460;
    if (Breakpoints.isTablet(width) || isWideShortPhone) return 440;
    return double.infinity;
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
    final verticalPadding = isWideShortPhone
        ? 16.0
        : isMobile
        ? 24.h
        : AppDimensions.margin(width);
    final contentMaxWidth = isWideShortPhone
        ? 380.0
        : _contentMaxWidth(width, isWideShortPhone);
    final backIconSize = isWideShortPhone
        ? 26.0
        : isMobile
        ? 30.w
        : 28.0;
    // Keep the scrolling content clear of the back button pinned on top.
    final backRowHeight = backIconSize + (isWideShortPhone ? 16.0 : 32.0);
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
        ? 26.0
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
    final linkTextSize = isWideShortPhone ? 12.0 : 14.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        top: verticalPadding + backRowHeight,
                        bottom: verticalPadding,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: contentMaxWidth,
                          minHeight:
                              (constraints.maxHeight -
                                      (verticalPadding * 2) -
                                      backRowHeight)
                                  .clamp(0.0, double.infinity),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              text: "Set your new password",
                              size: bodyTextSize,
                              fontWeight: FontWeight.w400,
                              color: appTextColor2,
                              isCentered: true,
                            ),
                            SizedBox(height: titleGap),
                            AppTextFeild(
                              text: "Old Password",
                              icon: Icons.lock,
                              controller: _oldPassword,
                              isObscure: _obscureOldPassword,
                              enableInteractiveSelection: false,
                              size: fieldTextSize,
                              height: fieldHeight,
                              suffixIcon: _obscureOldPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              onSuffixTap: () => setState(
                                () => _obscureOldPassword = !_obscureOldPassword,
                              ),
                            ),
                            SizedBox(height: fieldGap),
                            AppTextFeild(
                              text: "New Password",
                              icon: Icons.lock,
                              controller: _newPassword,
                              isObscure: _obscurePassword,
                              enableInteractiveSelection: false,
                              size: fieldTextSize,
                              height: fieldHeight,
                              suffixIcon: _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              onSuffixTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            SizedBox(height: fieldGap),
                            AppTextFeild(
                              text: "Confirm Password",
                              icon: Icons.lock,
                              controller: _confirmPassword,
                              isObscure: _obscureConfirmPassword,
                              enableInteractiveSelection: false,
                              size: fieldTextSize,
                              height: fieldHeight,
                              suffixIcon: _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              onSuffixTap: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                            SizedBox(height: buttonGap),
                            AppButton(
                              text: isLoading ? 'Please wait...' : 'Update',
                              onPressed: () {
                                if (!isLoading) _updatePassword();
                              },
                              height: buttonHeight,
                              size: fieldTextSize,
                            ),
                            SizedBox(height: fieldGap),
                            InkWell(
                              onTap: () => slideRightWidget(
                                context: context,
                                newPage: const ForgotPassword(),
                              ),
                              child: AppText(
                                text: "Forgot Password?",
                                size: linkTextSize,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Last child so it paints above the scroll view and keeps
                  // receiving taps.
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: verticalPadding),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          backOrange,
                          width: backIconSize,
                          height: backIconSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
