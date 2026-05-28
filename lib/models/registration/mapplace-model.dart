class MapPlacesResponse{
  String? placeId;
  String? mainText;
  MapPlacesResponse({
     this.placeId,
     this.mainText,
  });

  factory MapPlacesResponse.fromJson(Map<String, dynamic> json) {
    return MapPlacesResponse(
      placeId: json['place_id'] ?? '',
      mainText: json['main_text'] ?? '',
    );
  }
  @override
  String toString() {
    return 'MapPlacesResponse(placeId: $placeId, mainText: $mainText)';
  }
}

class MapCoordinatesResponse{
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