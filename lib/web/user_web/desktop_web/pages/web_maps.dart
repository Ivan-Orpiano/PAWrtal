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
  final Map<String, ClinicRatingStats>? ratingStatsCache; // NEW: Add this

  const WebMaps({
    super.key,
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.onFilterChanged,
    this.ratingStatsCache, // NEW: Add this
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

  final sanJoseDelMonteBounds = LatLngBounds(
    const LatLng(14.7500, 121.0000),
    const LatLng(14.8700, 121.1000),
  );

  bool isWithinBounds(LatLng point) {
    return sanJoseDelMonteBounds.contains(point);
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(WebMaps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter ||
        oldWidget.searchQuery != widget.searchQuery) {
      print('>>> ============================================');
      print('>>> FILTER CHANGED IN WEB MAPS');
      print('>>> Selected Filter: ${widget.selectedFilter}');
      print('>>> Search Query: ${widget.searchQuery}');
      print('>>> ============================================');
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
        if (!isWithinBounds(fetchedLocation)) {
          fetchedLocation = sanJoseDelMonteBounds.center;
        }
        setState(() {
          userLocation = fetchedLocation;
        });
      } else {
        // Default to center of bounds if location not available
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
      print("Error fetching clinics data: $e");
      if (mounted) {
        setState(() {
          error = "Failed to load clinics data";
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    print('>>> ============================================');
    print('>>> APPLYING FILTERS IN WEB MAPS');
    print('>>> All clinics count: ${allClinics.length}');
    print('>>> Filter: ${widget.selectedFilter}');
    print('>>> Search: ${widget.searchQuery}');
    print('>>> Has rating stats: ${widget.ratingStatsCache != null}');
    print('>>> ============================================');

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
      print('>>> After search filter: ${filtered.length} clinics');
    }

    // Apply status filter with closed dates support
    switch (widget.selectedFilter) {
      case 'Open':
        print('>>> Filtering for OPEN clinics...');
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) {
            print('>>>   ${clinic.clinicName}: No settings - excluded');
            return false;
          }

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          final isOpen = settings.isOpen;
          final isOpenNow = settings.isOpenNow();

          print('>>>   ${clinic.clinicName}:');
          print('>>>     - isOpen flag: $isOpen');
          print('>>>     - isOpenNow: $isOpenNow');
          print('>>>     - isTodayClosedDate: $isTodayClosedDate');
          print(
              '>>>     - Result: ${isOpen && isOpenNow && !isTodayClosedDate}');

          return isOpen && isOpenNow && !isTodayClosedDate;
        }).toList();
        break;

      case 'Available Today':
        print('>>> Filtering for AVAILABLE TODAY clinics...');
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) {
            print('>>>   ${clinic.clinicName}: No settings - excluded');
            return false;
          }

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          final isOpen = settings.isOpen;
          final isOpenToday = settings.isOpenToday();

          print('>>>   ${clinic.clinicName}:');
          print('>>>     - isOpen flag: $isOpen');
          print('>>>     - isOpenToday: $isOpenToday');
          print('>>>     - isTodayClosedDate: $isTodayClosedDate');
          print(
              '>>>     - Result: ${isOpen && isOpenToday && !isTodayClosedDate}');

          return isOpen && isOpenToday && !isTodayClosedDate;
        }).toList();
        break;

      case 'Closed':
        print('>>> Filtering for CLOSED clinics...');
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          if (settings == null) {
            print(
                '>>>   ${clinic.clinicName}: No settings - included as closed');
            return true;
          }

          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          final isTodayClosedDate = settings.closedDates.contains(todayStr);

          final isOpen = settings.isOpen;
          final isOpenNow = settings.isOpenNow();

          print('>>>   ${clinic.clinicName}:');
          print('>>>     - isOpen flag: $isOpen');
          print('>>>     - isOpenNow: $isOpenNow');
          print('>>>     - isTodayClosedDate: $isTodayClosedDate');

          final isClosed = !isOpen || !isOpenNow || isTodayClosedDate;
          print('>>>     - Result (is closed): $isClosed');

          return isClosed;
        }).toList();
        break;

      case 'Popular':
        print('>>> Filtering for POPULAR clinics...');

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
            final hasReviews = (stats?.totalReviews ?? 0) > 0;

            if (hasReviews) {
              print(
                  '>>>   ${clinic.clinicName}: ${stats?.totalReviews} reviews, ${stats?.averageRating} rating - included');
            } else {
              print('>>>   ${clinic.clinicName}: No reviews - excluded');
            }

            return hasReviews;
          }).toList();

          print('>>> Found ${filtered.length} popular clinics with reviews');
        } else {
          print(
              '>>> WARNING: No rating stats cache provided - showing all clinics');
        }
        break;

      case 'All':
      default:
        print('>>> Showing ALL clinics...');
        break;
    }

    print('>>> After status filter: ${filtered.length} clinics');

    // Only include clinics that have location data set
    final beforeLocationFilter = filtered.length;
    filtered = filtered.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      final hasLocation = settings?.location != null;

      if (!hasLocation) {
        print('>>>   ${clinic.clinicName}: No location data - excluded');
      }

      return hasLocation;
    }).toList();

    print(
        '>>> After location filter: ${filtered.length} clinics (removed ${beforeLocationFilter - filtered.length} without location)');

    setState(() {
      filteredClinics = filtered;
    });

    print('>>> ============================================');
    print('>>> FILTER COMPLETE');
    print('>>> Final filtered clinics: ${filteredClinics.length}');
    for (var clinic in filteredClinics) {
      final stats = widget.ratingStatsCache?[clinic.documentId ?? ''];
      if (stats != null) {
        print(
            '>>>   - ${clinic.clinicName} (${stats.totalReviews} reviews, ${stats.averageRating.toStringAsFixed(1)} rating)');
      } else {
        print('>>>   - ${clinic.clinicName}');
      }
    }
    print('>>> ============================================');
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

    print('>>> ============================================');
    print('>>> FINDING NEAREST OPEN CLINIC');
    print('>>> User location: $userLocation');
    print('>>> Total filtered clinics: ${filteredClinics.length}');
    print('>>> ============================================');

    for (final clinic in filteredClinics) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];

      if (settings?.location != null) {
        // CRITICAL: Check if clinic is OPEN and AVAILABLE
        final today = DateTime.now();
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final isTodayClosedDate = settings!.closedDates.contains(todayStr);

        // Clinic must be: isOpen flag true, open now, and NOT on a closed date
        final isOpenAndAvailable =
            settings.isOpen && settings.isOpenNow() && !isTodayClosedDate;

        if (!isOpenAndAvailable) {
          print('>>> ${clinic.clinicName}: SKIPPED (not open/available)');
          print('>>>   - isOpen: ${settings.isOpen}');
          print('>>>   - isOpenNow: ${settings.isOpenNow()}');
          print('>>>   - isTodayClosedDate: $isTodayClosedDate');
          continue; // Skip this clinic
        }

        final clinicLocation =
            LatLng(settings.location!['lat']!, settings.location!['lng']!);
        final dist = calculateDistance(userLocation!, clinicLocation);

        print('>>> ${clinic.clinicName}: ${dist.toStringAsFixed(2)} km (OPEN)');

        if (dist < shortestDistance) {
          shortestDistance = dist;
          nearest = clinic;
        }
      } else {
        print('>>> ${clinic.clinicName}: SKIPPED (no location data)');
      }
    }

    if (nearest != null) {
      final settings = clinicSettingsMap[nearest.documentId ?? ''];
      if (settings?.location != null) {
        final nearestLocation =
            LatLng(settings!.location!['lat']!, settings.location!['lng']!);

        if (isWithinBounds(nearestLocation)) {
          print('>>> ============================================');
          print('>>> NEAREST OPEN CLINIC FOUND: ${nearest.clinicName}');
          print('>>> Distance: ${shortestDistance.toStringAsFixed(2)} km');
          print('>>> Moving map to location: $nearestLocation');
          print('>>> ============================================');

          _mapController.move(nearestLocation, 17);
          fetchRoute(nearestLocation);
        } else {
          print('>>> Nearest clinic is out of bounds');
          _showNoNearestClinicMessage(
              'Nearest open clinic is outside the service area');
        }
      }
    } else {
      print('>>> ============================================');
      print('>>> NO OPEN CLINICS FOUND');
      print('>>> ============================================');
      _showNoNearestClinicMessage('No open clinics available nearby');
    }
  }

  List<Marker> getMarkers() {
    if (userLocation == null) return [];

    print('>>> ============================================');
    print('>>> GENERATING MARKERS');
    print('>>> User location: $userLocation');
    print('>>> Filtered clinics: ${filteredClinics.length}');
    print('>>> ============================================');

    final markers = <Marker>[];

    for (final clinic in filteredClinics) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];

      if (settings?.location == null) {
        print('>>>   ${clinic.clinicName}: No location - skipped');
        continue;
      }

      final location =
          LatLng(settings!.location!['lat']!, settings.location!['lng']!);

      if (!isWithinBounds(location)) {
        print('>>>   ${clinic.clinicName}: Out of bounds - skipped');
        continue;
      }

      double distanceInKm = calculateDistance(userLocation!, location);

      // CRITICAL: Determine marker color with closed dates support
      Color markerColor;

      // Check if today is a closed date
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final isTodayClosedDate = settings.closedDates.contains(todayStr);

      if (isTodayClosedDate) {
        markerColor = Colors.red; // Closed date - always red
        print('>>>   ${clinic.clinicName}: CLOSED DATE - Red marker');
      } else if (!settings.isOpen) {
        markerColor = Colors.red; // Not accepting appointments
        print('>>>   ${clinic.clinicName}: NOT OPEN - Red marker');
      } else if (settings.isOpenNow()) {
        markerColor = Colors.green; // Open now
        print('>>>   ${clinic.clinicName}: OPEN NOW - Green marker');
      } else if (settings.isOpenToday()) {
        markerColor = Colors.orange; // Open today but not right now
        print('>>>   ${clinic.clinicName}: OPEN TODAY - Orange marker');
      } else {
        markerColor = Colors.red; // Closed today by schedule
        print('>>>   ${clinic.clinicName}: CLOSED TODAY - Red marker');
      }

      markers.add(Marker(
        point: location,
        width: 70, // Make sure this is consistent
        height: 90, // Make sure this is consistent
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

    print('>>> ============================================');
    print('>>> MARKERS GENERATED: ${markers.length}');
    print('>>> ============================================');

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
      print("Error fetching route: $e");
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
              "Only clinics with set locations are shown on the map",
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLocation!,
                initialZoom: 15,
                maxZoom: 19,
                cameraConstraint: CameraConstraint.contain(
                  bounds: sanJoseDelMonteBounds,
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
                        // Find the clinic that corresponds to this marker
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

                        // Just return the popup directly - no wrapper needed
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
          // Filter info overlay
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
              child: Text(
                '${filteredClinics.length} clinics ${widget.selectedFilter != 'All' ? '(${widget.selectedFilter})' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
