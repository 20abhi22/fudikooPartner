// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:fudiko/components/reservation_summary_card.dart';
import 'package:fudiko/models/rerservation/reservation-search-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class SearchResultBox extends StatelessWidget {
  final ReservationSearchModel reservation;

  const SearchResultBox({super.key, required this.reservation});

  String formatDate(String dateString, {String format = "MMM dd"}) {
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'pending':
      case 'processing':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final discountRaw = reservation.discountPercentage ?? '';
    String discountText = '';
    if (discountRaw.isNotEmpty) {
      discountText = discountRaw.contains('.')
          ? discountRaw.split('.').first
          : discountRaw;
      discountText = '$discountText%';
    }

    final applicable = reservation.applicableFor ?? '';
    final dine = reservation.dineType ?? '';
    final primary = discountText.isNotEmpty
        ? discountText
        : (reservation.offerCode.isNotEmpty
              ? reservation.offerCode
              : 'No Offer');
    final secondaryParts = <String>[];

    if (applicable.isNotEmpty) secondaryParts.add('for $applicable');
    if (dine.isNotEmpty) secondaryParts.add(dine);

    final reservationId = reservation.reservationId.length >= 6
        ? reservation.reservationId.substring(0, 6)
        : reservation.reservationId;

    return ReservationSummaryCard(
      reservationId: reservationId,
      titleColor: appTextColor3,
      iconColor: processTagIconColor,
      iconPath: offerIcon,
      offerPrimary: primary,
      offerSecondary: secondaryParts.join(' - '),
      dateLabel: formatDate(reservation.date),
      timeLabel: reservation.time,
      people: reservation.people,
      trailingDate: formatDate(reservation.createdAt),
      trailingTime: formatTime(reservation.createdAt),
      statusLabel: reservation.status,
      statusColor: _statusColor(reservation.status),
    );
  }
}
