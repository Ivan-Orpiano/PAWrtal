import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class AppwriteService {
  static const String endpoint = '';
  static const String projectId = '';
  static const String databaseId = '';
  static const String reportsCollectionId = '';
  static const String repliesCollectionId = '';

  late Client client;
  late Databases databases;
  late Account account;

  AppwriteService() {
    client = Client().setEndpoint(endpoint).setProject(projectId);

    databases = Databases(client);
    account = Account(client);
  }
}

class UserReport {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime createdAt;
  final List<String>? attachments;

  UserReport({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.attachments,
  });

  factory UserReport.fromDocument(Document doc) {
    return UserReport(
      id: doc.$id,
      userId: doc.data['userId'] ?? '',
      userName: doc.data['userName'] ?? '',
      userEmail: doc.data['userEmail'] ?? '',
      title: doc.data['title'] ?? '',
      description: doc.data['description'] ?? '',
      category: doc.data['category'] ?? 'General',
      priority: doc.data['priority'] ?? 'Medium',
      status: doc.data['status'] ?? 'Open',
      createdAt: DateTime.parse(
          doc.data['createdAt'] ?? DateTime.now().toIso8601String()),
      attachments: doc.data['attachments'] != null
          ? List<String>.from(doc.data['attachments'])
          : null,
    );
  }
}

class AdminReply {
  final String id;
  final String reportId;
  final String adminId;
  final String adminName;
  final String message;
  final DateTime createdAt;

  AdminReply({
    required this.id,
    required this.reportId,
    required this.adminId,
    required this.adminName,
    required this.message,
    required this.createdAt,
  });

