import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';

/// White card with a centred question and a green Yes / red No pair — the same
/// confirmation used on the Banquet tab. Resolves to `true` only when the user
/// taps Yes; tapping No or dismissing the barrier resolves to `false`.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String message,
  String confirmText = "Yes",
  String cancelText = "No",
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final isWideShortPhone = Breakpoints.isWideShortPhone(size);
      final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
      final horizontalMargin = isMobile ? 20.w : 20.0;
      final cardPaddingH = isMobile ? 40.w : 40.0;
      final cardPaddingV = isMobile ? 30.h : 30.0;
      final cardRadius = isMobile ? 15.r : 15.0;
      final buttonGap = isMobile ? 20.w : 20.0;
      final buttonHeight = isMobile ? 35.h : 35.0;
      final messageGap = isMobile ? 20.h : 20.0;

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: cardPaddingH,
            vertical: cardPaddingV,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: message,
                size: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                isCentered: true,
                lineSpacing: 1.2,
                // A long message has to wrap instead of being clipped —
                // AppText only turns softWrap on when maxLines is set.
                softWrap: true,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: messageGap),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: AppButton(
                        text: confirmText,
                        onPressed: () => Navigator.of(context).pop(true),
                        size: 12,
                        borderRadius: 5,
                        bgColor1: Colors.green,
                        bgColor2: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(width: buttonGap),
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: AppButton(
                        text: cancelText,
                        onPressed: () => Navigator.of(context).pop(false),
                        size: 12,
                        borderRadius: 5,
                        bgColor1: Colors.red,
                        bgColor2: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}
