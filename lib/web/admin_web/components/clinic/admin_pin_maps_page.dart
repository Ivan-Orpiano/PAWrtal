import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class AdminPinMapsPage extends StatefulWidget {
  final Function(Map<String, double>) onLocationSelected;
  final Map<String, double>? currentLocation;

  const AdminPinMapsPage({
    super.key,
    required this.onLocationSelected,
    this.currentLocation,
  });

  @override
  State<AdminPinMapsPage> createState() => _AdminPinMapsPageState();
}

class _AdminPinMapsPageState extends State<AdminPinMapsPage> {
  final MapController _mapController = MapController();
  LatLng? userLocation;
  LatLng? selectedLocation;
  bool isLoading = true;

  // San Jose del Monte bounds
  final sanJoseDelMonteBounds = LatLngBounds(
    const LatLng(14.7500, 121.0000),
    const LatLng(14.8700, 121.1000),
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _fetchUserLocation();
    _setInitialLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      Position? position = await _getCurrentUserLocation();
      if (position != null) {
        LatLng fetchedLocation = LatLng(position.latitude, position.longitude);
        if (!_isWithinBounds(fetchedLocation)) {
          fetchedLocation = sanJoseDelMonteBounds.center;
        }
        setState(() {
          userLocation = fetchedLocation;
        });
      } else {
        setState(() {
          userLocation = sanJoseDelMonteBounds.center;
        });
      }
    } catch (e) {
      print("Error fetching user location: $e");
      setState(() {
        userLocation = sanJoseDelMonteBounds.center;
      });
    }
  }

  void _setInitialLocation() {
    if (widget.currentLocation != null) {
      setState(() {
        selectedLocation = LatLng(
          widget.currentLocation!['lat']!,
          widget.currentLocation!['lng']!,
        );
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Position?> _getCurrentUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Error getting current location: $e");
      return null;
    }
  }

  bool _isWithinBounds(LatLng point) {
    return sanJoseDelMonteBounds.contains(point);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isWithinBounds(point)) {
      _showOutOfBoundsDialog();
      return;
    }

    setState(() {
      selectedLocation = point;
    });

    // Call the callback with the selected coordinates
    widget.onLocationSelected({
      'lat': point.latitude,
      'lng': point.longitude,
    });
  }

  void _showOutOfBoundsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Not Available'),
          content: const Text(
            'Please select a location within San Jose del Monte, Bulacan area.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _centerToUserLocation() {
    if (userLocation != null) {
      _mapController.move(userLocation!, 15);
    }
  }

  void _clearSelection() {
    setState(() {
      selectedLocation = null;
    });
    widget.onLocationSelected({});
  }

  List<Marker> _getMarkers() {
    final markers = <Marker>[];

    // Add user location marker
    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    // Add selected location marker
    if (selectedLocation != null) {
      markers.add(
        Marker(
          point: selectedLocation!,
          width: 110,
          height: 70,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Clinic Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading map...'),
            ],
          ),
        ),
      );
    }

    if (userLocation == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Unable to load map'),
              Text('Please check your internet connection'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap on the map to pin your clinic location. Only locations within San Jose del Monte area are allowed.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Map
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: selectedLocation ?? userLocation!,
                    initialZoom: selectedLocation != null ? 17 : 15,
                    maxZoom: 19,
                    cameraConstraint: CameraConstraint.contain(
                      bounds: sanJoseDelMonteBounds,
                    ),
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    MarkerLayer(markers: _getMarkers()),
                  ],
                ),
              ),

              // Control buttons
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "center",
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _centerToUserLocation,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.black,
                      ),
                    ),
                    if (selectedLocation != null) ...[
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "clear",
                        mini: true,
                        backgroundColor: Colors.red,
                        onPressed: _clearSelection,
                        child: const Icon(
                          Icons.clear,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Selected location info
        if (selectedLocation != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Selected Location:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'No location selected yet. Tap on the map to pin your clinic location.',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
