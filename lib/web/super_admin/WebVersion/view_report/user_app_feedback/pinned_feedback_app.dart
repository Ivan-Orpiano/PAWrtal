import 'package:capstone_app/web/super_admin/WebVersion/services/attachment_viewer_widget.dart';
import 'package:capstone_app/web/user_web/controllers/web_feedback_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';

class PinnedFeedbackPage extends StatefulWidget {
  const PinnedFeedbackPage({super.key});

  @override
  State<PinnedFeedbackPage> createState() => _PinnedFeedbackPageState();
}

class _PinnedFeedbackPageState extends State<PinnedFeedbackPage> {
  late WebFeedbackController controller;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<WebFeedbackController>();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Get only pinned feedback
  List<FeedbackAndReport> get pinnedFeedback {
  final pinned = controller.filteredFeedback.where((f) => f.isPinned).toList();
  
  // ⭐ Sort pinned feedback by date (newest first)
  pinned.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  
  return pinned;
}

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: () => _buildMobileLayout(),
      tabletBody: () => _buildTabletLayout(),
      desktopBody: () => _buildDesktopLayout(),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF517399)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            Icon(Icons.push_pin, color: Colors.amber[800], size: 20),
            const SizedBox(width: 8),
            const Text(
              'Pinned Reports',
              style: TextStyle(
                color: Color(0xFF517399),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF517399)),
            onPressed: () => controller.loadAllFeedback(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 12),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildPinnedStatsCard(),
          _buildMobileSearchBar(),
          Expanded(child: _buildPinnedFeedbackList(isMobile: true)),
        ],
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF517399)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            Icon(Icons.push_pin, color: Colors.amber[800]),
            const SizedBox(width: 8),
            const Text(
              'Pinned Reports',
              style: TextStyle(
                color: Color(0xFF517399),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF517399)),
            onPressed: () => controller.loadAllFeedback(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 12),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildPinnedStatsCard(),
          _buildTabletSearchBar(),
          Expanded(child: _buildPinnedFeedbackList(isTablet: true)),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF517399)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            Icon(Icons.push_pin, color: Colors.amber[800]),
            const SizedBox(width: 8),
            const Text(
              'Pinned Reports',
              style: TextStyle(
                color: Color(0xFF517399),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF517399)),
            onPressed: () => controller.loadAllFeedback(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildPinnedStatsCard(),
          _buildDesktopSearchBar(),
          Expanded(child: _buildPinnedFeedbackList()),
        ],
      ),
    );
  }

  // ==================== PINNED STATS CARD ====================
  Widget _buildPinnedStatsCard() {
    return Obx(() {
      final pinnedCount = pinnedFeedback.length;
      final criticalCount =
          pinnedFeedback.where((f) => f.priority == Priority.critical).length;
      final pendingCount =
          pinnedFeedback.where((f) => f.status == FeedbackStatus.pending).length;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber[700]!, Colors.amber[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.push_pin,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pinnedCount Pinned Reports',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPinnedStatChip(
                        Icons.warning,
                        '$criticalCount Critical',
                        Colors.red[900]!,
                      ),
                      const SizedBox(width: 12),
                      _buildPinnedStatChip(
                        Icons.schedule,
                        '$pendingCount Pending',
                        Colors.orange[900]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPinnedStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SEARCH BARS ====================
  Widget _buildMobileSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color.fromRGBO(248, 253, 255, 1),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search pinned feedback...',
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    searchController.clear();
                    controller.updateSearchQuery('');
                  },
                )
              : const SizedBox()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF517399)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (value) => controller.updateSearchQuery(value),
      ),
    );
  }

  Widget _buildTabletSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color.fromRGBO(248, 253, 255, 1),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search pinned feedback...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.updateSearchQuery('');
                  },
                )
              : const SizedBox()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF517399)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onChanged: (value) => controller.updateSearchQuery(value),
      ),
    );
  }

  Widget _buildDesktopSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color.fromRGBO(248, 253, 255, 1),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search pinned feedback...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.updateSearchQuery('');
                  },
                )
              : const SizedBox()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF517399)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => controller.updateSearchQuery(value),
      ),
    );
  }

  // ==================== PINNED FEEDBACK LIST ====================
  Widget _buildPinnedFeedbackList({bool isMobile = false, bool isTablet = false}) {
    return Obx(() {
      if (controller.isLoadingFeedback.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (pinnedFeedback.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.push_pin_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No pinned feedback',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pin important reports to view them here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        itemCount: pinnedFeedback.length,
        itemBuilder: (context, index) {
          final feedback = pinnedFeedback[index];
          if (isMobile) {
            return _buildMobileFeedbackCard(feedback);
          } else if (isTablet) {
            return _buildTabletFeedbackCard(feedback);
          }
          return _buildFeedbackCard(feedback);
        },
      );
    });
  }

  // ==================== REUSE CARD BUILDERS FROM ORIGINAL PAGE ====================
  // Copy the exact same card builders from app_feedback.dart
  Widget _buildMobileFeedbackCard(FeedbackAndReport feedback) {
    // Exact copy from AdminFeedbackManagement._buildMobileFeedbackCard
    return Obx(() {
      final feedbackItem = controller.allFeedback.firstWhere(
        (f) => f.documentId == feedback.documentId,
        orElse: () => feedback,
      );
      final isPinned = feedbackItem.isPinned;

      return Card(
        color: isPinned
            ? const Color.fromRGBO(255, 248, 225, 1)
            : const Color.fromRGBO(242, 250, 252, 1),
        margin: const EdgeInsets.only(bottom: 10),
        elevation: isPinned ? 6 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPinned
              ? const BorderSide(color: Colors.amber, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showFeedbackDetails(feedback),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => controller.togglePin(feedback.documentId!),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isPinned
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 14,
                          color: isPinned ? Colors.amber[800] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildClickablePriorityBadge(feedback),
                    const Spacer(),
                    _buildClickableStatusBadge(feedback),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  feedback.subject,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  feedback.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTypeBadge(feedback.feedbackType),
                    _buildCategoryBadge(feedback.category),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        feedback.userName,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(feedback.submittedAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTabletFeedbackCard(FeedbackAndReport feedback) {
    // Similar implementation...
    return _buildMobileFeedbackCard(feedback);
  }

  Widget _buildFeedbackCard(FeedbackAndReport feedback) {
    // Similar implementation...
    return _buildMobileFeedbackCard(feedback);
  }

  // Copy helper methods from original file
  Widget _buildClickablePriorityBadge(FeedbackAndReport feedback) {
    Color color = _getPriorityColor(feedback.priority);
    IconData icon = _getPriorityIcon(feedback.priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            feedback.priority.displayName,
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

  Widget _buildClickableStatusBadge(FeedbackAndReport feedback) {
    Color color = _getStatusColor(feedback.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        feedback.status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(FeedbackType type) {
    Color color = _getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(FeedbackCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return Colors.red;
      case Priority.high:
        return Colors.orange;
      case Priority.medium:
        return Colors.yellow[700]!;
      case Priority.low:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.critical:
        return Icons.error;
      case Priority.high:
        return Icons.warning;
      case Priority.medium:
        return Icons.info;
      case Priority.low:
        return Icons.low_priority;
    }
  }

  Color _getTypeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Colors.red;
      case FeedbackType.feature:
        return Colors.green;
      case FeedbackType.complaint:
        return Colors.orange;
      case FeedbackType.question:
        return Colors.purple;
      case FeedbackType.compliment:
        return Colors.teal;
      case FeedbackType.systemIssue:
        return Colors.deepOrange;
    }
  }

  Color _getStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return Colors.orange;
      case FeedbackStatus.inProgress:
        return Colors.blue;
      case FeedbackStatus.completed:
        return Colors.green;
      case FeedbackStatus.closed:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

 void _showFeedbackDetails(FeedbackAndReport feedback) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(248, 253, 255, 1),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // 🎨 Creative Header with Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[700]!, Colors.amber[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.push_pin,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pinned Feedback Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${feedback.documentId?.substring(0, 8)}...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status badges
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusChip(feedback.status),
                      _buildPriorityChip(feedback.priority),
                      _buildTypeChip(feedback.feedbackType),
                    ],
                  ),
                ],
              ),
            ),

            // 📄 Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject
                    _buildDetailCard(
                      icon: Icons.subject,
                      title: 'Subject',
                      content: feedback.subject,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    _buildDetailCard(
                      icon: Icons.description,
                      title: 'Description',
                      content: feedback.description,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),

                    // User Info
                    _buildDetailCard(
                      icon: Icons.person,
                      title: 'Submitted by',
                      content: '${feedback.userName}\n${feedback.userEmail}',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),

                    // Technical Info
                    _buildDetailCard(
                      icon: Icons.info_outline,
                      title: 'Technical Information',
                      content:
                          'App Version: ${feedback.appVersion}\nDevice: ${feedback.deviceInfo}\nPlatform: ${feedback.platform}',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    // Timestamps
                    _buildDetailCard(
                      icon: Icons.access_time,
                      title: 'Timeline',
                      content:
                          'Submitted: ${_formatFullDateTime(feedback.submittedAt)}\nPinned: ${feedback.pinnedAt != null ? _formatFullDateTime(feedback.pinnedAt!) : 'N/A'}\nPinned by: ${feedback.pinnedBy ?? 'N/A'}',
                      color: Colors.teal,
                    ),

                    // Attachments
                    if (feedback.attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAttachmentsCard(feedback),
                    ],
                  ],
                ),
              ),
            ),

            // 🎯 Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Unpin Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller.togglePin(feedback.documentId!);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.push_pin_outlined, size: 18),
                      label: const Text('Unpin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Archive Button (Creative Style)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showArchiveConfirmation(context, feedback),
                      icon: const Icon(Icons.archive, size: 18),
                      label: const Text('Archive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// 🎨 Helper method for status chip
Widget _buildStatusChip(FeedbackStatus status) {
  final color = _getStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getStatusIcon(status), color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(
          status.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPriorityChip(Priority priority) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getPriorityIcon(priority), color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(
          priority.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildTypeChip(FeedbackType type) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    ),
    child: Text(
      type.displayName,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

IconData _getStatusIcon(FeedbackStatus status) {
  switch (status) {
    case FeedbackStatus.pending:
      return Icons.schedule;
    case FeedbackStatus.inProgress:
      return Icons.autorenew;
    case FeedbackStatus.completed:
      return Icons.check_circle;
    case FeedbackStatus.closed:
      return Icons.lock;
  }
}

Widget _buildDetailCard({
  required IconData icon,
  required String title,
  required String content,
  required Color color,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

Widget _buildAttachmentsCard(FeedbackAndReport feedback) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.attach_file, color: Colors.blue[700], size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Attachments (${feedback.attachments.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: feedback.attachments.map((attachmentId) {
            final url = controller.getAttachmentUrl(attachmentId);
            final isVideo = _isVideoAttachment(attachmentId, url);
            
            return GestureDetector(
              onTap: () => _showAttachmentDialog(context, url, isVideo),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: AttachmentViewerWidget(
                  attachmentUrl: url,
                  fileId: attachmentId,
                  isVideo: isVideo,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

String _formatFullDateTime(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

bool _isVideoAttachment(String fileId, String url) {
  final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
  final urlLower = url.toLowerCase();
  return videoExtensions.any((ext) => urlLower.contains('.$ext'));
}

void _showAttachmentDialog(BuildContext context, String url, bool isVideo) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isVideo ? 'Video Attachment' : 'Image Attachment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AttachmentViewerWidget(
                  attachmentUrl: url,
                  fileId: url,
                  isVideo: isVideo,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// 🎯 CREATIVE ARCHIVE CONFIRMATION DIALOG
void _showArchiveConfirmation(BuildContext context, FeedbackAndReport feedback) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange[50]!,
              Colors.orange[100]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎨 Creative Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[600]!, Colors.orange[400]!],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.archive,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Archive This Feedback?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // 📝 Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feedback.subject,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Submitted by: ${feedback.userName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange[800], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This action will remove the feedback from active view. It can be permanently deleted later.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🎯 Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context); // Close confirmation
                        Navigator.pop(context); // Close details
                        
                        // Archive the feedback
                        await controller.archiveFeedback(feedback.documentId!);
                      },
                      icon: const Icon(Icons.archive, size: 20),
                      label: const Text(
                        'Archive Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}