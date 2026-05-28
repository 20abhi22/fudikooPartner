import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/registration/mapplace-model.dart';
import 'package:fudiko/utils/tokens.dart';

class MapService {
  Future<List<MapPlacesResponse>> listPlaces(String place) async {
    try {
      final token = await getToken();
      final encodedPlace = Uri.encodeQueryComponent(place);
      final response = await DioClient.dio.get(
        '/places/search?input=$encodedPlace',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> predictions = response.data['predictions'];

        return predictions.map<MapPlacesResponse>((place) {
          return MapPlacesResponse.fromJson({
            'place_id': place['place_id'],
            'main_text': place['structured_formatting']['main_text'],
          });
        }).toList();
      } else {
        debugPrint('Places search failed');
        return [];
      }
    } catch (e) {
      debugPrint('Places search error: $e');
      return [];
    }
  }

  Future<MapCoordinatesResponse> getPlace(String placeId) async {
    try {
      final token = await getToken();
      final response = await DioClient.dio.get(
        '/places/details?place_id=$placeId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final formateddata = response.data['result']['geometry']['location'];
        return MapCoordinatesResponse.fromJson(formateddata);
      } else {
        debugPrint('Place details failed');
        return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
      }
    } catch (e) {
      debugPrint('Place details error: $e');
      return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
    }
  }
}
