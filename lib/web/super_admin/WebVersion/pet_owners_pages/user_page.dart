import 'package:flutter/material.dart';

class User {
  final String name;
  final int age;
  final String email;
  final String address;
  final bool isVerified;

  User({
    required this.name,
    required this.age,
    required this.email,
    required this.address,
    required this.isVerified,
  });
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<User> verifiedUsers = [
    User(
        name: "Jane Doe",
        age: 29,
        email: "jane@example.com",
        address: "123 Dog St",
        isVerified: true),
  ];

  List<User> unverifiedUsers = [
    User(
        name: "John Smith",
        age: 25,
        email: "john@example.com",
        address: "456 Cat Rd",
        isVerified: false),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  void deleteUser(User user) {
    setState(() {
      if (user.isVerified) {
        verifiedUsers.remove(user);
      } else {
        unverifiedUsers.remove(user);
      }
    });
  }

  void showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("User Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${user.name}"),
            Text("Age: ${user.age}"),
            Text("Email: ${user.email}"),
            Text("Address: ${user.address}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          TextButton(
            onPressed: () {
              deleteUser(user);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget buildUserList(List<User> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          title: Text(user.name),
          subtitle: Text(user.email),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => showUserDetails(user),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color.fromRGBO(248, 253, 255, 0.8), // AppBar color
        title: const Text("Pet Owners Management"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor:
              const Color.fromRGBO(81, 115, 153, 0.8), // Tab indicator color
          labelColor: Colors.white, // Selected tab text color
          unselectedLabelColor: Colors.white70, // Unselected tab text color
          tabs: const [
            Tab(
              child: Text(
                "Verified Pet Owners",
                style: TextStyle(color: Color.fromRGBO(81, 115, 153, 1)),
              ),
            ),
            Tab(
              child: Text(
                "Unverified Pet Owners",
                style: TextStyle(color: Color.fromRGBO(200, 80, 80, 1)),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color.fromRGBO(248, 253, 255, 1), // Background color
        child: TabBarView(
          controller: _tabController,
          children: [
            buildUserList(verifiedUsers),
            buildUserList(unverifiedUsers),
          ],
        ),
      ),
    );
  }
}
