import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'vet_popup.dart';

class WebMaps extends StatefulWidget {
  final String selectedFilter;
  final String searchQuery;
  final Function(String)? onFilterChanged;
  final Map<String, ClinicRatingStats>? ratingStatsCache;

  const WebMaps({
    super.key,
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.onFilterChanged,
    this.ratingStatsCache,
  });

  @override
  State<WebMaps> createState() => _WebMapsState();
}

class _WebMapsState extends State<WebMaps> {
  final MapController _mapController = MapController();
  final PopupController _popupController = PopupController();
  LatLng? userLocation;
  List<LatLng> routePoints = [];
  final Distance distance = const Distance();

  List<Clinic> allClinics = [];
  List<Clinic> filteredClinics = [];
  Map<String, ClinicSettings?> clinicSettingsMap = {};
  bool isLoading = true;
  String? error;

  // KEEP ORIGINAL CAMERA BOUNDS - Same as before
  // This defines what the camera can see
  final sanJoseDelMonteBounds = LatLngBounds(
    const LatLng(14.7667, 121.0167), // Southwest: 14°46'N, 121°1'E
    const LatLng(14.8667, 121.1667), // Northeast: 14°52'N, 121°10'E
  );

  // STRICT SJDM POLYGON BOUNDARIES - Based on official barangay map
  // Traced from the actual SJDM city boundary map showing all 62 barangays
  // Excludes neighboring municipalities: Norzagaray (N), Rodriguez/Quezon (E),
  // Quezon City/Caloocan (S), Santa Maria/Marilao (W)
  final List<LatLng> sjdmPolygonBoundary = const [
    // Start from SOUTHWEST - Muzon area (border with Caloocan City)
    LatLng(14.7680, 121.0480), // Muzon South - southernmost point

    // SOUTH BORDER - Muzon to San Manuel (Caloocan & Quezon City border)
    LatLng(14.7700, 121.0520), // Muzon South boundary
    LatLng(14.7720, 121.0580), // Between Muzon and Gaya-Gaya
    LatLng(14.7750, 121.0650), // Gaya-Gaya/Graceville area
    LatLng(14.7780, 121.0720), // San Manuel area

    // SOUTHEAST CURVE - San Manuel to Ciudad Real (Quezon City border)
    LatLng(14.7820, 121.0800), // Tungkong Mangga south
    LatLng(14.7860, 121.0880), // Ciudad Real west
    LatLng(14.7900, 121.0950), // Ciudad Real center

    // EAST BORDER START - Ciudad Real to Paradise III (Rodriguez, Rizal border)
    LatLng(14.7950, 121.1020), // Ciudad Real east
    LatLng(14.8000, 121.1080), // Paradise III south
    LatLng(14.8050, 121.1140), // Paradise III center

    // EAST BORDER MIDDLE - Paradise III to San Isidro (Rodriguez/Quezon border)
    LatLng(14.8100, 121.1180), // Paradise III north / San Isidro
    LatLng(14.8150, 121.1200), // San Isidro - easternmost point
    LatLng(14.8200, 121.1190), // San Roque east

    // NORTHEAST CURVE - San Roque to Minuyan areas
    LatLng(14.8250, 121.1160), // Kaybanban east
    LatLng(14.8300, 121.1120), // Minuyan II east
    LatLng(14.8350, 121.1080), // Minuyan III east
    LatLng(14.8400, 121.1050), // Minuyan IV east

    // NORTH BORDER START - Minuyan to Citrus (Norzagaray border - conservative)
    LatLng(14.8450, 121.1000), // Minuyan Proper east
    LatLng(14.8480, 121.0920), // Citrus north - avoid disputed areas
    LatLng(14.8500, 121.0850), // Minuyan V north (conservative boundary)

    // NORTH BORDER MIDDLE - Minuyan to Sapang Palay (Norzagaray border)
    LatLng(14.8510, 121.0780), // Santo Nino II north
    LatLng(14.8500, 121.0700), // Bagong Buhay north
    LatLng(14.8480, 121.0620), // San Rafael V north
    LatLng(14.8460, 121.0550), // San Martin de Porres / Lawang Pari
    LatLng(14.8440, 121.0480), // Assumption / Maharlika north

    // NORTHWEST CORNER - Sapang Palay area (Norzagaray border)
    LatLng(14.8420, 121.0410), // Sapang Palay north
    LatLng(14.8390, 121.0350), // Sapang Palay northwest
    LatLng(14.8350, 121.0300), // Gaya-Gaya north / Kaypian

    // WEST BORDER - Kaypian to Dulong Bayan (Santa Maria border)
    LatLng(14.8300, 121.0270), // Kaypian west - westernmost point
    LatLng(14.8250, 121.0290), // Kaybanban west
    LatLng(14.8200, 121.0310), // San Pedro west
    LatLng(14.8150, 121.0330), // Santo Cristo west

    // WEST BORDER SOUTH - Santo Cristo to Muzon (Santa Maria/Marilao border)
    LatLng(14.8100, 121.0350), // Dulong Bayan west
    LatLng(14.8050, 121.0370), // Poblacion west
    LatLng(14.8000, 121.0390), // Gumaoc West
    LatLng(14.7950, 121.0410), // Gaya-Gaya west
    LatLng(14.7900, 121.0430), // Gaya-Gaya southwest
    LatLng(14.7850, 121.0450), // Muzon West
    LatLng(14.7800, 121.0460), // Muzon area
    LatLng(14.7750, 121.0470), // Muzon South area

    // Close polygon - back to start
    LatLng(14.7680, 121.0480), // Muzon South - southernmost point
  ];

