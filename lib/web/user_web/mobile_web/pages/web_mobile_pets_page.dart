// import 'package:capstone_app/data/models/pet_model.dart';
// import 'package:capstone_app/mobile/user/components/pets_components/pets_controller.dart';
// import 'package:capstone_app/web/user_web/mobile_web/components/web_mobile_pet_creation_sheet.dart';
// import 'package:capstone_app/web/user_web/mobile_web/components/web_mobile_pet_details_page.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';

// class WebMobilePetsPage extends StatefulWidget {
//   const WebMobilePetsPage({super.key});

//   @override
//   State<WebMobilePetsPage> createState() => _WebMobilePetsPageState();
// }

// class _WebMobilePetsPageState extends State<WebMobilePetsPage> {
//   late final PetsController petsController;

//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!Get.isRegistered<PetsController>()) {
//         petsController = Get.put(PetsController(
//           authRepository: Get.find(),
//           session: Get.find(),
//         ));
//       } else {
//         petsController = Get.find();
//       }

//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     if (Get.isRegistered<PetsController>()) {
//       Get.delete<PetsController>();
//     }
//     super.dispose();
//   }

//   void _showPetCreationSheet() {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       context: context,
//       builder: (context) => const WebMobilePetCreationSheet(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!Get.isRegistered<PetsController>()) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.blue.shade50,
//       body: Column(
//         children: [
//           // Header Section
//           SizedBox(
//             height: 75,
//             child: Center(
//               child: Text(
//                 "Pets",
//                 style: GoogleFonts.inter(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                 ),
//               ),
//             ),
//           ),
          
//           // Main Content Area
//           Expanded(
//             child: Container(
//               width: double.maxFinite,
//               height: double.maxFinite,
//               decoration: const BoxDecoration(
//                 color: Color.fromARGB(255, 230, 230, 230),
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   // Section Header with Filter
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Your pets",
//                           style: GoogleFonts.inter(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 22,
//                           ),
//                         ),
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: const Color.fromARGB(255, 81, 115, 153),
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.grey.shade400,
//                                 spreadRadius: 2,
//                                 blurRadius: 3,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: IconButton(
//                             icon: const Icon(
//                               Icons.filter_list_rounded,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                             onPressed: () {
//                               // TODO: Implement filter functionality
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Pets Grid
//                   Expanded(
//                     child: Obx(() {
//                       if (petsController.isLoading.value) {
//                         return const Center(
//                           child: CircularProgressIndicator(),
//                         );
//                       }

//                       if (petsController.pets.isEmpty) {
//                         return Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.pets_outlined,
//                                 size: 80,
//                                 color: Colors.grey.shade400,
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 "No pets yet",
//                                 style: GoogleFonts.inter(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 "Add your first pet to get started!",
//                                 style: GoogleFonts.inter(
//                                   fontSize: 14,
//                                   color: Colors.grey.shade500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }

//                       return Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 10,
//                         ),
//                         child: GridView.builder(
//                           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 2,
//                             crossAxisSpacing: 20,
//                             mainAxisSpacing: 30,
//                             childAspectRatio: 0.8,
//                           ),
//                           itemCount: petsController.pets.length,
//                           itemBuilder: (context, index) {
//                             final pet = petsController.pets[index];
//                             return _WebMobilePetTile(
//                               pet: pet,
//                               onTap: () => _navigateToPetDetails(pet),
//                             );
//                           },
//                         ),
//                       );
//                     }),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
      
//       // Floating Action Button
//       floatingActionButton: FloatingActionButton(
//         heroTag: "mobile_web_pets_fab",
//         onPressed: _showPetCreationSheet,
//         elevation: 6,
//         backgroundColor: const Color.fromARGB(255, 81, 115, 153),
//         foregroundColor: Colors.white,
//         child: const Icon(Icons.add_rounded),
//       ),
//     );
//   }

//   void _navigateToPetDetails(Pet pet) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => WebMobilePetDetailsPage(pet: pet),
//       ),
//     );

//     if (result == true) {
//       petsController.fetchPets();
//     }
//   }
// }

// class _WebMobilePetTile extends StatelessWidget {
//   final Pet pet;
//   final VoidCallback onTap;

//   const _WebMobilePetTile({
//     required this.pet,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(30),
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Container(
//           decoration: BoxDecoration(
//             color: const Color.fromARGB(255, 81, 115, 153),
//             borderRadius: BorderRadius.circular(30),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Pet Image
//               Expanded(
//                 flex: 3,
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(30),
//                     topRight: Radius.circular(30),
//                   ),
//                   child: Image.network(
//                     pet.image ?? 'https://via.placeholder.com/150',
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => Container(
//                       width: double.infinity,
//                       color: const Color.fromARGB(255, 60, 85, 120),
//                       child: const Icon(
//                         Icons.pets,
//                         size: 50,
//                         color: Colors.white70,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
              
//               // Pet Info
//               Expanded(
//                 flex: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         pet.name,
//                         style: GoogleFonts.inter(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                           color: Colors.white,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         pet.breed,
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: Colors.white70,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           pet.type,
//                           style: GoogleFonts.inter(
//                             fontSize: 12,
//                             color: Colors.white,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }