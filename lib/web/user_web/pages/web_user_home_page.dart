import 'package:capstone_app/web/user_web/components/appbar_components/notification_icon_web.dart';
import 'package:capstone_app/web/user_web/components/appbar_components/profile_icon_web.dart';
import 'package:capstone_app/web/user_web/pages/appointments_web_page.dart';
import 'package:capstone_app/web/user_web/pages/dashboard_web_page.dart';
import 'package:capstone_app/web/user_web/pages/messages_web_page.dart';
import 'package:capstone_app/web/user_web/pages/pets_web_page.dart';
import 'package:flutter/material.dart';

class WebUserHomePage extends StatefulWidget {
  const WebUserHomePage({super.key});

  @override
  State<WebUserHomePage> createState() => _WebUserHomePageState();
}

class _WebUserHomePageState extends State<WebUserHomePage> {

  int _selectedIndex = 0;
  bool _isExpanded = false;

    final List<Widget> _pages = const [
    WebDashboardPage(),
    AppointmentsWebPage(),
    MessagesWebPage(),
    PetsWebPage(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.grey.shade400,
        backgroundColor: const Color.fromARGB(192, 255, 255, 255),
        elevation: 1,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            const SizedBox(width: 25),
            InkWell(
              onTap: () {},
              child: Image.asset(
                'lib/images/PAWrtal_logo.png',
                height: 50,
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: "Search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: const [
          NotificationIconWeb(),
          ProfileIconWeb(),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color.fromARGB(192, 255, 255, 255),
            elevation: 1,
            useIndicator: true,
            extended: _isExpanded,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: _isExpanded ? NavigationRailLabelType.none : NavigationRailLabelType.none,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(
                  Icons.home_rounded
                ),
                selectedIcon: const Icon(
                  Icons.home_rounded,
                  color: Colors.blue
                ),
                label: DefaultTextStyle(
                  style: TextStyle(
                    color: _selectedIndex == 0 ? Colors.blue : Colors.black,
                    fontWeight: _selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                  child: const Text("Dashboard"),
                ),
              ),

              NavigationRailDestination(
                icon: const Icon(
                  Icons.calendar_today_rounded
                ),
                selectedIcon: const Icon(
                  Icons.calendar_today, 
                  color: Colors.blue),
                label: DefaultTextStyle(
                  style: TextStyle(
                    color: _selectedIndex == 1 ? Colors.blue : Colors.black,
                    fontWeight: _selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                  child: const Text("Appointments"),
                ),
              ),

              NavigationRailDestination(
                icon: const Icon(
                  Icons.message_rounded
                ),
                selectedIcon: const Icon(
                  Icons.message, 
                  color: Colors.blue),
                label: DefaultTextStyle(
                  style: TextStyle(
                    color: _selectedIndex == 2 ? Colors.blue : Colors.black,
                    fontWeight: _selectedIndex == 2 ? FontWeight.bold : FontWeight.normal,
                  ),
                  child: const Text("Messages"),
                ),
              ),

              NavigationRailDestination(
                icon: const Icon(
                  Icons.pets_rounded
                ),
                selectedIcon: const Icon(
                  Icons.pets, 
                  color: Colors.blue),
                label: DefaultTextStyle(
                  style: TextStyle(
                    color: _selectedIndex == 3 ? Colors.blue : Colors.black,
                    fontWeight: _selectedIndex == 3 ? FontWeight.bold : FontWeight.normal,
                  ),
                  child: const Text("Pets"),
                ),
              ),
            ],
          ),
          const VerticalDivider(
            thickness: 1, width: 1
          ),
          Expanded(
            child: _pages[_selectedIndex]
          ),
        ],
      )
    );
  }
}
//     return Scaffold(
//       appBar: AppBar(
//         shadowColor: Colors.grey.shade400,
//         backgroundColor: const Color.fromARGB(192, 255, 255, 255),
//         elevation: 1,
//         title: Row(
//           children: [
//             InkWell(
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 0;
//                 });
//               },
//               child: Image.asset(
//                 'lib/images/logo.png',
//                 height: 50,
//               ),
//             ),
//             SizedBox(
//               width: 300,
//               child: TextField(
//                 decoration: InputDecoration(
//                   prefixIcon: const Icon(Icons.search_rounded),
//                   hintText: "Search",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                 ),
//               ),
//             ),
//             const Spacer(),

//             Expanded(
//               child: Center(
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.home_rounded),
//                       onPressed: () {
//                         setState(() {
//                           _selectedIndex = 0;
//                         });
//                       },
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.calendar_month_rounded),
//                       onPressed: () {
//                         setState(() {
//                           _selectedIndex = 1;
//                         });
//                       },
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.message_rounded),
//                       onPressed: () {
//                         setState(() {
//                           _selectedIndex = 2;
//                         });
//                       },
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.pets_rounded),
//                       onPressed: () {
//                         setState(() {
//                           _selectedIndex = 3;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const Spacer()
//           ],
//         ),
//         actions: const [
//           NotificationIconWeb(),
//           ProfileIconWeb()
//         ],
//       ),
//       body: _pages[_selectedIndex],
//     );
//   }
// }