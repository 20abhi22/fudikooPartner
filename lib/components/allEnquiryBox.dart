import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/banquet/all-enquiry-model.dart';
import 'package:fudiko/screens/others/offerSendPage.dart';
import 'package:fudiko/services/banquet-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:intl/intl.dart';

class AllEnquiryBox extends StatefulWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onActionCompleted;
  final BanquetEnquiryModel enquiry;
  final bool showSaveIcon;
  const AllEnquiryBox({
    super.key,
    this.onPressed,
    this.onActionCompleted,
    required this.enquiry,
    this.showSaveIcon = true,
  });

  @override
  State<AllEnquiryBox> createState() => _AllEnquiryBoxState();
}

class _AllEnquiryBoxState extends State<AllEnquiryBox> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool get _isExpired => _remaining == Duration.zero;

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
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    try {
      final format = DateFormat("yyyy-MM-dd hh:mm a");
      final expiry = format.parse(
        "${widget.enquiry.expirationDate} ${widget.enquiry.expirationTime}",
      );
      final now = DateTime.now();
      if (expiry.isAfter(now)) {
        setState(() => _remaining = expiry.difference(now));
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          final diff = expiry.difference(DateTime.now());
          if (diff.isNegative) {
            _timer?.cancel();
            setState(() => _remaining = Duration.zero);
          } else {
            setState(() => _remaining = diff);
          }
        });
      }
    } catch (e) {
      print('Timer error: $e');
    }
  }

  String get _timerText {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveEnquiry() async {
    try {
      final result = await BanquetEnquiryService().saveEnquiry(
        widget.enquiry.uuid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            text: result['message'] ?? "Saved",
            size: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
      if (result['status'] == true) widget.onActionCompleted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            text: "Error saving enquiry",
            size: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }
  }

  Future<void> _deleteEnquiry() async {
    try {
      final result = await BanquetEnquiryService().deleteEnquiry(
        widget.enquiry.uuid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            text: result['message'] ?? "Deleted",
            size: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
      if (result['status'] == true) {
        widget.onPressed?.call();
        widget.onActionCompleted?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            text: "Error deleting enquiry",
            size: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }
  }

  Future<void> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 40.w,
              right: 40.w,
              top: 30.h,
              bottom: 30.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: title,
                  size: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  isCentered: true,
                  softWrap: true,
                ),
                SizedBox(height: 10.h),
                AppText(
                  text: message,
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  isCentered: true,
                  softWrap: true,
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 35.h,
                        child: AppButton(
                          text: confirmText,
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await onConfirm();
                          },
                          borderRadius: 5.r,
                          bgColor1: confirmColor,
                          bgColor2: confirmColor,
                          size: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: SizedBox(
                        height: 35.h,
                        child: AppButton(
                          text: "No",
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          size: 12,
                          borderRadius: 5.r,
                          bgColor1: Colors.red,
                          bgColor2: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enquiry;
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        // height: 259.h, not giving as menu increases the height and it looks bad with fixed height
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10), // 10% opacity
              offset: Offset(0, 0), // X, Y
              blurRadius: 10, // Blur
              spreadRadius: 2, // Spread
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
                        // AppText(
                        //   text: e.enquiryId,
                        //   size: 20,
                        //   fontWeight: FontWeight.bold,
                        //   color: appTextColor3,
                        // ),
                        Row(
                          children: [
                            AppText(
                              text: e.enquiryId,
                              size: 20,
                              fontWeight: FontWeight.bold,
                              color: appTextColor3,
                            ),
                            SizedBox(width: 8.w),
                            // if (_isExpired)
                            //   Container(
                            //     padding: EdgeInsets.symmetric(
                            //       horizontal: 8.w,
                            //       vertical: 2.h,
                            //     ),
                            //     decoration: BoxDecoration(
                            //       color: Colors.red.withOpacity(0.1),
                            //       borderRadius: BorderRadius.circular(8.r),
                            //       border: Border.all(
                            //         color: Colors.red,
                            //         width: 1,
                            //       ),
                            //     ),
                            //     child: AppText(
                            //       text: "Expired",
                            //       size: 10,
                            //       fontWeight: FontWeight.w600,
                            //       color: Colors.red,
                            //     ),
                            //   ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon(
                            //   Icons.wallet_rounded,
                            //   color: appTextColor5,
                            //   size: 18.w,
                            // ),
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
                            Flexible(
                              child: FutureBuilder<String>(
                                future: TranslatorService.translate(
                                  'rupees Per Person',
                                ),
                                builder: (context, snapshot) {
                                  final translated =
                                      snapshot.data ?? 'rupees Per Person';

                                  return RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: e.estimatedAmount,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: appTextColor5,
                                          ),
                                        ),

                                        TextSpan(
                                          text: ' $translated',
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
                        SizedBox(height: 10.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon(
                            //   Icons.calendar_month_rounded,
                            //   color: appTextColor5,
                            //   size: 18.w,
                            // ),
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                banquetTagIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                calenderIcon,
                                width: 17.w,
                                height: 17.h,
                              ),
                            ),
                            SizedBox(width: 5.h),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: formatDate(e.date),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: appTextColor5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' - ${formatTime(e.time)}',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                        color: appTextColor5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon(
                            //   Icons.groups,
                            //   color: appTextColor5,
                            //   size: 18.w,
                            // ),
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
                            Flexible(
                              child: Row(
                                children: [
                                  Text(
                                    '${e.people}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: appTextColor5,
                                    ),
                                  ),

                                  SizedBox(width: 2.w),

                                  AppText(
                                    text: e.people == 1 ? 'Person' : 'Persons',

                                    size: 14,

                                    fontWeight: FontWeight.w500,

                                    color: appTextColor5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon(
                            //   Icons.fastfood,
                            //   color: appTextColor5,
                            //   size: 18.w,
                            // ),
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
                            SizedBox(width: 5.w),
                            Expanded(
                              child: AppText(
                                text: e.menuItems,
                                size: 13,
                                fontWeight: FontWeight.w400,
                                color: appTextColor5,

                                softWrap: true, //good
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: formatDate(e.date),
                        size: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 5),
                      AppText(
                        text: formatDate(e.time),
                        size: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: appTextColor3,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showConfirmDialog(
                            title:
                                'Are you sure you want to delete this enquiry?',
                            message:
                                'This action will remove the enquiry from the list permanently.',
                            confirmText: 'Yes',
                            confirmColor: Colors.green,
                            onConfirm: _deleteEnquiry,
                          );
                        },
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Color(0xFFE05B5B),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            enquiryboxDeleteIcon,
                            width: 20.w,
                            height: 20.h,
                          ),
                        ),
                        // child: Icon(
                        //   Icons.delete,
                        //   color: Colors.red,
                        //   size: 20.w,
                        // ),
                      ),
                      SizedBox(width: 5.w),
                      if (widget.showSaveIcon) ...[
                        GestureDetector(
                          onTap: () {
                            _showConfirmDialog(
                              title:
                                  'Are you sure you want to save this enquiry?',
                              message:
                                  'Saving will move this enquiry to the saved list for later follow-up.',
                              confirmText: 'Yes',
                              confirmColor: appButtonColor,
                              onConfirm: _saveEnquiry,
                            );
                          },
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Color(0xFFD37F25),
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              enquiryboxSaveIcon,
                              width: 26.w,
                              height: 26.h,
                            ),
                          ),
                          // child: Icon(
                          //   Icons.bookmark,
                          //   color: appButtonColor2,
                          //   size: 20.w,
                          // ),
                        ),
                        SizedBox(width: 5.w),
                      ],
                      // Icon(
                      //   Icons.person_search_sharp,
                      //   color: appLinkColor,
                      //   size: 20.w,
                      // ),
                      // AppText(
                      //   text: "Details",
                      //   size: 12,
                      //   fontWeight: FontWeight.w500,
                      //   color: appLinkColor,
                      // ),
                      GestureDetector(
                        onTap: () async {
                          final detail = await BanquetEnquiryService()
                              .showEnquiry(widget.enquiry.uuid);
                          if (!mounted) return;
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
                                      text: detail.enquiryId,
                                      size: 18,
                                      fontWeight: FontWeight.bold,
                                      color: appTextColor3,
                                    ),
                                    SizedBox(height: 12.h),
                                    _detailRow("Date", detail.date),
                                    _detailRow("Time", detail.time),
                                    _detailRow(
                                      "People",
                                      detail.people.toString(),
                                    ),
                                    _detailRow("Menu", detail.menuItems),
                                    _detailRow(
                                      "Estimated",
                                      detail.estimatedAmount,
                                    ),
                                    _detailRow("Status", detail.status),
                                    _detailRow(
                                      "Expires",
                                      "${detail.expirationDate} ${detail.expirationTime}",
                                    ),
                                    SizedBox(height: 16.h),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: AppText(
                                          text: "Close",
                                          size: 14,
                                          fontWeight: FontWeight.w400,
                                          color: appButtonColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                processDetailsIconColor,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                detailsIcon,
                                width: 15.w,
                                height: 15.h,
                                // fit: BoxFit.contain,
                              ),
                            ),
                            AppText(
                              text: "Details",
                              size: 13.sp,
                              fontWeight: FontWeight.w400,
                              color: processDetailsIconColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          // Icon(Icons.timer, color: Colors.red, size: 20.w),
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Color(0xFFED4444),
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              stopWatchIcon,
                              width: 17.w,
                              height: 17.h,
                            ),
                          ),
                          SizedBox(width: 5),
                          AppText(
                            text: _timerText,
                            size: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFED4444),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),

                      SizedBox(
                        width: 150.w,
                        height: 35.h,
                        child: AppButton(
                          text: _isExpired
                              ? "Offer Discount"
                              : "Offer Discount",
                          onPressed: _isExpired
                              ? () {}
                              : () {
                                  Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OfferSendPage(
                                        enquiry: widget.enquiry,
                                      ),
                                    ),
                                  ).then((isSent) {
                                    if (isSent == true) {
                                      widget.onActionCompleted?.call();
                                    }
                                  });
                                },
                          bgColor1: _isExpired
                              ? Colors.grey
                              : banquetOfferIconColor,
                          bgColor2: _isExpired
                              ? Colors.grey
                              : banquetOfferIconColor,
                          size: 13.sp,
                          borderRadius: 8.r,
                        ),
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

  // Add helper inside _AllEnquiryBoxState:
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: "$label: ",
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
