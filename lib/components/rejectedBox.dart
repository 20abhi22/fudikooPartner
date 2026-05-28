import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/rerservation/reservation-cancelled-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class RejectedBox extends StatelessWidget {
  final ReservationCancelledModel reservation;
  final VoidCallback? onCallBackPressed;
  final bool isCallBackEnabled;
  final String? discountPercentage;
  final String? applicableFor;
  final String? dineType;

  const RejectedBox({
    super.key,
    required this.reservation,
    this.onCallBackPressed,
    this.isCallBackEnabled = true,
    this.discountPercentage,
    this.applicableFor,
    this.dineType,
  });

  String formatDate(String dateString, {String format = "MMM dd"}) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat(format).format(date);
    } catch (e) {
      return dateString;
    }
  }

  String formatTime(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return dateString;
    }
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 37.w,
            top: 20.h,
            bottom: 5.h,
            right: 20.w,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: reservation.reservationId,
                          size: 20,
                          fontWeight: FontWeight.w700,
                          color: rejectedTitleTextColor,
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                rejectedDetailsIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(offerIcon, width: 18.w),
                            ),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: Builder(
                                builder: (context) {
                                  final discountRaw = discountPercentage ?? '';
                                  String discountText = '';
                                  if (discountRaw.isNotEmpty) {
                                    discountText = discountRaw.contains('.')
                                        ? discountRaw.split('.').first
                                        : discountRaw;
                                    discountText = '$discountText%';
                                  }

                                  final applicable = applicableFor ?? '';
                                  final dine = dineType ?? '';

                                  final primary = discountText.isNotEmpty
                                      ? discountText
                                      : (reservation.offerCode.isNotEmpty
                                            ? reservation.offerCode
                                            : 'No Offer');

                                  final secondaryParts = <String>[];
                                  if (applicable.isNotEmpty)
                                    secondaryParts.add('for $applicable');
                                  if (dine.isNotEmpty) secondaryParts.add(dine);
                                  final secondary = secondaryParts.join(' · ');

                                  return RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: primary,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: appTextColor5,
                                          ),
                                        ),
                                        if (secondary.isNotEmpty)
                                          TextSpan(
                                            text: ' $secondary',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
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
                        ),
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                rejectedDetailsIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(calenderIcon, width: 18.w),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              "${formatDate(reservation.date)}",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: appTextColor5,
                              ),
                            ),
                            // ColorFiltered(colorFilter:  ColorFilter.mode(appTextColor5, BlendMode.srcIn), child: Image.asset(calenderIcon, width: 18.w)),
                            // SizedBox(width: 5.w),
                            AppText(
                              text: " - ${formatTime(reservation.time)}",
                              size: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: appTextColor5,
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                rejectedDetailsIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(groupIcon, width: 18.w),
                            ),
                            SizedBox(width: 5.w),
                            AppText(
                              text: "${reservation.people} ",
                              size: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: appTextColor5,
                            ),
                            AppText(
                              text: reservation.people > 1
                                  ? "Persons"
                                  : "Person",
                              size: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: appTextColor5,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: "${formatDate(reservation.date)}",
                        size: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: appTextColor5,
                      ),
                      SizedBox(height: 5.h),
                      AppText(
                        text: "${formatTime(reservation.time)}",
                        size: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: appTextColor5,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 80.w,
                      height: 25.h,
                      child: AppButton(
                        text: "Call back",
                        onPressed: isCallBackEnabled
                            ? (onCallBackPressed ?? () {})
                            : () {},
                        bgColor1: isCallBackEnabled
                            ? rejectedCallBackIconColor
                            : Colors.grey,
                        bgColor2: isCallBackEnabled
                            ? rejectedCallBackIconColor
                            : Colors.grey,
                        size: 12,
                        borderRadius: 5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}
