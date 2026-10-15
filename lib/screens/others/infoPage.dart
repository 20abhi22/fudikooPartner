import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/locationDropDown.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/registration/mapplace-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/infoPage2.dart';
import 'package:fudiko/services/map-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/snackbar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fudiko/utils/error_messages.dart';

class InfoPage extends StatefulWidget {
  final String? authToken;
  const InfoPage({super.key, this.authToken});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final TextEditingController _establishmentNameController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedType = '';
  String _selectedPlaceName = '';
  double? _selectedLat;
  double? _selectedLng;
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  LatLng? get _selectedLatLng {
    if (_selectedLat == null || _selectedLng == null) {
      return null;
    }
    return LatLng(_selectedLat!, _selectedLng!);
  }

  @override
  void dispose() {
    _establishmentNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          _showSnack('Camera permission denied');
          return;
        }
      }

      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnack(
        friendlyErrorMessage(e, fallback: 'Could not pick that image. Please try again.'),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    // Put the keyboard away before the sheet slides up over the form.
    FocusScope.of(context).unfocus();

    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    // Put the keyboard away before pushing the full-screen picker.
    FocusScope.of(context).unfocus();

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerPage(authToken: widget.authToken),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedLat = result['lat'] as double?;
      _selectedLng = result['lng'] as double?;
      _selectedPlaceName = result['place'] as String? ?? '';
      _locationController.text = _selectedPlaceName;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showErrorSnack(context, message);
  }

  void _continue() {
    if (_establishmentNameController.text.isEmpty) {
      _showSnack('Please enter establishment name');
      return;
    }
    if (_selectedType.isEmpty) {
      _showSnack('Please select establishment type');
      return;
    }
    if (_locationController.text.isEmpty) {
      _showSnack('Please select a location');
      return;
    }

    slideRightWidget(
      newPage: InfoPage2(
        establishmentName: _establishmentNameController.text,
        establishmentType: _selectedType,
        locationId: '$_selectedLat,$_selectedLng', // ✅ pass coordinates
        // Carry the picked address forward so the Address field arrives
        // pre-filled instead of making the partner retype it.
        initialAddress: _selectedPlaceName,
        profileImage: _profileImage,
        authToken: widget.authToken,
      ),
      context: context,
    );

    //     Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => InfoPage2(
    //       establishmentName: _establishmentNameController.text,
    //       establishmentType: _selectedType,
    //       locationId: '${_selectedLat},${_selectedLng}',  // ✅ pass coordinates
    //       profileImage: _profileImage,
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final metrics = _InfoPageMetrics(size: size);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.horizontalPadding,
              vertical: metrics.verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: metrics.shouldCenterContent
                    ? (constraints.maxHeight - (metrics.verticalPadding * 2))
                          .clamp(0.0, double.infinity)
                          .toDouble()
                    : 0,
              ),
              child: Align(
                alignment: metrics.shouldCenterContent
                    ? Alignment.center
                    : Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: metrics.contentMaxWidth,
                  ),
                  child: metrics.useSplitLayout
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _avatarBlock(metrics)),
                            SizedBox(width: metrics.splitGap),
                            Expanded(child: _formBlock(metrics)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: metrics.topGap),
                            _avatarBlock(metrics),
                            SizedBox(height: metrics.fieldGap),
                            _formBlock(metrics),
                            SizedBox(height: metrics.bottomGap),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarBlock(_InfoPageMetrics metrics) {
    return Center(
      child: SizedBox(
        width: metrics.avatarSize,
        height: metrics.avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ClipOval(
              child: _profileImage != null
                  ? Image.file(
                      _profileImage!,
                      width: metrics.avatarSize,
                      height: metrics.avatarSize,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/avatar.png',
                      width: metrics.avatarSize,
                      height: metrics.avatarSize,
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  padding: EdgeInsets.all(metrics.cameraPadding),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 140, 0),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: metrics.cameraIconSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formBlock(_InfoPageMetrics metrics) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextFeild(
          text: 'Establishment Name',
          icon: Icons.store,
          controller: _establishmentNameController,
          height: metrics.fieldHeight,
          size: metrics.fieldTextSize,
        ),
        SizedBox(height: metrics.fieldGap),
        LocationDropdown(
          hintText: 'Establishment Type',
          fontSize: metrics.fieldTextSize,
          height: metrics.fieldHeight,
          iconColor: appTextColor2,
          locations: const ['Restaurant', 'Cafe', 'Cool Bar', 'Bar', 'Buffet'],
          onLocationSelected: (value) {
            setState(() => _selectedType = value);
          },
        ),
        SizedBox(height: metrics.fieldGap),
        if (_selectedLatLng != null) ...[
          _mapPreview(metrics),
          SizedBox(height: metrics.fieldGap),
        ],
        GestureDetector(
          onTap: _openMapPicker,
          child: AbsorbPointer(
            child: AppTextFeild(
              text: _selectedPlaceName.isEmpty
                  ? 'Location'
                  : _selectedPlaceName,
              icon: Icons.location_on,
              controller: _locationController,
              suffixIcon: Icons.map_outlined,
              height: metrics.fieldHeight,
              size: metrics.fieldTextSize,
            ),
          ),
        ),
        SizedBox(height: metrics.buttonTopGap),
        AppButton(
          text: 'Continue',
          onPressed: _continue,
          height: metrics.buttonHeight,
          size: metrics.buttonTextSize,
        ),
      ],
    );
  }

  Widget _mapPreview(_InfoPageMetrics metrics) {
    return Container(
      height: metrics.mapPreviewHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.mapPreviewRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: metrics.mapPreviewShadowBlur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(metrics.mapPreviewRadius),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedLatLng!,
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('selected-location'),
              position: _selectedLatLng!,
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          compassEnabled: false,
        ),
      ),
    );
  }
}

