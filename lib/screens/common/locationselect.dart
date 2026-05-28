import 'package:flutter/material.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/utils/constants.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as geo;

class LocationSelect extends StatefulWidget {
  final Function(String,String,String) returndata;
  const LocationSelect({super.key, required this.returndata});

  @override
  State<LocationSelect> createState() => _LocationSelectState();
}

class _LocationSelectState extends State<LocationSelect> {
  double _distance = 10;
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(12.9716, 77.5946);
  late final String lat;
  late final String lng;


  loc.Location location = loc.Location();
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _goToCurrentLocation() async {
    var userLocation = await location.getLocation();

    LatLng currentLatLng = LatLng(
      userLocation.latitude!,
      userLocation.longitude!,
    );

    setState(() {
      lat = userLocation.latitude!.toString();
      lng = userLocation.longitude!.toString();
    });

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLatLng, zoom: 15.0),
      ),
    );

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("current_location"),
          position: currentLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  Future<void> _searchLocation() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      List<geo.Location> locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final target = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );

        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 14.0),
          ),
        );

        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId("searched_location"),
              position: target,
              infoWindow: InfoWindow(title: query),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location not found: $query")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: SizedBox.expand(
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 11.0,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: _markers,
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 70, top: 30),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search Location",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _searchLocation(),
                ),
              ),
              Positioned(
                top: 30,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Current Location Button
              Positioned(
                bottom: 250,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ),

              // Bottom slider + button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.orange,
                                  inactiveTrackColor: Colors.grey[300],
                                  thumbColor: Colors.orange,
                                  overlayColor: Colors.orange.withOpacity(0.2),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                  ),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  min: 0,
                                  max: 50,
                                  value: _distance,
                                  onChanged: (value) {
                                    setState(() {
                                      _distance = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_distance.toInt()} km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: 200,
                          height: 40,
                          child: AppButton(
                            text: "Apply",
                            onPressed: () {
                              Navigator.pop(context);
                              // print(_distance.toInt().toString());
                              // print(lat);
                              // print(lng);
                              widget.returndata(
                                lat,
                                lng,
                                _distance.toInt().toString(),
                              );
                            },
                            size: 15,
                            borderRadius: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
