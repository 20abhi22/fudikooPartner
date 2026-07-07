import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/banquet/all-enquiry-model.dart';
import 'package:fudiko/models/banquet/sent-enquiry-model.dart';

import 'package:fudiko/utils/tokens.dart';

class BanquetEnquiryService {
  Future<BanquetEnquiryListResponse> getAllEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/enquiry/all',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return BanquetEnquiryListResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> deleteEnquiry(String uuid) async {
    final token = await getToken();
    final data = FormData.fromMap({'enquiry_id': uuid});
    final response = await DioClient.dio.post(
      '/partner/enquiry/delete',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> saveEnquiry(String uuid) async {
    final token = await getToken();
    final data = FormData.fromMap({'enquiry_id': uuid});
    final response = await DioClient.dio.post(
      '/partner/enquiry/save',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<BanquetEnquiryListResponse> getSavedEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/enquiry/saved',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return BanquetEnquiryListResponse.fromJson(response.data);
  }

  Future<BanquetEnquiryListResponse> getDeletedEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/enquiry/deleted',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return BanquetEnquiryListResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> offerDiscount({
    required String uuid,
    required String amount,
    required String extraOffer,
    required String comments,
  }) async {
    final token = await getToken();
    final data = FormData.fromMap({
      'enquiry_id': uuid,
      'amount': amount,
      'extra_offer': extraOffer,
      'comments': comments,
    });
    final response = await DioClient.dio.post(
      '/partner/enquiry/offer-discount',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<BanquetEnquiryListResponse> searchEnquiries(String query) async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/enquiry/search',
      queryParameters: {'id': query},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return BanquetEnquiryListResponse.fromJson(response.data);
  }

  Future<BanquetEnquiryModel> showEnquiry(String uuid) async {
    final token = await getToken();
    final data = FormData.fromMap({
      'enquiry_id': uuid,
    }); // key=enquiry_id, value=uuid
    final response = await DioClient.dio.post(
      '/partner/enquiry/show',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return BanquetEnquiryModel.fromJson(response.data['enquiry']);
  }

  Future<SentEnquiryListResponse> getSentEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/enquiry/sent',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SentEnquiryListResponse.fromJson(response.data);
  }

  Future<BanquetEnquiryListResponse> getConfirmedEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/enquiry/confirmed',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return BanquetEnquiryListResponse.fromJson(response.data);
  }

  Future<BanquetEnquiryListResponse> getCompletedEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/enquiry/completed',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return BanquetEnquiryListResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> remindReservation(String reservationId) async {
    final token = await getToken();
    final data = FormData.fromMap({'reservation_id': reservationId});
    final response = await DioClient.dio.post(
      '/partner/enquiry/reservation/remind',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> callbackReservation(String reservationId) async {
    final token = await getToken();
    final data = FormData.fromMap({'reservation_id': reservationId});
    final response = await DioClient.dio.post(
      '/partner/enquiry/reservation/callback',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteSentEnquiry(String enquiryId) async {
    final token = await getToken();
    final data = FormData.fromMap({'enquiry_id': enquiryId});
    final response = await DioClient.dio.post(
      '/partner/enquiry/delete-sent',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> confirmPartyResponse(String responseId) async {
    final token = await getToken();
    final data = FormData.fromMap({'response_id': responseId});
    final response = await DioClient.dio.post(
      '/customer/enquiry/confirm',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }
}
//   Future<bool> offerDiscount({
//   required String enquiryId,
//   required String amount,
//   required String extraOffer,
//   required String comments,
// }) async {
//   final token = await getToken();
//   final response = await DioClient.dio.post(
//     '/partner/enquiry/offer-discount',
//     data: FormData.fromMap({
//       'enquiry_id': enquiryId,
//       'amount': amount,
//       'extra_offer': extraOffer,
//       'comments': comments,
//     }),
//     options: Options(headers: {'Authorization': 'Bearer $token'}),
//   );
//   return response.data['status'] == true;
// }

// Future<bool> saveEnquiry(String enquiryId) async {
//   final token = await getToken();
//   final response = await DioClient.dio.post(
//     '/partner/enquiry/save',
//     data: FormData.fromMap({'enquiry_id': enquiryId}),
//     options: Options(headers: {'Authorization': 'Bearer $token'}),
//   );
//   return response.data['status'] == true;
// }

// Future<bool> deleteEnquiry(String enquiryId) async {
//   final token = await getToken();
//   final response = await DioClient.dio.post(
//     '/partner/enquiry/delete',
//     data: FormData.fromMap({'enquiry_id': enquiryId}),
//     options: Options(headers: {'Authorization': 'Bearer $token'}),
//   );
//   return response.data['status'] == true;
// }
