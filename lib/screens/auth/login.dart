import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/login/login-model.dart';
import 'package:fudiko/models/login/login-response-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/forgotpassword.dart';
import 'package:fudiko/screens/auth/registration.dart';
import 'package:fudiko/services/login-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tokens.dart';
import 'package:fudiko/widgets/app_shell.dart';

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
      pushWidgetWhileRemove(newPage: const AppShell(), context: context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const AppShell()),
      // );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.sizeOf(context);
            final metrics = _LoginMetrics(size: size);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.horizontalPadding,
                vertical: metrics.verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight - (metrics.verticalPadding * 2),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: metrics.contentWidth),
                    child: metrics.useSplitLayout
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
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
                              SizedBox(height: metrics.titleFormGap),
                              _formBlock(metrics),
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

  Widget _brandBlock(_LoginMetrics metrics) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logofudikoo.png',
          width: metrics.logoWidth,
          fit: BoxFit.contain,
        ),
        SizedBox(height: metrics.logoTitleGap),
        AppText(
          text: 'PARTNER APP',
          size: metrics.titleSize,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  Widget _formBlock(_LoginMetrics metrics) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextFeild(
          text: 'Username',
          isTextCenter: true,
          iconImagePath: tabProfileIcon,
          controller: _email,
          height: metrics.fieldHeight,
          size: metrics.fieldTextSize,
        ),
        SizedBox(height: metrics.fieldGap),
        AppTextFeild(
          text: 'Password',
          isTextCenter: true,
          iconImagePath: padlockIcon,
          isObscure: true,
          controller: _password,
          height: metrics.fieldHeight,
          size: metrics.fieldTextSize,
        ),
        SizedBox(height: metrics.buttonGap),
        AppButton(
          text: isLoading ? 'Please wait...' : 'Login',
          onPressed: isLoading ? () {} : loginUser,
          height: metrics.buttonHeight,
          size: metrics.fieldTextSize,
        ),
        SizedBox(height: metrics.linkGap),
        GestureDetector(
          onTap: () => slideRightWidget(
            newPage: const ForgotPassword(),
            context: context,
          ),
          child: AppText(
            text: 'Forget Password?',
            size: metrics.linkTextSize,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: metrics.signupGap),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppText(
              text: 'Dont have an Account?  ',
              size: metrics.linkTextSize,
              fontWeight: FontWeight.normal,
              color: appTextColor2,
            ),
            GestureDetector(
              onTap: () =>
                  slideRightWidget(newPage: const Register(), context: context),
              child: AppText(
                text: 'Sign Up',
                size: metrics.linkTextSize,
                fontWeight: FontWeight.normal,
                color: appTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginMetrics {
  const _LoginMetrics({required this.size});

  final Size size;

  bool get isLandscape => size.width > size.height;
  bool get isWideShortPhone => Breakpoints.isWideShortPhone(size);
  bool get useSplitLayout => isLandscape && size.width >= 700;
  bool get isCompactLandscape => isWideShortPhone || useSplitLayout;

  double get horizontalPadding => isCompactLandscape ? 28 : 30.w;
  double get verticalPadding => isCompactLandscape ? 18 : 24.h;
  double get contentWidth {
    if (useSplitLayout) return size.width.clamp(680.0, 920.0);
    if (isWideShortPhone) return size.width * 0.62;
    return double.infinity;
  }

  double get splitGap => size.width >= 900 ? 56 : 36;
  double get logoWidth => isCompactLandscape ? 190 : 250.w;
  double get logoTitleGap => isCompactLandscape ? 2 : 6.h;
  double get titleSize => isCompactLandscape ? 16 : 20;
  double get titleFormGap => isCompactLandscape ? 26 : 65.h;
  double get fieldHeight => isCompactLandscape ? 46 : 56.h;
  double get fieldTextSize => isCompactLandscape ? 13 : 15;
  double get fieldGap => isCompactLandscape ? 10 : 15.h;
  double get buttonGap => isCompactLandscape ? 18 : 30.h;
  double get buttonHeight => isCompactLandscape ? 46 : 52.h;
  double get linkGap => isCompactLandscape ? 10 : 15.h;
  double get linkTextSize => isCompactLandscape ? 13 : 15;
  double get signupGap => isCompactLandscape ? 36 : 100.h;
}
