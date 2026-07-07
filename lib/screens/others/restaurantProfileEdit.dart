import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/registration/mapplace-model.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/screens/others/restaurantBioPage.dart';
import 'package:fudiko/services/map-service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantProfileEdit extends StatefulWidget {
  final PartnerProfileModel? profile;

  const RestaurantProfileEdit({super.key, this.profile});

  @override
  State<RestaurantProfileEdit> createState() => _RestaurantProfileEditState();
}

class _RestaurantProfileEditState extends State<RestaurantProfileEdit> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090); // default: Delhi
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final MapService _mapService = MapService();
  Timer? _locationSearchDebounce;
  static final BitmapDescriptor _orangeMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  String? _selectedEstablishmentType;
  String _resolvedLocationText = '';
  bool _isSearchingLocations = false;
  String? _locationSearchError;
  List<MapPlacesResponse> _locationSuggestions = [];
  Set<Marker> _markers = {};
  int _locationSearchVersion = 0;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController.text = profile?.name ?? '';
    _selectedEstablishmentType = (profile != null && profile.type.isNotEmpty)
        ? profile.type
        : null;
    _locationController.text = profile?.address ?? '';

    final hasSavedLocation =
        profile != null && (profile.lat != 0 || profile.lng != 0);
    if (hasSavedLocation) {
      _selectedLocation = LatLng(profile.lat, profile.lng);
      _resolvedLocationText = _locationController.text;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: _selectedLocation,
          icon: _orangeMarker,
        ),
      };
    } else if (_locationController.text.isNotEmpty) {
      _setLocationFromAddress(_locationController.text);
    } else if (_locationController.text.isEmpty) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _locationSearchDebounce?.cancel();
    _locationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      geolocator.LocationPermission permission =
          await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied ||
          permission == geolocator.LocationPermission.deniedForever) {
        return;
      }

      geolocator.Position position =
          await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high,
          );

      final latLng = LatLng(position.latitude, position.longitude);
      _updateLocation(latLng);

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _setLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty || !mounted) return;

      final latLng = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );
      setState(() {
        _selectedLocation = latLng;
        _resolvedLocationText = address;
        _markers = {
          Marker(
            markerId: const MarkerId('selected'),
            position: latLng,
            icon: _orangeMarker,
          ),
        };
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    } catch (_) {
      // Keep the current address text even if geocoding fails.
    }
  }

  Future<void> _updateLocation(LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: latLng,
          icon: _orangeMarker,
        ),
      };
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address =
            '${p.street}, ${p.subLocality}, ${p.locality}, ${p.country}';
        setState(() {
          _locationController.text = address;
          _resolvedLocationText = address;
        });
      }
    } catch (e) {
      final fallbackAddress = '${latLng.latitude}, ${latLng.longitude}';
      setState(() {
        _locationController.text = fallbackAddress;
        _resolvedLocationText = fallbackAddress;
      });
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerPage(
          initialLocation: _selectedLocation,
          initialPlaceName: _locationController.text,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final lat = result['lat'] as double?;
    final lng = result['lng'] as double?;
    if (lat == null || lng == null) return;

    final latLng = LatLng(lat, lng);
    setState(() {
      _selectedLocation = latLng;
      final place = result['place'] as String? ?? '';
      _locationController.text = place;
      _resolvedLocationText = place;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: latLng,
          icon: _orangeMarker,
        ),
      };
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  void onSearchChanged(String query) {
    _locationSearchDebounce?.cancel();
    final currentVersion = ++_locationSearchVersion;

    if (query.trim() != _resolvedLocationText.trim()) {
      _resolvedLocationText = '';
    }

    _locationSearchDebounce = Timer(const Duration(milliseconds: 1500), () {
      final trimmedQuery = query.trim();

      if (!mounted || currentVersion != _locationSearchVersion) return;

      if (trimmedQuery.length < 3) {
        setState(() {
          _locationSuggestions = [];
          _isSearchingLocations = false;
          _locationSearchError = null;
        });
        return;
      }

      performSmartSearch(trimmedQuery);
    });
  }

  Future<void> performSmartSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 3) {
      setState(() {
        _locationSuggestions = [];
        _isSearchingLocations = false;
        _locationSearchError = null;
      });
      return;
    }

    final currentVersion = _locationSearchVersion;

    setState(() {
      _isSearchingLocations = true;
      _locationSearchError = null;
      _locationSuggestions = [];
    });

    try {
      final results = await _mapService.smartPlaceSearchProgressive(
        trimmedQuery,
        // userLatLng: _selectedLocation,
        onResults: (results, isLoadingMore) {
          if (!mounted || currentVersion != _locationSearchVersion) return;
          if (_locationController.text.trim() != trimmedQuery) return;

          setState(() {
            _locationSuggestions = results;
            _locationSearchError = null;
            _isSearchingLocations = results.isEmpty && isLoadingMore;
          });
        },
      );

      if (!mounted || currentVersion != _locationSearchVersion) return;
      if (_locationController.text.trim() != trimmedQuery) return;

      setState(() {
        _locationSuggestions = results;
        _locationSearchError = results.isEmpty ? 'No places found' : null;
        _isSearchingLocations = false;
      });
    } catch (e) {
      if (!mounted || currentVersion != _locationSearchVersion) return;
      if (_locationController.text.trim() != trimmedQuery) return;

      setState(() {
        _locationSuggestions = [];
        _locationSearchError = e is MapPlaceSearchException
            ? e.message
            : 'Could not load suggestions. Please try again.';
        _isSearchingLocations = false;
      });
    }
  }

  Future<void> _selectLocationSuggestion(MapPlacesResponse place) async {
    final placeId = place.placeId;
    final placeName = place.mainText ?? '';
    final hasCoordinates = place.lat != null && place.lng != null;
    if (!hasCoordinates && (placeId == null || placeId.isEmpty)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchingLocations = true;
      _locationController.text = placeName;
      _resolvedLocationText = placeName;
      _locationSuggestions = [];
      _locationSearchError = null;
    });

    final coordinates = hasCoordinates
        ? MapCoordinatesResponse(lat: place.lat, lng: place.lng)
        : await _mapService.getPlace(placeId!);

    final lat = coordinates.lat;
    final lng = coordinates.lng;
    if (!mounted) return;
    if (lat == null || lng == null) {
      setState(() => _isSearchingLocations = false);
      return;
    }

    final latLng = LatLng(lat, lng);
    setState(() {
      _selectedLocation = latLng;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: latLng,
          icon: _orangeMarker,
        ),
      };
      _resolvedLocationText = placeName;
      _isSearchingLocations = false;
      _locationSearchError = null;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  Future<bool> _resolveTypedLocationIfNeeded() async {
    final locationText = _locationController.text.trim();
    if (locationText.isEmpty) return false;
    if (_resolvedLocationText.trim() == locationText) return true;

    try {
      final locations = await locationFromAddress(locationText);
      if (locations.isEmpty || !mounted) return false;

      final latLng = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );
      setState(() {
        _selectedLocation = latLng;
        _resolvedLocationText = locationText;
        _locationSuggestions = [];
        _locationSearchError = null;
        _markers = {
          Marker(
            markerId: const MarkerId('selected'),
            position: latLng,
            icon: _orangeMarker,
          ),
        };
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      return true;
    } catch (e) {
      return false;
    }
  }

  double _contentMaxWidth(Size size) {
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 460;
    if (Breakpoints.isTabletDevice(size) ||
        Breakpoints.isWideShortPhone(size)) {
      return 440;
    }
    return double.infinity;
  }

  EdgeInsets _contentPadding(Size size) {
    final width = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    return EdgeInsets.symmetric(
      horizontal: isWideShortPhone
          ? 24.0
          : isMobile
          ? 30.w
          : AppDimensions.padding(width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final isTabletLandscape =
        Breakpoints.isTabletDevice(size) && screenWidth > size.height;
    final bannerHeight = isWideShortPhone
        ? 120.0
        : isTabletLandscape
        ? 130.0
        : isMobile
        ? 150.h
        : 160.0;
    final headerPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(screenWidth);
    final backSize = isMobile ? 28.w : 26.0;
    final topGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 50.h
        : 44.0;
    final fieldGap = isMobile ? 20.h : 18.0;
    final smallGap = isMobile ? 8.h : 8.0;
    final actionGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 40.h
        : 34.0;
    final bottomGap = isWideShortPhone
        ? 28.0
        : isMobile
        ? 60.h
        : 48.0;
    final fieldRadius = isMobile ? 20.r : 18.0;
    final fieldTextSize = isMobile ? 16.0 : 14.0;
    final mapHeight = isWideShortPhone
        ? 150.0
        : isTabletLandscape
        ? 180.0
        : isMobile
        ? 200.h
        : 240.0;
    final mapIconMargin = isMobile ? 12.r : 12.0;
    final mapIconPadding = isMobile ? 8.r : 8.0;
    final mapIconSize = isMobile ? 18.sp : 18.0;
    final suggestionRadius = isMobile ? 16.r : 16.0;
    final suggestionMaxHeight = isMobile ? 220.h : 220.0;
    final suggestionTextSize = isMobile ? 14.sp : 14.0;
    final buttonWidth = isMobile ? 160.w : 160.0;
    final buttonHeight = isMobile ? 50.h : 48.0;

    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/banner1.png',
                  height: bannerHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.all(headerPadding),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    // child: Icon(
                    //   Icons.arrow_back_ios_outlined,
                    //   size: 30.w,
                    //   color: Colors.white,
                    // ),
                    child: Image.asset(
                      'assets/images/backarrow_icon.png',
                      width: backSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: _contentPadding(size),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _contentMaxWidth(size)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: topGap),
                    AppTextFeild(
                      text: "Establishment Name",
                      controller: _nameController,
                      fieldBorderRadius: fieldRadius,
                      size: fieldTextSize,
                    ),
                    SizedBox(height: fieldGap),
                    AppDropDown(
                      hint: _selectedEstablishmentType ?? 'Establishment type',
                      onChanged: (value) =>
                          setState(() => _selectedEstablishmentType = value),
                    ),
                    SizedBox(height: fieldGap),

                    Container(
                      height: mapHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(fieldRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: isMobile ? 10.r : 10.0,
                            offset: Offset(0, isMobile ? 4.r : 4.0),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(fieldRadius),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _selectedLocation,
                                zoom: 14,
                              ),
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                              markers: _markers,
                              myLocationButtonEnabled: false,
                              myLocationEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              compassEnabled: false,
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _openMapPicker,
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      margin: EdgeInsets.all(mapIconMargin),
                                      padding: EdgeInsets.all(mapIconPadding),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: isMobile ? 8.r : 8.0,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.open_in_full,
                                        color: Colors.orange,
                                        size: mapIconSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: fieldGap),

                    Column(
                      children: [
                        AppTextFeild(
                          text: "Location",
                          controller: _locationController,
                          icon: Icons.location_on,
                          onChanged: onSearchChanged,
                          fieldBorderRadius: fieldRadius,
                          size: fieldTextSize,
                        ),
                        if (_isSearchingLocations) ...[
                          SizedBox(height: smallGap),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12.h : 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                suggestionRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child: CupertinoActivityIndicator(radius: 8),
                              ),
                            ),
                          ),
                        ] else if (_locationSearchError != null) ...[
                          SizedBox(height: smallGap),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 14.w : 14.0,
                              vertical: isMobile ? 12.h : 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                suggestionRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _locationSearchError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: suggestionTextSize,
                              ),
                            ),
                          ),
                        ] else if (_locationSuggestions.isNotEmpty) ...[
                          SizedBox(height: smallGap),
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxHeight: suggestionMaxHeight,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                suggestionRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _locationSuggestions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              itemBuilder: (context, index) {
                                final place = _locationSuggestions[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.orange,
                                  ),
                                  title: Text(
                                    place.mainText ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: suggestionTextSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: (place.secondaryText ?? '').isEmpty
                                      ? null
                                      : Text(
                                          place.secondaryText!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                  onTap: () => _selectLocationSuggestion(place),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: actionGap),
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: AppButton(
                        text: 'Add',
                        size: 15,
                        onPressed: () async {
                          if (_nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter establishment name',
                                ),
                              ),
                            );
                            return;
                          }
                          if (_selectedEstablishmentType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select establishment type',
                                ),
                              ),
                            );
                            return;
                          }
                          if (_locationController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter location'),
                              ),
                            );
                            return;
                          }
                          final hasResolvedLocation =
                              await _resolveTypedLocationIfNeeded();
                          if (!context.mounted) return;
                          if (!hasResolvedLocation) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a valid location'),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantBioEditPage(
                                establishmentName: _nameController.text,
                                establishmentType: _selectedEstablishmentType!,
                                location: _locationController.text,
                                lat: _selectedLocation.latitude,
                                lng: _selectedLocation.longitude,
                                description: widget.profile?.description ?? '',
                                availableDishes:
                                    widget.profile?.availableDishes ?? '',
                                phone: widget.profile?.phone ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: bottomGap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPickerPage extends StatefulWidget {
  final LatLng initialLocation;
  final String initialPlaceName;

  const _MapPickerPage({
    required this.initialLocation,
    required this.initialPlaceName,
  });

  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  GoogleMapController? _mapController;
  final TextEditingController _placeSearchController = TextEditingController();
  final MapService _mapService = MapService();
  Timer? _placeSearchDebounce;
  static final BitmapDescriptor _orangeMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  late LatLng _pickedLocation;
  late String _placeName;
  bool _isGeocoding = false;
  bool _isSearchingPlaces = false;
  bool _isFetchingNextPage = false;
  bool _isFetchingCurrentLocation = false;
  bool _hasSubmittedSearch = false;
  String? _placeSearchError;
  List<MapPlacesResponse> _placeSuggestions = [];
  List<MapPlacesResponse> _textSearchResults = [];
  List<MapPlacesResponse> _savedAddresses = [];
  List<MapPlacesResponse> _recentSearches = [];
  Set<Marker> _markers = {};
  int _placeSearchRequestId = 0;
  bool _isSearchDropdownOpen = false;
  bool _showPickedMarker = false;
  static const String _recentSearchPrefsKey = 'recent_map_place_searches';

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    _placeName = 'Fetching location...';
    _placeSearchController.clear();
    _showPickedMarker = false;
    _updateMarker(_pickedLocation);
    _loadSavedAndRecent();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _placeSearchDebounce?.cancel();
    _placeSearchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation({bool selectLocation = false}) async {
    if (_isFetchingCurrentLocation) return;

    setState(() {
      _isFetchingCurrentLocation = true;
    });

    try {
      geolocator.LocationPermission permission =
          await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied ||
          permission == geolocator.LocationPermission.deniedForever) {
        await _reverseGeocode(_pickedLocation);
        return;
      }

      final geolocator.Position position =
          await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high,
          );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickedLocation = latLng;
        if (selectLocation) {
          _showPickedMarker = true;
          _placeSuggestions = [];
          _textSearchResults = [];
          _isSearchDropdownOpen = false;
          _hasSubmittedSearch = false;
          _placeSearchError = null;
        }
      });
      await _animateTo(latLng, 15);
      _updateMarker(latLng);
      await _reverseGeocode(latLng);
    } catch (e) {
      debugPrint('Location error: $e');
      await _reverseGeocode(_pickedLocation);
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isGeocoding = true);
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((value) => value != null && value.isNotEmpty).toList();
        final address = parts.join(', ');
        setState(() {
          _placeName = address;
        });
      }
    } catch (e) {
      setState(() {
        _placeName = '${latLng.latitude}, ${latLng.longitude}';
      });
    }
    setState(() => _isGeocoding = false);
  }

  void _onPlaceSearchChanged(String value) {
    _placeSearchDebounce?.cancel();
    final trimmed = value.trim();
    final requestId = ++_placeSearchRequestId;

    if (trimmed.length < 3) {
      setState(() {
        _placeSuggestions = [];
        _textSearchResults = [];
        _isSearchDropdownOpen = true;
        _isSearchingPlaces = false;
        _isFetchingNextPage = false;
        _placeSearchError = null;
        _hasSubmittedSearch = false;
      });
      return;
    }

    setState(() {
      _isSearchDropdownOpen = true;
      _isSearchingPlaces = true;
      _placeSearchError = null;
      _hasSubmittedSearch = true;
    });
    _placeSearchDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || requestId != _placeSearchRequestId) return;
      smartPlaceSearch();
    });
  }

  Future<void> fetchAutocompleteSuggestions(String query) async {
    final trimmedQuery = query.trim();
    List<MapPlacesResponse> suggestions = [];
    try {
      suggestions = await _mapService.fetchAutocompleteSuggestions(
        trimmedQuery,
        // _pickedLocation,
      );
    } catch (e) {
      if (!mounted || _placeSearchController.text.trim() != trimmedQuery) {
        return;
      }
      setState(() {
        _placeSearchError = e is MapPlaceSearchException
            ? e.message
            : 'Could not load suggestions. Please try again.';
        _isSearchingPlaces = false;
      });
      return;
    }

    if (!mounted || _placeSearchController.text.trim() != trimmedQuery) return;

    setState(() {
      _placeSuggestions = suggestions;
      _isSearchingPlaces = false;
    });
  }

  Future<void> smartPlaceSearch({LatLng? location}) async {
    final query = _placeSearchController.text.trim();
    if (query.isEmpty) return;

    _placeSearchDebounce?.cancel();
    // final searchLocation = location ?? _pickedLocation;
    final requestId = ++_placeSearchRequestId;

    setState(() {
      _hasSubmittedSearch = true;
      _isSearchDropdownOpen = true;
      _isSearchingPlaces = true;
      _isFetchingNextPage = false;
      _placeSearchError = null;
      _placeSuggestions = [];
      _textSearchResults = [];
    });

    try {
      final results = await _mapService.smartPlaceSearchProgressive(
        query,
        // userLatLng: searchLocation,
        onResults: (results, isLoadingMore) {
          if (!mounted || requestId != _placeSearchRequestId) return;

          setState(() {
            _textSearchResults = results;
            _isFetchingNextPage = isLoadingMore;
            _placeSearchError = null;
          });
        },
      );

      if (!mounted || requestId != _placeSearchRequestId) return;
      setState(() {
        _textSearchResults = results;
        _isSearchingPlaces = false;
        _isFetchingNextPage = false;
        _placeSearchError = results.isEmpty ? 'No places found' : null;
      });
    } catch (e) {
      if (!mounted || requestId != _placeSearchRequestId) return;
      setState(() {
        _isSearchingPlaces = false;
        _isFetchingNextPage = false;
        _placeSearchError = e is MapPlaceSearchException
            ? e.message
            : 'Could not search places. Please try again.';
      });
    }
  }

  List<MapPlacesResponse> mergeAndRemoveDuplicates(
    List<MapPlacesResponse> results,
  ) {
    return _mapService.mergeAndRemoveDuplicates(results);
  }

  Future<void> _selectPlaceSuggestion(MapPlacesResponse place) async {
    final placeId = place.placeId;
    final placeName = place.mainText ?? '';
    if (placeId == null || placeId.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchingPlaces = true;
      _placeName = placeName;
      _placeSearchController.text = placeName;
      _placeSuggestions = [];
      _textSearchResults = [];
      _isSearchDropdownOpen = false;
      _hasSubmittedSearch = false;
      _isFetchingNextPage = false;
      _placeSearchError = null;
    });

    final coordinates = await _mapService.getPlace(placeId);
    if (!mounted) return;

    final lat = coordinates.lat;
    final lng = coordinates.lng;
    if (lat == null || lng == null) {
      setState(() => _isSearchingPlaces = false);
      return;
    }

    final latLng = LatLng(lat, lng);
    setState(() {
      _pickedLocation = latLng;
      _showPickedMarker = true;
    });
    _updateMarker(latLng);
    await _animateTo(latLng, 15);
    await _reverseGeocode(latLng);
    await _saveRecentSearch(
      MapPlacesResponse(
        placeId: placeId,
        mainText: placeName,
        secondaryText: place.secondaryText,
        lat: latLng.latitude,
        lng: latLng.longitude,
      ),
    );
    if (mounted) {
      setState(() => _isSearchingPlaces = false);
    }
  }

  Future<void> _selectSearchResult(MapPlacesResponse place) async {
    final lat = place.lat;
    final lng = place.lng;
    if (lat == null || lng == null) return;

    final latLng = LatLng(lat, lng);
    final label = [
      place.mainText,
      place.secondaryText,
    ].where((value) => value != null && value.isNotEmpty).join(', ');

    FocusScope.of(context).unfocus();
    setState(() {
      _pickedLocation = latLng;
      _placeName = label;
      _placeSearchController.text = place.mainText ?? label;
      _placeSuggestions = [];
      _textSearchResults = [];
      _isSearchDropdownOpen = false;
      _hasSubmittedSearch = false;
      _isFetchingNextPage = false;
      _placeSearchError = null;
      _showPickedMarker = true;
    });
    _updateMarker(latLng);
    await _animateTo(latLng, 16);
    await _saveRecentSearch(place);
  }

  Future<void> _animateTo(LatLng latLng, double zoom) async {
    final controller = _mapController;
    if (controller == null) return;

    await controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, zoom));
  }

  void _updateMarker(LatLng latLng) {
    setState(() {
      _markers = _showPickedMarker
          ? {
              Marker(
                markerId: const MarkerId('picked'),
                position: latLng,
                icon: _orangeMarker,
                draggable: true,
                onDragEnd: (newPos) async {
                  setState(() {
                    _pickedLocation = newPos;
                    _showPickedMarker = true;
                  });
                  await _reverseGeocode(newPos);
                  _updateMarker(newPos);
                },
              ),
            }
          : {};
    });
  }

  Future<void> _loadSavedAndRecent() async {
    final saved = widget.initialPlaceName.trim().isEmpty
        ? <MapPlacesResponse>[]
        : [
            MapPlacesResponse(
              placeId: 'saved_initial',
              mainText: widget.initialPlaceName,
              secondaryText: 'Saved address',
              lat: widget.initialLocation.latitude,
              lng: widget.initialLocation.longitude,
            ),
          ];

    final prefs = await SharedPreferences.getInstance();
    final rawRecent = prefs.getStringList(_recentSearchPrefsKey) ?? [];
    final recent = rawRecent
        .map((value) {
          try {
            return MapPlacesResponse.fromJson(
              Map<String, dynamic>.from(jsonDecode(value) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<MapPlacesResponse>()
        .toList();

    if (!mounted) return;
    setState(() {
      _savedAddresses = saved;
      _recentSearches = mergeAndRemoveDuplicates(recent);
    });
  }

  Future<void> _saveRecentSearch(MapPlacesResponse place) async {
    if ((place.mainText ?? '').isEmpty) return;

    final merged = mergeAndRemoveDuplicates([
      place,
      ..._recentSearches,
    ]).take(6).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchPrefsKey,
      merged.map((place) => jsonEncode(place.toJson())).toList(),
    );

    if (!mounted) return;
    setState(() => _recentSearches = merged);
  }

  bool _canShowQuickSuggestions() {
    return _isSearchDropdownOpen &&
        !_hasSubmittedSearch &&
        !_isSearchingPlaces &&
        (_savedAddresses.isNotEmpty ||
            _recentSearches.isNotEmpty ||
            _placeSuggestions.isNotEmpty);
  }

  Widget _buildPlaceSearchField({
    required bool isMobile,
    required double panelRadius,
  }) {
    final hasText = _placeSearchController.text.trim().isNotEmpty;
    final iconSize = isMobile ? 22.0 : 20.0;

    return TextField(
      controller: _placeSearchController,
      textInputAction: TextInputAction.search,
      onTap: () {
        setState(() => _isSearchDropdownOpen = true);
      },
      onChanged: _onPlaceSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search place',
        prefixIcon: Icon(Icons.search, color: Colors.orange, size: iconSize),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(Icons.close, color: Colors.orange, size: iconSize),
                onPressed: () {
                  _placeSearchDebounce?.cancel();
                  _placeSearchRequestId++;
                  setState(() {
                    _placeSearchController.clear();
                    _placeSuggestions = [];
                    _textSearchResults = [];
                    _isSearchingPlaces = false;
                    _isFetchingNextPage = false;
                    _hasSubmittedSearch = false;
                    _placeSearchError = null;
                    _isSearchDropdownOpen = true;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(panelRadius),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12.h : 12.0),
      ),
    );
  }

  Widget _buildQuickSuggestions({
    required bool isMobile,
    required double maxHeight,
    required double panelRadius,
  }) {
    if (!_canShowQuickSuggestions()) return const SizedBox.shrink();

    return _buildListShell(
      maxHeight: maxHeight,
      panelRadius: panelRadius,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          if (_savedAddresses.isNotEmpty)
            _buildPlaceSection(
              title: 'Saved addresses',
              places: _savedAddresses,
              icon: Icons.bookmark_border,
              isMobile: isMobile,
              onTap: _selectSearchResult,
            ),
          if (_recentSearches.isNotEmpty)
            _buildPlaceSection(
              title: 'Recent searches',
              places: _recentSearches,
              icon: Icons.history,
              isMobile: isMobile,
              onTap: _selectSearchResult,
            ),
          if (_placeSuggestions.isNotEmpty)
            _buildPlaceSection(
              title: 'Suggestions',
              places: _placeSuggestions,
              icon: Icons.location_on_outlined,
              isMobile: isMobile,
              onTap: _selectPlaceSuggestion,
            ),
        ],
      ),
    );
  }

  Widget _buildTextSearchResults({
    required bool isMobile,
    required double maxHeight,
    required double panelRadius,
  }) {
    if (!_isSearchDropdownOpen || !_hasSubmittedSearch) {
      return const SizedBox.shrink();
    }

    if (_placeSearchError != null) {
      return _buildListShell(
        maxHeight: maxHeight,
        panelRadius: panelRadius,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 14.w : 14.0),
          child: Text(
            _placeSearchError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    if (_textSearchResults.isEmpty && _isSearchingPlaces) {
      return _buildListShell(
        maxHeight: maxHeight,
        panelRadius: panelRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 18.h : 18.0),
          child: const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ),
            ),
          ),
        ),
      );
    }

    if (_textSearchResults.isEmpty && !_isSearchingPlaces) {
      return _buildListShell(
        maxHeight: maxHeight,
        panelRadius: panelRadius,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 14.w : 14.0),
          child: const Text(
            'No places found',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    if (_textSearchResults.isEmpty) return const SizedBox.shrink();

    return _buildListShell(
      maxHeight: maxHeight,
      panelRadius: panelRadius,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _textSearchResults.length + (_isFetchingNextPage ? 1 : 0),
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.18)),
        itemBuilder: (context, index) {
          if (index >= _textSearchResults.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange,
                  ),
                ),
              ),
            );
          }

          final place = _textSearchResults[index];
          return _buildPlaceTile(
            place: place,
            icon: Icons.place_outlined,
            isMobile: isMobile,
            onTap: () => _selectSearchResult(place),
          );
        },
      ),
    );
  }

  Widget _buildListShell({
    required double maxHeight,
    required double panelRadius,
    required Widget child,
  }) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(panelRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _buildPlaceSection({
    required String title,
    required List<MapPlacesResponse> places,
    required IconData icon,
    required bool isMobile,
    required ValueChanged<MapPlacesResponse> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 14.w : 14.0,
            isMobile ? 10.h : 10.0,
            isMobile ? 14.w : 14.0,
            isMobile ? 4.h : 4.0,
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...places.map(
          (place) => _buildPlaceTile(
            place: place,
            icon: icon,
            isMobile: isMobile,
            onTap: () => onTap(place),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceTile({
    required MapPlacesResponse place,
    required IconData icon,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.orange, size: isMobile ? 24.0 : 22.0),
      title: AppText(
        text: place.mainText ?? '',
        size: isMobile ? 14.sp : 14.0,
        fontWeight: FontWeight.w500,
      ),
      subtitle: (place.secondaryText ?? '').isEmpty
          ? null
          : Text(
              place.secondaryText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isLandscape = screenWidth > size.height;
    final overlayPadding = isWideShortPhone
        ? 16.0
        : isMobile
        ? 16.w
        : AppDimensions.padding(screenWidth);
    final overlayTop = isWideShortPhone
        ? 12.0
        : isMobile
        ? 16.h
        : 24.0;
    final panelRadius = isMobile ? 14.r : 14.0;
    final suggestionGap = isMobile ? 8.h : 8.0;
    final suggestionMaxHeight = isWideShortPhone
        ? 150.0
        : isMobile
        ? 220.h
        : (isTablet && isLandscape
              ? 180.0
              : isTablet
              ? 280.0
              : 300.0);
    final searchPanelMaxWidth = isMobile ? double.infinity : 560.0;
    final bottomPanelMaxWidth = isMobile ? double.infinity : 680.0;
    final bottomPanelMargin = isMobile || isWideShortPhone
        ? EdgeInsets.zero
        : const EdgeInsets.all(24);
    final bottomPanelPadding = EdgeInsets.symmetric(
      horizontal: isWideShortPhone
          ? 16.0
          : isMobile
          ? 20.w
          : 20.0,
      vertical: isWideShortPhone
          ? 10.0
          : isMobile
          ? 16.h
          : 14.0,
    );
    final bottomPanelRadius = BorderRadius.circular(
      isMobile || isWideShortPhone ? 0 : 18.0,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'lat': _pickedLocation.latitude,
                'lng': _pickedLocation.longitude,
                'place': _placeName,
              });
            },
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _animateTo(_pickedLocation, 15);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (latLng) async {
              setState(() {
                _pickedLocation = latLng;
                _showPickedMarker = true;
              });
              _updateMarker(latLng);
              await _reverseGeocode(latLng);
            },
          ),
          Positioned(
            top: overlayTop,
            left: overlayPadding,
            right: overlayPadding,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: searchPanelMaxWidth),
                child: Column(
                  children: [
                    Material(
                      color: Colors.white,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(panelRadius),
                      child: _buildPlaceSearchField(
                        isMobile: isMobile,
                        panelRadius: panelRadius,
                      ),
                    ),
                    if (_canShowQuickSuggestions()) ...[
                      SizedBox(height: suggestionGap),
                      _buildQuickSuggestions(
                        isMobile: isMobile,
                        maxHeight: suggestionMaxHeight,
                        panelRadius: panelRadius,
                      ),
                    ],
                    if (_hasSubmittedSearch) ...[
                      SizedBox(height: suggestionGap),
                      _buildTextSearchResults(
                        isMobile: isMobile,
                        maxHeight: suggestionMaxHeight,
                        panelRadius: panelRadius,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: bottomPanelMargin,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: bottomPanelMaxWidth),
                  child: Container(
                    padding: bottomPanelPadding,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: bottomPanelRadius,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.orange),
                        SizedBox(width: isMobile ? 10.w : 10.0),
                        Expanded(
                          child: _isGeocoding
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _placeName,
                                  maxLines: isMobile ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                        IconButton(
                          onPressed: _isFetchingCurrentLocation
                              ? null
                              : () => _getCurrentLocation(selectLocation: true),
                          icon: _isFetchingCurrentLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          color: Colors.orange,
                          tooltip: 'Use current location',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
