import 'package:flutter/material.dart';
import 'package:fudiko/components/reservation_summary_card.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class ProcessingBox extends StatelessWidget {
  final VoidCallback? deleteOnPressed;
  final VoidCallback? onAcceptPressed;
  final int id;
  final String uuid;
  final String reservationId;
  final String userId;
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

  const ProcessingBox({
    super.key,
    this.deleteOnPressed,
    required this.id,
    required this.uuid,
    required this.reservationId,
    required this.userId,
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
    this.onAcceptPressed,
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
      actions: [
        ReservationCardActionButton(
          text: 'Decline',
          onPressed: deleteOnPressed ?? () {},
          color: processDeclineIconColor,
        ),
        ReservationCardActionButton(
          text: 'Accept',
          onPressed: onAcceptPressed ?? () {},
          color: processAcceptIconColor,
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
