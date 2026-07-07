// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/reservation_summary_card.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/nav/profile.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class ConfirmedBox extends StatelessWidget {
  final VoidCallback? deleteOnPressed;
  final Future<void> Function(String reservationId)? onRemindPressed;
  final int id;
  final String uuid;
  final String reservationId;
  final String userId;
  final String customerId;
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
    this.onRemindPressed,
    required this.id,
    required this.uuid,
    required this.reservationId,
    required this.userId,
    required this.customerId,
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

  String formatDate(String dateString, {String format = 'MMM dd'}) {
    try {
      return DateFormat(format).format(DateTime.parse(dateString));
    } catch (_) {
      return dateString;
    }
  }

  String formatTime(String dateString) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(dateString));
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offerText();

    return ReservationSummaryCard(
      reservationId: reservationId,
      titleColor: appTextColor3,
      iconColor: processTagIconColor,
      iconPath: offerIcon,
      offerPrimary: offer.$1,
      offerSecondary: offer.$2,
      dateLabel: formatDate(date),
      timeLabel: time,
      people: people,
      trailingDate: formatDate(createdAt),
      trailingTime: formatTime(createdAt),
      trailingTextColor: const Color(0xFFC95F05),
      leadingAction: _DetailsAction(
        onTap: () => slideRightWidget(
          newPage: Profile(customerId: customerId),
          context: context,
        ),
      ),
      actions: [
        ReservationCardActionButton(
          text: 'Remind',
          onPressed: onRemindPressed == null
              ? () {}
              : () => onRemindPressed!(uuid),
          color: confirmedRemindIconColor,
          width: 82,
        ),
      ],
    );
  }

  (String, String) _offerText() {
    final discountRaw = discountPercentage ?? '';
    var discountText = '';
    if (discountRaw.isNotEmpty) {
      discountText = discountRaw.contains('.')
          ? discountRaw.split('.').first
          : discountRaw;
      discountText = '$discountText%';
    }

    final primary = discountText.isNotEmpty
        ? discountText
        : (offerCode.isNotEmpty ? offerCode : 'No Offer');
    final secondaryParts = <String>[
      if ((applicableFor ?? '').isNotEmpty) 'for $applicableFor',
      if ((dineType ?? '').isNotEmpty) dineType!,
      if ((startTime ?? '').isNotEmpty || (endTime ?? '').isNotEmpty)
        [
          if ((startTime ?? '').isNotEmpty) startTime!,
          if ((endTime ?? '').isNotEmpty) endTime!,
        ].join(' - '),
    ];

    return (primary, secondaryParts.join(' · '));
  }
}

class _DetailsAction extends StatelessWidget {
  final VoidCallback onTap;

  const _DetailsAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isMobile = Breakpoints.isMobile(screenWidth);
    final isWideShortPhone =
        isMobile && screenWidth >= 500 && size.height <= 760;
    final usesTabletLayout =
        Breakpoints.isTablet(screenWidth) || isWideShortPhone;
    final iconSize = isWideShortPhone
        ? 14.0
        : isMobile && !isWideShortPhone
        ? 15.w
        : usesTabletLayout
        ? 18.0
        : 16.0;
    final gap = isWideShortPhone
        ? 4.0
        : isMobile && !isWideShortPhone
        ? 5.w
        : usesTabletLayout
        ? 7.0
        : 6.0;
    final textSize = isWideShortPhone
        ? 12.0
        : usesTabletLayout
        ? 15.0
        : 13.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWideShortPhone
              ? 0
              : usesTabletLayout
              ? 4
              : 0,
          vertical: isWideShortPhone
              ? 2
              : usesTabletLayout
              ? 6
              : 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                confirmedDetailsIconColor,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                detailsIcon,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: gap),
            AppText(
              text: 'Details',
              size: textSize,
              fontWeight: FontWeight.w500,
              color: confirmedDetailsIconColor,
            ),
          ],
        ),
      ),
    );
  }
}
