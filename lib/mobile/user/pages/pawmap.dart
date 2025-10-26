import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/search_bar.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/tags.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/vet_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

class Pawmap extends StatefulWidget {
  const Pawmap({super.key});

  @override
  State<Pawmap> createState() => _PawmapState();
}

class _PawmapState extends State<Pawmap> {
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
  String searchQuery = '';
  String selectedFilter = 'All';

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

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
    _applyFilters();
  }

  void setFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    _applyFilters();
  }

  int getFilterCount(String filter) {
    var filtered = allClinics.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      return settings?.location != null;
    });

    switch (filter) {
      case 'All':
        return filtered.length;
      case 'Open':
        return filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return settings?.isOpen ?? true;
        }).length;
      case 'Closed':
        return filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return !(settings?.isOpen ?? true);
        }).length;
      case 'Available Today':
        return filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return (settings?.isOpen ?? true) && (settings?.isOpenToday() ?? true);
        }).length;
      default:
        return 0;
    }
  }

  void _applyFilters() {
    var filtered = allClinics;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((clinic) {
        final settings = clinicSettingsMap[clinic.documentId ?? ''];
        final services = settings?.services.join(' ') ?? clinic.services;

        return clinic.clinicName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            clinic.address.toLowerCase().contains(searchQuery.toLowerCase()) ||
            services.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    switch (selectedFilter) {
      case 'Open':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return settings?.isOpen ?? true;
        }).toList();
        break;
      case 'Closed':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return !(settings?.isOpen ?? true);
        }).toList();
        break;
      case 'Available Today':
        filtered = filtered.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return (settings?.isOpen ?? true) && (settings?.isOpenToday() ?? true);
        }).toList();
        break;
    }

    // Only include clinics that have location data set
    filtered = filtered.where((clinic) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      return settings?.location != null;
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

    for (final clinic in filteredClinics) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];
      if (settings?.location != null) {
        final clinicLocation =
            LatLng(settings!.location!['lat']!, settings.location!['lng']!);
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
        if (isWithinBounds(nearestLocation)) {
          _mapController.move(nearestLocation, 17);
          fetchRoute(nearestLocation);
        }
      }
    }
  }

  List<Marker> getMarkers() {
    if (userLocation == null) return [];

    final markers = <Marker>[];

    for (final clinic in filteredClinics) {
      final settings = clinicSettingsMap[clinic.documentId ?? ''];

      if (settings?.location == null) continue;

      final location =
          LatLng(settings!.location!['lat']!, settings.location!['lng']!);

      if (!isWithinBounds(location)) continue;

      double distanceInKm = calculateDistance(userLocation!, location);

      Color markerColor = Colors.red;
      if (settings.isOpen) {
        if (settings.isOpenToday()) {
          markerColor = Colors.green;
        } else {
          markerColor = Colors.orange;
        }
      }

      markers.add(
        Marker(
          point: location,
          width: 70,
          height: 90,
          child: GestureDetector(
            onTap: () {
              if (userLocation != null) {
                _popupController.hideAllPopups();
                fetchRoute(location);
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
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          userLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
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

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VetPopup(
                                  clinic: clinic,
                                  clinicSettings: settings,
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromARGB(255, 39, 86, 139),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () {
                                      _popupController.hideAllPopups();
                                      setState(() {
                                        routePoints.clear();
                                      });
                                    },
                                  ),
                                ),
                              ],
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

          // Search bar and tags at top
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, top: 16, bottom: 8, right: 16),
                child: MySearchBar(
                  onSearchChanged: updateSearchQuery,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: MyTags(
                  selectedFilter: selectedFilter,
                  onFilterChanged: setFilter,
                  getFilterCount: getFilterCount,
                ),
              ),
            ],
          ),

          // Nearest clinic button (plane icon) at bottom right
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: "nearest",
              backgroundColor: Colors.white,
              onPressed: moveToNearestMarker,
              child: const Icon(
                Icons.navigation,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton:Padding(
      //   padding: const EdgeInsets.only(bottom: 55),
      //   child: Container(
      //     width: 60,
      //     height: 60,
      //     decoration: BoxDecoration(
      //       color: Colors.grey.shade100,
      //       shape: BoxShape.circle,
      //       boxShadow: [
      //         BoxShadow(
      //           color: Colors.black.withValues(alpha: 0.15),
      //           blurRadius: 6,
      //           offset: const Offset(0, 3)
      //         )
      //       ],
      //     ),
      //     child: IconButton(
      //       icon: const Icon(Icons.close_rounded, color: Colors.black,),
      //       onPressed: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //   ),
      // )
    );
  }
}
