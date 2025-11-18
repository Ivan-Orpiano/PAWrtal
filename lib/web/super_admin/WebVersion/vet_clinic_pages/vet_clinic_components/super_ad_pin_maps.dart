import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class SuperAdPinMaps extends StatefulWidget {
  final Function(Map<String, double>) onLocationSelected;
  final Map<String, double>? currentLocation;

  const SuperAdPinMaps({
    super.key,
    required this.onLocationSelected,
    this.currentLocation,
  });

  @override
  State<SuperAdPinMaps> createState() => _SuperAdPinMapsState();
}

class _SuperAdPinMapsState extends State<SuperAdPinMaps> {
  final MapController _mapController = MapController();

  LatLng? userLocation;
  LatLng? selectedLocation;
  bool isLoading = true;

  final sanJoseDelMonteBounds = LatLngBounds(
    const LatLng(14.7667, 121.0167), // Southwest
    const LatLng(14.8667, 121.1667), // Northeast
  );

  final List<LatLng> sjdmPolygonBoundary = const [
    // Southwest - Muzon area
    LatLng(14.7680, 121.0480),
    // South border
    LatLng(14.7700, 121.0520),
    LatLng(14.7720, 121.0580),
    LatLng(14.7750, 121.0650),
    LatLng(14.7780, 121.0720),
    // Southeast curve
    LatLng(14.7820, 121.0800),
    LatLng(14.7860, 121.0880),
    LatLng(14.7900, 121.0950),
    // East border start
    LatLng(14.7950, 121.1020),
    LatLng(14.8000, 121.1080),
    LatLng(14.8050, 121.1140),
    // East border middle
    LatLng(14.8100, 121.1180),
    LatLng(14.8150, 121.1200),
    LatLng(14.8200, 121.1190),
    // Northeast curve
    LatLng(14.8250, 121.1160),
    LatLng(14.8300, 121.1120),
    LatLng(14.8350, 121.1080),
    LatLng(14.8400, 121.1050),
    // North border
    LatLng(14.8450, 121.1000),
    LatLng(14.8480, 121.0920),
    LatLng(14.8500, 121.0850),
    LatLng(14.8510, 121.0780),
    LatLng(14.8500, 121.0700),
    LatLng(14.8480, 121.0620),
    LatLng(14.8460, 121.0550),
    LatLng(14.8440, 121.0480),
    // Northwest corner
    LatLng(14.8420, 121.0410),
    LatLng(14.8390, 121.0350),
    LatLng(14.8350, 121.0300),
    LatLng(14.8300, 121.0270),
    // West border
    LatLng(14.8250, 121.0290),
    LatLng(14.8200, 121.0310),
    LatLng(14.8150, 121.0330),
    LatLng(14.8100, 121.0350),
    LatLng(14.8050, 121.0370),
    LatLng(14.8000, 121.0390),
    LatLng(14.7950, 121.0410),
    LatLng(14.7900, 121.0430),
    LatLng(14.7850, 121.0450),
    LatLng(14.7800, 121.0460),
    LatLng(14.7750, 121.0470),
    // Close polygon
    LatLng(14.7680, 121.0480),
  ];

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

        // If user location is outside SJDM polygon, default to city center
        if (!_isPointInPolygon(fetchedLocation, sjdmPolygonBoundary)) {
          fetchedLocation = const LatLng(14.8167, 121.0500);
        }

        if (mounted) {
          setState(() {
            userLocation = fetchedLocation;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userLocation = const LatLng(14.8167, 121.0500);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userLocation = const LatLng(14.8167, 121.0500);
        });
      }
    }
  }

  void _setInitialLocation() {
    if (widget.currentLocation != null) {
      if (mounted) {
        setState(() {
          selectedLocation = LatLng(
            widget.currentLocation!['lat']!,
            widget.currentLocation!['lng']!,
          );
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
      return null;
    }
  }

  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude;
    double bY = vertB.latitude;
    double aX = vertA.longitude;
    double bX = vertB.longitude;
    double pY = point.latitude;
    double pX = point.longitude;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      return false;
    }

    double m = (bY - aY) / (bX - aX);
    double bee = (-aX) * m + aY;
    double x = (pY - bee) / m;

    return x > pX;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length - 1; i++) {
      if (_rayCastIntersect(point, polygon[i], polygon[i + 1])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  bool _isWithinBounds(LatLng point) {
    return sanJoseDelMonteBounds.contains(point) &&
        _isPointInPolygon(point, sjdmPolygonBoundary);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isWithinBounds(point)) {
      _showOutOfBoundsDialog();
      return;
    }

    setState(() {
      selectedLocation = point;
    });

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Location Not Available'),
            ],
          ),
          content: const Text(
            'Please select a location within San Jose del Monte, Bulacan city limits. '
            'Only locations within the official SJDM boundary are allowed.',
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
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isLoading) {
      return Container(
        height: isMobile ? 300 : 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 81, 115, 153),
              ),
              SizedBox(height: 16),
              Text('Loading map...'),
            ],
          ),
        ),
      );
    }

    if (userLocation == null) {
      return Container(
        height: isMobile ? 300 : 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off,
                  size: isMobile ? 48 : 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Unable to load map',
                  style: TextStyle(fontSize: isMobile ? 14 : 16)),
              Text('Please check your internet connection',
                  style: TextStyle(fontSize: isMobile ? 12 : 14)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 81, 115, 153),
                const Color.fromARGB(255, 101, 133, 170).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinic Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pin the exact location of the clinic',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Info Container
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_rounded,
                  color: Colors.blue, size: isMobile ? 18 : 20),
              SizedBox(width: isMobile ? 8 : 10),
              Expanded(
                child: Text(
                  'Tap anywhere on the map to pin the clinic location. Only locations within San Jose del Monte, Bulacan are allowed.',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Map Container
        Container(
          height: isMobile ? 350 : 450,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "center_super_ad",
                      mini: true,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: _centerToUserLocation,
                      child: const Icon(
                        Icons.my_location,
                        color: Color.fromARGB(255, 81, 115, 153),
                        size: 20,
                      ),
                    ),
                    if (selectedLocation != null) ...[
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "clear_super_ad",
                        mini: true,
                        backgroundColor: Colors.red,
                        elevation: 4,
                        onPressed: _clearSelection,
                        child: const Icon(
                          Icons.clear,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Location Status
        if (selectedLocation != null)
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Selected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The clinic location has been pinned on the map',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_searching,
                    color: Colors.orange, size: isMobile ? 20 : 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No location selected yet. Tap on the map to pin the clinic location.',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
