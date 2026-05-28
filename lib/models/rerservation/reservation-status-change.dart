import 'package:dio/dio.dart';

class ReservationStatusChangeModel{
  final String reservationId;
  final String status;

  ReservationStatusChangeModel({required this.reservationId, required this.status});

  FormData toFormData() {
    final formData = FormData.fromMap({
      'reservation_id': reservationId,
      'status': status,
    });
    return formData;
  }
}

class ReservationStatusChangeResponseModel{
  final bool status;
  final String message;

  ReservationStatusChangeResponseModel({required this.status, required this.message});

  factory ReservationStatusChangeResponseModel.fromJson(Map<String, dynamic> json) {
    return ReservationStatusChangeResponseModel(
      status: json['status'],
      message: json['message'],
    );
  }


}