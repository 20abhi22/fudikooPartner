class MapPlacesResponse {
  String? placeId;
  String? mainText;
  String? secondaryText;
  double? lat;
  double? lng;
  List<String> types;
  double? rating;
  int? userRatingsTotal;
  double? distanceMeters;
  bool isSeed;

  MapPlacesResponse({
    this.placeId,
    this.mainText,
    this.secondaryText,
    this.lat,
    this.lng,
    this.types = const [],
    this.rating,
    this.userRatingsTotal,
    this.distanceMeters,
    this.isSeed = false,
  });

  factory MapPlacesResponse.fromJson(Map<String, dynamic> json) {
    return MapPlacesResponse(
      placeId: json['place_id'] ?? '',
      mainText: json['main_text'] ?? '',
      secondaryText: json['secondary_text'],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      types: (json['types'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const [],
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      isSeed: json['is_seed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'main_text': mainText,
      'secondary_text': secondaryText,
      'lat': lat,
      'lng': lng,
      'types': types,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'distance_meters': distanceMeters,
      'is_seed': isSeed,
    };
  }

  @override
  String toString() {
    return 'MapPlacesResponse(placeId: $placeId, mainText: $mainText)';
  }
}

class MapPlaceSearchPage {
  final List<MapPlacesResponse> results;
  final String? nextPageToken;
  final String status;
  final String? errorMessage;

  const MapPlaceSearchPage({
    required this.results,
    this.nextPageToken,
    this.status = 'OK',
    this.errorMessage,
  });
}

enum MapPlaceSearchType { nearby, text }

class MapCoordinatesResponse {
  double? lat;
  double? lng;
  MapCoordinatesResponse({
    this.lat,
    this.lng,
  });
  factory MapCoordinatesResponse.fromJson(Map<String, dynamic> json) {
    return MapCoordinatesResponse(
      lat: json['lat'] ?? 0.0,
      lng: json['lng'] ?? 0.0,
    );
  }
}
