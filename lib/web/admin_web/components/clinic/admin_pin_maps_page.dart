import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Barangay data model
class Barangay {
  final String name;
  final LatLng coordinates;

  Barangay(this.name, this.coordinates);
}

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
  final TextEditingController _barangaySearchController =
      TextEditingController();

  LatLng? userLocation;
  LatLng? selectedLocation;
  bool isLoading = true;
  List<Barangay> filteredBarangays = [];
  bool showDropdown = false;
  Barangay? selectedBarangay;

  final sanJoseDelMonteBounds = LatLngBounds(
    const LatLng(14.7500, 121.0200), // Southwest corner (near Sapang Palay)
    const LatLng(
        14.8700, 121.0900), // Northeast corner (near Minuyan/upper areas)
  );

  // Complete list of SJDM Barangays with approximate coordinates
  // NOTE: These are approximate coordinates distributed across SJDM bounds
  // Replace with actual barangay coordinates for accurate navigation
  final List<Barangay> barangays = [
    // NORTHERN AREA - Sapang Palay District (Upper SJDM)
    // PhilAtlas verified: Sapang Palay is at 14.8390, 121.0429 (NORTHERN, not southern!)
    Barangay('Sapang Palay', const LatLng(14.8390, 121.0429)),

    // NORTHERN AREA - Minuyan District (Uppermost SJDM, near Norzagaray border)
    Barangay('Minuyan', const LatLng(14.8523, 121.0770)), // PhilAtlas verified
    Barangay('Minuyan II',
        const LatLng(14.8349, 121.0922)), // Estimated near Minuyan
    Barangay(
        'Minuyan III', const LatLng(14.8400, 121.1099)), // PhilAtlas verified
    Barangay(
        'Minuyan IV', const LatLng(14.8461, 121.1186)), // PhilAtlas verified
    Barangay('Minuyan V',
        const LatLng(14.8490, 121.0950)), // Estimated between III & IV
    Barangay(
        'Minuyan Proper', const LatLng(14.8428, 121.0787)), // Near main Minuyan

    // NORTHWESTERN AREA (Assumption, Kaypian Area - Upper West)
    Barangay(
        'Assumption', const LatLng(14.8350, 121.0320)), // West of Sapang Palay
    Barangay('Kaypian', const LatLng(14.8300, 121.0280)), // Far northwest
    Barangay('Kaybanban', const LatLng(14.8450, 121.0250)), // Northwest area
    Barangay('Gaya-Gaya', const LatLng(14.8380, 121.0380)), // Near Sapang Palay
    Barangay('Lawang Pari', const LatLng(14.8400, 121.0450)), // Central north
    Barangay('Maharlika',
        const LatLng(14.8420, 121.0520)), // Northeast of Sapang Palay

    // NORTHEASTERN AREA (San Rafael District - Upper East)
    Barangay('San Rafael I', const LatLng(14.8280, 121.0720)), // East area
    Barangay('San Rafael II', const LatLng(14.8310, 121.0750)), // East area
    Barangay('San Rafael III', const LatLng(14.8340, 121.0780)), // East area
    Barangay('San Rafael IV', const LatLng(14.8370, 121.0710)), // East area
    Barangay('San Rafael V', const LatLng(14.8400, 121.0740)), // East area

    // CENTRAL-EAST AREA (Francisco Homes Subdivision)
    Barangay('Francisco Homes - Guijo',
        const LatLng(14.8140, 121.0600)), // PhilAtlas verified
    Barangay('Francisco Homes - Mulawin',
        const LatLng(14.8060, 121.0629)), // PhilAtlas verified
    Barangay('Francisco Homes - Narra',
        const LatLng(14.8099, 121.0585)), // PhilAtlas verified
    Barangay('Francisco Homes - Yakal',
        const LatLng(14.8080, 121.0650)), // Near Narra

    // CENTRAL AREA (Poblacion, City Center - Heart of SJDM)
    Barangay(
        'Poblacion', const LatLng(14.8153, 121.0435)), // PhilAtlas verified
    Barangay(
        'Poblacion I', const LatLng(14.8098, 121.0476)), // PhilAtlas verified
    Barangay(
        'Dulong Bayan', const LatLng(14.8120, 121.0410)), // West of Poblacion
    Barangay('Tungkong Mangga',
        const LatLng(14.8180, 121.0500)), // North of Poblacion

    // CENTRAL-WEST AREA (Gumaoc District)
    Barangay('Gumaoc Central', const LatLng(14.8050, 121.0420)), // Central west
    Barangay('Gumaoc East', const LatLng(14.8070, 121.0450)), // East of central
    Barangay('Gumaoc West', const LatLng(14.8030, 121.0390)), // West area

    // CENTRAL-SOUTH AREA (Fatima District)
    Barangay('Fatima', const LatLng(14.8020, 121.0550)), // Central south
    Barangay('Fatima II', const LatLng(14.7990, 121.0570)), // South of Fatima
    Barangay('Fatima III', const LatLng(14.8040, 121.0590)), // East of Fatima
    Barangay('Fatima IV', const LatLng(14.8060, 121.0620)), // Northeast
    Barangay('Fatima V', const LatLng(14.8010, 121.0610)), // Southeast

    // EASTERN AREA (Santo Niño, Santa Cruz District)
    Barangay('Santo Niño I', const LatLng(14.8150, 121.0680)), // East central
    Barangay('Santo Niño II', const LatLng(14.8170, 121.0710)), // Northeast
    Barangay('Santa Cruz I', const LatLng(14.7980, 121.0700)), // Southeast
    Barangay('Santa Cruz II', const LatLng(14.8000, 121.0730)), // Southeast
    Barangay('Santa Cruz III', const LatLng(14.8030, 121.0760)), // East
    Barangay('Santa Cruz IV', const LatLng(14.8050, 121.0790)), // East
    Barangay('Santa Cruz V', const LatLng(14.8080, 121.0820)), // East

    // SOUTHEASTERN AREA (Paradise, Graceville)
    Barangay('Paradise III', const LatLng(14.7920, 121.0850)), // Far southeast
    Barangay('Graceville', const LatLng(14.7890, 121.0820)), // Southeast
    Barangay('Citrus', const LatLng(14.7950, 121.0780)), // Southeast
    Barangay('Ciudad Real', const LatLng(14.7980, 121.0800)), // Southeast

    // SOUTH-CENTRAL AREA (San Pedro, San Manuel, San Isidro)
    Barangay('San Pedro', const LatLng(14.7870, 121.0520)), // South central
    Barangay('San Manuel', const LatLng(14.7890, 121.0580)), // South central
    Barangay('San Isidro', const LatLng(14.7920, 121.0620)), // South central
    Barangay('San Roque', const LatLng(14.7850, 121.0650)), // South

    // SOUTHWESTERN AREA (San Martin, Santo Cristo District)
    Barangay('San Martin I', const LatLng(14.7830, 121.0480)), // Southwest
    Barangay('San Martin II', const LatLng(14.7800, 121.0510)), // Southwest
    Barangay('San Martin III', const LatLng(14.7860, 121.0540)), // Southwest
    Barangay('San Martin IV', const LatLng(14.7880, 121.0510)), // Southwest
    Barangay('Saint Martin de Porres',
        const LatLng(14.7780, 121.0450)), // Far southwest
    Barangay('Santo Cristo', const LatLng(14.7850, 121.0420)), // Southwest

    // SOUTHERN AREA (Muzon District - Lower SJDM, near Caloocan border)
    // Muzon is actually in the SOUTH, bordering Metro Manila
    Barangay('Muzon Proper', const LatLng(14.7720, 121.0550)), // South
    Barangay('Muzon East', const LatLng(14.7750, 121.0580)), // South
    Barangay('Muzon South',
        const LatLng(14.7680, 121.0530)), // Far south (near Caloocan)
    Barangay('Muzon West', const LatLng(14.7700, 121.0500)), // South

    // CENTRAL-EAST AREA (Bagong Buhay District)
    Barangay('Bagong Buhay I', const LatLng(14.8180, 121.0650)), // Central east
    Barangay(
        'Bagong Buhay II', const LatLng(14.8210, 121.0680)), // Central east
    Barangay(
        'Bagong Buhay III', const LatLng(14.8240, 121.0710)), // Central east
  ];

  @override
  void initState() {
    super.initState();
    filteredBarangays = List.from(barangays);
    _initializeMap();

    // Listen to search text changes
    _barangaySearchController.addListener(_filterBarangays);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _barangaySearchController.dispose();
    super.dispose();
  }

  void _filterBarangays() {
    final query = _barangaySearchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        filteredBarangays = List.from(barangays);
        showDropdown = false;
      } else {
        filteredBarangays = barangays
            .where((barangay) => barangay.name.toLowerCase().contains(query))
            .toList();
        showDropdown = filteredBarangays.isNotEmpty;
      }
    });
  }

  void _selectBarangay(Barangay barangay) {
    setState(() {
      selectedBarangay = barangay;
      _barangaySearchController.text = barangay.name;
      showDropdown = false;
    });

    // Navigate map to selected barangay with smooth animation
    _mapController.move(barangay.coordinates, 17);

    // Optional: Auto-select the barangay location as clinic location
    // Uncomment if you want this behavior:
    // _onMapTap(TapPosition(null, null), barangay.coordinates);
  }

  void _clearBarangaySearch() {
    setState(() {
      _barangaySearchController.clear();
      selectedBarangay = null;
      filteredBarangays = List.from(barangays);
      showDropdown = false;
    });
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
        if (mounted) {
          setState(() {
            userLocation = fetchedLocation;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userLocation = sanJoseDelMonteBounds.center;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userLocation = sanJoseDelMonteBounds.center;
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

  bool _isMobileLayout(double screenWidth) {
    return screenWidth <= 785;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = _isMobileLayout(screenWidth);

    if (isLoading) {
      return Container(
        height: isMobile ? 300 : 400,
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
        height: isMobile ? 300 : 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
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
        // MODIFIED: Wrap search section in its own container with proper z-index handling
        Container(
          // Add this to ensure dropdown appears above other content
          decoration: const BoxDecoration(),
          child: _buildBarangaySearchSection(isMobile),
        ),

        const SizedBox(height: 16),

        // Original Info Container
        _buildInfoContainer(isMobile),

        const SizedBox(height: 16),

        // Map Container
        _buildMapContainer(isMobile),

        const SizedBox(height: 16),

        // Selected Location Display
        _buildLocationDisplay(isMobile),
      ],
    );
  }

  Widget _buildBarangaySearchSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded,
                  color: Colors.green, size: isMobile ? 18 : 20),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Text(
                  'Search for your barangay to quickly locate it on the map',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // CRITICAL FIX: Use CompositedTransformTarget/Follower for proper overlay
          // Or simpler approach: Use LayoutBuilder with Overlay
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  TextField(
                    controller: _barangaySearchController,
                    decoration: InputDecoration(
                      hintText: 'Search barangay (e.g., Poblacion, Muzon)',
                      hintStyle: TextStyle(fontSize: isMobile ? 12 : 13),
                      prefixIcon: const Icon(Icons.location_city, size: 20),
                      suffixIcon: _barangaySearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _clearBarangaySearch,
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.green, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),

                  // Dropdown list positioned below TextField
                  if (showDropdown && filteredBarangays.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: BoxConstraints(
                        maxHeight: isMobile ? 200 : 250,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filteredBarangays.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey[200],
                          ),
                          itemBuilder: (context, index) {
                            final barangay = filteredBarangays[index];
                            final query =
                                _barangaySearchController.text.toLowerCase();
                            final barangayName = barangay.name;
                            final matchIndex =
                                barangayName.toLowerCase().indexOf(query);

                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.location_on_outlined,
                                color: Colors.green,
                                size: isMobile ? 18 : 20,
                              ),
                              title: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  children: matchIndex >= 0 && query.isNotEmpty
                                      ? [
                                          TextSpan(
                                            text: barangayName.substring(
                                                0, matchIndex),
                                          ),
                                          TextSpan(
                                            text: barangayName.substring(
                                              matchIndex,
                                              matchIndex + query.length,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              backgroundColor:
                                                  Color(0xFFE8F5E9),
                                            ),
                                          ),
                                          TextSpan(
                                            text: barangayName.substring(
                                              matchIndex + query.length,
                                            ),
                                          ),
                                        ]
                                      : [TextSpan(text: barangayName)],
                                ),
                              ),
                              subtitle: Text(
                                _getBarangayAreaDescription(barangay.name),
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              onTap: () => _selectBarangay(barangay),
                              hoverColor: Colors.green.withOpacity(0.1),
                            );
                          },
                        ),
                      ),
                    ),

                  // No results message
                  if (showDropdown &&
                      filteredBarangays.isEmpty &&
                      _barangaySearchController.text.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.grey,
                            size: isMobile ? 18 : 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No barangay found matching "${_barangaySearchController.text}"',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          if (selectedBarangay != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green, size: isMobile ? 16 : 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Map navigated to ${selectedBarangay!.name}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.green[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoContainer(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue, size: isMobile ? 18 : 20),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Text(
              'Tap on the map to pin your clinic location. Only locations within San Jose del Monte area are allowed.',
              style:
                  TextStyle(color: Colors.blue, fontSize: isMobile ? 12 : 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer(bool isMobile) {
    return Container(
      height: isMobile ? 300 : 400,
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
                    size: 20,
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
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDisplay(bool isMobile) {
    if (selectedLocation != null) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on,
                    color: Colors.green, size: isMobile ? 18 : 20),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  'Selected Location:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
              style: TextStyle(fontSize: isMobile ? 11 : 12),
            ),
            Text(
              'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
              style: TextStyle(fontSize: isMobile ? 11 : 12),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: isMobile ? 18 : 20),
            SizedBox(width: isMobile ? 6 : 8),
            Expanded(
              child: Text(
                'No location selected yet. Tap on the map to pin your clinic location.',
                style: TextStyle(
                    color: Colors.orange, fontSize: isMobile ? 12 : 13),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getBarangayAreaDescription(String barangayName) {
    // NORTHERN DISTRICT - Minuyan Area (Uppermost SJDM, near Norzagaray)
    if ([
      'Minuyan',
      'Minuyan II',
      'Minuyan III',
      'Minuyan IV',
      'Minuyan V',
      'Minuyan Proper'
    ].contains(barangayName)) {
      return 'Northern District - Upper SJDM (near Norzagaray border)';
    }

    // NORTHERN DISTRICT - Sapang Palay Area (Upper SJDM)
    // CRITICAL: Sapang Palay is in the NORTH, verified at 14.8390 latitude
    if (barangayName == 'Sapang Palay') {
      return 'Northern District - Sapang Palay Resettlement Area';
    }

    // NORTHWESTERN AREA
    if ([
      'Assumption',
      'Kaypian',
      'Kaybanban',
      'Gaya-Gaya',
      'Lawang Pari',
      'Maharlika'
    ].contains(barangayName)) {
      return 'Northwestern District - Upper West SJDM';
    }

    // NORTHEASTERN AREA - San Rafael District
    if (barangayName.startsWith('San Rafael')) {
      return 'Northeastern District - San Rafael Area';
    }

    // CENTRAL-EAST - Francisco Homes
    if (barangayName.startsWith('Francisco Homes')) {
      return 'Central-East District - Francisco Homes Subdivision';
    }

    // CENTRAL DISTRICT - Poblacion/City Center
    if (['Poblacion', 'Poblacion I', 'Dulong Bayan', 'Tungkong Mangga']
        .contains(barangayName)) {
      return 'City Center - Poblacion District (Government Center)';
    }

    // CENTRAL-WEST - Gumaoc District
    if (barangayName.startsWith('Gumaoc')) {
      return 'Central-West District - Gumaoc Area';
    }

    // CENTRAL-SOUTH - Fatima District
    if (barangayName.startsWith('Fatima')) {
      return 'Central-South District - Fatima Area';
    }

    // EASTERN DISTRICT - Santo Niño & Santa Cruz
    if (barangayName.startsWith('Santo Niño') ||
        barangayName.startsWith('Santa Cruz')) {
      return 'Eastern District - Santo Niño/Santa Cruz Area';
    }

    // SOUTHEASTERN - Paradise/Graceville
    if (['Paradise III', 'Graceville', 'Citrus', 'Ciudad Real']
        .contains(barangayName)) {
      return 'Southeastern District - Paradise/Graceville Area';
    }

    // SOUTH-CENTRAL AREA
    if (['San Pedro', 'San Manuel', 'San Isidro', 'San Roque']
        .contains(barangayName)) {
      return 'South-Central District';
    }

    // SOUTHWESTERN - San Martin District
    if (barangayName.startsWith('San Martin') ||
        barangayName.contains('Saint Martin') ||
        barangayName == 'Santo Cristo') {
      return 'Southwestern District - San Martin Area';
    }

    // SOUTHERN DISTRICT - Muzon Area (LOWER SJDM, near Metro Manila)
    // Muzon is actually in the SOUTH, bordering Caloocan City
    if (barangayName.startsWith('Muzon')) {
      return 'Southern District - Muzon Area (borders Metro Manila/Caloocan)';
    }

    // CENTRAL-EAST - Bagong Buhay
    if (barangayName.startsWith('Bagong Buhay')) {
      return 'Central-East District - Bagong Buhay Area';
    }

    // Default
    return 'San Jose del Monte City, Bulacan';
  }
}
