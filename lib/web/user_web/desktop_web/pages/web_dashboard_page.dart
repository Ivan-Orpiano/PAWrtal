import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/web/user_web/components/web_dashboard_tiles_updated.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_maps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebDashboardPage extends StatefulWidget {
  const WebDashboardPage({super.key});

  @override
  State<WebDashboardPage> createState() => _WebDashboardPageState();
}

class _WebDashboardPageState extends State<WebDashboardPage> {
  final appwrite = AppWriteProvider();
  List<Clinic> allClinics = [];
  List<Clinic> filteredClinics = [];
  Map<String, ClinicSettings?> clinicSettingsMap = {};
  bool isLoading = true;
  bool _showMap = false;
  String searchQuery = '';
  String selectedFilter = 'All'; // All, Open, Closed, Nearby, Popular, Recommended

  @override
  void initState() {
    super.initState();
    fetchClinics();
  }

  Future<void> fetchClinics() async {
    try {
      final result = await appwrite.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
      );

      if (!mounted) return;

      // Create clinic objects
      final clinics = result.documents.map((doc) {
        final clinic = Clinic.fromMap(doc.data);
        clinic.documentId = doc.$id;
        return clinic;
      }).toList();

      // Load clinic settings for each clinic
      final authRepository = Get.find<AuthRepository>();
      final settingsMap = <String, ClinicSettings?>{};
      
      for (final clinic in clinics) {
        try {
          final settings = await authRepository.getClinicSettingsByClinicId(clinic.documentId ?? '');
          settingsMap[clinic.documentId ?? ''] = settings;
        } catch (e) {
          print("Error loading settings for clinic ${clinic.clinicName}: $e");
          settingsMap[clinic.documentId ?? ''] = null;
        }
      }

      setState(() {
        allClinics = clinics;
        clinicSettingsMap = settingsMap;
        filteredClinics = _applyFilters(clinics);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching clinics: $e");

      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<Clinic> _applyFilters(List<Clinic> clinics) {
    var filtered = clinics;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((clinic) {
        final settings = clinicSettingsMap[clinic.documentId ?? ''];
        final services = settings?.services.join(' ') ?? clinic.services;
        
        return clinic.clinicName.toLowerCase().contains(searchQuery.toLowerCase()) ||
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
      // Add more filters as needed
    }

    // Sort by status (open clinics first)
    filtered.sort((a, b) {
      final aSettings = clinicSettingsMap[a.documentId ?? ''];
      final bSettings = clinicSettingsMap[b.documentId ?? ''];
      
      final aIsOpen = aSettings?.isOpen ?? true;
      final bIsOpen = bSettings?.isOpen ?? true;
      
      if (aIsOpen && !bIsOpen) return -1;
      if (!aIsOpen && bIsOpen) return 1;
      
      // If both have same status, sort by name
      return a.clinicName.compareTo(b.clinicName);
    });

    return filtered;
  }

  void _filterClinics(String query) {
    setState(() {
      searchQuery = query;
      filteredClinics = _applyFilters(allClinics);
    });
  }

  void _setFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      filteredClinics = _applyFilters(allClinics);
    });
  }

  Widget _buildWebTagsStyleFilter() {
    final filters = [
      'All',
      'Open',
      'Available Today', 
      'Closed',
      'Nearby',
      'Popular',
      'Recommended',
    ];

    return Expanded(
      child: SizedBox(
        height: 50,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;
                  final count = _getFilterCount(filter);
                  
                  return GestureDetector(
                    onTap: () => _setFilter(filter),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        children: [
                          Text(
                            count > 0 && filter != 'All' ? '$filter ($count)' : filter,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.black : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 2,
                              width: _getTextWidth(
                                count > 0 && filter != 'All' ? '$filter ($count)' : filter
                              ),
                              color: Colors.black,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text, 
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'All':
        return allClinics.length;
      case 'Open':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return settings?.isOpen ?? true;
        }).length;
      case 'Available Today':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return (settings?.isOpen ?? true) && (settings?.isOpenToday() ?? true);
        }).length;
      case 'Closed':
        return allClinics.where((clinic) {
          final settings = clinicSettingsMap[clinic.documentId ?? ''];
          return !(settings?.isOpen ?? true);
        }).length;
      default:
        return 0;
    }
  }

  Widget _buildMapView() {
    return const SizedBox(
      height: 770,
      child: WebMaps()
    );
  }

  Widget _buildClinicList() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 200),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (filteredClinics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 200),
          child: Column(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                searchQuery.isEmpty 
                  ? "No clinics match the selected filter" 
                  : "No clinics found for '$searchQuery'",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              if (searchQuery.isNotEmpty || selectedFilter != 'All') ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      selectedFilter = 'All';
                      filteredClinics = _applyFilters(allClinics);
                    });
                  },
                  child: const Text("Clear filters"),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return WebDashboardTilesUpdated(clinics: filteredClinics);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.only(left: 65, right: 65, top: 16),
        children: [
          Row(
            children: [
              _buildWebTagsStyleFilter(),
              const SizedBox(width: 12),
              WebSearchBar(
                onSearchChanged: _filterClinics,
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _showMap ? _buildMapView() : _buildClinicList(),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          height: 50,
          width: 120,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.white,
            label: _showMap 
              ? const Text("Show List", style: TextStyle(color: Colors.black)) 
              : const Text("Show Maps", style: TextStyle(color: Colors.black)),
            icon: _showMap 
              ? const Icon(Icons.list_rounded, color: Colors.black) 
              : const Icon(Icons.map_rounded, color: Colors.black),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ),
      ),
    );
  }
}