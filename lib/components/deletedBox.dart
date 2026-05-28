import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class DeletedBox extends StatefulWidget {
  final dynamic enquiry;
  final VoidCallback? onCallBackPressed;
  final VoidCallback? onActionCompleted;

  const DeletedBox({
    super.key,
    required this.enquiry,
    this.onCallBackPressed,
    this.onActionCompleted,
  });

  @override
  State<DeletedBox> createState() => _DeletedBoxState();
}

class _DeletedBoxState extends State<DeletedBox> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  bool get _isExpired => _remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    try {
      final expiry = DateFormat("yyyy-MM-dd hh:mm a").parse(
        "${widget.enquiry.expirationDate} ${widget.enquiry.expirationTime}",
      );
      final now = DateTime.now();

      if (expiry.isAfter(now)) {
        setState(() {
          _remaining = expiry.difference(now);
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          final difference = expiry.difference(DateTime.now());
          if (difference.isNegative) {
            _timer?.cancel();
            setState(() {
              _remaining = Duration.zero;
            });
          } else {
            setState(() {
              _remaining = difference;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Timer error: $e');
    }
  }

  String get _timerText {
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatDate(String dateString, {String format = "MMM dd"}) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat(format).format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
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
        width: double.infinity,
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
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: widget.enquiry.enquiryId,
                    size: 24,
                    fontWeight: FontWeight.w700,
                    color: rejectedTitleTextColor,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: _formatDate(widget.enquiry.date),
                        size: 12,
                        fontWeight: FontWeight.w600,
                        color: rejectedTitleTextColor,
                      ),
                      AppText(
                        text: _formatTime(widget.enquiry.time),
                        size: 11,
                        fontWeight: FontWeight.w400,
                        color: rejectedTitleTextColor,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      rejectedDetailsIconColor,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(walletIcon, width: 18.w),
                  ),
                  SizedBox(width: 8.w),
                  AppText(
                    text: "${widget.enquiry.estimatedAmount} Per person",
                    size: 18,
                    fontWeight: FontWeight.w700,
                    color: appTextColor5,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      rejectedDetailsIconColor,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(calenderIcon, width: 18.w),
                  ),
                  SizedBox(width: 8.w),
                  AppText(
                    text:
                        "${_formatDate(widget.enquiry.date)} - ${_formatTime(widget.enquiry.time)}",
                    size: 14,
                    fontWeight: FontWeight.w500,
                    color: appTextColor5,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      rejectedDetailsIconColor,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(groupIcon, width: 18.w),
                  ),
                  SizedBox(width: 8.w),
                  AppText(
                    text:
                        "${widget.enquiry.people} ${widget.enquiry.people == 1 ? 'Person' : 'Persons'}",
                    size: 14,
                    fontWeight: FontWeight.w500,
                    color: appTextColor5,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      rejectedDetailsIconColor,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(menuIcon, width: 18.w),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: AppText(
                      text: widget.enquiry.menuItems,
                      size: 14,
                      fontWeight: FontWeight.w400,
                      color: appTextColor5,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFED4444),
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          stopWatchIcon,
                          width: 17.w,
                          height: 17.h,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      AppText(
                        text: _timerText,
                        size: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFED4444),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 120.w,
                    height: 25.h,
                    child: AppButton(
                      text: "Call back",
                      onPressed: widget.onCallBackPressed ?? () {},
                      bgColor1: rejectedCallBackIconColor,
                      bgColor2: rejectedCallBackIconColor,
                      size: 12,
                      borderRadius: 8,
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
