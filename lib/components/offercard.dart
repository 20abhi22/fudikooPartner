import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/offer/offer-status-change-model.dart';
import 'package:fudiko/services/offer-service.dart';
import 'package:fudiko/utils/constants.dart';

class OfferCard extends StatefulWidget {
  final String url;
  final VoidCallback deleteOnTap;
  final VoidCallback editOnTap;
  final String percentage;
  final String applicableFor;
  final String dineType;
  final String startTime;
  final String endTime;
  final String activeDays;
  final String status;
  final String uuid;
  final ValueChanged<String>? onStatusChanged;

  const OfferCard({
    super.key,
    required this.url,
    required this.deleteOnTap,
    required this.editOnTap,
    required this.percentage,
    required this.applicableFor,
    required this.dineType,
    required this.startTime,
    required this.endTime,
    required this.activeDays,
    required this.status,
    required this.uuid,
    this.onStatusChanged,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool isDeletePressed = false;
  OfferService offerService = OfferService();
  late String currentStatus;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.status;
  }

  Future<void> changeStatus() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      OfferStatusChangeModel offer = OfferStatusChangeModel(widget.uuid);
      OfferStatusChangeReturnModel response = await offerService.changeStatus(
        offer,
      );

      if (!mounted) return;

      if (response.status) {
        final updatedStatus = currentStatus == "Active" ? "Inactive" : "Active";
        setState(() {
          currentStatus = updatedStatus;
        });
        widget.onStatusChanged?.call(updatedStatus);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone =
        Breakpoints.isMobile(width) && width >= 500 && size.height <= 760;
    final isMobile = Breakpoints.isMobile(width) && !isWideShortPhone;
    final cardPadding = isMobile
        ? EdgeInsets.all(16.w)
        : EdgeInsets.all(AppDimensions.padding(width) * 0.65);
    final bottomMargin = isMobile ? 20.h : 20.0;
    final cardRadius = isMobile ? 17.r : 14.0;
    final bannerRadius = isMobile ? 18.r : 14.0;
    final bannerHeight = isMobile ? 120.h : 132.0;
    final bannerPadding = EdgeInsets.only(
      left: isMobile ? 20.w : 22.0,
      top: isMobile ? 20.h : 18.0,
      bottom: isMobile ? 10.h : 10.0,
      right: isMobile ? 20.w : 22.0,
    );
    final discountSize = isMobile ? 36.sp : 36.0;
    final appliesSize = isMobile ? 13.sp : 13.0;
    final dineTypeSize = isMobile ? 11.sp : 12.0;
    final tagSize = isMobile ? 67.w : 68.0;
    final offerDetailsGap = isWideShortPhone
        ? 14.0
        : isMobile
        ? 8.h
        : 18.0;
    final sectionGap = isMobile ? 16.h : 16.0;
    final buttonWidth = isMobile ? 75.w : 82.0;
    final buttonHeight = isMobile ? 19.h : 24.0;

    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      padding: cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset.zero,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top-right switch
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                children: [
                  AppSwitch(
                    initialValue: currentStatus == "Active",
                    onToggle: (val) {
                      if (!isLoading) {
                        changeStatus();
                      }
                    },
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(
                            isMobile ? 30.r : 30,
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: isMobile ? 15.w : 15,
                            height: isMobile ? 15.w : 15,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10.h : 10),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(bannerRadius),
                child: Image.asset(
                  widget.url,
                  height: bannerHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: bannerPadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: "${widget.percentage.split('.')[0]}%",
                                  size: discountSize,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  lineSpacing: 1.0,
                                ),
                                // SizedBox(height: 5.w),
                                AppText(
                                  text:
                                      "FOR ${widget.applicableFor.toUpperCase().split('_').join(' ')}",
                                  size: appliesSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            SizedBox(height: offerDetailsGap),
                            AppText(
                              text: widget.dineType
                                  // .toUpperCase()
                                  .split(',')
                                  .join(' & '),
                              size: dineTypeSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/discounttag.png',
                        width: tagSize,
                        height: tagSize,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sectionGap),

          Row(
            children: [
              _IconContainer(
                imageIcon: OffercardClockIcon,
                label: "${widget.startTime} - ${widget.endTime}",
                expanded: false,
              ),
              SizedBox(width: isMobile ? 8.w : 8),
              _IconContainer(
                imageIcon: OffercardCalendarIcon,
                label: widget.activeDays,
                expanded: true,
              ),
            ],
          ),
          SizedBox(height: sectionGap),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: AppButton(
                  text: 'Delete',
                  bgColor1: offercardDeleteButtonColor,
                  bgColor2: offercardDeleteButtonColor,
                  onPressed: widget.deleteOnTap,
                  size: 12,
                  borderRadius: 5,
                ),
              ),
              SizedBox(width: isMobile ? 10.w : 10),
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: AppButton(
                  text: 'Edit',
                  bgColor1: offercardEditButtonColor,
                  bgColor2: offercardEditButtonColor,
                  onPressed: widget.editOnTap,
                  size: 12,
                  borderRadius: 5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  final String imageIcon;
  final String label;
  final bool expanded;

  const _IconContainer({
    required this.imageIcon,
    required this.label,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone =
        Breakpoints.isMobile(width) && width >= 500 && size.height <= 760;
    final isMobile = Breakpoints.isMobile(width) && !isWideShortPhone;
    final horizontalPadding = isMobile ? 10.w : 10.0;
    final verticalPadding = isMobile ? 6.h : 6.0;
    final iconSize = isMobile ? 16.w : 16.0;
    final gap = isMobile ? 6.w : 6.0;
    final textSize = isMobile ? 11.sp : 11.0;

    Widget content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF615A10), width: 0.5),
        borderRadius: BorderRadius.all(Radius.circular(isMobile ? 5.r : 5)),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Image.asset(
            fit: BoxFit.cover,
            imageIcon,
            width: iconSize,
            height: iconSize,
          ),
          SizedBox(width: gap),
          Flexible(
            child: Text(
              label.replaceAll(RegExp(r','), " "),
              style: TextStyle(fontSize: textSize, color: const Color(0xFF000000)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone =
        Breakpoints.isMobile(width) && width >= 500 && size.height <= 760;
    final isMobile = Breakpoints.isMobile(width) && !isWideShortPhone;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 10.h : 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 5.r : 5),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 11.sp : 11,
          ),
        ),
      ),
    );
  }
}