  // CRITICAL: Point-in-polygon test for STRICT SJDM boundary
  bool isWithinBounds(LatLng point) {
    // Ray casting algorithm for point-in-polygon test
    // This ensures ONLY areas within the polygon boundary are considered valid SJDM
    return _isPointInPolygon(point, sjdmPolygonBoundary);
  }

  // Ray casting algorithm implementation
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length - 1; i++) {
      if (_rayCastIntersect(point, polygon[i], polygon[i + 1])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1; // Odd number of intersections = inside
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

  @override
  void initState() {
    super.initState();
    _initializeMap();

    // MODIFIED: Force map to be interactive immediately after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && userLocation != null) {
        // Trigger a tiny move to "wake up" the map controller
        _mapController.move(userLocation!, 14);
      }
    });
  }

  @override
  void didUpdateWidget(WebMaps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter ||
        oldWidget.searchQuery != widget.searchQuery) {
      _applyFilters();
    }
  }

  Future<void> _initializeMap() async {
    await Future.wait([
      _fetchUserLocation(),
      _fetchClinicsData(),
    ]);
  }

  Future<void> _fetchUserLocation() async {
    try {
      Position? position = await _getCurrentUserLocation();
      if (position != null) {
        LatLng fetchedLocation = LatLng(position.latitude, position.longitude);

        // STRICT: If user location is outside SJDM polygon, default to city center
        if (!isWithinBounds(fetchedLocation)) {
          fetchedLocation =
              const LatLng(14.8167, 121.0500); // SJDM City Center (Poblacion)
        }

        setState(() {
          userLocation = fetchedLocation;
        });
      } else {
        // Default to SJDM city center
        setState(() {
          userLocation = const LatLng(14.8167, 121.0500);
        });
      }
    } catch (e) {
      setState(() {
        userLocation = const LatLng(14.8167, 121.0500);
      });
    }
  }

  Future<void> _fetchClinicsData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final authRepository = Get.find<AuthRepository>();

      // Fetch all clinics with their settings in one go
      final clinicsWithSettings = await authRepository.getClinicsWithSettings();

      final clinics = <Clinic>[];
      final settingsMap = <String, ClinicSettings?>{};

      for (final data in clinicsWithSettings) {
        final clinic = data['clinic'] as Clinic;
        final settings = data['settings'] as ClinicSettings?;

        clinics.add(clinic);
        settingsMap[clinic.documentId ?? ''] = settings;
      }

      if (mounted) {
        setState(() {
          allClinics = clinics;
          clinicSettingsMap = settingsMap;
          isLoading = false;
        });

        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Failed to load clinics data";
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    var filtered = List<Clinic>.from(allClinics);

    // Apply search filter first
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered.where((clinic) {
        final settings = clinicSettingsMap[clinic.documentId ?? ''];
        final services = settings?.services.join(' ') ?? clinic.services;

        return clinic.clinicName
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase()) ||
            clinic.address
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase()) ||
            services.toLowerCase().contains(widget.searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter with closed dates support
    switch (widget.selectedFilter) {
      case 'Open':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) {
            return false;
          }

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          final isOpen = settings.isOpen;
          final isOpenNow = settings.isOpenNow();

          return isOpen && isOpenNow && !isTodayClosedDate;
        }).toList();
        break;

      case 'Closed':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) {
            return true;
          }

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          final isOpen = settings.isOpen;
          final isOpenNow = settings.isOpenNow();

          final isClosed = !isOpen || !isOpenNow || isTodayClosedDate;

          return isClosed;
        }).toList();
        break;

      case 'Popular':
        if (widget.ratingStatsCache != null) {
          // Sort by review count (descending) and rating (descending)
          filtered.sort((a, b) {
            final aStats = widget.ratingStatsCache![a.documentId ?? ''];
            final bStats = widget.ratingStatsCache![b.documentId ?? ''];

            final aReviews = aStats?.totalReviews ?? 0;
            final bReviews = bStats?.totalReviews ?? 0;

            // First sort by review count
            if (aReviews != bReviews) {
              return bReviews.compareTo(aReviews);
            }

            // If same review count, sort by rating
            final aRating = aStats?.averageRating ?? 0.0;
            final bRating = bStats?.averageRating ?? 0.0;
            return bRating.compareTo(aRating);
          });

          // Only show clinics with at least 1 review
          filtered = filtered.where((clinic) {
            final stats = widget.ratingStatsCache![clinic.documentId ?? ''];
            return (stats?.totalReviews ?? 0) > 0;
          }).toList();
        }
        break;

      case 'All':
      default:
        break;
    }

    // CRITICAL: Only include clinics with location data AND within SJDM POLYGON
    filtered = filtered.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      if (settings?.location == null) {
        return false;
      }

      final location = LatLng(
        settings!.location!['lat']!,
        settings.location!['lng']!,
      );

      // STRICT POLYGON CHECK: Filter out clinics outside SJDM polygon boundary
      return isWithinBounds(location);
    }).toList();

    setState(() {
      filteredClinics = filtered;
    });
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

  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        ) /
        1000;
  }

  void moveToNearestMarker() {
    if (userLocation == null || filteredClinics.isEmpty) return;

    Clinic? nearest;
    double shortestDistance = double.infinity;

    for (final clinic in filteredClinics) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];

      if (settings?.location != null) {
        final clinicLocation =
            LatLng(settings!.location!['lat']!, settings.location!['lng']!);

        // STRICT: Skip clinics outside SJDM polygon
        if (!isWithinBounds(clinicLocation)) {
          continue;
        }

        // Check if clinic is OPEN and AVAILABLE
        final today = DateTime.now();
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final isTodayClosedDate = settings.closedDates.contains(todayStr);

        // Clinic must be: isOpen flag true, open now, and NOT on a closed date
        final isOpenAndAvailable =
            settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;

        if (!isOpenAndAvailable) {
          continue;
        }

        final dist = calculateDistance(userLocation!, clinicLocation);

        if (dist < shortestDistance) {
          shortestDistance = dist;
          nearest = clinic;
        }
      }
    }

    if (nearest != null) {
      final settings = clinicSettingsMap[nearest.documentId ?? ''];
      if (settings?.location != null) {
        final nearestLocation =
            LatLng(settings!.location!['lat']!, settings.location!['lng']!);

        // STRICT: Double-check polygon bounds before moving
        if (isWithinBounds(nearestLocation)) {
          _mapController.move(nearestLocation, 17);
          fetchRoute(nearestLocation);
        } else {
          _showNoNearestClinicMessage(
              'Nearest open clinic is outside San Jose del Monte city limits');
        }
      }
    } else {
      _showNoNearestClinicMessage(
          'No open clinics available in San Jose del Monte');
    }
  }

  List<Marker> getMarkers() {
    if (userLocation == null) return [];

    final markers = <Marker>[];

    for (final clinic in filteredClinics) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];

      if (settings?.location == null) {
        continue;
      }

      final location =
          LatLng(settings!.location!['lat']!, settings.location!['lng']!);

      // STRICT: Only show markers within SJDM polygon boundary
      if (!isWithinBounds(location)) {
        continue;
      }

      double distanceInKm = calculateDistance(userLocation!, location);

      // Determine marker color with closed dates support
      Color markerColor;

      // Check if today is a closed date
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final isTodayClosedDate = settings.closedDates.contains(todayStr);

      if (isTodayClosedDate) {
        markerColor = Colors.red; // Closed date - always red
      } else if (!settings.isOpen) {
        markerColor = Colors.red; // Not accepting appointments
      } else if (settings.isOpenNow()) {
        markerColor = Colors.green; // Open now
      } else if (settings.isOpenToday()) {
        markerColor = Colors.orange; // Open today but not right now
      } else {
        markerColor = Colors.red; // Closed today by schedule
      }

      markers.add(Marker(
        point: location,
        width: 70,
        height: 90,
        child: GestureDetector(
          onTap: () {
            if (userLocation != null) {
              // Hide existing popups
              _popupController.hideAllPopups();
              setState(() {
                routePoints.clear();
              });

              // Fetch route
              fetchRoute(location);

              // Show popup after route is drawn
              Future.delayed(const Duration(milliseconds: 150), () {
                final targetMarker = getMarkers().firstWhere(
                  (marker) => marker.point == location,
                  orElse: () => getMarkers().first,
                );

                // Recalculate snap position when showing popup
                setState(() {
                  _popupController.showPopupsOnlyFor([targetMarker]);
                });
              });
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.location_on, color: markerColor, size: 40),
              Positioned(
                top: 65,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    "${distanceInKm.toStringAsFixed(2)} km",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return markers;
  }

  Future<void> fetchRoute(LatLng destination) async {
    if (userLocation == null) return;

    try {
      String url =
          "https://router.project-osrm.org/route/v1/driving/${userLocation!.longitude},${userLocation!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];
          List<LatLng> points =
              coordinates.map((c) => LatLng(c[1], c[0])).toList();

          setState(() {
            routePoints = points;
            _popupController.hideAllPopups();
          });

          // Show popup after a brief delay
          Future.delayed(const Duration(milliseconds: 100), () {
            final targetMarker = getMarkers().firstWhere(
              (marker) => marker.point == destination,
              orElse: () => getMarkers().first,
            );
            _popupController.showPopupsOnlyFor([targetMarker]);
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading clinics...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
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
              error ?? "Failed to load clinic data",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchClinicsData,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.searchQuery.isEmpty
                  ? "No clinics match the selected filter"
                  : "No clinics found for '${widget.searchQuery}'",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Only clinics within San Jose del Monte city limits are shown",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (error != null) {
      return _buildErrorState();
    }

    if (filteredClinics.isEmpty) {
      return _buildEmptyState();
    }

    if (userLocation == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up map...'),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < mobileWidth;
      return Stack(
        children: [
          // MODIFIED: Use Listener to absorb pointer events and prevent parent scroll
          Listener(
            onPointerDown: (_) {},
            onPointerMove: (_) {},
            onPointerUp: (_) {},
            onPointerSignal: (_) {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLocation!,
                  initialZoom: 14,
                  minZoom: 12,
                  maxZoom: 19,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: sanJoseDelMonteBounds,
                  ),
                  // MODIFIED: Simplified interaction options - enable all gestures
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onTap: (_, __) {
                    setState(() {
                      routePoints.clear();
                      _popupController.hideAllPopups();
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),
                  if (routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: Colors.blue,
                          strokeWidth: 5.0,
                        ),
                      ],
                    ),
                  PopupMarkerLayer(
                    options: PopupMarkerLayerOptions(
                      popupController: _popupController,
                      markers: getMarkers(),
                      popupDisplayOptions: PopupDisplayOptions(
                        builder: (BuildContext context, Marker marker) {
                          final clinic = filteredClinics.firstWhere(
                            (c) {
                              final settings =
                                  clinicSettingsMap[c.documentId ?? ''];
                              if (settings?.location == null) return false;
                              final clinicLocation = LatLng(
                                  settings!.location!['lat']!,
                                  settings.location!['lng']!);
                              return clinicLocation == marker.point;
                            },
                          );
                          final settings =
                              clinicSettingsMap[clinic.documentId ?? ''];

                          return VetPopup(
                            clinic: clinic,
                            clinicSettings: settings,
                          );
                        },
                      ),
                    ),
                  ),
                  MarkerLayer(
                    markers: [
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
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Floating action button for finding nearest clinic
          if (!isMobile)
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: "nearest",
                mini: true,
                backgroundColor: Colors.white,
                onPressed: moveToNearestMarker,
                child: const Icon(
                  Icons.near_me,
                  color: Colors.black,
                ),
              ),
            ),
          // Filter info overlay with SJDM indicator
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${filteredClinics.length} clinics ${widget.selectedFilter != 'All' ? '(${widget.selectedFilter})' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'SJDM city limits only',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showNoNearestClinicMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
