import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
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
        return DateFormat(format).format(DateFormat(pattern).parseStrict(rawDate));
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
        return DateFormat('hh:mm a').format(DateFormat(pattern).parseStrict(rawTime));
      } catch (_) {}
    }

    return rawTime;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: Offset(0, 0),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
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
                          size: 20,
                          fontWeight: FontWeight.bold,
                          color: appTextColor3,
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
                                      width: 17.w,
                                      height: 17.h,
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  // TO THIS

Flexible(
  child: FutureBuilder<String>(
    future: TranslatorService.translate(
      'rupees Per Person',
    ),
    builder: (context, snapshot) {
      final translated =
          snapshot.data ?? 'rupees Per Person';

      return Row(
        children: [
          AppText(
            text: enquiry!.amount,
            size: 14,
            fontWeight: FontWeight.w400,
            color: appTextColor5,
          ),

          SizedBox(width: 3.w),

          AppText(
            text: translated,
            size: 14,
            fontWeight: FontWeight.w400,
            color: appTextColor5,
          ),
        ],
      );
    },
  ),
),
                                ],
                              )
                            : SizedBox.shrink(),
                        SizedBox(height: 10.h),
                        enquiry?.extraOffer != null && enquiry!.extraOffer.isNotEmpty
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
                                      width: 17.w,
                                      height: 17.h,
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  Flexible(
                                    child: AppText(
                                      text:enquiry!.extraOffer,
                                      size: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: appTextColor5,
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox.shrink(),
                        SizedBox(height: 10.h),
                        enquiry?.comments != null && enquiry!.comments.isNotEmpty
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
                                      width: 17.w,
                                      height: 17.h,
                                    ),
                                  ),
                                  SizedBox(width: 5.w),
                                  Expanded(
                                    child: AppText(
                                      text: enquiry!.comments,
                                      size: 15.sp,
                                      fontWeight: FontWeight.w400,
                                        color: appTextColor5,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          text: _formatDate(enquiry?.date),
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        SizedBox(height: 5.h),
                        AppText(
                          text: _formatTime(enquiry?.time),
                          size: 10,
                          fontWeight: FontWeight.w400,
                          color: appTextColor3,
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
                    height: 25.h,
                    width: 75.w,
                    child: AppButton(
                      text: "Delete",
                      onPressed: onDelete ?? () {},
                      bgColor1: sentDeleteButtonColor,
                      bgColor2: sentDeleteButtonColor,
                      size: 12,
                      borderRadius: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}