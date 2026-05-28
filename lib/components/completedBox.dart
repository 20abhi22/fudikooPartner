import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/rerservation/reservation-completed-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class CompletedBox extends StatelessWidget {
  final ReservationCompletedModel reservation;
  final String? discountPercentage;
  final String? applicableFor;
  final String? dineType;

  const CompletedBox({
    super.key,
    required this.reservation,
    this.discountPercentage,
    this.applicableFor,
    this.dineType,
  });

  String formatDate(String dateString, {String format = "MMM dd"}) {
    try {
      return DateFormat(format).format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  String formatTime(String dateString) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build offer display text same as ProcessingBox
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
    if (applicable.isNotEmpty) secondaryParts.add('for $applicable');
    if (dine.isNotEmpty) secondaryParts.add(dine);
    final secondary = secondaryParts.join(' · ');

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
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 37.w,
            top: 20.h,
            bottom: 20.h,
            right: 20.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reservation ID
                  AppText(
                    text: reservation.reservationId.length >= 6
                        ? reservation.reservationId.substring(0, 6)
                        : reservation.reservationId,
                    size: 20,
                    fontWeight: FontWeight.w700,
                    color: appTextColor5,
                  ),
                  SizedBox(height: 10.h),

                  // Offer row — matches ProcessingBox style
                  Row(
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          processTagIconColor,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          offerIcon,
                          width: 17.3.w,
                          height: 17.3.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      RichText(
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
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),

                  // Date & time row — matches ProcessingBox style
                  Row(
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          processTagIconColor,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          calenderIcon,
                          width: 16.4.w,
                          height: 16.4.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: formatDate(reservation.date),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: appTextColor5,
                              ),
                            ),
                            TextSpan(
                              text: ' - ${reservation.time}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: appTextColor5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),

                  // People row
                  Row(
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          processTagIconColor,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          groupIcon,
                          width: 15.6.w,
                          height: 15.6.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        reservation.people.toString(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: appTextColor5,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      AppText(
                        text: reservation.people == 1 ? 'Person' : 'Persons',
                        size: 14,
                        fontWeight: FontWeight.w500,
                        color: appTextColor5,
                      ),
                    ],
                  ),
                ],
              ),

              // Right column: createdAt date + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(
                    text: formatDate(reservation.createdAt),
                    size: 10,
                    fontWeight: FontWeight.w700,
                    color: appTextColor2,
                  ),
                  SizedBox(height: 5.h),
                  AppText(
                    text: formatTime(reservation.createdAt),
                    size: 10,
                    fontWeight: FontWeight.w500,
                    color: appTextColor2,
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