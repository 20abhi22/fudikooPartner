import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
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
          if(!mounted) return;
          setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    if (!EmailValidator.validate(email)) {
      if(!mounted) return;
       setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.length < 8) {
      if(!mounted) return;
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
      if(!mounted) return;
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

    RegResponseModel response = await registrationAuthService.registerUser(user);

    if(!mounted) return;
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
      if(!mounted) return;
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
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logofudikoo.png',
                  width: 250.w,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const AppText(
                  text: "PARTNER APP",
                  size: 20,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 60.h),
                AppTextFeild(
                  text: "Username",
                  icon: Icons.person,
                  controller: _name,
                ),
                SizedBox(height: 20.h),
                AppTextFeild(
                  text: "Email",
                  icon: Icons.mail,
                  controller: _email,
                ),
                SizedBox(height: 20.h),
                AppTextFeild(
                  text: "Password",
                  icon: Icons.lock,
                  controller: _password,
                  isObscure: _obscurePassword,
                  enableInteractiveSelection: false,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                SizedBox(height: 20.h),
                AppTextFeild(
                  text: "Confirm Password",
                  icon: Icons.lock,
                  controller: _confirmPassword,
                  isObscure: _obscureConfirmPassword,
                  enableInteractiveSelection: false,
                  suffixIcon: _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixTap: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                SizedBox(height: 30.h),
                AppButton(
                  text: isLoading ? 'Please wait...' : 'Create Account',
                  onPressed:   (){
                    isLoading ? null : register();
                  },
                ),
                SizedBox(height: 100.h),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        text: "Already have an Account?  ",
                        size: 15,
                        fontWeight: FontWeight.normal,
                        color: appTextColor2,
                      ),
                      GestureDetector(
                        onTap: () {
                          pushWidgetWhileRemove(newPage: Login(), context: context);
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => Login()),
                          // );
                        },
                        child: AppText(
                          text: "Sign In",
                          size: 15,
                          fontWeight: FontWeight.normal,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
