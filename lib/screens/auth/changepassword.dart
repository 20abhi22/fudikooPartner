import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/forgotpassword/changepassword-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/services/fogotpassword-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tokens.dart';

class ChangePassword extends StatefulWidget {
  final String? token;
  const ChangePassword({super.key, this.token});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;
  final ForgotPasswordService _forgotPasswordService = ForgotPasswordService();

  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  double _contentMaxWidth(Size size, bool isWideShortPhone) {
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 460;
    if (Breakpoints.isTabletDevice(size) || isWideShortPhone) return 440;
    return double.infinity;
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (isLoading) return;

    final currentPassword = _currentPassword.text.trim();
    final newPassword = _newPassword.text.trim();
    final confirmPassword = _confirmPassword.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (currentPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await _forgotPasswordService.updatePassword(
        UpdatePasswordModel(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));

      if (response.status) {
        await removeToken();
        if (!mounted) return;
        pushWidgetWhileRemove(newPage: const Login(), context: context);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final horizontalPadding = isWideShortPhone
        ? 36.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final topBottomPadding = isWideShortPhone
        ? 16.0
        : isMobile
        ? 24.h
        : AppDimensions.margin(width);
    final titleGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 40.h
        : 40.0;
    final fieldGap = isWideShortPhone
        ? 14.0
        : isMobile
        ? 20.h
        : 20.0;
    final buttonGap = isWideShortPhone
        ? 20.0
        : isMobile
        ? 30.h
        : 30.0;
    final fieldTextSize = isWideShortPhone
        ? 14.0
        : isMobile
        ? 16.0
        : 14.0;
    final fieldHeight = isWideShortPhone ? 46.0 : null;
    final buttonHeight = isWideShortPhone ? 46.0 : null;
    final buttonTextSize = isWideShortPhone ? 14.0 : null;

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
                    maxWidth: _contentMaxWidth(size, isWideShortPhone),
                    minHeight: (constraints.maxHeight - (topBottomPadding * 2))
                        .clamp(0.0, double.infinity),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        text: "Set your new password",
                        size: 15,
                        fontWeight: FontWeight.w400,
                        color: appTextColor2,
                        isCentered: true,
                      ),
                      SizedBox(height: titleGap),
                      AppTextFeild(
                        text: "Current Password",
                        size: fieldTextSize,
                        height: fieldHeight,
                        iconImagePath: padlockIcon,
                        isObscure: _obscureCurrentPassword,
                        enableInteractiveSelection: false,
                        suffixIcon: _obscureCurrentPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onSuffixTap: () => setState(
                          () => _obscureCurrentPassword =
                              !_obscureCurrentPassword,
                        ),
                        controller: _currentPassword,
                      ),
                      SizedBox(height: fieldGap),
                      AppTextFeild(
                        text: "New Password",
                        size: fieldTextSize,
                        height: fieldHeight,
                        iconImagePath: padlockIcon,
                        isObscure: _obscurePassword,
                        enableInteractiveSelection: false,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onSuffixTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        controller: _newPassword,
                      ),
                      SizedBox(height: fieldGap),
                      AppTextFeild(
                        text: "Confirm Password",
                        size: fieldTextSize,
                        height: fieldHeight,
                        iconImagePath: padlockIcon,
                        isObscure: _obscureConfirmPassword,
                        enableInteractiveSelection: false,
                        suffixIcon: _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onSuffixTap: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        controller: _confirmPassword,
                      ),
                      SizedBox(height: buttonGap),
                      AppButton(
                        text: isLoading ? 'Updating...' : 'Update',
                        onPressed: isLoading ? () {} : changePassword,
                        height: buttonHeight,
                        size: buttonTextSize,
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
