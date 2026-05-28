import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return GestureDetector(
      onTap: onboxTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
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
                    child: Icon(icon, color: iconColor ?? Colors.grey),
                  )
                : SizedBox.shrink(),
            SizedBox(width: 12),
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
                    fontSize: size ?? 16,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            suffixIcon != null
                ? InkWell(
                    onTap: onSuffixTap,
                    borderRadius: BorderRadius.circular(
                      20,
                    ), // ← rounds the ripple
                    child: Icon(suffixIcon, color: Colors.grey,),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
