import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';

class AppOtpField extends StatelessWidget {
  final String? text;
  final bool? enableInteractiveSelection;
  final VoidCallback? onSuffixTap;
  final TextEditingController? controller;
  final IconData? icon;
  final IconData? suffixIcon;
  final int? maxlines;
  final double? size;
  final Color? iconColor;
  final bool? isObscure;
  final Color? textColor;
  final bool? isTextCenter;
  final VoidCallback? iconOnTap;
  final VoidCallback? suffixIconOnTap;
  final VoidCallback? onboxTap;
  final bool? isreadonly;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const AppOtpField({
    super.key,
    this.text,
    this.controller,
    this.icon,
    this.enableInteractiveSelection,
    this.onSuffixTap,
    this.suffixIcon,
    this.maxlines,
    this.size,
    this.iconColor,
    this.isObscure,
    this.textColor,
    this.isTextCenter,
    this.iconOnTap,
    this.isreadonly,
    this.suffixIconOnTap,
    this.onboxTap,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final isMobile = Breakpoints.isMobile(screenWidth);
    final isWideShortPhone =
        isMobile && screenWidth >= 500 && screenSize.height <= 760;
    final horizontalPadding = isWideShortPhone ? 12.0 : isMobile ? 20.0 : 14.0;
    final height = isWideShortPhone ? 46.0 : isMobile ? 60.0 : 54.0;
    final borderRadius = isWideShortPhone ? 14.0 : isMobile ? 20.0 : 16.0;
    final iconGap = isWideShortPhone ? 8.0 : isMobile ? 12.0 : 8.0;
    final iconSize = isWideShortPhone ? 20.0 : isMobile ? 24.0 : 18.0;
    final fieldFontSize =
        size ?? (isWideShortPhone ? 14.0 : isMobile ? 16.sp : 14.0);
    final verticalPadding = isWideShortPhone ? 10.0 : isMobile ? 16.0 : 13.0;

    return GestureDetector(
      onTap: onboxTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            icon != null
                ? GestureDetector(
                    onTap: iconOnTap,
                    child: Icon(
                      icon,
                      color: iconColor ?? Colors.grey,
                      size: iconSize,
                    ),
                  )
                : SizedBox.shrink(),
            SizedBox(width: iconGap),
            Expanded(
              child: TextField(
                onTap: onboxTap,
                focusNode: focusNode,
                readOnly: isreadonly ?? false,
                maxLines: maxlines ?? 1,
                maxLength: maxLength,
                controller: controller,
                cursorColor: appTextColor,
                obscureText: isObscure ?? false,
                textAlign: isTextCenter == null
                    ? TextAlign.start
                    : TextAlign.center,
                keyboardType: keyboardType,
                enableInteractiveSelection: enableInteractiveSelection ?? true,
                onChanged: onChanged, // ← add
                inputFormatters: maxLength == 1
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: text,
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: textColor ?? Colors.grey,
                    fontSize: fieldFontSize,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                  ),
                ),
              ),
            ),
            suffixIcon != null
                ? InkWell(
                    onTap: onSuffixTap,
                    borderRadius: BorderRadius.circular(
                      borderRadius,
                    ), // ← rounds the ripple
                    child: Icon(
                      suffixIcon,
                      color: Colors.grey,
                      size: iconSize,
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
