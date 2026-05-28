import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class BanquetCompletedBox extends StatelessWidget {
  const BanquetCompletedBox({super.key});

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
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: "P17867",
                        size: 20,
                        fontWeight: FontWeight.bold,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 10.h),
                      Row(
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

                          SizedBox(width: 5.w),

                          Row(
                            children: [
                              AppText(
                                text: '1200',
                                size: 15,
                                fontWeight: FontWeight.w900,
                                color: appTextColor5,
                              ),

                              SizedBox(width: 2.w),

                              AppText(
                                text: 'Per Person',
                                size: 15,
                                fontWeight: FontWeight.w500,
                                color: appTextColor5,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
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

                          Row(
                            children: [
                              AppText(
                                text: '5%',
                                size: 15,
                                fontWeight: FontWeight.w700,
                                color: appTextColor5,
                              ),

                              SizedBox(width: 2.w),

                              AppText(
                                text: 'on extra drinks',
                                size: 15,
                                fontWeight: FontWeight.w500,
                                color: appTextColor5,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
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

                          SizedBox(width: 5.w),

                          Row(
                            children: [
                              AppText(
                                text: '20',
                                size: 15,
                                fontWeight: FontWeight.w700,
                                color: appTextColor5,
                              ),

                              SizedBox(width: 2.w),

                              AppText(
                                text: 'Person',
                                size: 15,
                                fontWeight: FontWeight.w500,
                                color: appTextColor5,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: "Apr 09",
                        size: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 5),
                      AppText(
                        text: "08:30 AM",
                        size: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                    ],
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
