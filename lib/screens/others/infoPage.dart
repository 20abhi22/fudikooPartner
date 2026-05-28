import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/locationDropDown.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/infoPage2.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
      builder: (context) => Container(
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

    slideRightWidget(newPage: 
    InfoPage2(
        establishmentName: _establishmentNameController.text,
        establishmentType: _selectedType,
        locationId: '${_selectedLat},${_selectedLng}',  // ✅ pass coordinates
        profileImage: _profileImage,
      ),context: context);

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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60.h),
              Stack(
                children: [
                  ClipOval(
                    child: _profileImage != null
                        ? Image.file(
                            _profileImage!,
                            width: 150.w,
                            height: 150.h,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/avatar.png',
                            width: 150.w,
                            height: 150.h,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 140, 0),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              AppTextFeild(
                text: 'Establishment Name',
                icon: Icons.store,
                controller: _establishmentNameController,
              ),
              SizedBox(height: 20.h),
              LocationDropdown(
                hintText: 'Establishment Type',
                fontSize: 16.sp,
                iconColor: appTextColor2,
                locations: const [
                  'Restaurant',
                  'Cafe',
                  'Cool Bar',
                  'Bar',
                  'Buffet',
                ],
                onLocationSelected: (value) {
                  setState(() => _selectedType = value);
                },
              ),
              SizedBox(height: 20.h),
              if (_selectedLatLng != null) ...[
                Container(
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
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
                ),
                SizedBox(height: 20.h),
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
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              AppButton(
                text: 'Continue',
                onPressed: _continue,
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPickerPage extends StatefulWidget {
  const _MapPickerPage();

  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  GoogleMapController? _mapController;
  LatLng _pickedLocation = const LatLng(55.7558, 37.6173);
  String _placeName = 'Fetching location...';
  bool _isGeocoding = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _pickedLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      await _reverseGeocode(latLng);
      _updateMarker(latLng);
    } catch (e) {
      debugPrint('Location error: $e');
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
        ].where((value) => value != null && value.isNotEmpty).toList();
        setState(() => _placeName = parts.join(', '));
      }
    } catch (e) {
      setState(() => _placeName = '${latLng.latitude}, ${latLng.longitude}');
    }
    setState(() => _isGeocoding = false);
  }

  void _updateMarker(LatLng latLng) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('picked'),
          position: latLng,
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
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.orange),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _isGeocoding
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
            ),
          ),
        ],
      ),
    );
  }
}
