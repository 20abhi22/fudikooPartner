import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:intl/intl.dart';

class ConfirmedBox extends StatefulWidget {
  final VoidCallback? deleteOnPressed;
  final VoidCallback? onAcceptPressed;
  final int id;
  final String uuid;
  final String reservationId;
  final String userId;
  final int people;
  final String restaurantId;
  final String time;
  final String date;
  final String offerCode;
  final String offerCodeStatus;
  final String? discountPercentage;
  final String? applicableFor;
  final String? dineType;
  final String? startTime;
  final String? endTime;
  final String? activeDays;
  final String status;
  final String createdAt;
  final String updatedAt;
  const ConfirmedBox({
    super.key,
    this.deleteOnPressed,
    this.onAcceptPressed,
    required this.id,
    required this.uuid,
    required this.reservationId,
    required this.userId,
    required this.people,
    required this.restaurantId,
    required this.time,
    required this.date,
    required this.offerCode,
    required this.offerCodeStatus,
    this.discountPercentage,
    this.applicableFor,
    this.dineType,
    this.startTime,
    this.endTime,
    this.activeDays,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  State<ConfirmedBox> createState() => _ConfirmedBoxState();
}

class _ConfirmedBoxState extends State<ConfirmedBox> {
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

  void _showDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: ' ${widget.reservationId}',
                size: 18,
                fontWeight: FontWeight.bold,
                color: appTextColor3,
              ),
              SizedBox(height: 12.h),
              _detailRow('Offer Code', widget.offerCode),
              _detailRow('Date', formatDate(widget.date)),
              _detailRow('Time', widget.time),
              _detailRow('People', widget.people.toString()),
              _detailRow('Offer Status', widget.offerCodeStatus),
              _detailRow('Status', widget.status),
              _detailRow(
                'Created',
                formatDate(widget.createdAt, format: 'dd MMM yyyy, hh:mm a'),
              ),
              SizedBox(height: 16.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: AppText(
                    text: 'Close',
                    color: appButtonColor,
                    size: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              offset: const Offset(0, 0),
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
                          text: '${widget.reservationId}',
                          size: 20,
                          fontWeight: FontWeight.w700,
                          color: appTextColor3,
                        ),
                        SizedBox(height: 10.h),
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
                            Flexible(
                              child: Builder(
                                builder: (context) {
                                  final discountRaw =
                                      widget.discountPercentage ?? '';
                                  String discountText = '';
                                  if (discountRaw.isNotEmpty) {
                                    discountText = discountRaw.contains('.')
                                        ? discountRaw.split('.').first
                                        : discountRaw;
                                    discountText = '${discountText}%';
                                  }
                                                  
                                  final applicable = widget.applicableFor ?? '';
                                  final dine = widget.dineType ?? '';
                                  final start = widget.startTime ?? '';
                                  final end = widget.endTime ?? '';
                                                  
                                  final primary = discountText.isNotEmpty
                                      ? discountText
                                      : (widget.offerCode.isNotEmpty
                                            ? widget.offerCode
                                            : 'No Offer');
                                                  
                                  final secondaryParts = <String>[];
                                  if (applicable.isNotEmpty)
                                    secondaryParts.add('for $applicable');
                                  if (dine.isNotEmpty) secondaryParts.add(dine);
                                  if (start.isNotEmpty || end.isNotEmpty) {
                                    final times = [
                                      if (start.isNotEmpty) start,
                                      if (end.isNotEmpty) end,
                                    ].join(' - ');
                                    secondaryParts.add(times);
                                  }
                                                  
                                  final secondary = secondaryParts.join(' · ');
                                                  
                                  return FutureBuilder<List<String>>(
                                    future: Future.wait([
                                      TranslatorService.translate(primary),
                                      TranslatorService.translate(secondary),
                                    ]),
                                    builder: (context, snapshot) {
                                      final translatedPrimary =
                                          snapshot.data?[0] ?? primary;
                                                  
                                      final translatedSecondary =
                                          snapshot.data?[1] ?? secondary;
                                                  
                                      return RichText(
                                        maxLines: 2,           // ← add
                overflow: TextOverflow.ellipsis,  // ← add
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: translatedPrimary,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w700,
                                                color: appTextColor5,
                                              ),
                                            ),
                                                  
                                            if (translatedSecondary.isNotEmpty)
                                              TextSpan(
                                                text: ' $translatedSecondary',
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
                                    text: formatDate(widget.date),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: appTextColor5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' - ${widget.time}',
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
                            Row(
                              children: [
                                Text(
                                  widget.people.toString(),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: appTextColor5,
                                  ),
                                ),
                    
                                SizedBox(width: 2.w),
                    
                                AppText(
                                  text: widget.people == 1 ? 'Person' : 'Persons',
                    
                                  size: 14,
                    
                                  fontWeight: FontWeight.w500,
                    
                                  color: appTextColor5,
                                ),
                              ],
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
                        text: formatDate(widget.createdAt),
                        size: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 5.h),
                      AppText(
                        text: formatTime(widget.createdAt),
                        size: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 15.h),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _showDetailsDialog,
                      child: Row(
                        children: [
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              confirmedDetailsIconColor,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              detailsIcon,
                              width: 15.w,
                              height: 15.w,
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          AppText(
                            text: "Details",
                            size: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: confirmedDetailsIconColor,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: 75.w,
                      height: 25.h,
                      child: AppButton(
                        text: "Remind",
                        onPressed: widget.onAcceptPressed ?? () {},
                        bgColor1: confirmedRemindIconColor,
                        bgColor2: confirmedRemindIconColor,
                        size: 12,
                        borderRadius: 5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: '$label: ',
            size: 12,
            fontWeight: FontWeight.w600,
            color: appTextColor2,
          ),
          Expanded(
            child: AppText(
              text: value,
              size: 12,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
            ),
          ),
        ],
      ),
    );
  }
}
