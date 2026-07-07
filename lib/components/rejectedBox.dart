// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:fudiko/components/reservation_summary_card.dart';
import 'package:fudiko/models/rerservation/reservation-cancelled-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class RejectedBox extends StatelessWidget {
  final ReservationCancelledModel reservation;
  final VoidCallback? onCallBackPressed;
  final bool isCallBackEnabled;
  final String? discountPercentage;
  final String? applicableFor;
  final String? dineType;

  const RejectedBox({
    super.key,
    required this.reservation,
    this.onCallBackPressed,
    this.isCallBackEnabled = true,
    this.discountPercentage,
    this.applicableFor,
    this.dineType,
  });

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
  Widget build(BuildContext context) {
    final offer = _offerText();
    return ReservationSummaryCard(
      reservationId: reservation.reservationId,
      titleColor: rejectedTitleTextColor,
      iconColor: rejectedDetailsIconColor,
      iconPath: offerIcon,
      offerPrimary: offer.$1,
      offerSecondary: offer.$2,
      dateLabel: formatDate(reservation.date),
      timeLabel: formatTime(reservation.time),
      people: reservation.people,
      trailingDate: formatDate(reservation.date),
      trailingTime: formatTime(reservation.time),
      actions: [
        ReservationCardActionButton(
          text: 'Call back',
          onPressed: isCallBackEnabled ? (onCallBackPressed ?? () {}) : () {},
          color: isCallBackEnabled ? rejectedCallBackIconColor : Colors.grey,
          width: 88,
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
        : (reservation.offerCode.isNotEmpty
              ? reservation.offerCode
              : 'No Offer');
    final secondaryParts = <String>[
      if ((applicableFor ?? '').isNotEmpty) 'for $applicableFor',
      if ((dineType ?? '').isNotEmpty) dineType!,
    ];

    return (primary, secondaryParts.join(' · '));
  }
}
