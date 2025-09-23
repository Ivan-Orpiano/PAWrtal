import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/super_admin_feedback_manager.dart';
import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserFeedback {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String description;
  final FeedbackType type;
  final Priority priority;
  final FeedbackStatus status;
  final DateTime submittedAt;
  final String? adminReply;
  final DateTime? repliedAt;
  final List<String> attachments;
  final String appVersion;
  final String deviceInfo;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.submittedAt,
    this.adminReply,
    this.repliedAt,
    this.attachments = const [],
    required this.appVersion,
    required this.deviceInfo,
  });
}

enum FeedbackType { bug, feature, complaint, question, compliment }

enum Priority { low, medium, high, critical }

enum FeedbackStatus { pending, inProgress, resolved, closed }

class ApplicationReport extends StatefulWidget {
  const ApplicationReport({super.key});
  @override
  State<ApplicationReport> createState() => _ApplicationReportState();
}

class _ApplicationReportState extends State<ApplicationReport> {
  List<UserFeedback> feedbackList = [];
  List<UserFeedback> filteredFeedbackList = [];
  String searchQuery = '';
  FeedbackStatus? selectedStatus;
  FeedbackType? selectedType;
  Priority? selectedPriority;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMockData();
    filteredFeedbackList = feedbackList;
  }

  void _loadMockData() {
    feedbackList = [
      UserFeedback(
        id: 'FB001',
        userId: 'U001',
        userName: 'John Doe',
        userEmail: 'john.doe@email.com',
        subject: 'App crashes when uploading large files',
        description:
            'The application consistently crashes when I try to upload files larger than 50MB. This happens on both WiFi and cellular connection.',
        type: FeedbackType.bug,
        priority: Priority.high,
        status: FeedbackStatus.pending,
        submittedAt: DateTime.now().subtract(Duration(hours: 2)),
        attachments: ['crash_log.txt', 'screenshot.png'],
        appVersion: '2.1.4',
        deviceInfo: 'iPhone 14 Pro, iOS 16.5',
      ),
      UserFeedback(
        id: 'FB002',
        userId: 'U002',
        userName: 'Sarah Wilson',
        userEmail: 'sarah.wilson@email.com',
        subject: 'Feature request: Dark mode support',
        description:
            'Would love to see a dark mode option in the app settings. Current bright theme strains eyes during night usage.',
        type: FeedbackType.feature,
        priority: Priority.medium,
        status: FeedbackStatus.inProgress,
        submittedAt: DateTime.now().subtract(Duration(days: 1)),
        attachments: [],
        appVersion: '2.1.4',
        deviceInfo: 'Samsung Galaxy S23, Android 13',
        adminReply:
            'Thank you for the suggestion! Dark mode is currently in development and will be available in version 2.2.0.',
        repliedAt: DateTime.now().subtract(Duration(hours: 12)),
      ),
      UserFeedback(
        id: 'FB003',
        userId: 'U003',
        userName: 'Mike Johnson',
        userEmail: 'mike.johnson@email.com',
        subject: 'Login issues after recent update',
        description:
            'Unable to login after updating to version 2.1.4. App shows "Invalid credentials" even with correct password.',
        type: FeedbackType.bug,
        priority: Priority.critical,
        status: FeedbackStatus.resolved,
        submittedAt: DateTime.now().subtract(Duration(days: 2)),
        attachments: ['error_screenshot.jpg'],
        appVersion: '2.1.4',
        deviceInfo: 'Google Pixel 7, Android 13',
        adminReply:
            'This issue has been identified and fixed in version 2.1.5. Please update your app from the store.',
        repliedAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      UserFeedback(
        id: 'FB004',
        userId: 'U004',
        userName: 'Emma Davis',
        userEmail: 'emma.davis@email.com',
        subject: 'Excellent customer service!',
        description:
            'I had an issue last week and the support team was incredibly helpful and responsive. Thank you!',
        type: FeedbackType.compliment,
        priority: Priority.low,
        status: FeedbackStatus.closed,
        submittedAt: DateTime.now().subtract(Duration(days: 3)),
        attachments: [],
        appVersion: '2.1.3',
        deviceInfo: 'iPad Air, iOS 16.4',
        adminReply:
            'Thank you so much for your kind words! We\'re delighted to hear about your positive experience.',
        repliedAt: DateTime.now().subtract(Duration(days: 2)),
      ),
    ];
  }

  void _filterFeedback() {
    setState(() {
      filteredFeedbackList = feedbackList.where((feedback) {
        bool matchesSearch = searchQuery.isEmpty ||
            feedback.subject
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            feedback.userName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            feedback.description
                .toLowerCase()
                .contains(searchQuery.toLowerCase());

        bool matchesStatus =
            selectedStatus == null || feedback.status == selectedStatus;
        bool matchesType =
            selectedType == null || feedback.type == selectedType;
        bool matchesPriority =
            selectedPriority == null || feedback.priority == selectedPriority;

        return matchesSearch && matchesStatus && matchesType && matchesPriority;
      }).toList();

      // Sort by priority and date
      filteredFeedbackList.sort((a, b) {
        int priorityComparison = _getPriorityValue(b.priority)
            .compareTo(_getPriorityValue(a.priority));
        if (priorityComparison != 0) return priorityComparison;
        return b.submittedAt.compareTo(a.submittedAt);
      });
    });
  }

  int _getPriorityValue(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return 4;
      case Priority.high:
        return 3;
      case Priority.medium:
        return 2;
      case Priority.low:
        return 1;
    }
  }

  void _showFeedbackDetails(UserFeedback feedback) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDetailsDialog(
        feedback: feedback,
        onReply: (reply) => _handleReply(feedback.id, reply),
        onStatusUpdate: (status) => _updateFeedbackStatus(feedback.id, status),
        onDelete: () => _deleteFeedback(feedback.id),
      ),
    );
  }

  void _handleReply(String feedbackId, String reply) {
    setState(() {
      final index = feedbackList.indexWhere((f) => f.id == feedbackId);
      if (index != -1) {
        feedbackList[index] = UserFeedback(
          id: feedbackList[index].id,
          userId: feedbackList[index].userId,
          userName: feedbackList[index].userName,
          userEmail: feedbackList[index].userEmail,
          subject: feedbackList[index].subject,
          description: feedbackList[index].description,
          type: feedbackList[index].type,
          priority: feedbackList[index].priority,
          status: FeedbackStatus.resolved,
          submittedAt: feedbackList[index].submittedAt,
          adminReply: reply,
          repliedAt: DateTime.now(),
          attachments: feedbackList[index].attachments,
          appVersion: feedbackList[index].appVersion,
          deviceInfo: feedbackList[index].deviceInfo,
        );
      }
    });
    _filterFeedback();
  }

  void _updateFeedbackStatus(String feedbackId, FeedbackStatus status) {
    setState(() {
      final index = feedbackList.indexWhere((f) => f.id == feedbackId);
      if (index != -1) {
        feedbackList[index] = UserFeedback(
          id: feedbackList[index].id,
          userId: feedbackList[index].userId,
          userName: feedbackList[index].userName,
          userEmail: feedbackList[index].userEmail,
          subject: feedbackList[index].subject,
          description: feedbackList[index].description,
          type: feedbackList[index].type,
          priority: feedbackList[index].priority,
          status: status,
          submittedAt: feedbackList[index].submittedAt,
          adminReply: feedbackList[index].adminReply,
          repliedAt: feedbackList[index].repliedAt,
          attachments: feedbackList[index].attachments,
          appVersion: feedbackList[index].appVersion,
          deviceInfo: feedbackList[index].deviceInfo,
        );
      }
    });
    _filterFeedback();
  }

  void _deleteFeedback(String feedbackId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        title: Text(
          'Delete Feedback',
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this feedback? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                feedbackList.removeWhere((f) => f.id == feedbackId);
              });
              _filterFeedback();
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close details dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feedback deleted successfully'),
                  backgroundColor: Colors.red[600],
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.bug_report_sharp,
                color: Color.fromARGB(255, 81, 115, 153)),
            SizedBox(width: 8),
            Text(
              'System Reports',
              style: TextStyle(
                  color: Color.fromARGB(255, 81, 115, 153),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
            onPressed: () {
              _loadMockData();
              _filterFeedback();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.analytics,
              color: Color.fromARGB(255, 81, 115, 153),
            ),
            onPressed: () => _showAnalytics(),
          ),
        ],
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildStatsCards(),
          _buildFiltersSection(),
          Expanded(child: _buildFeedbackList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const VetClinicDeletionManager()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        child: const Icon(Icons.pets, color: Color.fromARGB(255, 81, 115, 153)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildStatsCards() {
    final pending =
        feedbackList.where((f) => f.status == FeedbackStatus.pending).length;
    final inProgress =
        feedbackList.where((f) => f.status == FeedbackStatus.inProgress).length;
    final resolved =
        feedbackList.where((f) => f.status == FeedbackStatus.resolved).length;
    final critical =
        feedbackList.where((f) => f.priority == Priority.critical).length;

    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
              'Pending', pending.toString(), Colors.orange, Icons.pending),
          SizedBox(width: 12),
          _buildStatCard(
              'In Progress', inProgress.toString(), Colors.blue, Icons.work),
          SizedBox(width: 12),
          _buildStatCard('Resolved', resolved.toString(), Colors.green,
              Icons.check_circle),
          SizedBox(width: 12),
          _buildStatCard(
              'Critical', critical.toString(), Colors.red, Icons.warning),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Focus(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search feedback...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          searchQuery = '';
                          _filterFeedback();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: const Color.fromRGBO(81, 115, 153, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: const Color.fromRGBO(81, 115, 153, 1), width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                searchQuery = value;
                _filterFeedback();
              },
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown<FeedbackStatus>(
                  'Status',
                  selectedStatus,
                  FeedbackStatus.values,
                  (value) => setState(() {
                    selectedStatus = value;
                    _filterFeedback();
                  }),
                  (status) => _getStatusText(status),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown<FeedbackType>(
                  'Type',
                  selectedType,
                  FeedbackType.values,
                  (value) => setState(() {
                    selectedType = value;
                    _filterFeedback();
                  }),
                  (type) => _getTypeText(type),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown<Priority>(
                  'Priority',
                  selectedPriority,
                  Priority.values,
                  (value) => setState(() {
                    selectedPriority = value;
                    _filterFeedback();
                  }),
                  (priority) => _getPriorityText(priority),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String label,
    T? selectedValue,
    List<T> items,
    Function(T?) onChanged,
    String Function(T) getText,
  ) {
    return DropdownButtonFormField<T>(
      dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        floatingLabelStyle: const TextStyle(color: Color(0xFF517399)),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF517399)),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: selectedValue,
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text('All'),
        ),
        ...items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: Text(getText(item)),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildFeedbackList() {
    if (filteredFeedbackList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No feedback found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredFeedbackList.length,
      itemBuilder: (context, index) {
        final feedback = filteredFeedbackList[index];
        return _buildFeedbackCard(feedback);
      },
    );
  }

  Widget _buildFeedbackCard(UserFeedback feedback) {
    return Card(
      color: const Color.fromRGBO(242, 250, 252, 1),
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFeedbackDetails(feedback),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPriorityBadge(feedback.priority),
                  SizedBox(width: 8),
                  _buildTypeBadge(feedback.type),
                  Spacer(),
                  _buildStatusBadge(feedback.status),
                  // Add delete button for resolved and closed feedback
                  if (feedback.status == FeedbackStatus.resolved ||
                      feedback.status == FeedbackStatus.closed) ...[
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteFeedback(feedback.id),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      tooltip: 'Delete feedback',
                      constraints: BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.all(4),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
              Text(
                feedback.subject,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                feedback.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    feedback.userName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    _formatDateTime(feedback.submittedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (feedback.attachments.isNotEmpty) ...[
                    SizedBox(width: 16),
                    Icon(Icons.attachment, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      '${feedback.attachments.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              if (feedback.adminReply != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              size: 16, color: Colors.blue[600]),
                          SizedBox(width: 4),
                          Text(
                            'Admin Reply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[600],
                            ),
                          ),
                          Spacer(),
                          Text(
                            _formatDateTime(feedback.repliedAt!),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        feedback.adminReply!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(Priority priority) {
    Color color;
    IconData icon;
    switch (priority) {
      case Priority.critical:
        color = Colors.red;
        icon = Icons.error;
        break;
      case Priority.high:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case Priority.medium:
        color = Colors.yellow[700]!;
        icon = Icons.info;
        break;
      case Priority.low:
        color = Colors.grey;
        icon = Icons.low_priority;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            _getPriorityText(priority),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(FeedbackType type) {
    Color color = Colors.blue;
    switch (type) {
      case FeedbackType.bug:
        color = Colors.red;
        break;
      case FeedbackType.feature:
        color = Colors.green;
        break;
      case FeedbackType.complaint:
        color = Colors.orange;
        break;
      case FeedbackType.question:
        color = Colors.purple;
        break;
      case FeedbackType.compliment:
        color = Colors.teal;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getTypeText(type),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(FeedbackStatus status) {
    Color color;
    switch (status) {
      case FeedbackStatus.pending:
        color = Colors.orange;
        break;
      case FeedbackStatus.inProgress:
        color = Colors.blue;
        break;
      case FeedbackStatus.resolved:
        color = Colors.green;
        break;
      case FeedbackStatus.closed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return 'Critical';
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  String _getTypeText(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'Bug';
      case FeedbackType.feature:
        return 'Feature';
      case FeedbackType.complaint:
        return 'Complaint';
      case FeedbackType.question:
        return 'Question';
      case FeedbackType.compliment:
        return 'Compliment';
    }
  }

  String _getStatusText(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.inProgress:
        return 'In Progress';
      case FeedbackStatus.resolved:
        return 'Resolved';
      case FeedbackStatus.closed:
        return 'Closed';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        title: Text('Feedback Analytics'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnalyticsItem(
                  'Total Feedback', feedbackList.length.toString()),
              _buildAnalyticsItem('Average Response Time', '4.2 hours'),
              _buildAnalyticsItem('Resolution Rate', '87.5%'),
              _buildAnalyticsItem('User Satisfaction', '4.6/5.0'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  color: Colors.blue[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class FeedbackDetailsDialog extends StatefulWidget {
  final UserFeedback feedback;
  final Function(String) onReply;
  final Function(FeedbackStatus) onStatusUpdate;
  final VoidCallback onDelete;

  FeedbackDetailsDialog({
    required this.feedback,
    required this.onReply,
    required this.onStatusUpdate,
    required this.onDelete,
  });

  @override
  State<FeedbackDetailsDialog> createState() => _FeedbackDetailsDialogState();
}

class _FeedbackDetailsDialogState extends State<FeedbackDetailsDialog> {
  final TextEditingController _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    if (widget.feedback.adminReply != null) {
      _replyController.text = widget.feedback.adminReply!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Feedback Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Add delete button in header for resolved/closed feedback
                if (widget.feedback.status == FeedbackStatus.resolved ||
                    widget.feedback.status == FeedbackStatus.closed)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: Icon(Icons.delete_outline, color: Colors.red[600]),
                    tooltip: 'Delete feedback',
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('User Information', [
                      'Name: ${widget.feedback.userName}',
                      'Email: ${widget.feedback.userEmail}',
                      'User ID: ${widget.feedback.userId}',
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Feedback Information', [
                      'ID: ${widget.feedback.id}',
                      'Subject: ${widget.feedback.subject}',
                      'Type: ${_getTypeText(widget.feedback.type)}',
                      'Priority: ${_getPriorityText(widget.feedback.priority)}',
                      'Status: ${_getStatusText(widget.feedback.status)}',
                      'Submitted: ${_formatFullDateTime(widget.feedback.submittedAt)}',
                    ]),
                    SizedBox(height: 16),
                    _buildDetailSection('Technical Information', [
                      'App Version: ${widget.feedback.appVersion}',
                      'Device Info: ${widget.feedback.deviceInfo}',
                    ]),
                    SizedBox(height: 16),
                    _buildDescriptionSection(),
                    if (widget.feedback.attachments.isNotEmpty) ...[
                      SizedBox(height: 16),
                      _buildAttachmentsSection(),
                    ],
                    SizedBox(height: 16),
                    _buildReplySection(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.feedback.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments (${widget.feedback.attachments.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[800],
            ),
          ),
          SizedBox(height: 8),
          ...widget.feedback.attachments.map(
            (attachment) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(attachment),
                    size: 16,
                    color: Colors.orange[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attachment,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _downloadAttachment(attachment),
                    child: Text('Download',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 81, 115, 153),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.feedback.adminReply != null
            ? Colors.green[50]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.feedback.adminReply != null
              ? Colors.green[200]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 20,
                color: widget.feedback.adminReply != null
                    ? Colors.green[600]
                    : Colors.grey[600],
              ),
              SizedBox(width: 8),
              Text(
                widget.feedback.adminReply != null
                    ? 'Admin Reply'
                    : 'Compose Reply',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.feedback.adminReply != null
                      ? Colors.green[800]
                      : Colors.grey[800],
                ),
              ),
              if (widget.feedback.adminReply != null) ...[
                Spacer(),
                Text(
                  'Replied: ${_formatFullDateTime(widget.feedback.repliedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _replyController,
            maxLines: 4,
            enabled: _isReplying || widget.feedback.adminReply == null,
            decoration: InputDecoration(
              hintText: 'Type your reply to the customer...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          if (widget.feedback.adminReply == null || _isReplying) ...[
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _sendReply,
                  icon: Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                  label: Text(widget.feedback.adminReply == null
                      ? 'Send Reply'
                      : 'Update Reply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(81, 115, 153, 1),
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_isReplying) ...[
                  SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isReplying = false;
                        _replyController.text =
                            widget.feedback.adminReply ?? '';
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isReplying = true;
                });
              },
              icon: Icon(
                Icons.edit,
                color: Colors.white,
              ),
              label: Text('Edit Reply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<FeedbackStatus>(
            dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
            value: widget.feedback.status,
            decoration: InputDecoration(
              labelText: 'Update Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: FeedbackStatus.values
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusText(status)),
                  ),
                )
                .toList(),
            onChanged: (status) {
              if (status != null && status != widget.feedback.status) {
                widget.onStatusUpdate(status);
                Navigator.pop(context);
              }
            },
          ),
        ),
        SizedBox(width: 16),
        // Add delete button in action buttons for resolved/closed feedback
        if (widget.feedback.status == FeedbackStatus.resolved ||
            widget.feedback.status == FeedbackStatus.closed)
          ElevatedButton.icon(
            onPressed: widget.onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: Colors.white,
            ),
            label: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _copyFeedbackInfo(),
          child: Text('Copy Info'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
            foregroundColor: Colors.white,
          ),
        ),
        SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _exportFeedback(),
          child: Text('Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'txt':
      case 'log':
        return Icons.description;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attachment;
    }
  }

  void _downloadAttachment(String filename) {
    // TODO: Implement actual file download logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $filename...'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  void _sendReply() {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a reply message'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    widget.onReply(_replyController.text.trim());
    setState(() {
      _isReplying = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reply sent successfully'),
        backgroundColor: Colors.green[600],
      ),
    );

    Navigator.pop(context);
  }

  void _copyFeedbackInfo() {
    final info = '''
Feedback ID: ${widget.feedback.id}
User: ${widget.feedback.userName} (${widget.feedback.userEmail})
Subject: ${widget.feedback.subject}
Type: ${_getTypeText(widget.feedback.type)}
Priority: ${_getPriorityText(widget.feedback.priority)}
Status: ${_getStatusText(widget.feedback.status)}
Submitted: ${_formatFullDateTime(widget.feedback.submittedAt)}
App Version: ${widget.feedback.appVersion}
Device: ${widget.feedback.deviceInfo}

Description:
${widget.feedback.description}

${widget.feedback.adminReply != null ? 'Admin Reply:\n${widget.feedback.adminReply}' : ''}
    ''';

    Clipboard.setData(ClipboardData(text: info));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feedback information copied to clipboard'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  void _exportFeedback() {
    // TODO: Implement actual export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting feedback data...'),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  String _getTypeText(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.feature:
        return 'Feature Request';
      case FeedbackType.complaint:
        return 'Complaint';
      case FeedbackType.question:
        return 'Question';
      case FeedbackType.compliment:
        return 'Compliment';
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return 'Critical';
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  String _getStatusText(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.inProgress:
        return 'In Progress';
      case FeedbackStatus.resolved:
        return 'Resolved';
      case FeedbackStatus.closed:
        return 'Closed';
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
