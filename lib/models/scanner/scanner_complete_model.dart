// lib/models/scanner/scanner_complete_model.dart

class ScannerOfferModel {
  final String uuid;
  final String partnerUid;
  final String discountPercentage;
  final String applicableFor;
  final String dineType;
  final String startTime;
  final String endTime;
  final String activeDays;
  final String status;

  ScannerOfferModel({
    required this.uuid,
    required this.partnerUid,
    required this.discountPercentage,
    required this.applicableFor,
    required this.dineType,
    required this.startTime,
    required this.endTime,
    required this.activeDays,
    required this.status,
  });

  factory ScannerOfferModel.fromJson(Map<String, dynamic> json) {
    return ScannerOfferModel(
      uuid: _s(json['uuid']),
      partnerUid: _s(json['partner_uid']),
      discountPercentage: _s(json['discount_percentage']),
      applicableFor: _s(json['applicable_for']),
      dineType: _s(json['dine_type']),
      startTime: _s(json['start_time']),
      endTime: _s(json['end_time']),
      activeDays: _s(json['active_days']),
      status: _s(json['status']),
    );
  }

  static String _s(dynamic v) => v?.toString() ?? '';
}

class ScannerReservationModel {
  final int id;
  final String uuid;
  final String reservationId;
  final String userId;
  final int people;
  final String restaurantId;
  final String offerId;
  final String time;
  final String date;
  final String offerCode;
  final String offerCodeStatus;
  final String? billAmount;
  final String? billImage;
  final String status;
  final String createdAt;
  final String updatedAt;
  final ScannerOfferModel? offer;

  ScannerReservationModel({
    required this.id,
    required this.uuid,
    required this.reservationId,
    required this.userId,
    required this.people,
    required this.restaurantId,
    required this.offerId,
    required this.time,
    required this.date,
    required this.offerCode,
    required this.offerCodeStatus,
    this.billAmount,
    this.billImage,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.offer,
  });

  factory ScannerReservationModel.fromJson(Map<String, dynamic> json) {
    final offerRaw = json['offer'];
    final offer = offerRaw is Map
        ? ScannerOfferModel.fromJson(Map<String, dynamic>.from(offerRaw))
        : null;

    return ScannerReservationModel(
      id: _i(json['id']),
      uuid: _s(json['uuid']),
      reservationId: _s(json['reservation_id']),
      userId: _s(json['user_id']),
      people: _i(json['people']),
      restaurantId: _s(json['restaurant_id']),
      offerId: _s(json['offer_id']),
      time: _s(json['time']),
      date: _s(json['date']),
      offerCode: _s(json['offer_code']),
      offerCodeStatus: _s(json['offer_code_status']),
      billAmount: json['bill_amount']?.toString(),
      billImage: json['bill_image']?.toString(),
      status: _s(json['status']),
      createdAt: _s(json['created_at']),
      updatedAt: _s(json['updated_at']),
      offer: offer,
    );
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _s(dynamic v) => v?.toString() ?? '';
}

/// Top-level response for POST /api/partner/reservations/complete
class ScannerCompleteResponse {
  final bool status;
  final String message;
  final ScannerReservationModel? reservation;

  ScannerCompleteResponse({
    required this.status,
    required this.message,
    this.reservation,
  });

  factory ScannerCompleteResponse.fromJson(Map<String, dynamic> json) {
    final reservationRaw = json['reservation'];
    final reservation = reservationRaw is Map
        ? ScannerReservationModel.fromJson(
            Map<String, dynamic>.from(reservationRaw),
          )
        : null;

    return ScannerCompleteResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      reservation: reservation,
    );
  }
}