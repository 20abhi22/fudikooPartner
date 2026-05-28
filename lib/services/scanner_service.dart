// lib/services/scanner/scanner_service.dart
//
// Intentionally separate from ReservationService so that future scanner
// types (banquet, catering, etc.) can each have their own service that
// calls a different endpoint, without touching shared reservation logic.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/scanner/scanner_complete_model.dart';
import 'package:fudiko/utils/tokens.dart';
import 'package:http_parser/http_parser.dart';

/// Sealed class lets callers pattern-match success vs failure without
/// catching exceptions in the UI layer.
sealed class ScannerResult {}

class ScannerSuccess extends ScannerResult {
  final ScannerCompleteResponse data;
  ScannerSuccess(this.data);
}

class ScannerFailure extends ScannerResult {
  final String message;
  ScannerFailure(this.message);
}

// ---------------------------------------------------------------------------
// Base class — one completeReservation contract, different endpoints/logic
// ---------------------------------------------------------------------------

abstract class BaseScannerService {
  Future<ScannerResult> completeReservation({
    required String reservationId,
    required String billAmount,
    required File billImage,
  });
}

// ---------------------------------------------------------------------------
// Restaurant QR scanner (current)
// ---------------------------------------------------------------------------

class RestaurantScannerService extends BaseScannerService {
  @override
  Future<ScannerResult> completeReservation({
    required String reservationId,
    required String billAmount,
    required File billImage,
  }) async {
    return _post(
      path: '/partner/reservations/complete',
      reservationId: reservationId,
      billAmount: billAmount,
      billImage: billImage,
    );
  }
}

// ---------------------------------------------------------------------------
// Banquet QR scanner (stub — wire up when endpoint is ready)
// ---------------------------------------------------------------------------

class BanquetScannerService extends BaseScannerService {
  @override
  Future<ScannerResult> completeReservation({
    required String reservationId,
    required String billAmount,
    required File billImage,
  }) async {
    return _post(
      path: '/partner/banquet/complete',   // <-- update when available
      reservationId: reservationId,
      billAmount: billAmount,
      billImage: billImage,
    );
  }
}

// ---------------------------------------------------------------------------
// Catering QR scanner (stub — wire up when endpoint is ready)
// ---------------------------------------------------------------------------

class CateringScannerService extends BaseScannerService {
  @override
  Future<ScannerResult> completeReservation({
    required String reservationId,
    required String billAmount,
    required File billImage,
  }) async {
    return _post(
      path: '/partner/catering/complete',  // <-- update when available
      reservationId: reservationId,
      billAmount: billAmount,
      billImage: billImage,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared multipart POST — used by all concrete services above
// ---------------------------------------------------------------------------

Future<ScannerResult> _post({
  required String path,
  required String reservationId,
  required String billAmount,
  required File billImage,
}) async {
  try {
    final token = await getToken();

    // Detect image mime type from extension (default to jpeg)
    final ext = billImage.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'png' : 'jpeg';

    final formData = FormData.fromMap({
      'reservation_id': reservationId,
      'bill_amount': billAmount,
      'bill_image': await MultipartFile.fromFile(
        billImage.path,
        filename: billImage.path.split('/').last,
        contentType: MediaType('image', mime),
      ),
    });

    final response = await DioClient.dio.post(
      path,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final parsed = ScannerCompleteResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      return ScannerSuccess(parsed);
    }

    return ScannerFailure('Unexpected response (${response.statusCode})');
  } on DioException catch (e) {
    final msg = e.response?.data?['message']?.toString() ??
        e.message ??
        'Network error';
    return ScannerFailure(msg);
  } catch (e) {
    return ScannerFailure('Something went wrong. Please try again.');
  }
}