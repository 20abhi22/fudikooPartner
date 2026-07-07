import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
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
        final iconSize = isMobile ? 18.w : 18.0;
        final gap = isMobile ? 8.w : 8.0;
        final buttonWidth = isMobile ? 120.w : 118.0;
        final buttonHeight = isMobile ? 25.h : 32.0;

        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 20.h : 18),
          child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 17.r : 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppText(
                      text: widget.enquiry.enquiryId,
                      size: isMobile ? 24 : 21,
                      fontWeight: FontWeight.w700,
                      color: rejectedTitleTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: isMobile ? 10.w : 12),
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
                      banquetTagIconColor,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(walletIcon, width: iconSize),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: AppText(
                      text: "${widget.enquiry.estimatedAmount} Per person",
                      size: isMobile ? 18 : 15,
                      fontWeight: FontWeight.w700,
                      color: appTextColor5,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    child: Image.asset(calenderIcon, width: iconSize),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: AppText(
                      text:
                          "${_formatDate(widget.enquiry.date)} - ${_formatTime(widget.enquiry.time)}",
                      size: 14,
                      fontWeight: FontWeight.w500,
                      color: appTextColor5,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    child: Image.asset(groupIcon, width: iconSize),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: AppText(
                      text:
                          "${widget.enquiry.people} ${widget.enquiry.people == 1 ? 'Person' : 'Persons'}",
                      size: 14,
                      fontWeight: FontWeight.w500,
                      color: appTextColor5,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      banquetTagIconColor,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(menuIcon, width: iconSize),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: AppText(
                      text: widget.enquiry.menuItems,
                      size: 14,
                      fontWeight: FontWeight.w400,
                      color: appTextColor5,
                      maxLines: isMobile ? null : 3,
                      overflow: isMobile ? null : TextOverflow.ellipsis,
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
                          width: isMobile ? 17.w : 17,
                          height: isMobile ? 17.h : 17,
                        ),
                      ),
                      SizedBox(width: isMobile ? 5.w : 6),
                      AppText(
                        text: _timerText,
                        size: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFED4444),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: AppButton(
                      text: "Call back",
                      onPressed: widget.onCallBackPressed ?? () {},
                      bgColor1: rejectedCallBackIconColor,
                      bgColor2: rejectedCallBackIconColor,
                      size: 12,
                      borderRadius: isMobile ? 8 : 5,
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
