import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/catering/all-enquiry-model.dart';
import 'package:fudiko/models/catering/sent-enquiry-model.dart';

import 'package:fudiko/utils/tokens.dart';

class CateringEnquiryService {
  Future<CateringEnquiryListResponse> getAllEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/catering-enquiry/all',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CateringEnquiryListResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> deleteEnquiry(String uuid) async {
    final token = await getToken();
    final data = FormData.fromMap({'enquiry_id': uuid});
    final response = await DioClient.dio.post(
      '/partner/catering-enquiry/delete',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> saveEnquiry(String uuid) async {
    final token = await getToken();
    final data = FormData.fromMap({'enquiry_id': uuid});
    final response = await DioClient.dio.post(
      '/partner/catering-enquiry/save',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<CateringEnquiryListResponse> searchEnquiries(String query) async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/catering-enquiry/search',
      queryParameters: {'id': query},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CateringEnquiryListResponse.fromJson(response.data);
  }

  Future<CateringEnquiryListResponse> getSavedEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/catering-enquiry/saved',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CateringEnquiryListResponse.fromJson(response.data);
  }

  Future<CateringEnquiryListResponse> getDeletedEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/catering-enquiry/deleted',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CateringEnquiryListResponse.fromJson(response.data);
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
      '/partner/catering-enquiry/offer-discount',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<CateringEnquiryModel> showEnquiry(String uuid) async {
    final token = await getToken();
    final data = FormData.fromMap({
      'enquiry_id': uuid,
    }); // key=enquiry_id, value=uuid
    final response = await DioClient.dio.post(
      '/partner/catering-enquiry/show',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CateringEnquiryModel.fromJson(response.data['enquiry']);
  }

  Future<SentEnquiryListResponse> getSentEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/catering-enquiry/sent',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SentEnquiryListResponse.fromJson(response.data);
  }

  Future<CateringEnquiryListResponse> getConfirmedEnquiries() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/catering-enquiry/confirmed',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CateringEnquiryListResponse.fromJson(response.data);
  }

  Future<CateringEnquiryListResponse> getCompletedEnquiries({
    String? startDate,
    String? endDate,
  }) async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/catering-enquiry/completed',
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CateringEnquiryListResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> deleteSentEnquiry(String enquiryId) async {
    final token = await getToken();
    final data = FormData.fromMap({'enquiry_id': enquiryId});
    final response = await DioClient.dio.post(
      '/partner/catering-enquiry/delete-sent',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> confirmCateringResponse(
    String responseId,
  ) async {
    final token = await getToken();
    final data = FormData.fromMap({'response_id': responseId});
    final response = await DioClient.dio.post(
      '/customer/catering-enquiry/confirm',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }
}
