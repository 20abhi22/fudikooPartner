import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/catering/all-enquiry-model.dart';
import 'package:fudiko/screens/others/OfferCateringSendpage.dart';
import 'package:fudiko/services/catering-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:intl/intl.dart';

class CateringAllEnquiryBox extends StatefulWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onActionCompleted;
  final CateringEnquiryModel enquiry;
  final bool showSaveIcon;
  const CateringAllEnquiryBox({
    super.key,
    this.onPressed,
    this.onActionCompleted,
    required this.enquiry,
    this.showSaveIcon = true,
  });

  @override
  State<CateringAllEnquiryBox> createState() => _CateringAllEnquiryBoxState();
}

class _CateringAllEnquiryBoxState extends State<CateringAllEnquiryBox> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  // final CateringEnquiryService _service = CateringEnquiryService();

  bool get _isExpired => _remaining == Duration.zero;

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
      // ignore
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
      final result = await CateringEnquiryService().saveEnquiry(
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
      final result = await CateringEnquiryService().deleteEnquiry(
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

  Future<void> _confirmAndSave() async {
    await _showConfirmDialog(
      title: 'Save Enquiry',
      message: 'Are you sure you want to save this enquiry?',
      confirmText: 'Save',
      confirmColor: appButtonColor,
      onConfirm: _saveEnquiry,
    );
  }

  Future<void> _confirmAndDelete() async {
    await _showConfirmDialog(
      title: 'Delete Enquiry',
      message:
          'Are you sure you want to delete this enquiry? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: const Color(0xFFE05B5B),
      onConfirm: _deleteEnquiry,
    );
  }

  String _formatDate(String? rawDate, {String format = "MMM dd"}) {
    if (rawDate == null) return '';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat(format).format(parsed);
    } catch (e) {
      return rawDate;
    }
  }

  String _formatTime(String? rawTime) {
    if (rawTime == null) return '';
    try {
      final parsed = DateTime.parse(rawTime);
      return DateFormat('hh:mm a').format(parsed);
    } catch (e) {
      return rawTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enquiry;
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
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
                          text: e.enquiryId,
                          size: 20,
                          fontWeight: FontWeight.w700,
                          color: appTextColor3,
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
                              child: Image.asset(
                                walletIcon,
                                width: 17.w,
                                height: 17.h,
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

                                  return Row(
                                    children: [
                                      AppText(
                                        text: e.estimatedAmount,
                                        size: 14,
                                        fontWeight: FontWeight.w700,
                                        color: appTextColor5,
                                      ),

                                      SizedBox(width: 3.w),

                                      AppText(
                                        text: translated,
                                        size: 14,
                                        fontWeight: FontWeight.w500,
                                        color: appTextColor5,
                                      ),
                                    ],
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
                                      text: _formatDate(e.date),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: appTextColor5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' - ${_formatTime(e.time)}',
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
                                writingIcon,
                                width: 18.w,
                                height: 17.h,
                              ),
                            ),
                            SizedBox(width: 5.h),
                            Flexible(
                              child: FutureBuilder<String>(
                                future: TranslatorService.translate(
                                  'Needs to be added',
                                ),
                                builder: (context, snapshot) {
                                  return AppText(
                                    text: snapshot.data ?? 'Needs to be added',
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor5,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        if (e.menuItems.isNotEmpty)
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
                              SizedBox(width: 5.w),
                              Expanded(
                                child: AppText(
                                  text: e.menuItems,
                                  size: 13.sp,
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
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: _formatDate(e.date),
                        size: 10,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 5.h),
                      AppText(
                        text: _formatTime(e.time),
                        size: 10,
                        fontWeight: FontWeight.w600,
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
                        onTap: _confirmAndDelete,
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
                      ),
                      SizedBox(width: 5.w),
                      if (widget.showSaveIcon) ...[
                        GestureDetector(
                          onTap: _confirmAndSave,
                          child: Image.asset(
                            enquiryboxSaveIcon,
                            width: 26.w,
                            height: 26.h,
                          ),
                        ),
                        SizedBox(width: 5.w),
                      ],
                      GestureDetector(
                        onTap: () async {
                          final detail = await CateringEnquiryService()
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
                              ),
                            ),
                            AppText(
                              text: " Details",
                              size: 15,
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
                      // SizedBox(
                      //   width: 150.w,
                      //   height: 35.h,
                      //   child: AppButton(
                      //     text: "Offer Discount",
                      //     onPressed: () {},
                      //     bgColor1: appToggleColor,
                      //     bgColor2: appToggleColor,
                      //     size: 12,
                      //     borderRadius: 5,
                      //   ),
                      // ),
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
                                      builder: (context) =>
                                          OfferCateringSendPage(
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
