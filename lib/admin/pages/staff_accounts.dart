import 'package:capstone_app/admin/components/staff_account_tile.dart';
import 'package:capstone_app/admin/pages/staff_account/staff_account_creation_page.dart';
import 'package:flutter/material.dart';

class StaffAccountsPage extends StatefulWidget {
  const StaffAccountsPage({super.key});

  @override
  State<StaffAccountsPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<StaffAccountsPage> {
  void _staffAccountCreationPopUp() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (ctx) => const StaffAccountCreationPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      floatingActionButton: FloatingActionButton(
        onPressed: _staffAccountCreationPopUp,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 75, bottom: 50),
            child: Text(
              "Staff Account List",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 17),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                )),
            child: Column(
              children: [
                const SizedBox(
                  height: 40,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Flexible(
                          child: TextField(
                        cursorColor: Colors.grey,
                        decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: BorderSide.none),
                            hintText: 'Search',
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            prefixIcon: Container(
                              width: 70,
                              height: 70,
                              padding: const EdgeInsets.all(15),
                              child: const Image(
                                image: AssetImage('lib/images/search_icon.jpg'),
                                color: Colors.grey,
                              ),
                            )),
                      )),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 10),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            iconSize: 25,
                            color: Colors.black,
                            icon: const Icon(Icons.sort),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 30, right: 30, bottom: 240),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          StaffAccountTile(),
                          StaffAccountTile(),
                          StaffAccountTile(),
                          StaffAccountTile(),
                          StaffAccountTile(),
                          StaffAccountTile(),
                          StaffAccountTile(),
                          StaffAccountTile(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
