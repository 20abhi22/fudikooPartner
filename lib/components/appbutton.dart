import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/utils/translator_service.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor1;
  final Color? bgColor2;
  final double? size;
  final IconData? icon;
  final double? borderRadius;
  final bool? isShadow;
  final FontWeight? fontWeight;
  final double? height;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor1,
    this.bgColor2,
    this.size,
    this.icon,
    this.borderRadius,
    this.isShadow,
    this.fontWeight,
    this.height,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _translate();
    }
  }

  Future<void> _translate() async {
    final result = await TranslatorService.translate(widget.text);

    if (mounted) {
      setState(() {
        _translated = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width?.w,
      height: widget.height?.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius?.r ?? 20.r),
        gradient: widget.bgColor1 == null && widget.bgColor2 == null
            ? const LinearGradient(
                colors: [Color(0xFFC95F05), Color(0xFFF97A0D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  widget.bgColor1 ?? const Color(0xFFC95F05),
                  widget.bgColor2 ?? const Color(0xFFF97A0D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: widget.isShadow == false
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.icon != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 16.r),
                  child: Icon(widget.icon, color: Colors.white, size: 25.w),
                ),
              ),
            Center(
              child: Text(
                _translated.isEmpty ? widget.text : _translated,
                style: TextStyle(
                  fontSize: widget.size?.sp ?? 20.sp,
                  fontWeight: widget.fontWeight ?? FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
