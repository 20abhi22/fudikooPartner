import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/catering/sent-enquiry-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:intl/intl.dart';

class CateringSentBox extends StatelessWidget {
  final SentEnquiryModel? enquiry;
  final VoidCallback? onDelete;
  final VoidCallback? onAccept;
  final String? moneyDetails;
  final String? discountDetails;
  final String? messageDetails;

  const CateringSentBox({
    super.key,
    this.enquiry,
    this.onDelete,
    this.onAccept,
    this.discountDetails,
    this.messageDetails,
    this.moneyDetails,
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
        final gap = isMobile ? 5.w : 6.0;
        final buttonWidth = isMobile ? 75.w : 92.0;
        final buttonHeight = isMobile ? 25.h : 32.0;
        final titleSize = isMobile ? 20.0 : 21.0;
        final bodySize = isMobile ? 14.0 : 15.0;

        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 20.h : 18),
          child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 17.r : 8),
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
                          text: enquiry?.enquiryId ?? "Loading...",
                          size: titleSize,
                          fontWeight: FontWeight.bold,
                          color: appTextColor3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10.h),
                        enquiry?.amount != null && enquiry!.amount.isNotEmpty
                            ? Row(
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

                                  // TO THIS
                                  Expanded(
                                    child: FutureBuilder<String>(
                                      future: TranslatorService.translate(
                                        'rupees Per Person',
                                      ),
                                      builder: (context, snapshot) {
                                        final translated =
                                            snapshot.data ??
                                            'rupees Per Person';

                                        return RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: enquiry!.amount,
                                                style: TextStyle(
                                                  fontSize: isMobile
                                                      ? bodySize.sp
                                                      : bodySize,
                                                  fontWeight: FontWeight.w400,
                                                  color: appTextColor5,
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' $translated',
                                                style: TextStyle(
                                                  fontSize: isMobile
                                                      ? bodySize.sp
                                                      : bodySize,
                                                  fontWeight: FontWeight.w400,
                                                  color: appTextColor5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox.shrink(),
                        SizedBox(height: 10.h),
                        enquiry?.extraOffer != null &&
                                enquiry!.extraOffer.isNotEmpty
                            ? Row(
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
                                    child: AppText(
                                      text: enquiry!.extraOffer,
                                      size: bodySize,
                                      fontWeight: FontWeight.w500,
                                      color: appTextColor5,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox.shrink(),
                        SizedBox(height: 10.h),
                        enquiry?.comments != null &&
                                enquiry!.comments.isNotEmpty
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      banquetTagIconColor,
                                      BlendMode.srcIn,
                                    ),
                                    child: Image.asset(
                                      commentIcon,
                                      width: iconSize,
                                      height: iconSize,
                                    ),
                                  ),
                                  SizedBox(width: gap),
                                  Expanded(
                                    child: AppText(
                                      text: enquiry!.comments,
                                      size: bodySize,
                                      fontWeight: FontWeight.w400,
                                      color: appTextColor5,
                                      maxLines: isMobile ? 3 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox.shrink(),
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
                          text: _formatDate(enquiry?.date),
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5.h),
                        AppText(
                          text: _formatTime(enquiry?.time),
                          size: 10,
                          fontWeight: FontWeight.w400,
                          color: appTextColor3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: buttonHeight,
                    width: buttonWidth,
                    child: AppButton(
                      text: "Delete",
                      onPressed: onDelete ?? () {},
                      bgColor1: sentDeleteButtonColor,
                      bgColor2: sentDeleteButtonColor,
                      size: 12,
                      borderRadius: isMobile ? 6 : 5,
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