class _InfoPageMetrics {
  const _InfoPageMetrics({required this.size});

  final Size size;

  double get width => size.width;
  double get height => size.height;
  bool get isMobile => Breakpoints.isMobile(width);
  bool get isTabletDevice => Breakpoints.isTabletDevice(size);
  bool get isWideShortPhone => Breakpoints.isWideShortPhone(size);
  bool get isLandscape => width > height;
  bool get useSplitLayout => isLandscape && width >= 700;
  bool get isCompactLandscape => isWideShortPhone || useSplitLayout;
  bool get shouldCenterContent =>
      isCompactLandscape || isTabletDevice || Breakpoints.isDesktop(width);

  double get horizontalPadding {
    if (isCompactLandscape) return 28.0;
    if (isTabletDevice) return 64.0;
    if (isMobile) return 30.w;
    return AppDimensions.padding(width);
  }

  double get verticalPadding {
    if (isCompactLandscape) return 18.0;
    if (isTabletDevice) return 32.0;
    return 0.0;
  }

  double get contentMaxWidth {
    if (useSplitLayout) return width.clamp(680.0, 920.0);
    if (isWideShortPhone) return 380.0;
    if (isTabletDevice) return 600.0;
    return double.infinity;
  }

  double get splitGap => width >= 900 ? 56.0 : 36.0;
  double get topGap => shouldCenterContent ? 0.0 : 60.h;
  double get avatarSize {
    if (isCompactLandscape) return 100.0;
    if (isTabletDevice) return 180.0;
    return 150.w;
  }

  double get cameraPadding {
    if (isCompactLandscape) return 6.0;
    if (isTabletDevice) return 10.0;
    return 8.r;
  }

  double get cameraIconSize {
    if (isCompactLandscape) return 16.0;
    if (isTabletDevice) return 22.0;
    return 20.sp;
  }

  double get fieldGap {
    if (isCompactLandscape) return 10.0;
    if (isTabletDevice) return 20.0;
    return 20.h;
  }

  double get mapPreviewHeight {
    final rawHeight = isCompactLandscape
        ? 110.0
        : isTabletDevice
        ? 190.0
        : isMobile
        ? 140.h
        : 170.0;
    return math.min(rawHeight, height * (isLandscape ? 0.28 : 0.22));
  }

  double get mapPreviewRadius {
    if (isCompactLandscape) return 14.0;
    if (isTabletDevice) return 20.0;
    if (isMobile) return 20.r;
    return 18.0;
  }

  double get mapPreviewShadowBlur {
    if (isCompactLandscape) return 8.0;
    if (isTabletDevice) return 12.0;
    if (isMobile) return 10.0;
    return 12.0;
  }

  double? get fieldHeight {
    if (isCompactLandscape) return 46.0;
    if (isTabletDevice) return 64.0;
    return null;
  }

