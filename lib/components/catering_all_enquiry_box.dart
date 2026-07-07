import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/catering/all-enquiry-model.dart';
import 'package:fudiko/screens/others/OfferCateringSendpage.dart';
import 'package:fudiko/services/catering-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:intl/intl.dart';
import 'package:fudiko/services/badge_controller.dart';

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
      // refresh badges when catering enquiry saved
      BadgeController.instance.refresh();
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
        // refresh badges when catering enquiry deleted
        BadgeController.instance.refresh();
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final screenWidth = screenSize.width;
        final isWideShortPhone =
            Breakpoints.isMobile(screenWidth) &&
            screenWidth >= 500 &&
            screenSize.height <= 760;
        final isMobile = Breakpoints.isMobile(screenWidth) && !isWideShortPhone;
        final dialogMaxWidth = isMobile ? double.infinity : 420.0;
        final dialogRadius = isMobile ? 15.r : 15.0;
        final horizontalPadding = isMobile ? 34.w : 36.0;
        final verticalPadding = isMobile ? 28.h : 26.0;
        final buttonHeight = isMobile ? 35.h : 36.0;
        final buttonGap = isMobile ? 20.w : 18.0;
        final buttonRadius = isMobile ? 5.r : 5.0;
        final buttonTextSize = isMobile ? 12.sp : 12.0;
        final contentGap = isMobile ? 20.h : 18.0;
        final questionText = title.trim().endsWith('?') ? title : message;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20.w : 24.0,
            vertical: isMobile ? 40.h : 40.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogMaxWidth),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(dialogRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: questionText,
                    size: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    isCentered: true,
                    softWrap: true,
                    maxLines: 2,
                  ),
                  SizedBox(height: contentGap),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: AppButton(
                            text: confirmText,
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await onConfirm();
                            },
                            borderRadius: buttonRadius,
                            bgColor1: confirmColor,
                            bgColor2: confirmColor,
                            size: buttonTextSize,
                          ),
                        ),
                      ),
                      SizedBox(width: buttonGap),
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: AppButton(
                            text: "No",
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            size: buttonTextSize,
                            borderRadius: buttonRadius,
                            bgColor1: const Color(0xFFCE3F3F),
                            bgColor2: const Color(0xFFCE3F3F),
                          ),
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

  Future<void> _confirmAndSave() async {
    await _showConfirmDialog(
      title: 'Are you sure you want to save this enquiry?',
      message: 'Are you sure you want to save this enquiry?',
      confirmText: 'Yes',
      confirmColor: const Color(0xFF73B256),
      onConfirm: _saveEnquiry,
    );
  }

  Future<void> _confirmAndDelete() async {
    await _showConfirmDialog(
      title: 'Are you sure you want to delete this enquiry?',
      message: 'Are you sure you want to delete this enquiry?',
      confirmText: 'Yes',
      confirmColor: const Color(0xFF73B256),
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
        final iconSize = isMobile ? 17.w : 18.0;
        final smallIconSize = isMobile ? 16.w : 18.0;
        final gap = isMobile ? 5.w : 6.0;
        final actionIconSize = isMobile ? 22.w : 22.0;
        final buttonWidth = isMobile ? 150.w : 168.0;
        final buttonHeight = isMobile ? 35.h : 36.0;

        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 20.h : 18),
          child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 20.r : 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: const Offset(0, 4),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: cardPadding,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: FutureBuilder<String>(
                                future: TranslatorService.translate(
                                  'rupees Per Person',
                                ),
                                builder: (context, snapshot) {
                                  final translated =
                                      snapshot.data ?? 'rupees Per Person';

                                  return RichText(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: e.estimatedAmount,
                                          style: TextStyle(
                                            fontSize: isMobile ? 14.sp : 15,
                                            fontWeight: FontWeight.w700,
                                            color: appTextColor5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' $translated',
                                          style: TextStyle(
                                            fontSize: isMobile ? 14.sp : 15,
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
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _formatDate(e.date),
                                      style: TextStyle(
                                        fontSize: isMobile ? 14.sp : 15,
                                        fontWeight: FontWeight.w700,
                                        color: appTextColor5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' - ${_formatTime(e.time)}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 15.sp : 15,
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
                                width: smallIconSize,
                                height: smallIconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    '${e.people}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 14.sp : 15,
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
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: FutureBuilder<String>(
                                future: TranslatorService.translate(
                                  e.otherServices.isNotEmpty
                                      ? e.otherServices
                                      : 'Needs to be added',
                                ),
                                builder: (context, snapshot) {
                                  return AppText(
                                    text: snapshot.data ?? 'Needs to be added',
                                    size: 15,
                                    fontWeight: FontWeight.w500,
                                    color: appTextColor5,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                  width: iconSize,
                                  height: iconSize,
                                ),
                              ),
                              SizedBox(width: gap),
                              Expanded(
                                child: AppText(
                                  text: e.menuItems,
                                  size: isMobile ? 13 : 14,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor5,
                                  maxLines: isMobile ? 3 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 10.w : 12),
                  SizedBox(
                    width: isMobile ? 70.w : 88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          text: _formatDate(e.date),
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5.h),
                        AppText(
                          text: _formatTime(e.time),
                          size: 10,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
                            width: actionIconSize,
                            height: actionIconSize,
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 5.w : 6.0),
                      if (widget.showSaveIcon) ...[
                        GestureDetector(
                          onTap: _confirmAndSave,
                          child: Image.asset(
                            enquiryboxSaveIcon,
                            width: actionIconSize,
                            height: actionIconSize,
                          ),
                        ),
                        SizedBox(width: isMobile ? 5.w : 6.0),
                      ],
                      // GestureDetector(
                      //   // onTap: () async {
                      //   //   final detail = await CateringEnquiryService()
                      //   //       .showEnquiry(widget.enquiry.uuid);
                      //   //   if (!mounted) return;
                      //   //   showDialog(
                      //   //     context: context,
                      //   //     builder: (context) => Dialog(
                      //   //       backgroundColor: Colors.white,
                      //   //       shape: RoundedRectangleBorder(
                      //   //         borderRadius: BorderRadius.circular(16.r),
                      //   //       ),
                      //   //       child: Padding(
                      //   //         padding: EdgeInsets.all(20.w),
                      //   //         child: Column(
                      //   //           mainAxisSize: MainAxisSize.min,
                      //   //           crossAxisAlignment: CrossAxisAlignment.start,
                      //   //           children: [
                      //   //             AppText(
                      //   //               text: detail.enquiryId,
                      //   //               size: 18,
                      //   //               fontWeight: FontWeight.bold,
                      //   //               color: appTextColor3,
                      //   //             ),
                      //   //             SizedBox(height: 12.h),
                      //   //             _detailRow("Date", detail.date),
                      //   //             _detailRow("Time", detail.time),
                      //   //             _detailRow(
                      //   //               "People",
                      //   //               detail.people.toString(),
                      //   //             ),
                      //   //             _detailRow("Menu", detail.menuItems),
                      //   //             _detailRow(
                      //   //               "Estimated",
                      //   //               detail.estimatedAmount,
                      //   //             ),
                      //   //             _detailRow("Status", detail.status),
                      //   //             _detailRow(
                      //   //               "Expires",
                      //   //               "${detail.expirationDate} ${detail.expirationTime}",
                      //   //             ),
                      //   //             SizedBox(height: 16.h),
                      //   //             Align(
                      //   //               alignment: Alignment.centerRight,
                      //   //               child: TextButton(
                      //   //                 onPressed: () => Navigator.pop(context),
                      //   //                 child: AppText(
                      //   //                   text: "Close",
                      //   //                   size: 14,
                      //   //                   fontWeight: FontWeight.w400,
                      //   //                   color: appButtonColor,
                      //   //                 ),
                      //   //               ),
                      //   //             ),
                      //   //           ],
                      //   //         ),
                      //   //       ),
                      //   //     ),
                      //   //   );
                      //   // },
                      //   onTap: (){
                      //   slideRightWidget(newPage: const Profile(), context: context);
                      // },
                      //   child: Row(
                      //     children: [
                      //       ColorFiltered(
                      //         colorFilter: ColorFilter.mode(
                      //           processDetailsIconColor,
                      //           BlendMode.srcIn,
                      //         ),
                      //         child: Image.asset(
                      //           detailsIcon,
                      //           width: 15.w,
                      //           height: 15.h,
                      //         ),
                      //       ),
                      //       AppText(
                      //         text: " Details",
                      //         size: 15,
                      //         fontWeight: FontWeight.w400,
                      //         color: processDetailsIconColor,
                      //       ),
                      //     ],
                      //   ),
                      // ),
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
                              width: isMobile ? 17.w : 17,
                              height: isMobile ? 17.h : 17,
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
                        width: buttonWidth,
                        height: buttonHeight,
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
                          size: isMobile ? 13.sp : 13,
                          borderRadius: isMobile ? 8.r : 8,
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
      },
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
