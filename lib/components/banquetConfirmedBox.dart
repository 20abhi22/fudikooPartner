import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/banquet/all-enquiry-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class BanquetConfirmedBox extends StatelessWidget {
  final BanquetEnquiryModel enquiry;
  final VoidCallback? onDetailsTap;
  final VoidCallback? onRemindTap;

  const BanquetConfirmedBox({
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
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
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
                          text: enquiry.enquiryId,
                          size: 20,
                          fontWeight: FontWeight.bold,
                          color: appTextColor3,
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
                                width: 17.w,
                                height: 18.h,
                              ),
                            ),
                            SizedBox(width: 5),
                            Flexible(
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText(
        text: enquiry.estimatedAmount,
        size: 14,
        fontWeight: FontWeight.w900,
        color: appTextColor5,
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
                                width: 17.w,
                                height: 17.h,
                              ),
                            ),
                            SizedBox(width: 5),
                            Flexible(
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText(
        text: enquiry.searchRadius,
        size: 14,
        fontWeight: FontWeight.w700,
        color: appTextColor5,
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
                                width: 16.w,
                                height: 16.h,
                              ),
                            ),
                            SizedBox(width: 5),
                            Flexible(
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText(
        text: enquiry.people.toString(),
        size: 14,
        fontWeight: FontWeight.w700,
        color: appTextColor5,
      ),

      SizedBox(width: 2.w),

      AppText(
        text: 'Person',
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
                                width: 17.w,
                                height: 17.h,
                              ),
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: AppText(
                                text: enquiry.menuItems,
                                size: 13,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor5,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: _formatDate(enquiry.date),
                        size: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 5),
                      AppText(
                        text: _formatTime(enquiry.time),
                        size: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onDetailsTap,
                    child: Row(
                      children: [
                       ColorFiltered(colorFilter: ColorFilter.mode(processDetailsIconColor, BlendMode.srcIn), child: Image.asset(detailsIcon, width: 15.w, height: 15.w)),
                        SizedBox(width: 5),
                        AppText(
                          text: "Details",
                          size: 10,
                          fontWeight: FontWeight.w500,
                          color: processDetailsIconColor,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80.w,
                    height: 25.h,
                    child: AppButton(
                      text: "Remind",
                      onPressed: onRemindTap ?? () {},
                      bgColor1: confirmedRemindButtonColor,
                      bgColor2:  confirmedRemindButtonColor,
                      size: 12.sp,
                      borderRadius: 5.r,
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
