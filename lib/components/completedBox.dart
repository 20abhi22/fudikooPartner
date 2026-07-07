// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:fudiko/components/reservation_summary_card.dart';
import 'package:fudiko/models/rerservation/reservation-completed-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class CompletedBox extends StatelessWidget {
  final ReservationCompletedModel reservation;
  final String? discountPercentage;
  final String? applicableFor;
  final String? dineType;

  const CompletedBox({
    super.key,
    required this.reservation,
    this.discountPercentage,
    this.applicableFor,
    this.dineType,
  });

  String formatDate(String dateString, {String format = "MMM dd"}) {
    try {
      return DateFormat(format).format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  String formatTime(String dateString) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offerText();
    return ReservationSummaryCard(
      reservationId: reservation.reservationId.length >= 6
          ? reservation.reservationId.substring(0, 6)
          : reservation.reservationId,
      titleColor: appTextColor5,
      iconColor: processTagIconColor,
      iconPath: offerIcon,
      offerPrimary: offer.$1,
      offerSecondary: offer.$2,
      dateLabel: formatDate(reservation.date),
      timeLabel: reservation.time,
      people: reservation.people,
      trailingDate: formatDate(reservation.createdAt),
      trailingTime: formatTime(reservation.createdAt),
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
