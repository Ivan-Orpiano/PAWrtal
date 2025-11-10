import 'package:capstone_app/data/models/feedback_deletion_request_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/vet_deletion_reports.dart';
import 'package:get/get.dart';
import 'vet_deletion_request_controller.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';

class PinnedDeletionRequest extends StatefulWidget {
  const PinnedDeletionRequest({super.key});

  @override
  State<PinnedDeletionRequest> createState() => _PinnedDeletionRequestState();
}

class _PinnedDeletionRequestState extends State<PinnedDeletionRequest> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;
  late final VetDeletionRequestController _controller;
  Timer? _refreshTimer;

 @override
void initState() {
  super.initState();
  
  if (Get.isRegistered<VetDeletionRequestController>()) {
    _controller = Get.find<VetDeletionRequestController>();
  } else {
    _controller = Get.put(
      VetDeletionRequestController(
        authRepository: Get.find<AuthRepository>(),
      ),
    );
  }
  
  // FIXED: Load data after the first frame is built
   SchedulerBinding.instance.addPostFrameCallback((_) {
    _controller.loadAllDeletionRequests();
  });

  // Auto-refresh every 40 seconds
  _refreshTimer = Timer.periodic(const Duration(seconds: 40), (timer) {
    if (mounted) {
      _controller.loadAllDeletionRequests();
    }
  });
}
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileWidth;

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileWidth &&
      MediaQuery.of(context).size.width < tabletWidth;

  void _showRequestDetails(FeedbackDeletionRequest request) async {
    final clinicName = _controller.clinicNamesCache[request.clinicId] ??
        await _controller.getClinicName(request.clinicId);
    final review = await _controller.getReview(request.reviewId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => RequestDetailDialog(
        request: request,
        clinicName: clinicName,
        review: review,
      ),
    );
  }

  void _handleDeletionRequest(FeedbackDeletionRequest request) async {
    final clinicName = await _controller.getClinicName(request.clinicId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => DeleteRequestActionDialog(
        request: request,
        clinicName: clinicName,
        onApprove: (reviewNotes) => _controller.approveDeletionRequest(
          request,
          'Super Admin',
          reviewNotes,
        ),
        onDeny: (reviewNotes) => _controller.rejectDeletionRequest(
          request,
          'Super Admin',
          reviewNotes,
        ),
      ),
    );
  }

  void _deleteRequest(FeedbackDeletionRequest request) async {
    final clinicName = await _controller.getClinicName(request.clinicId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Color(0xFFE74C3C)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm Deletion',
                style: TextStyle(
                  fontSize: _isMobile(context) ? 16 : 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this pinned request for "$clinicName"?\n\nThis action cannot be undone.',
          style: TextStyle(fontSize: _isMobile(context) ? 14 : 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF95A5A6),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.deleteProcessedRequest(request);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedRequestsList() {
    return Obx(() {
      // Filter for ONLY pinned requests
      final pinnedRequests = _controller.filteredRequests
          .where((request) => request.isPinned)
          .toList();

      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (pinnedRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.push_pin_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Pinned Requests',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pin important deletion requests to keep them easily accessible',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(_isMobile(context) ? 12 : 16),
        itemCount: pinnedRequests.length,
        itemBuilder: (context, index) {
          final request = pinnedRequests[index];
          return _buildRequestCard(request);
        },
      );
    });
  }

  Widget _buildRequestCard(FeedbackDeletionRequest request) {
    return Obx(() {
      final clinicName =
          _controller.clinicNamesCache[request.clinicId] ?? 'Loading...';
      final isMobile = _isMobile(context);
      final isPinned = request.isPinned;

      return FutureBuilder<RatingAndReview?>(
        future: _controller.getReview(request.reviewId),
        builder: (context, reviewSnapshot) {
          final review = reviewSnapshot.data;

          return Card(
            // Amber/yellow background for pinned items
            color: const Color.fromRGBO(255, 248, 225, 1),
            margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.amber, width: 2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showRequestDetails(request),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with pin button, clinic name, and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Pin button
                        InkWell(
                          onTap: () => _controller.togglePin(request.documentId!),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.push_pin,
                              size: isMobile ? 14 : 16,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: isMobile ? 18 : 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  clinicName,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(request.status),
                      ],
                    ),

                    // Pinned indicator with metadata
                    SizedBox(height: isMobile ? 6 : 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: Colors.amber[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[800],
                            ),
                          ),
                          if (request.pinnedBy != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'by ${request.pinnedBy}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (request.pinnedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatRelativeTime(request.pinnedAt!),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Review information
                    if (review != null) ...[
                      SizedBox(height: isMobile ? 8 : 12),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
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
                                Icon(
                                  Icons.rate_review,
                                  size: isMobile ? 12 : 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Review Details',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 6 : 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'By: ${review.userName}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...List.generate(5, (index) {
                                      return Icon(
                                        index < review.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: isMobile ? 12 : 14,
                                        color: Colors.amber,
                                      );
                                    }),
                                    const SizedBox(width: 4),
                                    Text(
                                      review.rating.toString(),
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (review.reviewText != null &&
                                review.reviewText!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                review.reviewText!,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: isMobile ? 8 : 12),

                    // Reason badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.report_problem,
                            size: isMobile ? 12 : 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              request.reason,
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Additional details
                    if (request.additionalDetails != null &&
                        request.additionalDetails!.isNotEmpty) ...[
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        request.additionalDetails!,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: isMobile ? 8 : 12),

                    // Meta information
                    Wrap(
                      spacing: isMobile ? 8 : 16,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person,
                                size: isMobile ? 14 : 16,
                                color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: isMobile ? 14 : 16,
                                color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${request.requestedAt.day}/${request.requestedAt.month}/${request.requestedAt.year}',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        // NEW: Attachment preview in card
                          if (request.hasAttachments) ...[
                          SizedBox(height: isMobile ? 8 : 12),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: isMobile ? 14 : 16,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${request.attachments.length} attachment(s)',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '- Tap to view details',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  color: Colors.blue[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: isMobile ? 60 : 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: request.attachments.length,
                              itemBuilder: (context, index) {
                                final attachmentId = request.attachments[index];
                                final imageUrl = Get.find<AuthRepository>()
                                    .appWriteProvider
                                    .getImageUrl(attachmentId);
                                
                                return Padding(
                                  padding: EdgeInsets.only(right: isMobile ? 6 : 8),
                                  child: Container(
                                    width: isMobile ? 60 : 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: SizedBox(
                                              width: isMobile ? 16 : 20,
                                              height: isMobile ? 16 : 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey.shade400,
                                              size: isMobile ? 20 : 24,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Review notes
                    if (request.reviewNotes != null &&
                        request.reviewNotes!.isNotEmpty) ...[
                      SizedBox(height: isMobile ? 8 : 12),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: request.status == 'rejected'
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: request.status == 'rejected'
                                ? Colors.red[200]!
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  request.status == 'rejected'
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  size: isMobile ? 14 : 16,
                                  color: request.status == 'rejected'
                                      ? Colors.red[600]
                                      : Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Review Notes',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: request.status == 'rejected'
                                        ? Colors.red[600]
                                        : Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 6 : 8),
                            Text(
                              request.reviewNotes!,
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: isMobile ? 8 : 12),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (request.isPending) ...[
                          Flexible(
                            child: ElevatedButton.icon(
                              onPressed: _controller.isProcessing.value
                                  ? null
                                  : () => _handleDeletionRequest(request),
                              icon: Icon(
                                Icons.gavel,
                                size: isMobile ? 14 : 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Process',
                                style: TextStyle(fontSize: isMobile ? 12 : 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 81, 115, 153),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 6 : 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (request.isApproved || request.isRejected) ...[
                          Flexible(
                            child: ElevatedButton.icon(
                              onPressed: _controller.isProcessing.value
                                  ? null
                                  : () => _deleteRequest(request),
                              icon: Icon(
                                Icons.delete_forever,
                                size: isMobile ? 14 : 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                isMobile ? 'Archive' : 'Archive Record',
                                style: TextStyle(fontSize: isMobile ? 12 : 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(251, 140, 0, 1),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 6 : 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildStatusChip(String status) {
    final isMobile = _isMobile(context);
    Color color;
    switch (status) {
      case 'approved':
        color = const Color(0xFF2ECC71);
        break;
      case 'pending':
        color = const Color(0xFFF39C12);
        break;
      case 'rejected':
        color = const Color(0xFFE74C3C);
        break;
      default:
        color = const Color(0xFF95A5A6);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.capitalize!,
        style: TextStyle(
          color: color,
          fontSize: isMobile ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: const Color.fromRGBO(81, 115, 153, 1),
            size: isMobile ? 22 : 24,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
              Icons.push_pin,
              color: Colors.amber[800],
              size: isMobile ? 20 : 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pinned Deletion Requests',
                style: TextStyle(
                  color: const Color.fromARGB(255, 81, 115, 153),
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 16 : 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        elevation: 0,
        actions: [
          // Auto-refresh indicator
          Obx(() {
            if (_controller.isLoading.value) {
              return Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: SizedBox(
                  width: isMobile ? 18 : 20,
                  height: isMobile ? 18 : 20,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: const Color.fromRGBO(81, 115, 153, 1),
              size: isMobile ? 22 : 24,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const VeterinaryReport(),
                ),
              );
            },
            tooltip: 'Back to All Requests',
          ),
          
          // Refresh button
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: const Color.fromRGBO(81, 115, 153, 1),
              size: isMobile ? 22 : 24,
            ),
            onPressed: () => _controller.loadAllDeletionRequests(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          // Pinned count header
          Obx(() {
            final pinnedCount = _controller.pinnedRequestIds.length;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.amber[200]!,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.push_pin,
                      color: Colors.amber[800],
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pinnedCount Pinned Request${pinnedCount != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                        Text(
                          'Priority deletion requests for quick access',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Pinned requests list
          Expanded(child: _buildPinnedRequestsList()),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isMobile = _isMobile(context);

    return Drawer(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 48 : 60,
              isMobile ? 16 : 24,
              isMobile ? 16 : 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromRGBO(81, 115, 153, 1),
                  Color.fromRGBO(81, 115, 153, 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: isMobile ? 28 : 32,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  'Developer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Management Panel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.local_hospital_rounded,
                  title: 'Veterinary Clinics',
                  subtitle: 'Manage vet clinics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SuperAdminVetClinicDashboard(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_rounded,
                  title: 'Pet Owner Management',
                  subtitle: 'Manage user accounts',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SuperAdminUserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.feedback_rounded,
                  title: 'System Reports',
                  subtitle: 'User feedback & reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminFeedbackManagement(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: 'Deletion Reports',
                  subtitle: 'All deletion requests',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VeterinaryReport(),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 4 : 8,
                  ),
                  child: const Divider(),
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: _isLoggingOut
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 14 : 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(81, 115, 153, 0.7),
                            Color.fromRGBO(81, 115, 153, 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: isMobile ? 18 : 20,
                            height: isMobile ? 18 : 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Logging Out...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : InkWell(
                      onTap: () async {
                        setState(() => _isLoggingOut = true);
                        try {
                          await LogoutHelper.logout();
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoggingOut = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 14 : 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(220, 53, 69, 1),
                              Color.fromRGBO(200, 35, 51, 1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: isMobile ? 18 : 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isMobile = _isMobile(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 2 : 4,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(81, 115, 153, 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(81, 115, 153, 0.2),
                      Color.fromRGBO(81, 115, 153, 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromRGBO(81, 115, 153, 1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: isMobile ? 14 : 16,
                color: const Color.fromRGBO(81, 115, 153, 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}