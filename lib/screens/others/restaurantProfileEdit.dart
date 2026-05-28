import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appdropdown.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/models/registration/mapplace-model.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/screens/others/restaurantBioPage.dart';
import 'package:fudiko/services/map-service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart';

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
  List<MapPlacesResponse> _locationSuggestions = [];
  Set<Marker> _markers = {};

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

  void _onLocationSearchChanged(String value) {
    _locationSearchDebounce?.cancel();
    if (value.trim() != _resolvedLocationText.trim()) {
      _resolvedLocationText = '';
    }

    if (value.trim().length < 3) {
      setState(() {
        _locationSuggestions = [];
        _isSearchingLocations = false;
      });
      return;
    }

    setState(() => _isSearchingLocations = true);
    _locationSearchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _loadLocationSuggestions(value),
    );
  }

  Future<void> _loadLocationSuggestions(String query) async {
    final trimmedQuery = query.trim();
    final suggestions = await _mapService.listPlaces(trimmedQuery);
    if (!mounted || _locationController.text.trim() != trimmedQuery) return;

    setState(() {
      _locationSuggestions = suggestions;
      _isSearchingLocations = false;
    });
  }

  Future<void> _selectLocationSuggestion(MapPlacesResponse place) async {
    final placeId = place.placeId;
    final placeName = place.mainText ?? '';
    if (placeId == null || placeId.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchingLocations = true;
      _locationController.text = placeName;
      _resolvedLocationText = placeName;
      _locationSuggestions = [];
    });

    final coordinates = await _mapService.getPlace(placeId);
    if (!mounted) return;

    final lat = coordinates.lat;
    final lng = coordinates.lng;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/banner1.png',
                  height: 150.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.all(30.w),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    // child: Icon(
                    //   Icons.arrow_back_ios_outlined,
                    //   size: 30.w,
                    //   color: Colors.white,
                    // ),
                    child: Image.asset(
                      'assets/images/backarrow_icon.png',
                      width: 28.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 50.h),
                  AppTextFeild(
                    text: "Establishment Name",
                    controller: _nameController,
                  ),
                  SizedBox(height: 20.h),
                  AppDropDown(
                    hint: _selectedEstablishmentType ?? 'Establishment type',
                    onChanged: (value) =>
                        setState(() => _selectedEstablishmentType = value),
                  ),
                  SizedBox(height: 20.h),

                  Container(
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.r),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
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
                                    margin: EdgeInsets.all(12.r),
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: 8.r,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.open_in_full,
                                      color: Colors.orange,
                                      size: 18.sp,
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
                  SizedBox(height: 20.h),

                  Column(
                    children: [
                      AppTextFeild(
                        text: "Location",
                        controller: _locationController,
                        icon: Icons.location_on,
                        onChanged: _onLocationSearchChanged,
                      ),
                      if (_isSearchingLocations) ...[
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
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
                      ] else if (_locationSuggestions.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(maxHeight: 220.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
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
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
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
                  SizedBox(height: 40.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 100.w),
                    child: AppButton(
                      text: 'Add',
                      onPressed: () async {
                        if (_nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter establishment name'),
                            ),
                          );
                          return;
                        }
                        if (_selectedEstablishmentType == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select establishment type'),
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
                  SizedBox(height: 60.h),
                ],
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
  bool _isFetchingCurrentLocation = false;
  List<MapPlacesResponse> _placeSuggestions = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    _placeName = widget.initialPlaceName.isEmpty
        ? 'Fetching location...'
        : widget.initialPlaceName;
    _placeSearchController.text = widget.initialPlaceName;
    _updateMarker(_pickedLocation);
    if (widget.initialPlaceName.isEmpty) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _placeSearchDebounce?.cancel();
    _placeSearchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
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
      setState(() => _pickedLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
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
          _placeSearchController.text = address;
        });
      }
    } catch (e) {
      setState(() {
        _placeName = '${latLng.latitude}, ${latLng.longitude}';
        _placeSearchController.text = _placeName;
      });
    }
    setState(() => _isGeocoding = false);
  }

  void _onPlaceSearchChanged(String value) {
    _placeSearchDebounce?.cancel();

    if (value.trim().length < 3) {
      setState(() {
        _placeSuggestions = [];
        _isSearchingPlaces = false;
      });
      return;
    }

    setState(() => _isSearchingPlaces = true);
    _placeSearchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _loadPlaceSuggestions(value),
    );
  }

  Future<void> _loadPlaceSuggestions(String query) async {
    final trimmedQuery = query.trim();
    final suggestions = await _mapService.listPlaces(trimmedQuery);
    if (!mounted || _placeSearchController.text.trim() != trimmedQuery) return;

    setState(() {
      _placeSuggestions = suggestions;
      _isSearchingPlaces = false;
    });
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
    setState(() => _pickedLocation = latLng);
    _updateMarker(latLng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    await _reverseGeocode(latLng);
    if (mounted) {
      setState(() => _isSearchingPlaces = false);
    }
  }

  void _updateMarker(LatLng latLng) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('picked'),
          position: latLng,
          icon: _orangeMarker,
          draggable: true,
          onDragEnd: (newPos) async {
            setState(() => _pickedLocation = newPos);
            await _reverseGeocode(newPos);
            _updateMarker(newPos);
          },
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(_pickedLocation, 15),
              );
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onTap: (latLng) async {
              setState(() => _pickedLocation = latLng);
              _updateMarker(latLng);
              await _reverseGeocode(latLng);
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TextField(
                  //   controller: _placeSearchController,
                  //   textInputAction: TextInputAction.search,
                  //   onChanged: _onPlaceSearchChanged,
                  //   decoration: InputDecoration(
                  //     hintText: 'Search place',
                  //     prefixIcon: const Icon(
                  //       Icons.search,
                  //       color: Colors.orange,
                  //     ),
                  //     suffixIcon: _isSearchingPlaces
                  //         ? const Padding(
                  //             padding: EdgeInsets.all(14),
                  //             child: SizedBox(
                  //               height: 16,
                  //               width: 16,
                  //               child: CircularProgressIndicator(
                  //                 strokeWidth: 2,
                  //               ),
                  //             ),
                  //           )
                  //         : const Icon(Icons.location_city_outlined),
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(14.r),
                  //       borderSide: BorderSide.none,
                  //     ),
                  //     filled: true,
                  //     fillColor: const Color(0xFFF5F5F5),
                  //     contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  //   ),
                  // ),
                  if (_placeSuggestions.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      constraints: BoxConstraints(maxHeight: 160.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _placeSuggestions.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.grey.withValues(alpha: 0.18),
                        ),
                        itemBuilder: (context, index) {
                          final place = _placeSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.orange,
                            ),
                            title: Text(
                              place.mainText ?? '',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => _selectPlaceSuggestion(place),
                          );
                        },
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _isGeocoding
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CupertinoActivityIndicator(
                                  radius: 7,
                                  color: Colors.orange,
                                ),
                              )
                            : Text(
                                _placeName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isFetchingCurrentLocation
                          ? null
                          : _getCurrentLocation,
                      icon: _isFetchingCurrentLocation
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _isFetchingCurrentLocation
                            ? 'Fetching location...'
                            : 'Use current location',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudiko/components/appbutton.dart';
// import 'package:fudiko/components/appdropdown.dart';
// import 'package:fudiko/components/apptextfeild.dart';
// import 'package:fudiko/screens/others/restaurantBioPage.dart';

// class RestaurantProfileEdit extends StatelessWidget {
//   const RestaurantProfileEdit({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               Stack(
//                 children: [
//                   Image.asset(
//                     'assets/images/banner1.png',
//                     height: 150.h,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                   ),
//                   Padding(
//                     padding:  EdgeInsets.all(30.w),
//                     child: GestureDetector(
//                       onTap: (){
//                         Navigator.pop(context);
//                       },
//                       child: Icon(
//                         Icons.arrow_back_ios_outlined,
//                         size: 30.w,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               ConstrainedBox(
//                 constraints: BoxConstraints(
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 30.w),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(height: 50.h),

//                       AppTextFeild(text: "Establishment Name"),
//                       SizedBox(height: 20.h),
//                       AppDropDown(
//                         hint: 'Establishment type',
//                       ),
//                       SizedBox(height: 20.h),
//                       Container(
//                         height: 200.h,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(20.r),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               blurRadius: 10.r,
//                               offset: Offset(0, 4.r),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 20.h),
//                       AppTextFeild(text: "Location"),
//                       SizedBox(height: 40.h),
//                       Padding(
//                         padding:  EdgeInsets.symmetric(horizontal: 100.w),
//                         child: AppButton(text: 'Add', onPressed: () {
//                           Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => RestaurantBioEditPage(),
//                               ),
//                             );
//                         }),
//                       ),
//                       SizedBox(height: 60.h),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//     );
//   }
// }
