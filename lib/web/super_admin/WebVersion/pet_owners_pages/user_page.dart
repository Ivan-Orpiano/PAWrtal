import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> verifiedUsers = [
    {
      "name": "Kapnot Enoch",
      "email": "enochkap@email.com",
      "date": "2025-05-10",
      "status": "Verified"
    },
    {
      "name": "Cutie Pie Machete",
      "email": "creamypie@email.com",
      "date": "2025-01-22",
      "status": "Verified"
    },
  ];

  final List<Map<String, String>> unverifiedUsers = [
    {
      "name": "MacDike Lawoza",
      "email": "Dmac@email.com",
      "date": "2025-08-01",
      "status": "Unverified"
    },
    {
      "name": "Mike Pup",
      "email": "mikepup@email.com",
      "date": "2025-07-19",
      "status": "Unverified"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        title: const Text(
          "🐾 Pawrtal Users",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(81, 115, 153, 1),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          labelColor: const Color.fromRGBO(81, 115, 153, 1),
          indicatorColor: const Color.fromRGBO(81, 115, 153, 1),
          tabs: const [
            Tab(text: "Verified Users"),
            Tab(text: "Unverified Users"),
          ],
        ),
      ),
      backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(verifiedUsers),
          _buildUserList(unverifiedUsers),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, String>> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showUserCard(users[index]),
          child: Card(
            color: const Color.fromRGBO(248, 253, 255, 1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: const Icon(Icons.pets,
                  color: Color.fromRGBO(81, 115, 153, 1)),
              title: Text(users[index]["name"]!),
              subtitle: Text(users[index]["email"]!),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.grey.shade600),
            ),
          ),
        );
      },
    );
  }

  void _showUserCard(Map<String, String> user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets,
                    size: 50, color: Color.fromRGBO(81, 115, 153, 1)),
                const SizedBox(height: 10),
                Text(user["name"]!,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _infoRow("Email", user["email"]!),
                _infoRow("Date Created", user["date"]!),
                _infoRow("Status", user["status"]!),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
