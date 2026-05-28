import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/appotpfield.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/infoPage.dart';
import 'package:fudiko/utils/constants.dart';

class Otp extends StatefulWidget {
  const Otp({super.key});

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  final List<TextEditingController> _controllers = List.generate(
    4, (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  void _onKeyPressed(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/otp.png',
              width: 180.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 40.h),
            AppText(
              text:
                  "An OTP has been sent to your registered email address. Kindly enter it to continue.",
              size: 15,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
              isCentered: true,
              lineSpacing: 1.2,
            ),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyPressed(event, index),
                      child: AppOtpField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        isTextCenter: true,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        onChanged: (value) => _onChanged(value, index),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 40.h),
            AppButton(
              text: 'Verify',
              onPressed: () {
                if (_otp.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter complete OTP'),
                    ),
                  );
                  return;
                }
                print('OTP: $_otp');
                slideRightWidget(newPage: InfoPage(), context: context);
                // Navigator.of(context).pushReplacement(
                //   MaterialPageRoute(
                //     builder: (context) => InfoPage(),
                //   ),
                // );
              },
            ),
          ],
        ),
      ),
    );
  }
}

