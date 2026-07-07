import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/registration/registration-model.dart';
import 'package:fudiko/models/registration/registration-response-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/screens/auth/otp.dart';
import 'package:fudiko/services/registration-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tokens.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  RegistrationAuthService registrationAuthService = RegistrationAuthService();
  bool isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> register() async {
    setState(() {
      isLoading = true;
    });
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();
    final confirmPassword = _confirmPassword.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    if (!EmailValidator.validate(email)) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.length < 8) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final user = UserRegistrationModel(
      username: name,
      email: email,
      password: password,
    );

    RegResponseModel response = await registrationAuthService.registerUser(
      user,
    );

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
    if (response.status) {
      await saveToken(response.token!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      slideRightWidget(newPage: const Otp(), context: context);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => const Otp()),
      // );
    } else {
      if (!mounted) return;
      final errors = response.fieldErrors;
      if (errors != null) {
        if (errors.containsKey('email')) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errors['email']!)));
        }

        if (errors.containsKey('username')) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errors['username']!)));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final metrics = _RegisterMetrics(size: size);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                  vertical: metrics.verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: metrics.contentMaxWidth,
                    minHeight:
                        constraints.maxHeight - (metrics.verticalPadding * 2),
                  ),
                  child: Center(
                    child: metrics.useSplitLayout
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _brandBlock(metrics)),
                              SizedBox(width: metrics.splitGap),
                              Expanded(child: _formBlock(metrics)),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _brandBlock(metrics),
                              SizedBox(height: metrics.formTopGap),
                              _formBlock(metrics),
                              SizedBox(height: metrics.bottomGap),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _brandBlock(_RegisterMetrics metrics) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logofudikoo.png',
          width: metrics.logoWidth,
          fit: BoxFit.contain,
        ),
        SizedBox(height: metrics.logoGap),
        AppText(
          text: 'PARTNER APP',
          size: metrics.titleSize,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  Widget _formBlock(_RegisterMetrics metrics) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextFeild(
          text: "Username",
          iconImagePath: tabProfileIcon,
          iconImagecolor: appTextColor5,
          controller: _name,
          size: metrics.fieldTextSize,
          height: metrics.fieldHeight,
        ),
        SizedBox(height: metrics.fieldGap),
        AppTextFeild(
          text: "Email",
          iconImagePath: tabEmailIcon,
          iconImagecolor: appTextColor5,
          controller: _email,
          size: metrics.fieldTextSize,
          height: metrics.fieldHeight,
        ),
        SizedBox(height: metrics.fieldGap),
        AppTextFeild(
          text: "Password",
          iconImagePath: padlockIcon,
          iconImagecolor: appTextColor5,
          controller: _password,
          size: metrics.fieldTextSize,
          height: metrics.fieldHeight,
          isObscure: _obscurePassword,
          enableInteractiveSelection: false,
          suffixIcon: _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixTap: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        SizedBox(height: metrics.fieldGap),
        AppTextFeild(
          text: "Confirm Password",
          iconImagePath: padlockIcon,
          iconImagecolor: appTextColor5,
          controller: _confirmPassword,
          size: metrics.fieldTextSize,
          height: metrics.fieldHeight,
          isObscure: _obscureConfirmPassword,
          enableInteractiveSelection: false,
          suffixIcon: _obscureConfirmPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onSuffixTap: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
        ),
        SizedBox(height: metrics.buttonGap),
        AppButton(
          text: isLoading ? 'Please wait...' : 'Create Account',
          onPressed: () {
            if (!isLoading) {
              register();
            }
          },
          height: metrics.buttonHeight,
          size: metrics.fieldTextSize,
        ),
        SizedBox(height: metrics.signInTopGap),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppText(
              text: "Already have an Account?  ",
              size: metrics.linkTextSize,
              fontWeight: FontWeight.normal,
              color: appTextColor2,
              isCentered: true,
            ),
            GestureDetector(
              onTap: () {
                pushWidgetWhileRemove(newPage: const Login(), context: context);
              },
              child: AppText(
                text: "Sign In",
                size: metrics.linkTextSize,
                fontWeight: FontWeight.normal,
                color: Colors.blue,
                isCentered: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RegisterMetrics {
  const _RegisterMetrics({required this.size});

  final Size size;

  double get width => size.width;
  double get height => size.height;
  bool get isMobile => Breakpoints.isMobile(width);
  bool get isWideShortPhone => Breakpoints.isWideShortPhone(size);
  bool get isLandscape => width > height;
  bool get useSplitLayout => isLandscape && width >= 700;
  bool get isCompactLandscape => isWideShortPhone || useSplitLayout;

  double get horizontalPadding {
    if (isCompactLandscape) return 28.0;
    if (isMobile) return 30.w;
    return AppDimensions.padding(width);
  }

  double get verticalPadding {
    if (isCompactLandscape) return 18.0;
    if (isMobile) return 24.h;
    return AppDimensions.margin(width);
  }

  double get contentMaxWidth {
    if (useSplitLayout) return width.clamp(680.0, 920.0);
    if (isWideShortPhone) return 380.0;
    if (Breakpoints.isDesktop(width)) return 460.0;
    if (Breakpoints.isTablet(width)) return 440.0;
    return double.infinity;
  }

  double get splitGap => width >= 900 ? 56.0 : 36.0;
  double get logoWidth => isCompactLandscape
      ? 190.0
      : isMobile
      ? 250.w
      : 250.0;
  double get logoGap => isCompactLandscape
      ? 2.0
      : isMobile
      ? 10.h
      : 10.0;
  double get titleSize => isCompactLandscape ? 16.0 : 20.0;
  double get formTopGap => isCompactLandscape
      ? 26.0
      : isMobile
      ? 60.h
      : 48.0;
  double get fieldGap => isCompactLandscape
      ? 10.0
      : isMobile
      ? 20.h
      : 20.0;
  double get buttonGap => isCompactLandscape
      ? 18.0
      : isMobile
      ? 30.h
      : 30.0;
  double get signInTopGap => isCompactLandscape
      ? 36.0
      : isMobile
      ? 100.h
      : 64.0;
  double get bottomGap => isCompactLandscape
      ? 18.0
      : isMobile
      ? height * 0.05
      : 32.0;
  double? get fieldHeight => isCompactLandscape ? 46.0 : null;
  double? get buttonHeight => isCompactLandscape ? 46.0 : null;
  double get fieldTextSize => isCompactLandscape
      ? 13.0
      : isMobile
      ? 16.0
      : 14.0;
  double get linkTextSize => isCompactLandscape ? 13.0 : 15.0;
}