  double get fieldTextSize {
    if (isCompactLandscape) return 13.0;
    if (isTabletDevice) return 17.0;
    return 16.sp;
  }

  double? get buttonHeight {
    if (isCompactLandscape) return 46.0;
    if (isTabletDevice) return 64.0;
    return null;
  }

  double? get buttonTextSize {
    if (isCompactLandscape) return 13.0;
    if (isTabletDevice) return 17.0;
    return null;
  }

  double get buttonTopGap {
    if (isCompactLandscape) return 24.0;
    if (isTabletDevice) return 36.0;
    return 40.h;
  }

  double get bottomGap => shouldCenterContent ? 0.0 : 60.h;
}

class _MapPickerPage extends StatefulWidget {
  final String? authToken;

  const _MapPickerPage({this.authToken});

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

  LatLng _pickedLocation = const LatLng(55.7558, 37.6173);
  String _placeName = 'Fetching location...';
  bool _isGeocoding = false;
  bool _isSearchingPlaces = false;
  bool _isFetchingNextPage = false;
  bool _isFetchingCurrentLocation = false;
  bool _hasSubmittedSearch = false;
  String? _placeSearchError;
  List<MapPlacesResponse> _textSearchResults = [];
  List<MapPlacesResponse> _recentSearches = [];
  Set<Marker> _markers = {};
  int _placeSearchRequestId = 0;
  bool _isSearchDropdownOpen = false;
  bool _showPickedMarker = false;
  static const String _recentSearchPrefsKey = 'recent_map_place_searches';

  /// Secondary copy — subtitles, section headers, empty/error states.
  /// [AppText] defaults its color to the brand orange, so body text has to
  /// pass a color explicitly.
  Color get _mutedTextColor => appTextColor5.withValues(alpha: 0.6);

  @override
  void initState() {
    super.initState();
    _updateMarker(_pickedLocation);
    _loadRecentSearches();
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

    setState(() => _isFetchingCurrentLocation = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _reverseGeocode(_pickedLocation);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickedLocation = latLng;
        if (selectLocation) {
          _showPickedMarker = true;
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
      if (mounted) setState(() => _isFetchingCurrentLocation = false);
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
        final Placemark p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((value) => value != null && value.isNotEmpty).toList();
        setState(() => _placeName = parts.join(', '));
      }
    } catch (e) {
      setState(() => _placeName = '${latLng.latitude}, ${latLng.longitude}');
    }
    setState(() => _isGeocoding = false);
  }

  void _onPlaceSearchChanged(String value) {
    _placeSearchDebounce?.cancel();
    final trimmed = value.trim();
    final requestId = ++_placeSearchRequestId;

    if (trimmed.length < 3) {
      setState(() {
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

    _placeSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || requestId != _placeSearchRequestId) return;
      smartPlaceSearch();
    });
  }

