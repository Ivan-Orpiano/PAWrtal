import 'package:capstone_app/web/user_web/components/web_dashboard_tiles_updated.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_dashboard_grid_tile.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_filter.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_search_bar.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_tags.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_maps.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';

class WebTabletDashboardPageUpdated extends StatefulWidget {
  const WebTabletDashboardPageUpdated({super.key});

  @override
  State<WebTabletDashboardPageUpdated> createState() =>
      _WebTabletDashboardPageUpdatedState();
}

class _WebTabletDashboardPageUpdatedState
    extends State<WebTabletDashboardPageUpdated> {
  final appwrite = AppWriteProvider();
  List<Clinic> clinics = [];
  List<Clinic> filteredClinics = [];
  bool isLoading = true;
  bool _showMap = false;
  String searchQuery = '';

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

      setState(() {
        clinics = result.documents.map((doc) {
          final clinic = Clinic.fromMap(doc.data);
          clinic.documentId = doc.$id;
          return clinic;
        }).toList();
        filteredClinics = clinics;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching clinics: $e");

      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _filterClinics(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredClinics = clinics;
      } else {
        filteredClinics = clinics.where((clinic) {
          return clinic.clinicName
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              clinic.address.toLowerCase().contains(query.toLowerCase()) ||
              clinic.services.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Widget _buildMapView() {
    return const SizedBox(height: 770, child: WebMaps());
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
                    ? "No clinics available"
                    : "No clinics found for '$searchQuery'",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _filterClinics(''),
                  child: const Text("Clear search"),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return WebDashboardGridTile(clinics: filteredClinics);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.only(left: 65, right: 65, top: 16),
        children: [
          Row(
            children: [
              const WebTags(),
              const SizedBox(width: 12),
              const WebFilter(),
              WebSearchBar(
                onSearchChanged: _filterClinics,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 16),
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
                : const Text("Show Maps",
                    style: TextStyle(color: Colors.black)),
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
