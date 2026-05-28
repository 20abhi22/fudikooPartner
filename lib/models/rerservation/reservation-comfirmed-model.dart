class ReservationConfirmedModel {
  final int id;
  final String uuid;
  final String reservationId;
  final String userId;
  final int people;
  final String restaurantId;
  final String time;
  final String date;
  final String offerId;
  final String offerCode;
  final String offerCodeStatus;
  final String status;
  final String createdAt;
  final String updatedAt;

  ReservationConfirmedModel({
    required this.id,
    required this.uuid,
    required this.reservationId,
    required this.userId,
    required this.people,
    required this.restaurantId,
    required this.time,
    required this.date,
    required this.offerId,
    required this.offerCode,
    required this.offerCodeStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  factory ReservationConfirmedModel.fromJson(Map<String, dynamic> json) {
    return ReservationConfirmedModel(
      id: _toInt(json['id']),
      uuid: _toString(json['uuid']),
      reservationId: _toString(json['reservation_id']),
      userId: _toString(json['user_id']),
      people: _toInt(json['people']),
      restaurantId: _toString(json['restaurant_id']),
      time: _toString(json['time']),
      date: _toString(json['date']),
      offerId: _toString(json['offer_id']),
      offerCode: _toString(json['offer_code']),
      offerCodeStatus: _toString(json['offer_code_status']),
      status: _toString(json['status']),
      createdAt: _toString(json['created_at']),
      updatedAt: _toString(json['updated_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}

class ReservationConfirmedModelResponse {
  final bool status;
  final List<ReservationConfirmedModel> reservations;

  ReservationConfirmedModelResponse({
    required this.status,
    required this.reservations,
  });

  factory ReservationConfirmedModelResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final reservationsJson = json['reservations'];
    final reservationsList = reservationsJson is List ? reservationsJson : const [];

    return ReservationConfirmedModelResponse(
      status: json['status'] == true,
      reservations: reservationsList
          .whereType<Map>()
          .map((item) => ReservationConfirmedModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