  Future<void> smartPlaceSearch({LatLng? location}) async {
    final query = _placeSearchController.text.trim();
    if (query.isEmpty) return;

    _placeSearchDebounce?.cancel();
    final requestId = ++_placeSearchRequestId;

    setState(() {
      _hasSubmittedSearch = true;
      _isSearchDropdownOpen = true;
      _isSearchingPlaces = true;
      _isFetchingNextPage = false;
      _placeSearchError = null;
      _textSearchResults = [];
    });

    try {
      final results = await _mapService.smartPlaceSearchProgressive(
        query,
        // userLatLng: searchLocation,
        tokenOverride: widget.authToken,
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

  Future<void> _selectSearchResult(MapPlacesResponse place) async {
    // Predictions are listed before their coordinates are resolved, so fetch
    // the details on tap instead of silently ignoring the selection.
    if ((place.lat == null || place.lng == null) &&
        (place.placeId ?? '').isNotEmpty) {
      try {
        place = await _mapService.fetchPlaceDetails(
          place.placeId!,
          tokenOverride: widget.authToken,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _placeSearchError = e is MapPlaceSearchException
            ? e.message
            : 'Could not load place details. Please try again.');
        return;
      }
    }
    final lat = place.lat;
    final lng = place.lng;
    if (lat == null || lng == null) return;

    final latLng = LatLng(lat, lng);
    final label = [
      place.mainText,
      place.secondaryText,
    ].where((value) => value != null && value.isNotEmpty).join(', ');

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _pickedLocation = latLng;
      _placeName = label;
      _placeSearchController.text = place.mainText ?? label;
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

  Future<void> _loadRecentSearches() async {
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
    setState(
      () => _recentSearches = _mapService.mergeAndRemoveDuplicates(recent),
    );
  }

  Future<void> _saveRecentSearch(MapPlacesResponse place) async {
    if ((place.mainText ?? '').isEmpty) return;

    final merged = _mapService
        .mergeAndRemoveDuplicates([place, ..._recentSearches])
        .take(6)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchPrefsKey,
      merged.map((place) => jsonEncode(place.toJson())).toList(),
    );

    if (!mounted) return;
    setState(() => _recentSearches = merged);
  }

  bool _canShowRecentSearches() {
    return _isSearchDropdownOpen &&
        !_hasSubmittedSearch &&
        !_isSearchingPlaces &&
        _recentSearches.isNotEmpty;
  }

  Widget _buildPlaceSearchField({
    required bool isMobile,
    required double fieldRadius,
  }) {
    final hasText = _placeSearchController.text.trim().isNotEmpty;
    final iconSize = isMobile ? 22.0 : 20.0;

    return TranslatedBuilder(
      text: 'Search place',
      builder: (context, hintText) => TextField(
        controller: _placeSearchController,
        textInputAction: TextInputAction.search,
        onTap: () => setState(() => _isSearchDropdownOpen = true),
        onChanged: _onPlaceSearchChanged,
        style: TextStyle(fontSize: 14, color: appTextColor5),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14, color: _mutedTextColor),
          prefixIcon: Icon(Icons.search, color: appTextColor, size: iconSize),
          suffixIcon: hasText
              ? IconButton(
                  icon: Icon(Icons.close, color: appTextColor, size: iconSize),
                  onPressed: () {
                    _placeSearchDebounce?.cancel();
                    _placeSearchRequestId++;
                    setState(() {
                      _placeSearchController.clear();
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
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: appSecondaryBackgroundColor,
          contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12.h : 12.0),
        ),
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
          child: AppText(
            text: title,
            size: 12,
            fontWeight: FontWeight.w600,
            color: _mutedTextColor,
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
      leading: Icon(icon, color: appTextColor, size: isMobile ? 24.0 : 22.0),
      // AppText already scales its size responsively, so pass the base value.
      title: AppText(
        text: place.mainText ?? '',
        size: 14,
        fontWeight: FontWeight.w500,
        color: appTextColor5,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (place.secondaryText ?? '').isEmpty
          ? null
          : AppText(
              text: place.secondaryText!,
              size: 12,
              fontWeight: FontWeight.w400,
              color: _mutedTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: onTap,
    );
  }

  Widget _buildRecentSearches({
    required bool isMobile,
    required double maxHeight,
    required double panelRadius,
  }) {
    if (!_canShowRecentSearches()) return const SizedBox.shrink();

    return _buildListShell(
      maxHeight: maxHeight,
      panelRadius: panelRadius,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          _buildPlaceSection(
            title: 'Recent searches',
            places: _recentSearches,
            icon: Icons.history,
            isMobile: isMobile,
            onTap: _selectSearchResult,
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
          padding: const EdgeInsets.all(14),
          child: AppText(
            text: _placeSearchError!,
            size: 13,
            fontWeight: FontWeight.w400,
            color: _mutedTextColor,
            isCentered: true,
          ),
        ),
      );
    }

    if (_textSearchResults.isEmpty && _isSearchingPlaces) {
      return _buildListShell(
        maxHeight: maxHeight,
        panelRadius: panelRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: appTextColor,
              ),
            ),
          ),
        ),
      );
    }

    if (_textSearchResults.isEmpty) {
      return _buildListShell(
        maxHeight: maxHeight,
        panelRadius: panelRadius,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AppText(
            text: 'No places found',
            size: 13,
            fontWeight: FontWeight.w400,
            color: _mutedTextColor,
            isCentered: true,
          ),
        ),
      );
    }

    return _buildListShell(
      maxHeight: maxHeight,
      panelRadius: panelRadius,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _textSearchResults.length + (_isFetchingNextPage ? 1 : 0),
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: appTextColor5.withValues(alpha: 0.12)),
        itemBuilder: (context, index) {
          if (index >= _textSearchResults.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: appTextColor,
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

  /// White circular control that floats over the map — back arrow,
  /// my-location. [size] is both the width and the height so it stays round.
  Widget _floatingCircle({
    required double size,
    required Widget child,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  /// White pill that floats over the map — the title, Confirm, and the
  /// resolved-address panel.
  Widget _floatingCapsule({
    required double radius,
    required Widget child,
    EdgeInsets? padding,
    double? height,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: padding,
          // widthFactor shrink-wraps the pill around its label, while the
          // alignment still centres that label inside the pill's fixed height.
          // Setting Container.alignment instead would stretch the pill to fill
          // whatever width it is offered.
          child: Align(
            alignment: Alignment.center,
            widthFactor: 1.0,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(_MapPickerMetrics metrics) {
    final capsulePadding = EdgeInsets.symmetric(
      horizontal: metrics.capsulePadding,
    );

    return Row(
      children: [
        _floatingCircle(
          size: metrics.controlHeight,
          onTap: () => Navigator.pop(context),
          child: Image.asset(
            backOrange,
            width: metrics.backIconSize,
            height: metrics.backIconSize,
          ),
        ),
        SizedBox(width: metrics.controlGap),
        _floatingCapsule(
          radius: metrics.controlRadius,
          height: metrics.controlHeight,
          padding: capsulePadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: metrics.titleMaxWidth),
            child: AppText(
              text: 'Select Location',
              size: metrics.titleTextSize,
              fontWeight: FontWeight.w600,
              color: appTextColor5,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: metrics.controlGap),
        _confirmCapsule(
          radius: metrics.controlRadius,
          height: metrics.controlHeight,
          padding: capsulePadding,
          onTap: () {
            Navigator.pop(context, {
              'lat': _pickedLocation.latitude,
              'lng': _pickedLocation.longitude,
              'place': _placeName,
            });
          },
          child: AppText(
            text: 'Confirm',
            size: metrics.titleTextSize,
            fontWeight: FontWeight.w600,
            color: appTextColor,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Wraps the Confirm pill so it takes the row's leftover width and stays
  /// pinned to the right edge while the title pill hugs its label.
  Widget _confirmCapsule({
    required double radius,
    required double height,
    required EdgeInsets padding,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: _floatingCapsule(
          radius: radius,
          height: height,
          padding: padding,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  Widget _buildBottomBar(_MapPickerMetrics metrics) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _floatingCapsule(
            radius: metrics.bottomCapsuleRadius,
            padding: metrics.bottomPanelPadding,
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: appTextColor,
                  size: metrics.bottomIconSize,
                ),
                SizedBox(width: metrics.isMobile ? 10.w : 10.0),
                Expanded(
                  child: _isGeocoding
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: appTextColor,
                          ),
                        )
                      : AppText(
                          text: _placeName,
                          size: 14,
                          fontWeight: FontWeight.w500,
                          color: appTextColor5,
                          maxLines: metrics.isMobile ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: metrics.controlGap),
        TranslatedBuilder(
          text: 'Use current location',
          builder: (context, tooltip) => _floatingCircle(
            size: metrics.locationButtonSize,
            tooltip: tooltip,
            onTap: _isFetchingCurrentLocation
                ? null
                : () => _getCurrentLocation(selectLocation: true),
            child: _isFetchingCurrentLocation
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: appTextColor,
                    ),
                  )
                : Icon(
                    Icons.my_location,
                    color: appTextColor,
                    size: metrics.bottomIconSize,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _MapPickerMetrics(size: MediaQuery.sizeOf(context));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: appSecondaryBackgroundColor,
      // No AppBar — the controls float over the map instead, so the map fills
      // the screen and every control reads as a card above it.
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
            // Native grey controls are off; the floating orange my-location
            // button drives recentering instead.
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
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
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.overlayPadding,
                  metrics.overlayTop,
                  metrics.overlayPadding,
                  0,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: metrics.searchPanelMaxWidth,
                    ),
                    child: Column(
                      children: [
                        _buildTopBar(metrics),
                        SizedBox(height: metrics.topBarGap),
                        Material(
                          color: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black26,
                          borderRadius: BorderRadius.circular(
                            metrics.controlRadius,
                          ),
                          child: _buildPlaceSearchField(
                            isMobile: metrics.isMobile,
                            fieldRadius: metrics.controlRadius,
                          ),
                        ),
                        if (_canShowRecentSearches()) ...[
                          SizedBox(height: metrics.suggestionGap),
                          _buildRecentSearches(
                            isMobile: metrics.isMobile,
                            maxHeight: metrics.suggestionMaxHeight,
                            panelRadius: metrics.panelRadius,
                          ),
                        ],
                        if (_hasSubmittedSearch) ...[
                          SizedBox(height: metrics.suggestionGap),
                          _buildTextSearchResults(
                            isMobile: metrics.isMobile,
                            maxHeight: metrics.suggestionMaxHeight,
                            panelRadius: metrics.panelRadius,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.overlayPadding,
                  0,
                  metrics.overlayPadding,
                  metrics.bottomInset,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: metrics.bottomPanelMaxWidth,
                    ),
                    child: _buildBottomBar(metrics),
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

class _MapPickerMetrics {
  const _MapPickerMetrics({required this.size});

  final Size size;

  double get width => size.width;
  double get height => size.height;
  bool get isMobile => Breakpoints.isMobile(width);
  bool get isTabletDevice => Breakpoints.isTabletDevice(size);
  bool get isWideShortPhone => Breakpoints.isWideShortPhone(size);
  bool get isLandscape => width > height;
  bool get isCompactLandscape =>
      isWideShortPhone || (isLandscape && height < 520);

  double get overlayPadding {
    if (isMobile || isCompactLandscape) return 16.w;
    return AppDimensions.padding(width);
  }

  double get overlayTop => isCompactLandscape
      ? 10.0
      : isMobile
      ? 12.h
      : 20.0;

  // ── Floating controls ───────────────────────────────────────────────────
  // Circles and pills share one height so the top row lines up. The values
  // stay plain doubles: a circle needs the same number on both axes.

  double get controlHeight {
    if (isCompactLandscape) return 40.0;
    if (isTabletDevice) return 52.0;
    return 46.0;
  }

  double get controlRadius => controlHeight / 2;
  double get controlGap => isCompactLandscape ? 8.0 : 10.0;
  double get capsulePadding => isCompactLandscape ? 14.0 : 18.0;
  double get backIconSize => isCompactLandscape ? 18.0 : 20.0;

  double get titleTextSize {
    if (isCompactLandscape) return 13.0;
    if (isTabletDevice) return 16.0;
    return 15.0;
  }

  double get topBarGap => isCompactLandscape ? 8.0 : 12.0;

  /// Ceiling for the title pill so an unusually long label ellipsizes instead
  /// of squeezing the Confirm pill off the row.
  double get titleMaxWidth {
    if (isCompactLandscape) return 150.0;
    if (isTabletDevice) return 260.0;
    return math.min(200.0, width * 0.42);
  }

  double get locationButtonSize {
    if (isCompactLandscape) return 44.0;
    if (isTabletDevice) return 56.0;
    return 50.0;
  }

  double get bottomIconSize => isCompactLandscape ? 20.0 : 22.0;
  double get bottomCapsuleRadius => isCompactLandscape ? 20.0 : 26.0;
  double get bottomInset => isCompactLandscape ? 10.0 : 16.0;

  EdgeInsets get bottomPanelPadding => EdgeInsets.symmetric(
    horizontal: isMobile ? 18.w : 18.0,
    vertical: isCompactLandscape
        ? 10.0
        : isMobile
        ? 14.h
        : 14.0,
  );

  // ── Search dropdown ─────────────────────────────────────────────────────

  double get panelRadius => isMobile || isCompactLandscape ? 14.r : 14.0;
  double get suggestionGap => isCompactLandscape
      ? 6.0
      : isMobile
      ? 8.h
      : 8.0;
  double get suggestionMaxHeight {
    final rawHeight = isMobile
        ? 220.h
        : isTabletDevice
        ? 280.0
        : 300.0;
    final usableHeight = height - 156.0;
    final capFraction = isLandscape ? 0.36 : 0.44;
    return math.max(
      96.0,
      math.min(rawHeight, math.min(usableHeight, height * capFraction)),
    );
  }

  double get searchPanelMaxWidth => isMobile ? double.infinity : 560.0;
  double get bottomPanelMaxWidth => isMobile ? double.infinity : 680.0;
}
