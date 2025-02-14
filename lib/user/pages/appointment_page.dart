import 'package:capstone_app/user/components/appointment_tabs/appointments_1st_tab.dart';
import 'package:capstone_app/user/components/appointment_tabs/appointments_2nd_tab.dart';
import 'package:capstone_app/user/components/appointment_tabs/appointments_3rd_tab.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> with SingleTickerProviderStateMixin {

  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          SizedBox(
            height: 75,
            child: Center(
              child: Text(
                "Appointments",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 20
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(top:20, left: 10, right: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      indicatorColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: const Color.fromARGB(255, 81, 115, 153),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Icon(
                                  Icons.pending_rounded,
                                ),
                              ),
                              Text(
                                "Pending"
                              )
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Icon(
                                  Icons.check_rounded,
                                ),
                              ),
                              Text(
                                "Accepted"
                              )
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Icon(
                                  Icons.cancel_rounded,
                                ),
                              ),
                              Text(
                                "Declined"
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        APFirstTab(),
                        APSecondTab(),
                        APThirdTab(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),    
    );
  }
}