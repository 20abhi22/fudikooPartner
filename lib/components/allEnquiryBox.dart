import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/banquet/all-enquiry-model.dart';
import 'package:fudiko/screens/others/offerSendPage.dart';
import 'package:fudiko/services/banquet-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:intl/intl.dart';
import 'package:fudiko/services/badge_controller.dart';

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
      // refresh global badges when an enquiry is saved
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
        // refresh global badges when an enquiry is deleted
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
        // height: 259.h, not giving as menu increases the height and it looks bad with fixed height
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
                        // AppText(
                        //   text: e.enquiryId,
                        //   size: 20,
                        //   fontWeight: FontWeight.bold,
                        //   color: appTextColor3,
                        // ),
                        Row(
                          children: [
                            Flexible(
                              child: AppText(
                                text: e.enquiryId,
                                size: 20,
                                fontWeight: FontWeight.bold,
                                color: appTextColor3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: isMobile ? 8.w : 8),
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
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                            SizedBox(width: gap),
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
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: formatDate(e.date),
                                      style: TextStyle(
                                        fontSize: isMobile ? 14.sp : 15,
                                        fontWeight: FontWeight.w700,
                                        color: appTextColor5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' - ${formatTime(e.time)}',
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
                                width: smallIconSize,
                                height: smallIconSize,
                              ),
                            ),
                            SizedBox(width: gap),
                            Flexible(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        text: formatDate(e.date),
                        size: 10,
                        fontWeight: FontWeight.w600,
                        color: appTextColor3,
                      ),
                      SizedBox(height: 5),
                      AppText(
                        text: formatDate(e.time),
                        size: 10,
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
                            confirmColor: const Color(0xFF73B256),
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
                            width: actionIconSize,
                            height: actionIconSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // child: Icon(
                        //   Icons.delete,
                        //   color: Colors.red,
                        //   size: 20.w,
                        // ),
                      ),
                      SizedBox(width: isMobile ? 5.w : 6.0),
                      if (widget.showSaveIcon) ...[
                        GestureDetector(
                          onTap: () {
                            _showConfirmDialog(
                              title:
                                  'Are you sure you want to save this enquiry?',
                              message:
                                  'Saving will move this enquiry to the saved list for later follow-up.',
                              confirmText: 'Yes',
                              confirmColor: const Color(0xFF73B256),
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
                              width: actionIconSize,
                              height: actionIconSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // child: Icon(
                          //   Icons.bookmark,
                          //   color: appButtonColor2,
                          //   size: 20.w,
                          // ),
                        ),
                        SizedBox(width: isMobile ? 5.w : 6.0),
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
                      // GestureDetector(
                      //   onTap: (){
                      //   slideRightWidget(newPage: const Profile(), context: context);
                      // },
                      //   // onTap: () async {
                      //   //   final detail = await BanquetEnquiryService()
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
                      //           // fit: BoxFit.contain,
                      //         ),
                      //       ),
                      //       AppText(
                      //         text: "Details",
                      //         size: 13.sp,
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
