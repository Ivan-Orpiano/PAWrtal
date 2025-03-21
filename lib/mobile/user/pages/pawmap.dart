import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'vet_popup.dart';

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
  final Distance distance = Distance();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> markerData = [
    {
      "name": "Qualipaws Animal Clinic",
      "location": LatLng(14.8131, 121.0453),
      "description": "Affordable animal care services in SJDM.",
      "image": "lib/images/qualipaws.jpg",
      "status": "Open",
    },
    {
      "name": "SM San Jose Del Monte",
      "location": LatLng(14.78569, 121.07577),
      "description": "A shopping mall with pet-friendly facilities.",
      "image": "lib/images/sm_sjdm.jpg",
      "status": "Closed",
    },
    {
      "name": "Pet Health Center",
      "location": LatLng(14.778830740347956, 121.07446884832339),
      "description": "Expert pet health services in your neighborhood.",
      "image": "lib/images/pet_health.jpg",
      "status": "Full",
    },
  ];

  final sanJoseDelMonteBounds = LatLngBounds(
    LatLng(14.7500, 121.0000),
    LatLng(14.8700, 121.1000),
  );

  bool isWithinBounds(LatLng point) {
    return sanJoseDelMonteBounds.contains(point);
  }

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    Position? position = await getUserLocation();
    if (position != null) {
      LatLng fetchedLocation = LatLng(position.latitude, position.longitude);
      if (!isWithinBounds(fetchedLocation)) {
        fetchedLocation = sanJoseDelMonteBounds.center;
      }
      setState(() {
        userLocation = fetchedLocation;
      });
    }
  }

  Future<Position?> getUserLocation() async {
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
    if (userLocation == null || markerData.isEmpty) return;

    Map<String, dynamic> nearest = markerData.reduce((a, b) {
      final aDist = calculateDistance(userLocation!, a["location"]);
      final bDist = calculateDistance(userLocation!, b["location"]);
      return aDist < bDist ? a : b;
    });

    LatLng nearestLocation = nearest["location"];
    if (isWithinBounds(nearestLocation)) {
      _mapController.move(nearestLocation, 17);
      fetchRoute(nearestLocation);
    }
  }

  List<Marker> getMarkers() {
    if (userLocation == null) return [];

    return markerData.map((data) {
      final location = data["location"] as LatLng;
      double distanceInKm = calculateDistance(userLocation!, location);

      return Marker(
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
              Icon(Icons.location_on, color: Colors.red, size: 40),
              Positioned(
                top: 65,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "${distanceInKm.toStringAsFixed(2)} km",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> fetchRoute(LatLng destination) async {
    if (userLocation == null) return;

    String url =
        "https://router.project-osrm.org/route/v1/driving/${userLocation!.longitude},${userLocation!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];
      List<LatLng> points = coordinates.map((c) => LatLng(c[1], c[0])).toList();

      setState(() {
        routePoints = points;
        _popupController.hideAllPopups();
        Future.delayed(Duration(milliseconds: 100), () {
          _popupController.showPopupsOnlyFor([
            getMarkers().firstWhere((marker) => marker.point == destination)
          ]);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          userLocation == null
              ? Center(child: CircularProgressIndicator())
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
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                      maxZoom: 19,
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
                            final markerInfo = markerData.firstWhere(
                                (element) =>
                                    element["location"] == marker.point);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VetPopup(data: markerInfo),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromARGB(255, 39, 86, 139),
                                  ),
                                  child: IconButton(
                                    icon:
                                        Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      _popupController.hideAllPopups();
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
                          child: Icon(Icons.my_location,
                              color: Colors.blue, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(25),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return markerData
                                .map((e) => e["name"] as String)
                                .where((name) => name.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (String selectedName) {
                            final selected = markerData.firstWhere(
                                (element) => element["name"] == selectedName);
                            final LatLng location = selected["location"];
                            if (isWithinBounds(location)) {
                              _mapController.move(location, 17);
                              fetchRoute(location);
                            }
                          },
                          fieldViewBuilder: (context, controller, focusNode,
                              onEditingComplete) {
                            _searchController.text = controller.text;
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onEditingComplete: onEditingComplete,
                              decoration: InputDecoration(
                                hintText: "Search...",
                                hintStyle: TextStyle(color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: moveToNearestMarker,
                      child: Text("Nearest",
                          style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {},
                      child:
                          Text("Open", style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () {},
                      child:
                          Text("More", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
