import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
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
        setState(() {
          currentStatus = currentStatus == "Active" ? "Inactive" : "Active";
        });
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
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // #000000 at 10%
            offset: Offset(0, 0), // X: 0, Y: 0
            blurRadius: 10, // Blur: 10
            spreadRadius: 2, // Spread: 2
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
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 15.w,
                            height: 15.w,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: Image.asset(
                  widget.url,
                  height: 120.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    top: 20.h,
                    bottom: 10.h,
                    right: 20.w,
                  ),
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
                                  size: 36.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  lineSpacing: 1.0,
                                ),
                                // SizedBox(height: 5.w),
                                AppText(
                                  text:
                                      "FOR ${widget.applicableFor.toUpperCase().split('_').join(' ')}",
                                  size: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            AppText(
                              text: widget.dineType
                                  // .toUpperCase()
                                  .split(',')
                                  .join(' & '),
                              size: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/discounttag.png',
                        width: 67.w,
                        height: 67.h,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          Row(
            children: [
              _IconContainer(
                imageIcon: OffercardClockIcon,
                label: "${widget.startTime} - ${widget.endTime}",
                expanded: false,
              ),
              SizedBox(width: 8.w),
              _IconContainer(
                imageIcon: OffercardCalendarIcon,
                label: widget.activeDays,
                expanded: true,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 75.w,
                height: 19.h,
                child: AppButton(
                  text: 'Delete',
                  bgColor1: offercardDeleteButtonColor,
                  bgColor2: offercardDeleteButtonColor,
                  onPressed: widget.deleteOnTap,
                  size: 12,
                  borderRadius: 5,
                ),
              ),
              SizedBox(width: 10.w),
              SizedBox(
                width: 75.w,
                height: 19.h,
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
    Widget content = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF615A10), width: 0.5.r),
        borderRadius: BorderRadius.all(Radius.circular(5.r)),
      ),
      child: Row(
  mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
  children: [
    Image.asset(
      fit: BoxFit.cover,
      imageIcon,
      width: 16.w,
      height: 16.h,
    ),
    SizedBox(width: 6.w),
    Flexible(   
      child: Text(
        label.replaceAll(RegExp(r','), " "),
        style: TextStyle(fontSize: 11.sp, color: Color(0xFF000000)),
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
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }
}
