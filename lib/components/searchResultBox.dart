import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/rerservation/reservation-search-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class SearchResultBox extends StatelessWidget {
  final ReservationSearchModel reservation;

  const SearchResultBox({super.key, required this.reservation});

  String formatDate(String dateString, {String format = "MMM dd"}) {
    try {
      return DateFormat(format).format(DateTime.parse(dateString));
    } catch (_) {
      return dateString;
    }
  }

  String formatTime(String dateString) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(dateString));
    } catch (_) {
      return dateString;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final discountRaw = reservation.discountPercentage ?? '';
    String discountText = '';
    if (discountRaw.isNotEmpty) {
      discountText = discountRaw.contains('.')
          ? discountRaw.split('.').first
          : discountRaw;
      discountText = '$discountText%';
    }

    final applicable = reservation.applicableFor ?? '';
    final dine = reservation.dineType ?? '';

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID + status badge
                    Row(
                      children: [
                        AppText(
                          text: reservation.reservationId.length >= 6
                              ? reservation.reservationId.substring(0, 6)
                              : reservation.reservationId,
                          size: 20,
                          fontWeight: FontWeight.w700,
                          color: appTextColor3,
                        ),
                        SizedBox(width: 10.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: _statusColor(reservation.status)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            reservation.status,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(reservation.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // Offer row
                    Row(
                      children: [
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                              processTagIconColor, BlendMode.srcIn),
                          child: Image.asset(offerIcon,
                              width: 17.3.w,
                              height: 17.3.w,
                              fit: BoxFit.contain),
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

                    // Date & time row
                    Row(
                      children: [
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                              processTagIconColor, BlendMode.srcIn),
                          child: Image.asset(calenderIcon,
                              width: 16.4.w,
                              height: 16.4.w,
                              fit: BoxFit.contain),
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
                              processTagIconColor, BlendMode.srcIn),
                          child: Image.asset(groupIcon,
                              width: 15.6.w,
                              height: 15.6.w,
                              fit: BoxFit.contain),
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
                          text:
                              reservation.people == 1 ? 'Person' : 'Persons',
                          size: 14,
                          fontWeight: FontWeight.w500,
                          color: appTextColor5,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(
                    text: formatDate(reservation.createdAt),
                    size: 10,
                    fontWeight: FontWeight.w700,
                    color: appTextColor3,
                  ),
                  SizedBox(height: 5.h),
                  AppText(
                    text: formatTime(reservation.createdAt),
                    size: 10,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
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