import 'package:capstone_app/admin/pages/staff_details_page.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/utils/appwrite_constant.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

class StaffAccountTile extends StatelessWidget {
  final dynamic staff; // Replace with your actual Staff model

  const StaffAccountTile({super.key, required this.staff});

  void _staffDetailsPopUp(dynamic staffData) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (ctx) => StaffDetailsPage(staffData: staffData),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _staffDetailsPopUp(staff),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // Staff Image
              Padding(
                  padding: const EdgeInsets.only(left: 16),
                child: SizedBox(             
                  width: 75,
                  height: 75,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: staff.image.isNotEmpty
                            ? '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.staffBucketID}/files/${staff.image}/view?project=${AppwriteConstants.projectID}'
                            : 'https://via.placeholder.com/150', // Default image if null
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
              ),

              // Staff Name and Department
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          staff.department,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Authorities: ",
                          style: TextStyle(
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'package:capstone_app/admin/pages/staff_details_page.dart';
// import 'package:flutter/material.dart';
// import 'package:capstone_app/pages/utils/appwrite_constant.dart';
// import 'package:capstone_app/pages/admin_home/admin_home_controller.dart';
// import 'package:get/get.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class StaffAccountTile extends StatefulWidget {
//   const StaffAccountTile({super.key});

//   @override
//   State<StaffAccountTile> createState() => _StaffAccountTileState();
// }

// class _StaffAccountTileState extends State<StaffAccountTile> {

//   final AdminHomeController controller = Get.find();

//   void _staffDetailsPopUp() {
//     showModalBottomSheet(
//         context: Get.context!,
//         builder: (ctx) => const StaffDetailsPage(),
//         isScrollControlled: true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return controller.obx(
//         (state) => ListView.separated (
//           padding: const EdgeInsets.only(top:8, bottom: 8),
//           separatorBuilder: (BuildContext context, int index) {
//             return const Divider(
//               height: 10,
//               color: Colors.grey,
//             );
//           },
//         physics: const BouncingScrollPhysics(),
//         itemBuilder: (BuildContext context, int index) {
//           return GestureDetector(
//             onTap: _staffDetailsPopUp,
//             child: Padding(
//           padding: const EdgeInsets.only(top: 10, bottom: 5),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: Row(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(10.0),
//                   child: CachedNetworkImage(
//                     fit: BoxFit.cover,
//                     imageUrl: state[index].image.isNotEmpty
//                         ? '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.staffBucketID}/files/${state[index].image}/view?project=${AppwriteConstants.projectID}'
//                         : 'https://via.placeholder.com/150', // Default image if null
//                     placeholder: (context, url) => const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                     errorWidget: (context, url, error) =>
//                     const Icon(Icons.error, color: Colors.red),
//                   ),
//                 ),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.only(left: 15),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           state[index].name,
//                           style: const TextStyle(
//                               fontWeight: FontWeight.bold, fontSize: 16),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.only(right: 20),
//                           child: Text(
//                             state[index].department,
//                             style: TextStyle(
//                               color: Colors.grey.shade400,
//                               fontSize: 13,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.only(top: 5),
//                           child: Text(
//                             "Authorities: ",
//                             style: TextStyle(
//                               color: Colors.grey.shade800,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     },
//     itemCount: state!.length),

//     onLoading: const Center(child: CircularProgressIndicator()),
//     onError: (error) => Center(
//       child: Text(error ?? "An error occurred"),
//     ),
//     onEmpty: const Center(
//       child: Text('No staff found'),
//     ),
//     );
//   }
// }

  // @override
  // Widget build(BuildContext context) {
  //   return GestureDetector(
  //     onTap: _staffDetailsPopUp,
  //     child: controller.obx(
  //       (state) => ListView.separated(
  //         padding: const EdgeInsets.only(top: 8, bottom: 8),
  //         separatorBuilder: (BuildContext context, int index) {
  //           return const Divider(
  //             height: 10,
  //             color: Colors.grey,
  //           );
  //         },
  //         physics: const BouncingScrollPhysics(),
  //         itemBuilder:(BuildContext context, int index) {
  //           return ListTile(
  //             leading: SizedBox(
  //               width: 100,
  //               height: 100,
  //               child: CachedNetworkImage(
  //                 fit: BoxFit.cover,
  //                 imageUrl:
  //                     '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.staffBucketID}/files/${state[index].image}/view?project=${AppwriteConstants.projectID}',
  //                 placeholder: (context, url) => const Center(
  //                   child: CircularProgressIndicator(),
  //                 ),
  //                 errorWidget: (context, url, error) =>
  //                     const Icon(Icons.error, color: Colors.red),
  //               ),
  //             ),
  //             title: Text(
  //               state[index].name,
  //               style: const TextStyle(fontSize: 16),
  //             ),
  //             subtitle: Text(
  //               state[index].department,
  //               style: const TextStyle(fontSize: 14),
  //             ),
  //             trailing: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 IconButton(
  //                   onPressed: () {},
  //                 icon: const Icon(Icons.edit, color: Colors.blue),
  //                 ),
  //                 IconButton(
  //                   onPressed: () {},
  //                   icon: const Icon(Icons.delete, color: Colors.red),
  //                 )
  //               ]),
  //           );
  //         },
  //         itemCount: state!.length),
  //       onLoading: const Center(child: CircularProgressIndicator()),
  //       onError: (error) => Center(
  //         child: Text(error!),
  //       ),
  //       onEmpty: const Center(
  //         child: Text('No staff found'),
  //       ),
  //     ),
  //   );

