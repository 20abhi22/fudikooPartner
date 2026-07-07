import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/support/support-information-model.dart';

class SupportService {
  Future<SupportInformationModel> getSupportInformation() async {
    final response = await DioClient.dio.get('/customer/support-information');
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid support information response');
    }

    final supportInformation = SupportInformationModel.fromJson(data);
    if (!supportInformation.status) {
      throw const FormatException('Support information is unavailable');
    }

    return supportInformation;
  }
}
