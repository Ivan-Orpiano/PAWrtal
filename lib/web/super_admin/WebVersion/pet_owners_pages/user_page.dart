import 'package:flutter/material.dart';
import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';

// Data Models
class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final DateTime accountCreated;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.accountCreated,
    required this.isVerified,
  });
}

// Main Super Admin Dashboard
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - Replace with your backend API calls
  List<User> _users = [
    User(
      id: '1',
      name: 'John Doe',
      phoneNumber: '+1234567890',
      email: 'john.doe@email.com',
      accountCreated: DateTime.now().subtract(Duration(days: 30)),
      isVerified: true,
    ),
    User(
      id: '2',
      name: 'Jane Smith',
      phoneNumber: '+0987654321',
      email: 'jane.smith@email.com',
      accountCreated: DateTime.now().subtract(Duration(days: 15)),
      isVerified: true,
    ),
    User(
      id: '3',
      name: 'Mike Johnson',
      phoneNumber: '+1122334455',
      email: 'mike.johnson@email.com',
      accountCreated: DateTime.now().subtract(Duration(days: 5)),
      isVerified: false,
    ),
    User(
      id: '4',
      name: 'Sarah Wilson',
      phoneNumber: '+5566778899',
      email: 'sarah.wilson@email.com',
      accountCreated: DateTime.now().subtract(Duration(days: 2)),
      isVerified: false,
    ),
  ];

  // Colors
  final Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  final Color accentColor = Color.fromARGB(255, 81, 115, 153);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<User> get verifiedUsers =>
      _users.where((user) => user.isVerified).toList();

  List<User> get unverifiedUsers =>
      _users.where((user) => !user.isVerified).toList();

  // TODO: Replace with actual backend API call
  Future<void> deleteUser(String userId) async {
    // Simulate API call delay
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _users.removeWhere((user) => user.id == userId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User deleted successfully'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UserDetailsDialog(
          user: user,
          onDelete: () => _confirmDelete(user),
          accentColor: accentColor,
        );
      },
    );
  }

  void _confirmDelete(User user) {
    Navigator.of(context).pop(); // Close user details dialog

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          title: Text(
            'Confirm Delete',
            style: TextStyle(color: Color.fromARGB(255, 81, 115, 153)),
          ),
          content: Text('Are you sure you want to delete ${user.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: Color.fromARGB(255, 81, 115, 153))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteUser(user.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                foregroundColor: const Color.fromARGB(255, 248, 253, 255),
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         surfaceTintColor: Colors.transparent,
        backgroundColor: Color.fromARGB(255, 248, 253, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 81, 115, 153)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SuperAdminDesktopHomePage()),
            );
          },
          tooltip: 'Back',
        ),
        title: Text(
          'Pet Owners',
          style: TextStyle(
            color: const Color.fromARGB(255, 81, 115, 153),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromARGB(255, 81, 115, 153),
          labelColor: const Color.fromARGB(255, 81, 115, 153),
          unselectedLabelColor: const Color.fromARGB(255, 189, 184, 176),
          tabs: [
            Tab(
              icon: Icon(
                Icons.verified_user,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
              text: 'Verified Users (${verifiedUsers.length})',
            ),
            Tab(
              icon: Icon(
                Icons.pending,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
              text: 'Unverified Users (${unverifiedUsers.length})',
            ),
          ],
        ),
      ),
      backgroundColor: backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          UserListView(
            users: verifiedUsers,
            onUserTap: _showUserDetails,
            accentColor: accentColor,
            isVerified: true,
          ),
          UserListView(
            users: unverifiedUsers,
            onUserTap: _showUserDetails,
            accentColor: accentColor,
            isVerified: false,
          ),
        ],
      ),
    );
  }
}

// User List View Component
class UserListView extends StatelessWidget {
  final List<User> users;
  final Function(User) onUserTap;
  final Color accentColor;
  final bool isVerified;

  const UserListView({
    Key? key,
    required this.users,
    required this.onUserTap,
    required this.accentColor,
    required this.isVerified,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.pending,
              size: 64,
              color: accentColor.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              isVerified
                  ? 'No verified users found'
                  : 'No unverified users found',
              style: TextStyle(
                fontSize: 18,
                color: accentColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserCard(
          user: user,
          onTap: () => onUserTap(user),
          accentColor: accentColor,
        );
      },
    );
  }
}

// User Card Component
class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final Color accentColor;

  const UserCard({
    Key? key,
    required this.user,
    required this.onTap,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(253, 248, 253, 255),
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: EdgeInsets.only(bottom: 12),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accentColor,
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Created: ${_formatDate(user.accountCreated)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                user.isVerified ? Icons.verified : Icons.pending,
                color: user.isVerified ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: accentColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// User Details Dialog
class UserDetailsDialog extends StatelessWidget {
  final User user;
  final VoidCallback onDelete;
  final Color accentColor;

  const UserDetailsDialog({
    Key? key,
    required this.user,
    required this.onDelete,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        // width: MediaQuery.of(context).size.width * 0.6,
        // height: MediaQuery.of(context).size.height * 0.4,
        color: const Color.fromARGB(255, 248, 253, 255),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accentColor,
                  radius: 30,
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            user.isVerified ? Icons.verified : Icons.pending,
                            color:
                                user.isVerified ? Colors.green : Colors.orange,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            user.isVerified ? 'Verified' : 'Unverified',
                            style: TextStyle(
                              color: user.isVerified
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Color.fromRGBO(248, 253, 255, 1),
                  ),
                  color: const Color.fromARGB(255, 253, 253, 253),
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildDetailRow(Icons.person, 'Name', user.name),
            _buildDetailRow(Icons.phone, 'Phone Number', user.phoneNumber),
            _buildDetailRow(Icons.email, 'Email', user.email),
            _buildDetailRow(Icons.calendar_today, 'Account Created',
                _formatDate(user.accountCreated)),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                        color: const Color.fromARGB(255, 81, 115, 153)),
                    selectionColor: Color.fromRGBO(248, 253, 255, 1),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete,
                    size: 18,
                    color: const Color.fromARGB(255, 248, 253, 255),
                  ),
                  label: Text('Delete User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


/* 
=== BACKEND INTEGRATION GUIDE ===

To integrate with your backend, replace the following sections:

1. User Model:
   - Add additional fields as needed
   - Implement fromJson() and toJson() methods for API serialization

2. Data Fetching:
   - Replace the sample _users list with API calls
   - Implement fetchVerifiedUsers() and fetchUnverifiedUsers() methods
   - Add proper error handling and loading states

3. Delete User Function:
   - Replace the deleteUser() method with actual API call
   - Handle network errors and show appropriate messages

4. Real-time Updates:
   - Consider implementing WebSocket or polling for real-time user updates
   - Add refresh functionality

Example API integration:

```dart
// Add these dependencies to pubspec.yaml:
// http: ^0.13.5
// json_annotation: ^4.8.0

import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://your-api-endpoint.com';
  
  static Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    throw Exception('Failed to load users');
  }
  
  static Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}
```

Additional Features to Consider:
- Search functionality
- Filtering by date range
- Bulk operations
- Export user data
- User role management
- Activity logs
*/