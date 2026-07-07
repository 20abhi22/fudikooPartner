import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/appotpfield.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/changepassword.dart';
import 'package:fudiko/screens/others/infoPage.dart';
import 'package:fudiko/services/otp_auth-service.dart';
import 'package:fudiko/utils/constants.dart';

class Otp extends StatefulWidget {
  // Null means registration flow; a value means forgot-password flow.
  final String? token;
  const Otp({super.key, this.token});

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final FocusNode _keyboardFocusNode = FocusNode();

  final OtpAuthService _otpservice = OtpAuthService();

  String? _otpId;
  bool _isSending = true; // true while send-otp call is in flight
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    final result = await _otpservice.sendOtp(tokenOverride: widget.token);
    if (!mounted) return;
    setState(() => _isSending = false);
    if (result.status) {
      _otpId = result.otpId;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }
    if (_otpId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP not ready, please wait')),
      );
      return;
    }
    setState(() => _isVerifying = true);
    // final result = await _otpservice.verifyOtp(_otp, _otpId!);
    final result = await _otpservice.verifyOtp(
      _otp,
      _otpId!,
      tokenOverride: widget.token,
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (result.status) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      if (widget.token != null) {
        slideRightWidget(
          newPage: ChangePassword(token: widget.token),
          context: context,
        );
      } else {
        slideRightWidget(newPage: InfoPage(), context: context);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _keyboardFocusNode.dispose();
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
    final size = MediaQuery.sizeOf(context);
    final metrics = _OtpMetrics(size: size);

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
                              Expanded(child: _introBlock(metrics)),
                              SizedBox(width: metrics.splitGap),
                              Expanded(child: _otpBlock(metrics)),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _introBlock(metrics),
                              SizedBox(height: metrics.gap),
                              _otpBlock(metrics),
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

  Widget _introBlock(_OtpMetrics metrics) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/otp.png',
          width: metrics.imageWidth,
          fit: BoxFit.contain,
        ),
        SizedBox(height: metrics.gap),
        AppText(
          text:
              "An OTP has been sent to your registered email address. Kindly enter it to continue.",
          size: metrics.bodyTextSize,
          fontWeight: FontWeight.w400,
          color: appTextColor2,
          isCentered: true,
          lineSpacing: 1.2,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _otpBlock(_OtpMetrics metrics) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: metrics.otpRowMaxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.otpFieldGap,
                  ),
                  child: RawKeyboardListener(
                    focusNode: _keyboardFocusNode,
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
        ),
        SizedBox(height: metrics.gap),
        AppButton(
          text: (_isSending || _isVerifying) ? 'Please wait...' : 'Verify',
          onPressed: () {
            if (!_isSending && !_isVerifying) _verifyOtp();
          },
          height: metrics.buttonHeight,
          size: metrics.buttonTextSize,
        ),
      ],
    );
  }
}

class _OtpMetrics {
  const _OtpMetrics({required this.size});

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
    if (useSplitLayout) return width.clamp(660.0, 860.0);
    if (isWideShortPhone) return 380.0;
    if (Breakpoints.isDesktop(width)) return 460.0;
    if (Breakpoints.isTablet(width)) return 440.0;
    return double.infinity;
  }

  double get splitGap => width >= 900 ? 52.0 : 34.0;
  double get imageWidth => isCompactLandscape
      ? 120.0
      : isMobile
      ? 180.w
      : 180.0;
  double get gap => isCompactLandscape
      ? 20.0
      : isMobile
      ? 40.h
      : 40.0;
  double get otpFieldGap => isCompactLandscape
      ? 4.0
      : isMobile
      ? 6.w
      : 6.0;
  double get otpRowMaxWidth {
    if (isWideShortPhone) return 300.0;
    if (isMobile) return double.infinity;
    return 360.0;
  }

  double get bodyTextSize => isCompactLandscape ? 13.0 : 15.0;
  double? get buttonHeight => isCompactLandscape ? 46.0 : null;
  double? get buttonTextSize => isCompactLandscape ? 13.0 : null;
}
