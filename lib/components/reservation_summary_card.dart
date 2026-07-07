import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';

class ReservationSummaryCard extends StatelessWidget {
  final String reservationId;
  final Color titleColor;
  final Color iconColor;
  final String iconPath;
  final String offerPrimary;
  final String offerSecondary;
  final String dateLabel;
  final String timeLabel;
  final int people;
  final String trailingDate;
  final String trailingTime;
  final Color? trailingTextColor;
  final String? statusLabel;
  final Color? statusColor;
  final Widget? leadingAction;
  final List<Widget> actions;

  const ReservationSummaryCard({
    super.key,
    required this.reservationId,
    required this.titleColor,
    required this.iconColor,
    required this.iconPath,
    required this.offerPrimary,
    required this.offerSecondary,
    required this.dateLabel,
    required this.timeLabel,
    required this.people,
    required this.trailingDate,
    required this.trailingTime,
    this.trailingTextColor,
    this.statusLabel,
    this.statusColor,
    this.leadingAction,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final screenSize = MediaQuery.sizeOf(context);
        final isWideShortPhone =
            Breakpoints.isMobile(screenSize.width) &&
            screenSize.width >= 500 &&
            screenSize.height <= 760;
        final isMobile = Breakpoints.isMobile(width) && !isWideShortPhone;
        final padding = isMobile
            ? EdgeInsets.fromLTRB(24.w, 18.h, 18.w, 12.h)
            : isWideShortPhone
            ? const EdgeInsets.all(20)
            : EdgeInsets.all(AppDimensions.padding(width) * 0.8);
        final iconSize = isMobile ? 17.w : 18.0;
        final titleSize = isMobile ? 20.0 : 21.0;
        final bodySize = isMobile ? 14.0 : 15.0;
        final cardRadius = isMobile ? 17.sp : 8.0;

        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 20.h : 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: padding,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: AppText(
                                    text: reservationId,
                                    size: titleSize,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (statusLabel != null &&
                                    statusLabel!.trim().isNotEmpty) ...[
                                  SizedBox(width: isMobile ? 10.w : 10),
                                  _StatusBadge(
                                    label: statusLabel!,
                                    color: statusColor ?? titleColor,
                                    isMobile: isMobile,
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: isMobile ? 10.h : 10),
                            _InfoRow(
                              iconPath: offerIcon,
                              iconColor: iconColor,
                              iconSize: iconSize,
                              child: _OfferText(
                                primary: offerPrimary,
                                secondary: offerSecondary,
                                fontSize: bodySize,
                              ),
                            ),
                            SizedBox(height: isMobile ? 6.h : 6),
                            _InfoRow(
                              iconPath: calenderIcon,
                              iconColor: iconColor,
                              iconSize: iconSize,
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: dateLabel,
                                      style: TextStyle(
                                        fontSize: bodySize,
                                        fontWeight: FontWeight.w700,
                                        color: appTextColor5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' - $timeLabel',
                                      style: TextStyle(
                                        fontSize: bodySize,
                                        fontWeight: FontWeight.w500,
                                        color: appTextColor5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 6.h : 6),
                            _InfoRow(
                              iconPath: groupIcon,
                              iconColor: iconColor,
                              iconSize: iconSize,
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$people ',
                                      style: TextStyle(
                                        fontSize: bodySize,
                                        fontWeight: FontWeight.w700,
                                        color: appTextColor5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: people == 1 ? 'Person' : 'Persons',
                                      style: TextStyle(
                                        fontSize: bodySize,
                                        fontWeight: FontWeight.w500,
                                        color: appTextColor5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: isWideShortPhone
                            ? 10.0
                            : AppDimensions.gap(width) * 0.5,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText(
                            text: trailingDate,
                            size: 10,
                            fontWeight: FontWeight.w700,
                            color: trailingTextColor ?? appTextColor5,
                            maxLines: 1,
                          ),
                          SizedBox(height: isMobile ? 5.h : 5),
                          AppText(
                            text: trailingTime,
                            size: 10,
                            fontWeight: FontWeight.w500,
                            color: trailingTextColor ?? appTextColor5,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (leadingAction != null || actions.isNotEmpty) ...[
                    SizedBox(height: isMobile ? 16.h : 16),
                    Row(
                      children: [
                        if (leadingAction != null) leadingAction!,
                        const Spacer(),
                        ...actions.map(
                          (action) => Padding(
                            padding: EdgeInsets.only(
                              left: isMobile ? 10.w : 10,
                            ),
                            child: action,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReservationCardActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final double width;

  const ReservationCardActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
    this.width = 82,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isWideShortPhone =
        Breakpoints.isMobile(screenWidth) &&
        screenWidth >= 500 &&
        size.height <= 760;
    final isMobile = Breakpoints.isMobile(screenWidth) && !isWideShortPhone;
    final isTablet = Breakpoints.isTablet(screenWidth) || isWideShortPhone;
    final buttonWidth = isMobile
        ? width
        : isTablet
        ? (text.length * 8.0 + 40).clamp(92.0, 150.0)
        : (text.length * 7.0 + 34).clamp(82.0, 130.0);
    final buttonHeight = isMobile
        ? 28.0
        : isTablet
        ? 34.0
        : 32.0;
    final textSize = isMobile
        ? 12.0
        : isTablet
        ? 12.0
        : 11.0;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: AppButton(
        text: text,
        onPressed: onPressed,
        bgColor1: color,
        bgColor2: color,
        size: textSize,
        borderRadius: isTablet ? 6 : 5,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isMobile;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.w : 8,
        vertical: isMobile ? 3.h : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(isMobile ? 8.r : 8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: isMobile ? 10.sp : 10,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String iconPath;
  final Color iconColor;
  final double iconSize;
  final Widget child;

  const _InfoRow({
    required this.iconPath,
    required this.iconColor,
    required this.iconSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone =
        Breakpoints.isMobile(size.width) &&
        size.width >= 500 &&
        size.height <= 760;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          child: Image.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: isWideShortPhone ? 6.0 : 6.w),
        Expanded(child: child),
      ],
    );
  }
}

class _OfferText extends StatelessWidget {
  final String primary;
  final String secondary;
  final double fontSize;

  const _OfferText({
    required this.primary,
    required this.secondary,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: primary,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: appTextColor5,
            ),
          ),
          if (secondary.isNotEmpty)
            TextSpan(
              text: ' $secondary',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: appTextColor5,
              ),
            ),
        ],
      ),
    );
  }
}
