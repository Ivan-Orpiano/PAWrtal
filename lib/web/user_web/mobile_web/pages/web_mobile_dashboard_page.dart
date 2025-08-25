import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_clinic_page_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebMobileDashboardPage extends StatefulWidget {
  const WebMobileDashboardPage({super.key});

  @override
  State<WebMobileDashboardPage> createState() => _WebMobileDashboardPageState();
}

class _WebMobileDashboardPageState extends State<WebMobileDashboardPage> {
  final appwrite = AppWriteProvider();
  List<Clinic> clinics = [];
  bool isLoading = true;
  int _selectedTagIndex = 0;

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
        clinics = result.documents.map((doc) => Clinic.fromMap(doc.data)).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching clinics: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clinics.isEmpty
              ? const Center(child: Text("No clinics available."))
              : ListView(
                  children: [
                    // Search Bar and Filter
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 5, right: 16),
                      child: Row(
                        children: [
                          // Search Bar
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade400,
                                    spreadRadius: 2,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Icon(Icons.search),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: "Search",
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sort Button
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade400,
                                  spreadRadius: 2,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.filter_list_rounded),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tags
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTag("All", 0),
                            _buildTag("Nearby", 1),
                            _buildTag("Popular", 2),
                            _buildTag("Recommended", 3),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Clinic Tiles
                    ...clinics.map((clinic) => _buildClinicTile(clinic)),
                  ],
                ),
    );
  }

  Widget _buildTag(String label, int index) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 10, right: 5, bottom: 10),
      child: ChoiceChip(
        checkmarkColor: Colors.black,
        elevation: 5,
        selectedColor: const Color.fromARGB(255, 81, 115, 153),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: _selectedTagIndex == index ? Colors.white : Colors.black,
          ),
        ),
        selected: _selectedTagIndex == index,
        onSelected: (newState) {
          setState(() {
            _selectedTagIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildClinicTile(Clinic clinic) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebClinicPageHandlerUpdated(clinic: clinic),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 350,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinic Image
            Container(
              height: 220,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: clinic.image.isNotEmpty
                    ? Image.network(
                        clinic.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'lib/images/test_image.jpg',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        },
                      )
                    : Image.asset(
                        'lib/images/test_image.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
              ),
            ),

            // Clinic Name
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, bottom: 5),
              child: Text(
                clinic.clinicName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: const Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ),

            // Clinic Address
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 5),
              child: Text(
                clinic.address,
                style: GoogleFonts.dmSans(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),

            // Clinic Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.house_outlined),
                      const SizedBox(width: 3),
                      Text("4 Rooms", style: GoogleFonts.dmSans(fontSize: 16)),
                      const SizedBox(width: 20),
                      const Icon(Icons.medical_services),
                      const SizedBox(width: 3),
                      Text("1 Veterinarian", style: GoogleFonts.dmSans(fontSize: 16)),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow),
                      SizedBox(width: 3),
                      Text("5.0"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}