  factory AdminReply.fromDocument(Document doc) {
    return AdminReply(
      id: doc.$id,
      reportId: doc.data['reportId'] ?? '',
      adminId: doc.data['adminId'] ?? '',
      adminName: doc.data['adminName'] ?? '',
      message: doc.data['message'] ?? '',
      createdAt: DateTime.parse(
          doc.data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ApplicationReport extends StatefulWidget {
  const ApplicationReport({super.key});
  @override
  State<ApplicationReport> createState() => _ApplicationReportState();
}

class _ApplicationReportState extends State<ApplicationReport> {
  final AppwriteService _appwriteService = AppwriteService();
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardOverview(),
    ReportsManagement(),
    AnalyticsView(),
    // SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              _showNotifications(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              _showAdminProfile(context);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue[900],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings,
                      size: 40, color: Colors.blue[900]),
                ),
                SizedBox(height: 10),
                Text('Super Admin',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Text('admin@company.com',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
          _buildDrawerItem(Icons.bug_report, 'Reports Management', 1),
          _buildDrawerItem(Icons.analytics, 'Analytics', 2),
          _buildDrawerItem(Icons.settings, 'Settings', 3),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon,
          color: _selectedIndex == index ? Colors.blue : Colors.grey),
      title: Text(title,
          style: TextStyle(
            color: _selectedIndex == index ? Colors.blue : Colors.black,
            fontWeight:
                _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          )),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.circle, color: Colors.red, size: 12),
              title: Text('New high priority report'),
              subtitle: Text('2 minutes ago'),
            ),
            ListTile(
              leading: Icon(Icons.circle, color: Colors.orange, size: 12),
              title: Text('3 pending responses'),
              subtitle: Text('1 hour ago'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAdminProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Admin Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            SizedBox(height: 16),
            Text('Super Admin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('admin@company.com'),
            SizedBox(height: 16),
            Text('Role: System Administrator'),
            Text('Last Login: ${DateTime.now().toString().substring(0, 16)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement logout logic
              Navigator.pop(context);
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Dashboard Overview
class DashboardOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Total Reports', '1,234', Colors.blue, Icons.bug_report)),
              SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'Open Reports', '89', Colors.orange, Icons.warning)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('Resolved Today', '23', Colors.green,
                      Icons.check_circle)),
              SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      'High Priority', '12', Colors.red, Icons.priority_high)),
            ],
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Reports',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _buildRecentReportItem(
                      'App Crashes on Login', 'John Doe', 'High', Colors.red),
                  _buildRecentReportItem('UI Bug in Settings', 'Jane Smith',
                      'Medium', Colors.orange),
                  _buildRecentReportItem(
                      'Feature Request', 'Bob Johnson', 'Low', Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportItem(
      String title, String user, String priority, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Reported by $user • Priority: $priority',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reports Management
class ReportsManagement extends StatefulWidget {
  @override
  _ReportsManagementState createState() => _ReportsManagementState();
}

class _ReportsManagementState extends State<ReportsManagement> {
  final AppwriteService _appwriteService = AppwriteService();
  List<UserReport> _reports = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);

      final result = await _appwriteService.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.reportsCollectionId,
        queries: [
          Query.orderDesc('createdAt'),
          Query.limit(100),
        ],
      );

      setState(() {
        _reports = result.documents
            .map((doc) => UserReport.fromDocument(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load reports: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildReportsList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedFilter,
            items: ['All', 'Open', 'In Progress', 'Resolved', 'Closed']
                .map((filter) {
              return DropdownMenuItem(value: filter, child: Text(filter));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedFilter = value!);
              _applyFilter();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No reports found',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _buildPriorityIndicator(report.priority),
            title: Text(report.title,
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${report.userName} • ${report.category}'),
                Text(
                    '${_formatDate(report.createdAt)} • Status: ${report.status}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text('View Details'),
                  value: 'view',
                ),
                PopupMenuItem(
                  child: Text('Reply'),
                  value: 'reply',
                ),
                PopupMenuItem(
                  child: Text('Change Status'),
                  value: 'status',
                ),
              ],
              onSelected: (value) => _handleReportAction(value, report),
            ),
            onTap: () => _showReportDetails(report),
          ),
        );
      },
    );
  }

  Widget _buildPriorityIndicator(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _handleReportAction(String action, UserReport report) {
    switch (action) {
      case 'view':
        _showReportDetails(report);
        break;
      case 'reply':
        _showReplyDialog(report);
        break;
      case 'status':
        _showStatusChangeDialog(report);
        break;
    }
  }

  void _showReportDetails(UserReport report) {
    showDialog(
      context: context,
      builder: (context) => ReportDetailsDialog(report: report),
    );
  }

  void _showReplyDialog(UserReport report) {
    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        report: report,
        onReplySent: () {
          _loadReports(); // Refresh the list
        },
      ),
    );
  }

  void _showStatusChangeDialog(UserReport report) {
    showDialog(
      context: context,
      builder: (context) => StatusChangeDialog(
        report: report,
        onStatusChanged: () {
          _loadReports(); // Refresh the list
        },
      ),
    );
  }

  void _applyFilter() {
    // Implement filtering logic
    _loadReports(); // For now, just reload
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

// Report Details Dialog
class ReportDetailsDialog extends StatelessWidget {
  final UserReport report;

  ReportDetailsDialog({required this.report});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildInfoRow(
                  'Reporter', '${report.userName} (${report.userEmail})'),
              _buildInfoRow('Category', report.category),
              _buildInfoRow('Priority', report.priority),
              _buildInfoRow('Status', report.status),
              _buildInfoRow('Created', _formatDate(report.createdAt)),
              SizedBox(height: 16),
              Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(report.description),
              ),
              if (report.attachments != null &&
                  report.attachments!.isNotEmpty) ...[
                SizedBox(height: 16),
                Text('Attachments:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...report.attachments!.map((attachment) => Chip(
                    label: Text(attachment),
                    avatar: Icon(Icons.attach_file, size: 16))),
              ],
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Show reply dialog
                    },
                    child: Text('Reply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child:
                Text('$label:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Reply Dialog
class ReplyDialog extends StatefulWidget {
  final UserReport report;
  final VoidCallback onReplySent;

  ReplyDialog({required this.report, required this.onReplySent});

  @override
  _ReplyDialogState createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final TextEditingController _messageController = TextEditingController();
  final AppwriteService _appwriteService = AppwriteService();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reply to: ${widget.report.title}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Reporter: ${widget.report.userName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Type your reply here...',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                  ),
                  Text('Also send email notification'),
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendReply,
                    child: _isSending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Send Reply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendReply() async {
    if (_messageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a reply message');
      return;
    }

    setState(() => _isSending = true);

    try {
      await _appwriteService.databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.repliesCollectionId,
        documentId: ID.unique(),
        data: {
          'reportId': widget.report.id,
          'adminId': 'current_admin_id', // Replace with actual admin ID
          'adminName': 'Super Admin', // Replace with actual admin name
          'message': _messageController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Update report status to "In Progress" if it was "Open"
      if (widget.report.status == 'Open') {
        await _appwriteService.databases.updateDocument(
          databaseId: AppwriteService.databaseId,
          collectionId: AppwriteService.reportsCollectionId,
          documentId: widget.report.id,
          data: {'status': 'In Progress'},
        );
      }

      Navigator.pop(context);
      widget.onReplySent();
      _showSuccessSnackBar('Reply sent successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to send reply: ${e.toString()}');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}

// Status Change Dialog
class StatusChangeDialog extends StatefulWidget {
  final UserReport report;
  final VoidCallback onStatusChanged;

  StatusChangeDialog({required this.report, required this.onStatusChanged});

  @override
  _StatusChangeDialogState createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<StatusChangeDialog> {
  final AppwriteService _appwriteService = AppwriteService();
  String _selectedStatus = '';
  bool _isUpdating = false;

  final List<String> _statusOptions = [
    'Open',
    'In Progress',
    'Resolved',
    'Closed',
    'On Hold',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Report Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report: ${widget.report.title}'),
          SizedBox(height: 16),
          Text('Current Status: ${widget.report.status}'),
          SizedBox(height: 16),
          Text('New Status:'),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: _statusOptions.map((status) {
              return DropdownMenuItem(value: status, child: Text(status));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedStatus = value!);
            },
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating || _selectedStatus == widget.report.status
              ? null
              : _updateStatus,
          child: _isUpdating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateStatus() async {
    setState(() => _isUpdating = true);

    try {
      await _appwriteService.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.reportsCollectionId,
        documentId: widget.report.id,
        data: {
          'status': _selectedStatus,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      Navigator.pop(context);
      widget.onStatusChanged();
      _showSuccessSnackBar('Status updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to update status: ${e.toString()}');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}

// Analytics View
class AnalyticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildAnalyticsCard('Reports This Week', '127',
                      Icons.trending_up, Colors.blue)),
              SizedBox(width: 16),
              Expanded(
                  child: _buildAnalyticsCard('Average Resolution Time',
                      '2.3 days', Icons.timer, Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
