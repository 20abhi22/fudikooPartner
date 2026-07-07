import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/catering/all-enquiry-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/nav/profile.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class CateringConfirmedBox extends StatelessWidget {
  final CateringEnquiryModel enquiry;
  final VoidCallback? onDetailsTap;
  final VoidCallback? onRemindTap;

  const CateringConfirmedBox({
    super.key,
    required this.enquiry,
    this.onDetailsTap,
    this.onRemindTap,

  });
  String _formatDate(String? rawDate, {String format = "MMM dd"}) {
    if (rawDate == null || rawDate.trim().isEmpty) return "Loading...";

    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) return DateFormat(format).format(parsed);

    for (final pattern in ["yyyy-MM-dd", "dd-MM-yyyy", "MM/dd/yyyy"]) {
      try {
        return DateFormat(
          format,
        ).format(DateFormat(pattern).parseStrict(rawDate));
      } catch (_) {}
    }

    return rawDate;
  }

  String _formatTime(String? rawTime) {
    if (rawTime == null || rawTime.trim().isEmpty) return "Loading...";

    final parsed = DateTime.tryParse(rawTime);
    if (parsed != null) return DateFormat('hh:mm a').format(parsed);

    for (final pattern in ["HH:mm:ss", "HH:mm", "hh:mm a", "h:mm a"]) {
      try {
        return DateFormat(
          'hh:mm a',
        ).format(DateFormat(pattern).parseStrict(rawTime));
      } catch (_) {}
    }

    return rawTime;
  }

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
        final cardPadding = isMobile
            ? EdgeInsets.all(20.w)
            : EdgeInsets.all(AppDimensions.padding(width) * 0.8);
        final iconSize = isMobile ? 17.w : 18.0;
        final smallIconSize = isMobile ? 16.w : 18.0;
        final gap = isMobile ? 5.w : 6.0;
        final buttonWidth = isMobile ? 66.w : 82.0;
        final buttonHeight = isMobile ? 24.h : 28.0;

        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 20.h : 18),
          child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 20.r : 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: const Offset(0, 4),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: cardPadding,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: enquiry.enquiryId,
                          size: 20,
                          fontWeight: FontWeight.bold,
                          color: appTextColor3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                banquetTagIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                walletIcon,
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: AppText(
                                      text: enquiry.estimatedAmount,
                                      size: 14,
                                      fontWeight: FontWeight.w700,
                                      color: appTextColor5,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  SizedBox(width: 2.w),

                                  AppText(
                                    text: 'Estimated',
                                    size: 14,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                banquetTagIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                offerIcon,
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: AppText(
                                      text: enquiry.searchRadius,
                                      size: 14,
                                      fontWeight: FontWeight.w700,
                                      color: appTextColor5,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  SizedBox(width: 2.w),

                                  AppText(
                                    text: 'Radius',
                                    size: 14,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                banquetTagIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                groupIcon,
                                width: smallIconSize,
                                height: smallIconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: Row(
                                children: [
                                  AppText(
                                    text: enquiry.people.toString(),
                                    size: 14,
                                    fontWeight: FontWeight.w700,
                                    color: appTextColor5,
                                  ),

                                  SizedBox(width: 2.w),

                                  AppText(
                                    text: enquiry.people == 1
                                        ? 'Person'
                                        : 'Persons',
                                    size: 14,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                banquetTagIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                menuIcon,
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: AppText(
                                text: enquiry.menuItems,
                                size: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w400,
                                color: appTextColor5,
                                maxLines: isMobile ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 10.w : 12),
                  SizedBox(
                    width: isMobile ? 70.w : 88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          text: _formatDate(enquiry.date),
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        AppText(
                          text: _formatTime(enquiry.time),
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _CateringDetailsAction(
                    onTap:
                        // onDetailsTap ??
                        () {
                          final customerId =  enquiry.customerId;
                              // ? enquiry.customerId
                              // : enquiry.userId;
                          slideRightWidget(
                            newPage: Profile(customerId: customerId),
                            context: context,
                          );
                        },
                  ),
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: AppButton(
                      text: "Remind",
                      onPressed: onRemindTap ?? () {},
                      bgColor1: confirmedRemindButtonColor,
                      bgColor2: confirmedRemindButtonColor,
                      size: isMobile ? 11.sp : 11,
                      borderRadius: isMobile ? 5.r : 5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _CateringDetailsAction extends StatelessWidget {
  final VoidCallback onTap;

  const _CateringDetailsAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final isWideShortPhone =
        Breakpoints.isMobile(screenWidth) &&
        screenWidth >= 500 &&
        screenSize.height <= 760;
    final isMobile = Breakpoints.isMobile(screenWidth) && !isWideShortPhone;
    final isTablet = Breakpoints.isTablet(screenWidth);
    final iconSize = isMobile
        ? 12.w
        : isTablet
        ? 14.0
        : 13.0;
    final gap = isMobile
        ? 4.w
        : isTablet
        ? 5.0
        : 5.0;
    final textSize = isTablet ? 12.0 : 11.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 2 : 0,
          vertical: isTablet ? 4 : 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                processDetailsIconColor,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                detailsIcon,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: gap),
            AppText(
              text: 'Details',
              size: textSize,
              fontWeight: FontWeight.w500,
              color: processDetailsIconColor,
            ),
          ],
        ),
      ),
    );
  }
}
