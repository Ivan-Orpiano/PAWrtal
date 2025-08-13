import 'package:flutter/material.dart';

class CrudeAdminAccount extends StatefulWidget {
  const CrudeAdminAccount({super.key});

  @override
  State<CrudeAdminAccount> createState() => _CrudeAdminAccountState();
}

class _CrudeAdminAccountState extends State<CrudeAdminAccount> {
  List<Map<String, String>> adminAccounts = [
    {
      'name': 'Kapitan Kalb',
      'email': 'kapbalb@gmail.com',
      'role': 'Super Kapitan'
    },
    {'name': 'Long Gorat', 'email': 'longlong@sti.com', 'role': 'Super Tanod'},
  ];

  void _addAdmin() {
    showDialog(
      context: context,
      builder: (context) {
        String name = "", email = "", role = "";
        return AlertDialog(
          title: const Text("Add Admin"),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Name"),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Email"),
                onChanged: (value) => email = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Role"),
                onChanged: (value) => role = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  adminAccounts.add({'name': name, 'email': email, 'role': role});
                });
                Navigator.pop(context);
              },
              child: const Text(
                "Add",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewAdmin(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Admin Details",
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${adminAccounts[index]['name']}",
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
              Text("Email: ${adminAccounts[index]['email']}",
                  style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
              Text("Role: ${adminAccounts[index]['role']}",
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

  void _editAdmin(int index) {
    showDialog(
      context: context,
      builder: (context) {
        String name = adminAccounts[index]['name']!;
        String email = adminAccounts[index]['email']!;
        String role = adminAccounts[index]['role']!;
        return AlertDialog(
          title: const Text(
            "Edit Admin",
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                    labelText: "Name",
                    labelStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                controller: TextEditingController(text: name),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(
                    labelText: "Email",
                    labelStyle:
                        TextStyle(color: Color.fromARGB(255, 248, 253, 255))),
                controller: TextEditingController(text: email),
                onChanged: (value) => email = value,
              ),
              TextField(
                decoration: const InputDecoration(
                    labelText: "Role",
                    labelStyle:
                        TextStyle(color: Color.fromARGB(255, 248, 253, 255))),
                controller: TextEditingController(text: role),
                onChanged: (value) => role = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  adminAccounts[index] = {'name': name, 'email': email, 'role': role};
                });
                Navigator.pop(context);
              },
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAdmin(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Delete",
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          content: const Text(
              "Are you sure you want to delete this admin account?",
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  adminAccounts.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text("Delete",
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
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
          itemCount: adminAccounts.length,
          itemBuilder: (context, index) {
            return Card(
              color: const Color.fromARGB(255, 81, 115, 153),
              child: ListTile(
                title: Text(adminAccounts[index]['name']!,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(adminAccounts[index]['email']!,
                    style: const TextStyle(color: Colors.white70)),
                onTap: () => _viewAdmin(index),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Color.fromARGB(255, 248, 253, 255)),
                      onPressed: () => _editAdmin(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Color.fromARGB(255, 248, 253, 255)),
                      onPressed: () => _deleteAdmin(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAdmin,
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 248, 253, 255),
        ),
      ),
    );
  }
}
