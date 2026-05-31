import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:intl/intl.dart';

class BanquetCompletedBox extends StatelessWidget {
  final String enquiryId;
  final String estimatedAmount;
  final String amount;
  final String extraOffer;
  final String comments;
  final String menuItems;
  final int people;
  final String date;
  final String time;

  const BanquetCompletedBox({
    super.key,
    required this.enquiryId,
    required this.estimatedAmount,
    required this.amount,
    required this.extraOffer,
    required this.comments,
    required this.menuItems,
    required this.people,
    required this.date,
    required this.time,
  });

  String _formatDate(String? rawDate, {String format = "MMM dd"}) {
    if (rawDate == null || rawDate.trim().isEmpty) return "Loading...";

    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) return DateFormat(format).format(parsed);

    for (final pattern in ["yyyy-MM-dd", "dd-MM-yyyy", "MM/dd/yyyy"]) {
      try {
        return DateFormat(
          format,
        ).format(DateFormat(pattern).parseStrict(rawDate));
      } catch (_) {}
    }

    return rawDate;
  }

  String _formatTime(String? rawTime) {
    if (rawTime == null || rawTime.trim().isEmpty) return "Loading...";

    final parsed = DateTime.tryParse(rawTime);
    if (parsed != null) return DateFormat('hh:mm a').format(parsed);

    for (final pattern in ["HH:mm:ss", "HH:mm", "hh:mm a", "h:mm a"]) {
      try {
        return DateFormat(
          'hh:mm a',
        ).format(DateFormat(pattern).parseStrict(rawTime));
      } catch (_) {}
    }

    return rawTime;
  }

  String _shortPeopleCount(int people) {
    return people <= 0 ? "-" : people.toString();
  }

  @override
  Widget build(BuildContext context) {
    final amountText = amount.trim().isNotEmpty
        ? amount.trim()
        : estimatedAmount.trim().isNotEmpty
        ? estimatedAmount.trim()
        : "Loading...";
    final offerText = _offerText();
    final menuText = menuItems.trim().isEmpty
        ? "Menu not specified"
        : menuItems.trim();
    final formattedFullDate = _formatDate(date, format: "MMMM dd");
    final fullDate = "$formattedFullDate - ${_formatTime(time).toLowerCase()}";

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              offset: Offset(0, 8.h),
              blurRadius: 24.r,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppText(
                    text: enquiryId,
                    size: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      text: _formatDate(date),
                      size: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF545450),
                    ),
                    AppText(
                      text: _formatTime(time).toLowerCase(),
                      size: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF545450),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 18.h),
            _InfoRow(iconPath: walletIcon, text: "$amountText Per person"),
            SizedBox(height: 8.h),
            _InfoRow(iconPath: offerIcon, text: offerText),
            SizedBox(height: 8.h),
            _InfoRow(
              iconPath: calenderIcon,
              text: fullDate,
              boldPrefix: formattedFullDate,
            ),
            SizedBox(height: 8.h),
            _InfoRow(
              iconPath: groupIcon,
              text: "${_shortPeopleCount(people)} Person",
            ),
            SizedBox(height: 8.h),
            _InfoRow(iconPath: menuIcon, text: menuText, maxLines: 3),
          ],
        ),
      ),
    );
  }

  String _offerText() {
    final offer = extraOffer.trim();
    final note = comments.trim();

    if (offer.isEmpty && note.isEmpty) return "Offer applied";
    if (offer.isEmpty) return note;
    if (note.isEmpty) return offer;
    return "$offer on $note";
  }
}

class _InfoRow extends StatelessWidget {
  final String iconPath;
  final String text;
  final String? boldPrefix;
  final int maxLines;

  const _InfoRow({
    required this.iconPath,
    required this.text,
    this.boldPrefix,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: ColorFiltered(
            colorFilter:  ColorFilter.mode(
              banquetTagIconColor,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              iconPath,
              width: 18.w,
              height: 18.w,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(child: _buildText()),
      ],
    );
  }

  Widget _buildText() {
    return AppText(
      text: text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      size: 14,
      color: offerPageTextColor,
      fontWeight: boldPrefix == null || !text.startsWith(boldPrefix!)
          ? FontWeight.w400
          : FontWeight.w800,
    );
  }
}
