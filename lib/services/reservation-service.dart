import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/rerservation/reservation-cancelled-model.dart';
import 'package:fudiko/models/rerservation/reservation-comfirmed-model.dart';
import 'package:fudiko/models/rerservation/reservation-completed-model.dart';
import 'package:fudiko/models/rerservation/reservation-processing-model.dart';
import 'package:fudiko/models/rerservation/reservation-search-model.dart';
import 'package:fudiko/models/rerservation/reservation-status-change.dart';
import 'package:fudiko/utils/tokens.dart';

class ReservationService {
  Future<Options> _authOptions() async {
    final token = await getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token'},
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    );
  }

  Future<Map<String, dynamic>?> _getJson(String path) async {
    try {
      final response = await DioClient.dio.get(
        path,
        options: await _authOptions(),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      // Return null to let callers map to empty-state models.
    }
    return null;
  }

  Future<ReservationProcessingModelResponse> getprocessingreservations() async {
    final data = await _getJson('/partner/reservations/processing');
    if (data == null) {
      return ReservationProcessingModelResponse(
        status: false,
        reservations: [],
      );
    }
    return ReservationProcessingModelResponse.fromJson(data);
  }

  Future<ReservationConfirmedModelResponse> getconfirmedreservations() async {
    final data = await _getJson('/partner/reservations/confirmed');
    if (data == null) {
      return ReservationConfirmedModelResponse(status: false, reservations: []);
    }
    return ReservationConfirmedModelResponse.fromJson(data);
  }

  Future<ReservationStatusChangeResponseModel> changeStatus(
    ReservationStatusChangeModel details,
  ) async {
    final data = details.toFormData();
    try {
      final response = await DioClient.dio.post(
        '/partner/reservations/update-status',
        data: data,
        options: await _authOptions(),
      );
      if (response.statusCode == 200) {
        return ReservationStatusChangeResponseModel.fromJson(response.data);
      } else {
        return ReservationStatusChangeResponseModel(
          status: false,
          message: "Error changing status",
        );
      }
    } catch (e) {
      return ReservationStatusChangeResponseModel(
        status: false,
        message: "Error changing status",
      );
    }
  }

  Future<ReservationStatusChangeResponseModel> remindReservation(
    String reservationId,
  ) async {
    try {
      final response = await DioClient.dio.post(
        '/partner/reservations/remind',
        data: FormData.fromMap({'reservation_id': reservationId}),
        options: await _authOptions(),
      );
      if (response.statusCode == 200) {
        return ReservationStatusChangeResponseModel.fromJson(response.data);
      }
      return ReservationStatusChangeResponseModel(
        status: false,
        message: 'Error sending reminder',
      );
    } catch (e) {
      return ReservationStatusChangeResponseModel(
        status: false,
        message: 'Error sending reminder',
      );
    }
  }

  Future<ReservationStatusChangeResponseModel> callbackReservation(
    String reservationId,
  ) async {
    try {
      final response = await DioClient.dio.post(
        '/partner/reservations/callback',
        data: FormData.fromMap({'reservation_id': reservationId}),
        options: await _authOptions(),
      );
      if (response.statusCode == 200) {
        return ReservationStatusChangeResponseModel.fromJson(response.data);
      }
      return ReservationStatusChangeResponseModel(
        status: false,
        message: 'Error sending callback',
      );
    } catch (e) {
      return ReservationStatusChangeResponseModel(
        status: false,
        message: 'Error sending callback',
      );
    }
  }

  Future<ReservationCancelledModelResponse> getcancelledreservations() async {
    final data = await _getJson('/partner/reservations/cancelled');
    if (data == null) {
      return ReservationCancelledModelResponse(status: false, reservations: []);
    }
    return ReservationCancelledModelResponse.fromJson(data);
  }

  Future<ReservationSearchResponse> searchReservations(String query) async {
    try {
      final response = await DioClient.dio.get(
        '/partner/reservations/search',
        queryParameters: {'id': query},
        options: await _authOptions(),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return ReservationSearchResponse.fromJson(response.data);
      }
    } catch (e) {
      // fall through
    }
    return ReservationSearchResponse(status: false, reservations: []);
  }

  Future<ReservationCompletedModelResponse> getcompletedreservations({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    try {
      final response = await DioClient.dio.get(
        '/partner/reservations/completed',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: await _authOptions(),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return ReservationCompletedModelResponse.fromJson(response.data);
      }
    } catch (e) {
      // fall through
    }
    return ReservationCompletedModelResponse(status: false, reservations: []);
  }
}
