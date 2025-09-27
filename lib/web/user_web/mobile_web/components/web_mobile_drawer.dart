// import 'package:appwrite/models.dart';
// import 'package:capstone_app/data/provider/appwrite_provider.dart';
// import 'package:capstone_app/utils/custom_snack_bar.dart';
// import 'package:capstone_app/utils/logout_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:get_storage/get_storage.dart';

// class WebMobileDrawer extends StatefulWidget {
//   const WebMobileDrawer({super.key});

//   @override
//   State<WebMobileDrawer> createState() => _WebMobileDrawerState();
// }

// class _WebMobileDrawerState extends State<WebMobileDrawer> {
//   final AppWriteProvider appWriteProvider = AppWriteProvider();
//   final GetStorage storage = GetStorage();

//   late User currentUser;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//   }

//   Future<void> _loadUser() async {
//     try {
//       final user = await appWriteProvider.getUser();
//       if (user != null && mounted) {
//         setState(() {
//           currentUser = user;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error loading user: $e");
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   void _showLogoutDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Logout'),
//           content: const Text('Are you sure you want to logout?'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await LogoutHelper.logout();
//               },
//               child: const Text(
//                 'Logout',
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       backgroundColor: const Color.fromARGB(255, 81, 115, 153),
//       child: isLoading
//           ? const Center(
//               child: CircularProgressIndicator(
//                 color: Colors.white,
//               ),
//             )
//           : SingleChildScrollView(
//               child: Column(
//                 children: [
//                   // User Icon Header
//                   const DrawerHeader(
//                     child: Icon(
//                       Icons.person_rounded,
//                       color: Colors.white,
//                       size: 50,
//                     ),
//                   ),

//                   // User Name
//                   ListTile(
//                     title: Text(
//                       currentUser.name,
//                       style: const TextStyle(
//                         fontSize: 25,
//                         color: Color.fromARGB(255, 248, 253, 255),
//                       ),
//                     ),
//                   ),

//                   // User Email
//                   Padding(
//                     padding: const EdgeInsets.only(),
//                     child: ListTile(
//                       title: Text(
//                         currentUser.email,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           color: Color.fromARGB(255, 248, 253, 255),
//                         ),
//                       ),
//                     ),
//                   ),

//                   // Verification Status
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 320),
//                     child: ListTile(
//                       title: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             currentUser.emailVerification
//                                 ? "Verified"
//                                 : "Not Verified",
//                             style: const TextStyle(
//                               fontSize: 18,
//                               color: Color.fromARGB(255, 248, 253, 255),
//                             ),
//                           ),
//                           if (!currentUser.emailVerification)
//                             TextButton(
//                               onPressed: () async {
//                                 try {
//                                   final success = await appWriteProvider.sendVerificationEmail();
//                                   if (mounted) {
//                                     if (success) {
//                                       CustomSnackBar.showSuccessSnackBar(
//                                         context: context,
//                                         title: "Success",
//                                         message: "Verification email sent successfully",
//                                       );
//                                     } else {
//                                       CustomSnackBar.showErrorSnackBar(
//                                         context: context,
//                                         title: "Error",
//                                         message: "Failed to send verification email",
//                                       );
//                                     }
//                                   }
//                                 } catch (e) {
//                                   if (mounted) {
//                                     CustomSnackBar.showErrorSnackBar(
//                                       context: context,
//                                       title: "Error",
//                                       message: "Error: ${e.toString()}",
//                                     );
//                                   }
//                                 }
//                               },
//                               child: const Text(
//                                 "Verify Now",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.blueAccent,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   // Settings
//                   ListTile(
//                     onTap: () {
//                       // TODO: Implement settings navigation
//                       CustomSnackBar.showSuccessSnackBar(
//                         context: context,
//                         title: "Settings",
//                         message: "Settings page coming soon!",
//                       );
//                     },
//                     leading: const Icon(Icons.settings_rounded),
//                     iconColor: const Color.fromARGB(255, 248, 253, 255),
//                     title: const Text(
//                       "Settings",
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Color.fromARGB(255, 248, 253, 255),
//                       ),
//                     ),
//                   ),

//                   // About Us
//                   ListTile(
//                     onTap: () {
//                       // TODO: Implement about us navigation
//                       CustomSnackBar.showSuccessSnackBar(
//                         context: context,
//                         title: "About Us",
//                         message: "About us page coming soon!",
//                       );
//                     },
//                     leading: const Icon(Icons.info_outline_rounded),
//                     iconColor: const Color.fromARGB(255, 248, 253, 255),
//                     title: const Text(
//                       "About us",
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Color.fromARGB(255, 248, 253, 255),
//                       ),
//                     ),
//                   ),

//                   // Sign Out
//                   ListTile(
//                     onTap: _showLogoutDialog,
//                     leading: const Icon(Icons.door_back_door_rounded),
//                     iconColor: const Color.fromARGB(255, 248, 253, 255),
//                     title: const Text(
//                       "Sign out",
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Color.fromARGB(255, 248, 253, 255),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }