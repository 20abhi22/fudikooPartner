import 'package:flutter/foundation.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/registration/mapplace-model.dart';

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class MapPlaceSearchException implements Exception {
  final String status;
  final String message;

  const MapPlaceSearchException(this.status, this.message);

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Callback typedef (kept for callers that use the progressive variant)
// ---------------------------------------------------------------------------

typedef PlaceSearchProgressCallback =
    void Function(List<MapPlacesResponse> results, bool isLoadingMore);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class MapService {
  // ── Search ──────────────────────────────────────────────────────────────

  /// Returns autocomplete predictions for [query].
  /// Mirrors the old `fetchAutocompletePredictions` / `fetchAutocompleteSuggestions`
  /// surface but routes through the backend.
  Future<List<MapPlacesResponse>> fetchAutocompletePredictions(
    String query,
  ) async {
    try {
      final response = await DioClient.dio.get(
        '/places/search',
        queryParameters: {'input': query},
      );

      _ensureOkStatus(response.data);

      final rawPredictions = response.data['predictions'];
      final predictions =
          rawPredictions is List ? rawPredictions : <dynamic>[];

      return predictions.map<MapPlacesResponse>((place) {
        final json = _asMap(place);
        final structured = json['structured_formatting'] is Map
            ? _asMap(json['structured_formatting'])
            : <String, dynamic>{};

        return MapPlacesResponse.fromJson({
          'place_id': json['place_id'],
          'main_text':
              structured['main_text'] ?? json['description'] ?? json['name'],
          'secondary_text': structured['secondary_text'] ?? '',
          'types': json['types'],
          'is_seed': false,
        });
      }).toList();
    } on MapPlaceSearchException {
      rethrow;
    } catch (e) {
      debugPrint('MapService.fetchAutocompletePredictions error: $e');
      throw const MapPlaceSearchException(
        'NETWORK_ERROR',
        'Could not load search suggestions. Please try again.',
      );
    }
  }

  /// Convenience alias kept for backward compatibility.
  Future<List<MapPlacesResponse>> fetchAutocompleteSuggestions(
    String query,
  ) =>
      fetchAutocompletePredictions(query);

  // ── Place details ────────────────────────────────────────────────────────

  /// Fetches full place details (name, address, lat/lng) for [placeId].
  Future<MapPlacesResponse> fetchPlaceDetails(String placeId) async {
    try {
      final response = await DioClient.dio.get(
        '/places/details',
        queryParameters: {'place_id': placeId},
      );

      _ensureOkStatus(response.data);

      final rawResult = response.data['result'];
      if (rawResult is! Map) {
        throw const MapPlaceSearchException(
          'INVALID_REQUEST',
          'Place details were not available.',
        );
      }

      final result = _asMap(rawResult);
      return _placeFromResultJson(result, placeId: placeId);
    } on MapPlaceSearchException {
      rethrow;
    } catch (e) {
      debugPrint('MapService.fetchPlaceDetails error: $e');
      throw const MapPlaceSearchException(
        'NETWORK_ERROR',
        'Could not load place details. Please try again.',
      );
    }
  }

  /// Returns only coordinates for [placeId].
  /// Kept for callers that previously used `getPlace`.
  Future<MapCoordinatesResponse> getPlace(String placeId) async {
    try {
      final response = await DioClient.dio.get(
        '/places/details',
        queryParameters: {'place_id': placeId},
      );

      _ensureOkStatus(response.data);

      final location =
          response.data['result']?['geometry']?['location'];
      if (location == null) {
        return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
      }
      return MapCoordinatesResponse.fromJson(
        _asMap(location),
      );
    } catch (e) {
      debugPrint('MapService.getPlace error: $e');
      return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
    }
  }

  // ── Higher-level helpers (kept for call-site compatibility) ──────────────

  /// Searches for places matching [query] and returns a flat list.
  /// Replaces `smartPlaceSearch` / `nearbySearchPlaces`.
  Future<List<MapPlacesResponse>> smartPlaceSearch(String query) =>
      fetchAutocompletePredictions(query);

  /// Progressive variant — emits results immediately then resolves details.
  /// Replaces `smartPlaceSearchProgressive`.
  Future<List<MapPlacesResponse>> smartPlaceSearchProgressive(
    String query, {
    required PlaceSearchProgressCallback onResults,
  }) async {
    // Emit initial empty loading state.
    onResults([], true);

    final predictions = await fetchAutocompletePredictions(query).catchError(
      (e) {
        debugPrint('Skipping autocomplete branch: $e');
        return <MapPlacesResponse>[];
      },
    );

    // Emit predictions immediately so the UI shows names without coords.
    onResults(predictions, true);

    // Resolve details (lat/lng) for each prediction progressively.
    final resolved = <MapPlacesResponse>[];
    for (final prediction in predictions) {
      final placeId = prediction.placeId;
      if (placeId == null || placeId.isEmpty) {
        resolved.add(prediction);
        onResults(List.unmodifiable(resolved), true);
        continue;
      }
      try {
        final detail = await fetchPlaceDetails(placeId);
        resolved.add(detail);
      } catch (_) {
        resolved.add(prediction);
      }
      onResults(List.unmodifiable(resolved), true);
    }

    onResults(List.unmodifiable(resolved), false);
    return resolved;
  }

  // ── Deduplication & sorting (unchanged, no external deps) ────────────────

  List<MapPlacesResponse> mergeAndRemoveDuplicates(
    List<MapPlacesResponse> results,
  ) {
    final seenKeys = <String>{};
    final unique = <MapPlacesResponse>[];
    for (final place in results) {
      if (seenKeys.add(_duplicateKey(place))) {
        unique.add(place);
      }
    }
    return unique;
  }

  List<MapPlacesResponse> sortResultsByRelevance(
    List<MapPlacesResponse> results,
    String query,
  ) {
    final normalizedQuery = _normalize(query);
    final sorted = [...results];

    sorted.sort((a, b) {
      final aName = _normalize(a.mainText ?? '');
      final bName = _normalize(b.mainText ?? '');

      final aExact = aName == normalizedQuery;
      final bExact = bName == normalizedQuery;
      if (aExact != bExact) return aExact ? -1 : 1;

      if (a.isSeed != b.isSeed) return a.isSeed ? -1 : 1;

      final aContains = aName.contains(normalizedQuery);
      final bContains = bName.contains(normalizedQuery);
      if (aContains != bContains) return aContains ? -1 : 1;

      final distCompare =
          (a.distanceMeters ?? double.infinity)
              .compareTo(b.distanceMeters ?? double.infinity);
      if (distCompare != 0) return distCompare;

      final ratingCompare = (b.rating ?? 0).compareTo(a.rating ?? 0);
      if (ratingCompare != 0) return ratingCompare;

      return (b.userRatingsTotal ?? 0).compareTo(a.userRatingsTotal ?? 0);
    });

    return sorted;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  MapPlacesResponse _placeFromResultJson(
    Map<String, dynamic> result, {
    required String placeId,
  }) {
    final geometry = result['geometry'] is Map
        ? _asMap(result['geometry'])
        : <String, dynamic>{};
    final location = geometry['location'] is Map
        ? _asMap(geometry['location'])
        : <String, dynamic>{};

    return MapPlacesResponse.fromJson({
      'place_id': placeId,
      'main_text': result['name'],
      'secondary_text': result['formatted_address'] ?? '',
      'lat': location['lat'],
      'lng': location['lng'],
      'types': result['types'],
      'rating': result['rating'],
      'user_ratings_total': result['user_ratings_total'],
      'is_seed': true,
    });
  }

  void _ensureOkStatus(dynamic data) {
    if (data is! Map) {
      throw const MapPlaceSearchException(
        'INVALID_RESPONSE',
        'Places search returned an invalid response.',
      );
    }
    final body = _asMap(data);
    final status = body['status']?.toString() ?? 'OK';
    if (status == 'OK') return;

    final message = switch (status) {
      'ZERO_RESULTS' => 'No places found.',
      'OVER_QUERY_LIMIT' => 'Search limit reached. Please try again later.',
      'REQUEST_DENIED' => 'Places request was denied.',
      'INVALID_REQUEST' => 'Invalid search request. Please try again.',
      _ => body['error_message']?.toString() ?? 'Places search failed.',
    };
    throw MapPlaceSearchException(status, message);
  }

  String _duplicateKey(MapPlacesResponse place) {
    final placeId = place.placeId;
    if (placeId != null && placeId.isNotEmpty) return 'id:$placeId';
    final name = _normalize(place.mainText ?? '');
    final lat = place.lat?.toStringAsFixed(5) ?? '';
    final lng = place.lng?.toStringAsFixed(5) ?? '';
    return 'fallback:$name:$lat:$lng';
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(value as Map);
  }
}




// import 'dart:math' as math;

// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:fudiko/api/dio_client.dart';
// import 'package:fudiko/models/registration/mapplace-model.dart';
// import 'package:fudiko/utils/tokens.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class MapPlaceSearchException implements Exception {
//   final String status;
//   final String message;

//   const MapPlaceSearchException(this.status, this.message);

//   @override
//   String toString() => message;
// }

// typedef PlaceSearchProgressCallback =
//     void Function(List<MapPlacesResponse> results, bool isLoadingMore);

// class MapService {
//   static const String _googlePlacesApiKey =
//       'GmapsAPIKey'; // Replace with your actual Google Places API key
//   static const int _defaultRadius = 5000;
//   static const String _placesBaseUrl =
//       'https://maps.googleapis.com/maps/api/place';

//   final Dio _googleDio = Dio();

//   Future<List<MapPlacesResponse>> fetchAutocompletePredictions(
//     String query, {
//     LatLng? location,
//     int radius = _defaultRadius,
//   }) async {
//     try {
//       final encodedQuery = Uri.encodeQueryComponent(query);
//       final locationBias = location == null
//           ? ''
//           : '&location=${location.latitude},${location.longitude}&radius=$radius';
//       final response = await _googleDio.get(
//         '$_placesBaseUrl/autocomplete/json'
//         '?input=$encodedQuery'
//         '$locationBias'
//         '&key=$_googlePlacesApiKey',
//       );
//       _ensureOkStatus(response.data);

//       final rawPredictions = response.data['predictions'];
//       final predictions = rawPredictions is List
//           ? rawPredictions
//           : <dynamic>[];

//       return predictions.take(5).map<MapPlacesResponse>((place) {
//         final json = _asMap(place);
//         final structured = json['structured_formatting'] is Map
//             ? _asMap(json['structured_formatting'])
//             : <String, dynamic>{};

//         return MapPlacesResponse.fromJson({
//           'place_id': json['place_id'],
//           'main_text':
//               structured['main_text'] ?? json['description'] ?? json['name'],
//           'secondary_text': structured['secondary_text'] ?? '',
//           'types': json['types'],
//           'is_seed': true,
//         });
//       }).toList();
//     } on MapPlaceSearchException {
//       rethrow;
//     } catch (e) {
//       debugPrint('Autocomplete search error: $e');
//       throw const MapPlaceSearchException(
//         'NETWORK_ERROR',
//         'Could not load search suggestions. Please try again.',
//       );
//     }
//   }

//   Future<List<MapPlacesResponse>> fetchAutocompleteSuggestions(
//     String query,
//     LatLng location,
//   ) {
//     return fetchAutocompletePredictions(query, location: location);
//   }

//   Future<MapPlacesResponse> fetchPlaceDetails(String placeId) async {
//     try {
//       final encodedPlaceId = Uri.encodeQueryComponent(placeId);
//       final response = await _googleDio.get(
//         '$_placesBaseUrl/details/json'
//         '?place_id=$encodedPlaceId'
//         '&fields=place_id,name,formatted_address,geometry,types,rating,user_ratings_total'
//         '&key=$_googlePlacesApiKey',
//       );
//       _ensureOkStatus(response.data);

//       final rawResult = response.data['result'];
//       if (rawResult is! Map) {
//         throw const MapPlaceSearchException(
//           'INVALID_REQUEST',
//           'Place details were not available.',
//         );
//       }

//       final result = _asMap(rawResult);
//       return _placeFromGoogleJson(result, isSeed: true);
//     } on MapPlaceSearchException {
//       rethrow;
//     } catch (e) {
//       debugPrint('Place details error: $e');
//       throw const MapPlaceSearchException(
//         'NETWORK_ERROR',
//         'Could not load place details. Please try again.',
//       );
//     }
//   }

//   Future<List<MapPlacesResponse>> nearbySearchPlaces(
//     String query,
//     LatLng location,
//   ) async {
//     return smartPlaceSearch(query, userLatLng: location);
//   }

//   Future<List<MapPlacesResponse>> smartPlaceSearch(
//     String query, {
//     required LatLng userLatLng,
//     int radius = _defaultRadius,
//   }) async {
//     var latestResults = <MapPlacesResponse>[];
//     await smartPlaceSearchProgressive(
//       query,
//       userLatLng: userLatLng,
//       radius: radius,
//       onResults: (results, _) => latestResults = results,
//     );
//     return latestResults;
//   }

//   Future<List<MapPlacesResponse>> smartPlaceSearchProgressive(
//     String query, {
//     required LatLng userLatLng,
//     int radius = _defaultRadius,
//     int seedLimit = 5,
//     required PlaceSearchProgressCallback onResults,
//   }) async {
//     final allResults = <MapPlacesResponse>[];
//     final branchErrors = <MapPlaceSearchException>[];
//     final dynamicRadius =
//         radius == _defaultRadius ? _dynamicRadiusForQuery(query) : radius;
//     final autocompleteFuture = fetchAutocompletePredictions(
//       query,
//       location: userLatLng,
//       radius: dynamicRadius,
//     );

//     List<MapPlacesResponse> emit(bool isLoadingMore) {
//       final uniqueResults = mergeAndRemoveDuplicates(allResults);
//       for (final place in uniqueResults) {
//         if (place.lat != null && place.lng != null) {
//           place.distanceMeters = calculateDistance(
//             userLatLng,
//             LatLng(place.lat!, place.lng!),
//           );
//         }
//       }
//       final sortedResults = sortResultsByRelevance(uniqueResults, query);
//       onResults(sortedResults, isLoadingMore);
//       return sortedResults;
//     }

//     final predictions = await autocompleteFuture.catchError((e) {
//       if (e is MapPlaceSearchException) branchErrors.add(e);
//       debugPrint('Skipping autocomplete branch: $e');
//       return <MapPlacesResponse>[];
//     });
//     final seedTasks = predictions.take(seedLimit).map((prediction) async {
//         final placeId = prediction.placeId;
//         if (placeId == null || placeId.isEmpty) return;

//         try {
//           final seed = await fetchPlaceDetails(placeId);
//           allResults.add(seed);
//           emit(true);
//           if (seed.lat == null || seed.lng == null) return;

//           await Future.wait([
//             _collectPageProgressively(
//               _searchNearbyPage(
//                 lat: seed.lat!,
//                 lng: seed.lng!,
//                 radius: dynamicRadius,
//                 keyword: _nearbyKeywordForQuery(query),
//                 type: _nearbyTypeForQuery(query),
//               ),
//               MapPlaceSearchType.nearby,
//               allResults,
//               () => emit(true),
//               onError: branchErrors.add,
//             ),
//             _collectPageProgressively(
//               _searchTextPage(
//                 query: query,
//                 lat: seed.lat!,
//                 lng: seed.lng!,
//                 radius: dynamicRadius,
//               ),
//               MapPlaceSearchType.text,
//               allResults,
//               () => emit(true),
//               onError: branchErrors.add,
//             ),
//           ]);
//         } catch (e) {
//           debugPrint('Skipping seed details for $placeId: $e');
//         }
//       });

//     await Future.wait(seedTasks);

//     if (allResults.isEmpty && branchErrors.isNotEmpty) {
//       throw branchErrors.first;
//     }

//     return emit(false);
//   }

//   Future<List<MapPlacesResponse>> searchNearbyFromSeed(
//     MapPlacesResponse seedPlace, {
//     String? query,
//     int radius = _defaultRadius,
//   }) async {
//     final lat = seedPlace.lat;
//     final lng = seedPlace.lng;
//     if (lat == null || lng == null) return [];

//     final firstPage = await _searchNearbyPage(
//       lat: lat,
//       lng: lng,
//       radius: radius,
//       keyword: _nearbyKeywordForQuery(query),
//       type: _nearbyTypeForQuery(query),
//     );
//     return _collectPages(firstPage, MapPlaceSearchType.nearby);
//   }

//   Future<List<MapPlacesResponse>> searchTextFromSeed(
//     String query,
//     MapPlacesResponse seedPlace, {
//     int radius = _defaultRadius,
//   }) async {
//     final lat = seedPlace.lat;
//     final lng = seedPlace.lng;
//     if (lat == null || lng == null) return [];

//     final firstPage = await _searchTextPage(
//       query: query,
//       lat: lat,
//       lng: lng,
//       radius: radius,
//     );
//     return _collectPages(firstPage, MapPlaceSearchType.text);
//   }

//   Future<List<MapPlacesResponse>> searchTextPlaces(
//     String query,
//     double lat,
//     double lng, {
//     int radius = _defaultRadius,
//   }) async {
//     final firstPage = await _searchTextPage(
//       query: query,
//       lat: lat,
//       lng: lng,
//       radius: radius,
//     );
//     return _collectPages(firstPage, MapPlaceSearchType.text);
//   }

//   Future<List<MapPlacesResponse>> searchNearbyPlaces(
//     double lat,
//     double lng, {
//     String? keyword,
//     int radius = _defaultRadius,
//   }) async {
//     final firstPage = await _searchNearbyPage(
//       lat: lat,
//       lng: lng,
//       radius: radius,
//       keyword: _nearbyKeywordForQuery(keyword),
//       type: _nearbyTypeForQuery(keyword),
//     );
//     return _collectPages(firstPage, MapPlaceSearchType.nearby);
//   }

//   Future<MapPlaceSearchPage> fetchNextPage(
//     String nextPageToken,
//     MapPlaceSearchType searchType,
//   ) async {
//     await Future.delayed(const Duration(seconds: 2));

//     try {
//       final encodedToken = Uri.encodeQueryComponent(nextPageToken);
//       final endpoint = searchType == MapPlaceSearchType.nearby
//           ? 'nearbysearch'
//           : 'textsearch';
//       final response = await _googleDio.get(
//         '$_placesBaseUrl/$endpoint/json'
//         '?pagetoken=$encodedToken'
//         '&key=$_googlePlacesApiKey',
//       );
//       _ensureOkStatus(response.data, allowZeroResults: true);
//       return _parseSearchResponse(response.data);
//     } on MapPlaceSearchException {
//       rethrow;
//     } catch (e) {
//       debugPrint('Next page search error: $e');
//       throw const MapPlaceSearchException(
//         'NETWORK_ERROR',
//         'Could not load more places. Please try again.',
//       );
//     }
//   }

//   List<MapPlacesResponse> mergeAndRemoveDuplicates(
//     List<MapPlacesResponse> results,
//   ) {
//     final seenKeys = <String>{};
//     final uniqueResults = <MapPlacesResponse>[];

//     for (final place in results) {
//       final key = _duplicateKey(place);
//       if (seenKeys.add(key)) {
//         uniqueResults.add(place);
//       }
//     }

//     return uniqueResults;
//   }

//   double calculateDistance(LatLng userLatLng, LatLng placeLatLng) {
//     const earthRadiusMeters = 6371000.0;
//     final dLat = _degreesToRadians(placeLatLng.latitude - userLatLng.latitude);
//     final dLng = _degreesToRadians(placeLatLng.longitude - userLatLng.longitude);
//     final lat1 = _degreesToRadians(userLatLng.latitude);
//     final lat2 = _degreesToRadians(placeLatLng.latitude);

//     final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(lat1) *
//             math.cos(lat2) *
//             math.sin(dLng / 2) *
//             math.sin(dLng / 2);
//     final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//     return earthRadiusMeters * c;
//   }

//   List<MapPlacesResponse> sortResultsByRelevance(
//     List<MapPlacesResponse> results,
//     String query,
//   ) {
//     final normalizedQuery = _normalize(query);
//     final sorted = [...results];

//     sorted.sort((a, b) {
//       final aName = _normalize(a.mainText ?? '');
//       final bName = _normalize(b.mainText ?? '');

//       final aExact = aName == normalizedQuery;
//       final bExact = bName == normalizedQuery;
//       if (aExact != bExact) return aExact ? -1 : 1;

//       if (a.isSeed != b.isSeed) return a.isSeed ? -1 : 1;

//       final aContains = aName.contains(normalizedQuery);
//       final bContains = bName.contains(normalizedQuery);
//       if (aContains != bContains) return aContains ? -1 : 1;

//       final distanceCompare = (a.distanceMeters ?? double.infinity).compareTo(
//         b.distanceMeters ?? double.infinity,
//       );
//       if (distanceCompare != 0) return distanceCompare;

//       final ratingCompare = (b.rating ?? 0).compareTo(a.rating ?? 0);
//       if (ratingCompare != 0) return ratingCompare;

//       return (b.userRatingsTotal ?? 0).compareTo(a.userRatingsTotal ?? 0);
//     });

//     return sorted;
//   }

//   Future<MapCoordinatesResponse> getPlace(String placeId) async {
//     try {
//       final token = await getToken();
//       final encodedPlaceId = Uri.encodeQueryComponent(placeId);
//       final response = await DioClient.dio.get(
//         '/places/details?place_id=$encodedPlaceId',
//         options: Options(headers: {'Authorization': 'Bearer $token'}),
//       );
//       if (response.statusCode == 200) {
//         final formattedData = response.data['result']['geometry']['location'];
//         return MapCoordinatesResponse.fromJson(formattedData);
//       } else {
//         debugPrint('Place details failed');
//         return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
//       }
//     } catch (e) {
//       debugPrint('Place details error: $e');
//       return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
//     }
//   }

//   Future<List<MapPlacesResponse>> _collectPages(
//     MapPlaceSearchPage firstPage,
//     MapPlaceSearchType searchType,
//   ) async {
//     final results = [...firstPage.results];
//     var nextPageToken = firstPage.nextPageToken;

//     while (nextPageToken != null && nextPageToken.isNotEmpty) {
//       final page = await fetchNextPage(nextPageToken, searchType);
//       results.addAll(page.results);
//       nextPageToken = page.nextPageToken;
//     }

//     return results;
//   }

//   Future<void> _collectPageProgressively(
//     Future<MapPlaceSearchPage> firstPageFuture,
//     MapPlaceSearchType searchType,
//     List<MapPlacesResponse> allResults,
//     VoidCallback emit, {
//     void Function(MapPlaceSearchException error)? onError,
//   }) async {
//     try {
//       var page = await firstPageFuture;
//       if (page.results.isNotEmpty) {
//         allResults.addAll(page.results);
//         emit();
//       }

//       var nextPageToken = page.nextPageToken;
//       while (nextPageToken != null && nextPageToken.isNotEmpty) {
//         page = await fetchNextPage(nextPageToken, searchType);
//         if (page.results.isNotEmpty) {
//           allResults.addAll(page.results);
//           emit();
//         }
//         nextPageToken = page.nextPageToken;
//       }
//     } catch (e) {
//       if (e is MapPlaceSearchException) onError?.call(e);
//       debugPrint('Skipping progressive search branch: $e');
//     }
//   }

//   Future<MapPlaceSearchPage> _searchNearbyPage({
//     required double lat,
//     required double lng,
//     required int radius,
//     String? keyword,
//     String? type,
//   }) async {
//     try {
//       final keywordParam = keyword == null || keyword.isEmpty
//           ? ''
//           : '&keyword=${Uri.encodeQueryComponent(keyword)}';
//       final typeParam = type == null || type.isEmpty
//           ? ''
//           : '&type=${Uri.encodeQueryComponent(type)}';
//       final response = await _googleDio.get(
//         '$_placesBaseUrl/nearbysearch/json'
//         '?location=$lat,$lng'
//         '&radius=$radius'
//         '$keywordParam'
//         '$typeParam'
//         '&key=$_googlePlacesApiKey',
//       );
//       _ensureOkStatus(response.data, allowZeroResults: true);
//       return _parseSearchResponse(response.data);
//     } on MapPlaceSearchException {
//       rethrow;
//     } catch (e) {
//       debugPrint('Nearby search error: $e');
//       throw const MapPlaceSearchException(
//         'NETWORK_ERROR',
//         'Could not search nearby places. Please try again.',
//       );
//     }
//   }

//   Future<MapPlaceSearchPage> _searchTextPage({
//     required String query,
//     required double lat,
//     required double lng,
//     required int radius,
//   }) async {
//     try {
//       final encodedQuery = Uri.encodeQueryComponent(query);
//       final response = await _googleDio.get(
//         '$_placesBaseUrl/textsearch/json'
//         '?query=$encodedQuery'
//         '&location=$lat,$lng'
//         '&radius=$radius'
//         '&key=$_googlePlacesApiKey',
//       );
//       _ensureOkStatus(response.data, allowZeroResults: true);
//       return _parseSearchResponse(response.data);
//     } on MapPlaceSearchException {
//       rethrow;
//     } catch (e) {
//       debugPrint('Text search error: $e');
//       throw const MapPlaceSearchException(
//         'NETWORK_ERROR',
//         'Could not search places. Please try again.',
//       );
//     }
//   }

//   MapPlaceSearchPage _parseSearchResponse(dynamic data) {
//     if (data is! Map) {
//       throw const MapPlaceSearchException(
//         'INVALID_RESPONSE',
//         'Places search returned an invalid response.',
//       );
//     }
//     final body = _asMap(data);
//     final rawResults = body['results'];
//     final results = rawResults is List ? rawResults : <dynamic>[];

//     return MapPlaceSearchPage(
//       status: body['status']?.toString() ?? 'OK',
//       errorMessage: body['error_message']?.toString(),
//       nextPageToken: body['next_page_token']?.toString() ??
//           body['nextPageToken']?.toString(),
//       results: results
//           .map((place) => _placeFromGoogleJson(_asMap(place)))
//           .toList(),
//     );
//   }

//   MapPlacesResponse _placeFromGoogleJson(
//     Map<String, dynamic> json, {
//     bool isSeed = false,
//   }) {
//     final geometry = json['geometry'] is Map
//         ? _asMap(json['geometry'])
//         : <String, dynamic>{};
//     final location = geometry['location'] is Map
//         ? _asMap(geometry['location'])
//         : <String, dynamic>{};

//     return MapPlacesResponse.fromJson({
//       'place_id': json['place_id'],
//       'main_text': json['name'],
//       'secondary_text': json['formatted_address'] ?? json['vicinity'] ?? '',
//       'lat': location['lat'],
//       'lng': location['lng'],
//       'types': json['types'],
//       'rating': json['rating'],
//       'user_ratings_total': json['user_ratings_total'],
//       'is_seed': isSeed,
//     });
//   }

//   void _ensureOkStatus(dynamic data, {bool allowZeroResults = false}) {
//     if (data is! Map) {
//       throw const MapPlaceSearchException(
//         'INVALID_RESPONSE',
//         'Places search returned an invalid response.',
//       );
//     }
//     final body = _asMap(data);
//     final status = body['status']?.toString() ?? 'OK';
//     if (status == 'OK') return;
//     if (allowZeroResults && status == 'ZERO_RESULTS') return;

//     final message = switch (status) {
//       'ZERO_RESULTS' => 'No places found',
//       'OVER_QUERY_LIMIT' => 'Search limit reached. Please try again later.',
//       'REQUEST_DENIED' => 'Google Places request was denied.',
//       'INVALID_REQUEST' => 'Invalid search request. Please try again.',
//       _ => body['error_message']?.toString() ?? 'Places search failed.',
//     };
//     throw MapPlaceSearchException(status, message);
//   }

//   bool _looksLikeGeneralAreaQuery(String query) {
//     final normalized = _normalize(query);
//     final words = normalized.split(' ').where((word) => word.isNotEmpty).toList();
//     const intentWords = {
//       'in',
//       'near',
//       'nearby',
//       'around',
//       'restaurant',
//       'restaurants',
//       'hotel',
//       'hotels',
//       'hospital',
//       'hospitals',
//       'cafe',
//       'cafes',
//       'store',
//       'stores',
//       'shop',
//       'shops',
//       'mall',
//       'school',
//       'college',
//       'bank',
//       'atm',
//     };

//     return words.length <= 2 && !words.any(intentWords.contains);
//   }

//   int _dynamicRadiusForQuery(String query) {
//     final normalized = _normalize(query);
//     if (normalized.contains('near me') ||
//         normalized.contains('nearby') ||
//         normalized.contains('around me')) {
//       return 3000;
//     }

//     if (_looksLikeGeneralAreaQuery(query)) {
//       return 8000;
//     }

//     return 5000;
//   }

//   String? _nearbyTypeForQuery(String? query) {
//     if (query == null || query.trim().isEmpty) return null;
//     final normalized = _normalize(query);

//     const typeMatches = {
//       'restaurant': ['restaurant', 'restaurants', 'food', 'dining'],
//       'cafe': ['cafe', 'coffee'],
//       'hospital': ['hospital', 'hospitals'],
//       'doctor': ['doctor', 'clinic'],
//       'pharmacy': ['pharmacy', 'medical store', 'chemist'],
//       'lodging': ['hotel', 'hotels', 'resort', 'stay', 'lodging'],
//       'school': ['school', 'schools'],
//       'university': ['college', 'university'],
//       'bank': ['bank', 'banks'],
//       'atm': ['atm'],
//       'shopping_mall': ['mall', 'shopping mall'],
//       'supermarket': ['supermarket', 'grocery', 'groceries'],
//       'store': ['store', 'stores', 'shop', 'shops'],
//       'gas_station': ['petrol', 'fuel', 'gas station'],
//       'parking': ['parking'],
//       'bus_station': ['bus stand', 'bus station'],
//       'train_station': ['railway', 'train station'],
//       'airport': ['airport'],
//     };

//     for (final entry in typeMatches.entries) {
//       if (entry.value.any((term) => normalized.contains(term))) {
//         return entry.key;
//       }
//     }

//     return null;
//   }

//   String? _nearbyKeywordForQuery(String? query) {
//     if (query == null || query.trim().isEmpty) return null;
//     if (_looksLikeGeneralAreaQuery(query)) return null;

//     final normalized = _normalize(query);
//     final splitPattern = RegExp(r'\b(in|near|nearby|around)\b');
//     final intentPart = normalized.split(splitPattern).first.trim();
//     final source = intentPart.isEmpty ? normalized : intentPart;
//     final cleanedWords = source
//         .split(' ')
//         .where(
//           (word) =>
//               word.isNotEmpty &&
//               word != 'me',
//         )
//         .toList();

//     if (cleanedWords.isEmpty) return null;
//     return cleanedWords.take(3).join(' ');
//   }

//   String _duplicateKey(MapPlacesResponse place) {
//     final placeId = place.placeId;
//     if (placeId != null && placeId.isNotEmpty) return 'id:$placeId';

//     final normalizedName = _normalize(place.mainText ?? '');
//     final lat = place.lat?.toStringAsFixed(5) ?? '';
//     final lng = place.lng?.toStringAsFixed(5) ?? '';
//     return 'fallback:$normalizedName:$lat:$lng';
//   }

//   String _normalize(String value) {
//     return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
//   }

//   double _degreesToRadians(double degrees) => degrees * math.pi / 180;

//   Map<String, dynamic> _asMap(dynamic value) {
//     if (value is Map<String, dynamic>) return value;
//     if (value is! Map) return <String, dynamic>{};
//     return Map<String, dynamic>.from(value as Map);
//   }
// }
