import 'package:flutter/material.dart';

class CrudeStaffAccount extends StatefulWidget {
  const CrudeStaffAccount({super.key});

  @override
  State<CrudeStaffAccount> createState() => _CrudeStaffAccountState();
}

class _CrudeStaffAccountState extends State<CrudeStaffAccount> {
  List<Map<String, String>> staffAccount = [
    {
      'name': 'Kong Kal',
      'email': 'kapbalb@gmail.com',
      'role': 'Assistant Secretart'
    },
    {'name': 'Kal Bokla', 'email': 'oblak@sti.com', 'role': 'Assistant Staff'},
  ];

  void _viewStaff(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Staff Details",
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${staffAccount[index]['name']}",
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
              Text("Email: ${staffAccount[index]['email']}",
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
              Text("Role: ${staffAccount[index]['role']}",
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close",
                  style: TextStyle(color: Color.fromARGB(255, 248, 253, 255))),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1,
        flexibleSpace: Container(
          margin: const EdgeInsets.only(top: 15.0),
          child: Center(
            child: Image.asset(
              "lib/images/PAWrtal_logo.png",
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView.builder(
          itemCount: staffAccount.length,
          itemBuilder: (context, index) {
            return Card(
              color: const Color.fromARGB(255, 81, 115, 153),
              child: ListTile(
                title: Text(staffAccount[index]['name']!,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(staffAccount[index]['email']!,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => _viewStaff(index),
              ),
            );
          },
        ),
      ),
    );
  }
}