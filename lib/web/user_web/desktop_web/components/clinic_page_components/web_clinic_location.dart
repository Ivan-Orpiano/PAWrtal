import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

class WebClinicLocationUpdated extends StatefulWidget {
  final Clinic clinic;

  const WebClinicLocationUpdated({super.key, required this.clinic});

  @override
  State<WebClinicLocationUpdated> createState() =>
      _WebClinicLocationUpdatedState();
}

class _WebClinicLocationUpdatedState extends State<WebClinicLocationUpdated> {
  final MapController _mapController = MapController();
  LatLng? userLocation;
  LatLng? clinicLocation;
  List<LatLng> routePoints = [];
  double distanceInKm = 0.0;
  bool isLoading = true;
  String? error;
  ClinicSettings? clinicSettings;
  bool userOutOfBounds = false;
  bool showWithoutUserLocation = false;

  // San Jose Del Monte, Bulacan bounds
  static const double southLat = 14.7500;
  static const double northLat = 14.8700;
  static const double westLng = 121.0000;
  static const double eastLng = 121.1000;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _fetchClinicSettings();

    if (clinicLocation != null) {
      await _fetchUserLocation();

      if (!showWithoutUserLocation &&
          userLocation != null &&
          clinicLocation != null) {
        await _fetchRoute();
        _fitMapToBounds();
      } else if (showWithoutUserLocation || userLocation == null) {
        // Just show clinic location
        _centerOnClinic();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchUserLocation() async {
    try {
      Position? position = await _getCurrentUserLocation();
      if (position != null) {
        LatLng fetchedLocation = LatLng(position.latitude, position.longitude);

        // Check if user is within San Jose Del Monte bounds
        if (!_isWithinBounds(fetchedLocation)) {
          print("User location outside San Jose Del Monte");
          setState(() {
            userOutOfBounds = true;
          });
          return;
        }

        setState(() {
          userLocation = fetchedLocation;
          userOutOfBounds = false;
        });
      }
    } catch (e) {
      print("Error fetching user location: $e");
    }
  }

  bool _isWithinBounds(LatLng point) {
    return point.latitude >= southLat &&
        point.latitude <= northLat &&
        point.longitude >= westLng &&
        point.longitude <= eastLng;
  }

  Future<void> _fetchClinicSettings() async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final settings = await authRepository
          .getClinicSettingsByClinicId(widget.clinic.documentId ?? '');

      if (settings?.location != null) {
        LatLng location =
            LatLng(settings!.location!['lat']!, settings.location!['lng']!);

        // Verify clinic is within San Jose Del Monte bounds
        if (!_isWithinBounds(location)) {
          setState(() {
            error = "Clinic location is outside San Jose Del Monte, Bulacan";
          });
          return;
        }

        setState(() {
          clinicSettings = settings;
          clinicLocation = location;
        });
      } else {
        setState(() {
          error = "Clinic location not set";
        });
      }
    } catch (e) {
      print("Error fetching clinic settings: $e");
      setState(() {
        error = "Failed to load clinic location";
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

  Future<void> _fetchRoute() async {
    if (userLocation == null || clinicLocation == null) return;

    try {
      String url =
          "https://router.project-osrm.org/route/v1/driving/${userLocation!.longitude},${userLocation!.latitude};${clinicLocation!.longitude},${clinicLocation!.latitude}?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];

          double distanceMeters = data['routes'][0]['distance'].toDouble();

          setState(() {
            routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList();
            distanceInKm = distanceMeters / 1000;
          });
        }
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  void _fitMapToBounds() {
    if (userLocation == null || clinicLocation == null) return;

    double minLat = userLocation!.latitude < clinicLocation!.latitude
        ? userLocation!.latitude
        : clinicLocation!.latitude;
    double maxLat = userLocation!.latitude > clinicLocation!.latitude
        ? userLocation!.latitude
        : clinicLocation!.latitude;
    double minLng = userLocation!.longitude < clinicLocation!.longitude
        ? userLocation!.longitude
        : clinicLocation!.longitude;
    double maxLng = userLocation!.longitude > clinicLocation!.longitude
        ? userLocation!.longitude
        : clinicLocation!.longitude;

    double latPadding = (maxLat - minLat) * 0.2;
    double lngPadding = (maxLng - minLng) * 0.2;

    minLat = (minLat - latPadding).clamp(southLat, northLat);
    maxLat = (maxLat + latPadding).clamp(southLat, northLat);
    minLng = (minLng - lngPadding).clamp(westLng, eastLng);
    maxLng = (maxLng + lngPadding).clamp(westLng, eastLng);

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    });
  }

  void _centerOnClinic() {
    if (clinicLocation == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(clinicLocation!, 15);
    });
  }

  void _continueWithoutLocation() {
    setState(() {
      showWithoutUserLocation = true;
      userOutOfBounds = false;
      isLoading = true;
    });
    _centerOnClinic();
    setState(() {
      isLoading = false;
    });
  }

  double getResponsivePadding(double screenWidth) {
    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 16;
    const double maxPadding = 380;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

  void _openDirections() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Get Directions"),
          content: Text("Opening directions to ${widget.clinic.clinicName}..."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _callClinic() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Call Clinic"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Call ${widget.clinic.clinicName}?"),
              const SizedBox(height: 8),
              Text(
                widget.clinic.contact,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Call"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildErrorState() {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error ?? "Failed to load location",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfBoundsDialog() {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 24),
              const Text(
                "Location Outside Service Area",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Your current location is outside San Jose Del Monte, Bulacan.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "You can still view the clinic location on the map.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continueWithoutLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Show Clinic Location",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                "Location",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Address and contact information
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.clinic.address,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Full address of ${widget.clinic.clinicName}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (distanceInKm > 0 && !showWithoutUserLocation) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${distanceInKm.toStringAsFixed(2)} km away",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions, size: 20),
                        label: const Text("Get Directions"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _callClinic,
                        icon: const Icon(Icons.phone, size: 20),
                        label: const Text("Call"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,
                          side: BorderSide(color: Colors.blue.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map container
          Container(
            width: double.maxFinite,
            height: 700,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: isLoading
                  ? _buildLoadingState()
                  : error != null
                      ? _buildErrorState()
                      : userOutOfBounds
                          ? _buildOutOfBoundsDialog()
                          : (clinicLocation == null)
                              ? _buildErrorState()
                              : Stack(
                                  children: [
                                    FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: clinicLocation!,
                                        initialZoom: 15,
                                        maxZoom: 19,
                                        cameraConstraint:
                                            CameraConstraint.contain(
                                          bounds: LatLngBounds(
                                            const LatLng(southLat, westLng),
                                            const LatLng(northLat, eastLng),
                                          ),
                                        ),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                                          subdomains: const [
                                            'a',
                                            'b',
                                            'c',
                                            'd'
                                          ],
                                        ),
                                        // Route polyline (only if user location exists and not showing without location)
                                        if (routePoints.isNotEmpty &&
                                            !showWithoutUserLocation)
                                          PolylineLayer(
                                            polylines: [
                                              Polyline(
                                                points: routePoints,
                                                color: Colors.blue,
                                                strokeWidth: 5.0,
                                              ),
                                            ],
                                          ),
                                        // Markers
                                        MarkerLayer(
                                          markers: [
                                            // User location marker (only if exists and not showing without location)
                                            if (userLocation != null &&
                                                !showWithoutUserLocation)
                                              Marker(
                                                point: userLocation!,
                                                width: 40,
                                                height: 40,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.my_location,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                            // Clinic location marker
                                            Marker(
                                              point: clinicLocation!,
                                              width: 70,
                                              height: 90,
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    color: Colors.red.shade600,
                                                    size: 40,
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 5,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.2),
                                                          blurRadius: 2,
                                                          offset: const Offset(
                                                              0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      widget.clinic.clinicName,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Info overlay
                                    Positioned(
                                      top: 20,
                                      left: 20,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.red.shade600,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              widget.clinic.clinicName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
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
