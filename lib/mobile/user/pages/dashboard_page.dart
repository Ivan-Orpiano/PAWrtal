import 'package:capstone_app/mobile/user/components/dashboard_components/dashboard_tile.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/search_bar.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/sort_button.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/tags.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';


class DashboardPage extends StatefulWidget {
const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final appwrite = AppWriteProvider();
  List<Clinic> clinics = [];
  bool isLoading = true;

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

      setState(() {
        clinics = result.documents
            .map((doc) => Clinic.fromMap(doc.data))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching clinics: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vet Clinics")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clinics.isEmpty
              ? const Center(child: Text("No clinics available."))
              : ListView.builder(
  itemCount: clinics.length,
  itemBuilder: (context, index) {
    return MyDashboardTile(clinic: clinics[index]);
  },
)
    );
  }
}