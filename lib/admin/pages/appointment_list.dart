import 'package:capstone_app/admin/pages/appointment_list_pages/accepted_page.dart';
import 'package:capstone_app/admin/pages/appointment_list_pages/pending_page.dart';
import 'package:capstone_app/admin/pages/appointment_list_pages/rejected_page.dart';
import 'package:flutter/material.dart';

class AppointmentListPage extends StatefulWidget {
  const AppointmentListPage({super.key});

  @override
  State<AppointmentListPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AppointmentListPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Container(
        alignment: Alignment.center,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 75, bottom: 50),
              child: Text(
                "Appointment List",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
              decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 230, 230, 230),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25))),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 30, right: 30, top: 20, bottom: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: TabBar(
                                  labelColor: Colors.white,
                                  dividerColor: Colors.transparent,
                                  unselectedLabelColor: Colors.black,
                                  indicatorColor: Colors.transparent,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicator: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 81, 115, 153),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  controller: tabController,
                                  tabs: const [
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.check_rounded),
                                          Text('Accepted'),
                                        ],
                                      ),
                                    ),
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.pending_rounded),
                                          Text('Pending'),
                                        ],
                                      ),
                                    ),
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.cancel_rounded),
                                          Text('Rejected'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 30, right: 30, bottom: 240),
                            child: TabBarView(
                              controller: tabController,
                              children: const [
                                AcceptedPage(),
                                PendingPage(),
                                RejectedPage(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
