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
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

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
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (!mounted) return;
          _showSnack('Photo permission denied');
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
      _showSnack('Error picking image: $e');
    }
  }

  Future<void> _showImageSourceDialog() async {
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
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const _MapPickerPage()),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        profileImage: _profileImage,
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
  const _MapPickerPage();

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

    _placeSearchDebounce = Timer(const Duration(milliseconds: 1500), () {
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
    required double panelRadius,
  }) {
    final hasText = _placeSearchController.text.trim().isNotEmpty;
    final iconSize = isMobile ? 22.0 : 20.0;

    return TextField(
      controller: _placeSearchController,
      textInputAction: TextInputAction.search,
      onTap: () => setState(() => _isSearchDropdownOpen = true),
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
    final metrics = _MapPickerMetrics(size: MediaQuery.sizeOf(context));

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
            top: metrics.overlayTop,
            left: metrics.overlayPadding,
            right: metrics.overlayPadding,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: metrics.searchPanelMaxWidth,
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.white,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(metrics.panelRadius),
                      child: _buildPlaceSearchField(
                        isMobile: metrics.isMobile,
                        panelRadius: metrics.panelRadius,
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: metrics.bottomPanelMargin,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: metrics.bottomPanelMaxWidth,
                  ),
                  child: Container(
                    padding: metrics.bottomPanelPadding,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: metrics.bottomPanelRadius,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.orange),
                        SizedBox(width: metrics.isMobile ? 10.w : 10.0),
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
                                  maxLines: metrics.isMobile ? 2 : 1,
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
      ? 16.h
      : 24.0;
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
  EdgeInsets get bottomPanelMargin {
    if (isMobile || isCompactLandscape) return EdgeInsets.zero;
    return const EdgeInsets.all(24);
  }

  EdgeInsets get bottomPanelPadding => EdgeInsets.symmetric(
    horizontal: isMobile ? 20.w : 20.0,
    vertical: isCompactLandscape
        ? 10.0
        : isMobile
        ? 16.h
        : 14.0,
  );

  BorderRadius get bottomPanelRadius =>
      BorderRadius.circular(isMobile || isCompactLandscape ? 0 : 18.0);
}
