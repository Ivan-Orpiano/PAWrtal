import 'package:capstone_app/pages/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StaffDetailsPage extends StatefulWidget {
  final dynamic staffData;

  const StaffDetailsPage({super.key, required this.staffData});

  @override
  State<StaffDetailsPage> createState() => _StaffDetailsPageState();
}

class _StaffDetailsPageState extends State<StaffDetailsPage> {
  bool pageAuth = false;
  bool appointmentsAuth = false;
  bool messagesAuth = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromARGB(255, 81, 115, 153),
      child: ListView(
        children: [
          // close button
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_downward_outlined, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // profile picture
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: CachedNetworkImage(
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  imageUrl: widget.staffData.image.isNotEmpty
                      ? '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.staffBucketID}/files/${widget.staffData.image}/view?project=${AppwriteConstants.projectID}'
                      : 'https://via.placeholder.com/150', // Default image
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),

          // STAFF DETAILS CONTAINER
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 230, 230, 230),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // name
                  Center(
                    child: Text(
                      widget.staffData.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // phone number
                  const Center(
                    child: Padding(
                      padding:  EdgeInsets.only(top: 5, bottom: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.phone, color: Colors.lightBlue, size: 20),
                           SizedBox(width: 5),
                          Text(
                            // widget.staffData.phone,
                            "0995 123 4567",
                            style:  TextStyle(fontSize: 13, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(),
                  const SizedBox(height: 20),

                  // email
                  buildInfoRow("Email Address", "email" /*widget.staffData.email*/),
                  
                  // address
                  buildInfoRow("Address", "address"/*widget.staffData.address*/),

                  const SizedBox(height: 20),

                  // authorities
                  const Text(
                    'Authorities',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  buildCheckbox("Veterinary Clinic Page", pageAuth),
                  buildCheckbox("Appointment List", appointmentsAuth),
                  buildCheckbox("Messages", messagesAuth),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // method for staff info display
  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 14)),
        ],
      ),
    );
  }

  // authority checkbox
  Widget buildCheckbox(String title, bool value) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) {
            setState(() {
              value = newValue!;
            });
          },
        ),
        Text(title, style: const TextStyle(color: Colors.black, fontSize: 14)),
      ],
    );
  }
}



// import 'package:flutter/material.dart';

// class StaffDetailsPage extends StatefulWidget {
//   const StaffDetailsPage({super.key});

//   @override
//   State<StaffDetailsPage> createState() => _MyWidgetState();
// }

// class _MyWidgetState extends State<StaffDetailsPage> {
//   bool pageAuth = false;
//   bool appointmentsAuth = false;
//   bool messagesAuth = false;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: const Color.fromARGB(255, 81, 115, 153),
//       child: ListView(
//         //physics: NeverScrollableScrollPhysics(),
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 10, top: 20),
//             child: Row(
//               children: [
//                 IconButton.filledTonal(
//                   icon: const Icon(Icons.arrow_downward_outlined),
//                   color: Colors.white,
//                   style: IconButton.styleFrom(
//                     iconSize: 25,
//                     minimumSize: const Size(5, 5),
//                     backgroundColor: Colors.transparent,
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding:
//                 const EdgeInsets.only(left: 70, right: 70, bottom: 70, top: 15),
//             child: Column(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(70),
//                   child: const Image(
//                     image: AssetImage('lib/images/pfp.jpg'),
//                     height: 100,
//                     width: 100,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             width: MediaQuery.of(context).size.width,
//             height: MediaQuery.of(context).size.height,
//             decoration: const BoxDecoration(
//               color: Color.fromARGB(255, 230, 230, 230),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(25),
//                 topRight: Radius.circular(25),
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.only(left: 40, right: 40),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   const SizedBox(
//                     height: 40,
//                   ),
//                   const Text(
//                     'Mike Dave Pogi Orpiano',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const Padding(
//                     padding: EdgeInsets.only(top: 5, bottom: 10),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.phone,
//                           color: Colors.lightBlue,
//                           size: 20,
//                         ),
//                         Text(
//                           '(+63) 9123456789',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(),
//                   const SizedBox(height: 20),
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.only(left: 20, right: 20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Email Address',
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               IconButton(
//                                 color: Colors.lightBlue,
//                                 iconSize: 20,
//                                 onPressed: null,
//                                 icon: Icon(Icons.edit),
//                               ),
//                             ],
//                           ),
//                           const Text(
//                             'admin@test.com',
//                             textAlign: TextAlign.left,
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           const Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Password',
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               IconButton(
//                                 color: Colors.lightBlue,
//                                 iconSize: 20,
//                                 onPressed: null,
//                                 icon: Icon(Icons.edit),
//                               ),
//                             ],
//                           ),
//                           const Text(
//                             '********',
//                             textAlign: TextAlign.left,
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           const Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Address',
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               IconButton(
//                                 color: Colors.lightBlue,
//                                 iconSize: 20,
//                                 onPressed: null,
//                                 icon: Icon(Icons.edit),
//                               ),
//                             ],
//                           ),
//                           const Text(
//                             'STI College San Jose del Monte',
//                             textAlign: TextAlign.left,
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 50),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Authorities',
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Row(
//                                 children: [
//                                   Checkbox(
//                                     value: pageAuth,
//                                     onChanged: (value) {
//                                       setState(() {
//                                         pageAuth = value!;
//                                       });
//                                     },
//                                   ),
//                                   const Text(
//                                     'Veterinary Clinic Page',
//                                     textAlign: TextAlign.left,
//                                     style: TextStyle(
//                                       color: Colors.black,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               Row(
//                                 children: [
//                                   Checkbox(
//                                     value: appointmentsAuth,
//                                     onChanged: (value) {
//                                       setState(() {
//                                         appointmentsAuth = value!;
//                                       });
//                                     },
//                                   ),
//                                   const Text(
//                                     'Appointment List',
//                                     textAlign: TextAlign.left,
//                                     style: TextStyle(
//                                       color: Colors.black,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               Row(
//                                 children: [
//                                   Checkbox(
//                                     value: messagesAuth,
//                                     onChanged: (value) {
//                                       setState(() {
//                                         messagesAuth = value!;
//                                       });
//                                     },
//                                   ),
//                                   const Text(
//                                     'Messages',
//                                     textAlign: TextAlign.left,
//                                     style: TextStyle(
//                                       color: Colors.black,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
