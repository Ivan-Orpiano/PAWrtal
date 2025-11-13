import 'package:capstone_app/data/models/feedback_deletion_request_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:get/get.dart';
import 'vet_deletion_request_controller.dart';
import 'pinned_deletion_request.dart';

class VeterinaryReport extends StatefulWidget {
  const VeterinaryReport({super.key});

  @override
  State<VeterinaryReport> createState() => _VeterinaryReportState();
}

class _VeterinaryReportState extends State<VeterinaryReport> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;
  late final VetDeletionRequestController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      VetDeletionRequestController(
        authRepository: Get.find<AuthRepository>(),
      ),
    );
    _searchController.addListener(() {
      _controller.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    Get.delete<VetDeletionRequestController>();
    super.dispose();
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileWidth;

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileWidth &&
      MediaQuery.of(context).size.width < tabletWidth;

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletWidth;

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
          'Are you sure you want to permanently delete the ${request.status} request for "$clinicName"?\n\nThis action cannot be undone.',
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


      Widget _buildDashboardStats() {
        return Obx(() {
         
          final totalStats = {
            'total': _controller.filteredRequests.length,
            'pending': _controller.filteredRequests.where((r) => r.status == 'pending').length,
            'approved': _controller.filteredRequests.where((r) => r.status == 'approved').length,
            'rejected': _controller.filteredRequests.where((r) => r.status == 'rejected').length,
          };

          // 🎯 BONUS: Also show pinned count for reference
          final pinnedCount = _controller.filteredRequests
              .where((r) => r.isPinned)
              .length;

          final isMobile = _isMobile(context);
          final isTablet = _isTablet(context);

          return Container(
            color: const Color.fromRGBO(248, 253, 255, 1),
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              children: [
              
                // 📊 Main stats cards (showing ALL requests, not just pinned)
                isMobile
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total',
                                  totalStats['total'].toString(),
                                  Icons.delete_forever,
                                  const Color(0xFF4A90E2),
                                  isCompact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  'Pending',
                                  totalStats['pending'].toString(),
                                  Icons.pending,
                                  const Color(0xFFF39C12),
                                  isCompact: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Approved',
                                  totalStats['approved'].toString(),
                                  Icons.check_circle,
                                  const Color(0xFF2ECC71),
                                  isCompact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  'Rejected',
                                  totalStats['rejected'].toString(),
                                  Icons.cancel,
                                  const Color(0xFFE74C3C),
                                  isCompact: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _buildStatCard(
                            'Total Requests',
                            totalStats['total'].toString(),
                            Icons.delete_forever,
                            const Color(0xFF4A90E2),
                            isCompact: isTablet,
                          ),
                          SizedBox(width: isTablet ? 8 : 12),
                          _buildStatCard(
                            'Pending',
                            totalStats['pending'].toString(),
                            Icons.pending,
                            const Color(0xFFF39C12),
                            isCompact: isTablet,
                          ),
                          SizedBox(width: isTablet ? 8 : 12),
                          _buildStatCard(
                            'Approved',
                            totalStats['approved'].toString(),
                            Icons.check_circle,
                            const Color(0xFF2ECC71),
                            isCompact: isTablet,
                          ),
                          SizedBox(width: isTablet ? 8 : 12),
                          _buildStatCard(
                            'Rejected',
                            totalStats['rejected'].toString(),
                            Icons.cancel,
                            const Color(0xFFE74C3C),
                            isCompact: isTablet,
                          ),
                        ],
                      ),
              ],
            ),
          );
        });
      }

      // ✅ KEEP THE _buildStatCard METHOD AS IS (no changes needed)
      Widget _buildStatCard(
        String title,
        String value,
        IconData icon,
        Color color, {
        bool isCompact = false,
      }) {
        final displayValue = value.isEmpty ? '0' : value;

        return Expanded(
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: isCompact ? 20 : 24),
                    Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: isCompact ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 4 : 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }
  Widget _buildSearchAndFilters() {
    final isMobile = _isMobile(context);

    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isMobile ? 'Search...' : 'Search by clinic, requester, or reason...',
              hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
              prefixIcon: Icon(Icons.search, size: isMobile ? 20 : 24),
              suffixIcon: Obx(() {
                return _controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: isMobile ? 20 : 24),
                        onPressed: () {
                          _searchController.clear();
                          _controller.updateSearchQuery('');
                        },
                      )
                    : const SizedBox.shrink();
              }),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color.fromRGBO(81, 115, 153, 1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromRGBO(81, 115, 153, 1),
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 10 : 12,
              ),
            ),
            style: TextStyle(fontSize: isMobile ? 13 : 14),
          ),
          const SizedBox(height: 12),
          isMobile
              ? Column(
                  children: [
                    _buildStatusDropdown(),
                    const SizedBox(height: 8),
                    _buildReasonDropdown(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatusDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildReasonDropdown()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final isMobile = _isMobile(context);

    return Obx(() {
      return DropdownButtonFormField<String>(
        dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
        value: _controller.selectedStatus.value,
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: isMobile ? 13 : 14,
          ),
          floatingLabelStyle: const TextStyle(color: Color(0xFF517399)),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF517399)),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 6 : 8,
          ),
        ),
        style: TextStyle(
          fontSize: isMobile ? 13 : 14,
          color: Colors.black,
        ),
        items: ['All', 'pending', 'approved', 'rejected']
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status == 'All' ? 'All' : status.capitalize!),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            _controller.updateStatusFilter(value);
          }
        },
      );
    });
  }

  Widget _buildReasonDropdown() {
    final isMobile = _isMobile(context);

    return Obx(() {
      final reasons = [
        'All',
        ..._controller.allRequests.map((r) => r.reason).toSet()
      ];

      return DropdownButtonFormField<String>(
        dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
        value: _controller.selectedReason.value,
        decoration: InputDecoration(
          labelText: 'Reason',
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: isMobile ? 13 : 14,
          ),
          floatingLabelStyle: const TextStyle(color: Color(0xFF517399)),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF517399)),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 6 : 8,
          ),
        ),
        style: TextStyle(
          fontSize: isMobile ? 13 : 14,
          color: Colors.black,
        ),
        items: reasons
            .map((reason) =>
                DropdownMenuItem(value: reason, child: Text(reason)))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            _controller.updateReasonFilter(value);
          }
        },
      );
    });
  }

    Widget _buildRequestList() {
      return Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

   
        final unpinnedRequests = _controller.filteredRequests
            .where((request) => !request.isPinned)
            .toList();

        if (unpinnedRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No deletion requests found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pinned requests are shown separately',
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
          padding: EdgeInsets.all(_isMobile(context) ? 12 : 16),
          itemCount: unpinnedRequests.length,
          itemBuilder: (context, index) {
            final request = unpinnedRequests[index];
            return _buildRequestCard(request);
          },
        );
      });
    }
Widget _buildRequestCard(FeedbackDeletionRequest request) {
    final clinicName = _controller.clinicNamesCache[request.clinicId] ?? 'Loading...';
    final isMobile = _isMobile(context);
    final isPinned = request.isPinned;

    return FutureBuilder<RatingAndReview?>(
      future: _controller.getReview(request.reviewId),
      builder: (context, reviewSnapshot) {
        final review = reviewSnapshot.data;

        return Card(
          // NEW: Change card color if pinned
          color: isPinned
              ? const Color.fromRGBO(255, 248, 225, 1) // Amber/yellow tint
              : const Color.fromRGBO(242, 250, 252, 1),
          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          // NEW: Increase elevation if pinned
          elevation: isPinned ? 6 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            // NEW: Add border if pinned
            side: isPinned
                ? const BorderSide(color: Colors.amber, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showRequestDetails(request),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with clinic name, status, and PIN BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // NEW: Pin button at the start
                      InkWell(
                        onTap: () => _controller.togglePin(request.documentId!),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          decoration: BoxDecoration(
                            color: isPinned
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: isMobile ? 14 : 16,
                            color: isPinned ? Colors.amber[800] : Colors.grey[600],
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

                  // NEW: Show pinned indicator
                  if (isPinned) ...[
                    SizedBox(height: isMobile ? 6 : 8),
                    Row(
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
                      ],
                    ),
                  ],

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
                      if (request.hasAttachments)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file,
                                size: isMobile ? 14 : 16,
                                color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${request.attachments.length} file(s)',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
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
              Icons.delete_forever,
              color: const Color.fromARGB(255, 81, 115, 153),
              size: isMobile ? 20 : 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMobile ? 'Deletion Reports' : 'Deletion Reports',
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
            return IconButton(
              icon: Icon(
                Icons.refresh,
                color: const Color.fromRGBO(81, 115, 153, 1),
                size: isMobile ? 22 : 24,
              ),
              onPressed: () => _controller.loadAllDeletionRequests(),
              tooltip: 'Refresh',
            );
          }),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Column(
        children: [
          _buildDashboardStats(),
          _buildSearchAndFilters(),
          Expanded(child: _buildRequestList()),
        ],
      ),
      floatingActionButton: _buildPinnedFAB(),
    );
  }

  Widget _buildPinnedFAB() {
    return Obx(() {
      final pinnedCount = _controller.pinnedRequestIds.length;

      return pinnedCount > 0
          ? Stack(
              alignment: Alignment.center,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinnedDeletionRequest(),
                      ),
                    );
                  },
                  backgroundColor: Colors.amber[700],
                  icon: const Icon(Icons.push_pin, color: Colors.white),
                  label: Text(
                    'Pinned ($pinnedCount)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  elevation: 6,
                  heroTag: 'pinned_deletion_requests',
                ),
                if (pinnedCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      child: Text(
                        '$pinnedCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            )
          : const SizedBox.shrink(); 
    });
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

// ============= RESPONSIVE DIALOG WIDGETS =============

class RequestDetailDialog extends StatelessWidget {
  final FeedbackDeletionRequest request;
  final String clinicName;
  final RatingAndReview? review;

  const RequestDetailDialog({
    super.key,
    required this.request,
    required this.clinicName,
    this.review,
  });

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileWidth;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? screenWidth * 0.95 : screenWidth * 0.9,
        constraints: BoxConstraints(
          maxWidth: isMobile ? 500 : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.delete_forever,
                    color: const Color(0xFF517399),
                    size: isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deletion Request Details',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: isMobile ? 12 : 16),

              // Review details if available
              if (review != null) ...[
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                          Icon(
                            Icons.rate_review,
                            color: Colors.blue,
                            size: isMobile ? 18 : 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Review Being Requested for Deletion',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 10 : 12),
                      _buildDetailRow(
                        context,
                        'Reviewer:',
                        review!.userName,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: isMobile ? 100 : 140,
                            child: Text(
                              'Rating:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7F8C8D),
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < review!.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: isMobile ? 16 : 18,
                                    color: Colors.amber,
                                  );
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  '${review!.rating}/5.0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _buildDetailRow(
                        context,
                        'Service:',
                        review!.serviceName,
                      ),
                      if (review!.petName != null)
                        _buildDetailRow(
                          context,
                          'Pet Name:',
                          review!.petName!,
                        ),
                      _buildDetailRow(
                        context,
                        'Posted:',
                        review!.getTimeAgo(),
                      ),
                      if (review!.reviewText != null &&
                          review!.reviewText!.isNotEmpty) ...[
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          'Review Text:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7F8C8D),
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E6ED)),
                          ),
                          child: Text(
                            review!.reviewText!,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      if (review!.hasImages) ...[
                        SizedBox(height: isMobile ? 6 : 8),
                        Row(
                          children: [
                            Icon(
                              Icons.image,
                              size: isMobile ? 14 : 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${review!.images.length} image(s) attached',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                const Divider(),
                SizedBox(height: isMobile ? 12 : 16),
              ],

              // Request information
              Text(
                'Request Information',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 12),
              _buildDetailRow(context, 'Vet Clinic:', clinicName),
              _buildDetailRow(context, 'Reason:', request.reason),
              _buildDetailRow(
                context,
                'Status:',
                request.status.capitalize!,
              ),
              _buildDetailRow(
                context,
                'Date Requested:',
                '${request.requestedAt.day}/${request.requestedAt.month}/${request.requestedAt.year} ${request.requestedAt.hour}:${request.requestedAt.minute.toString().padLeft(2, '0')}',
              ),
              if (request.reviewedAt != null)
                _buildDetailRow(
                  context,
                  'Date Processed:',
                  '${request.reviewedAt!.day}/${request.reviewedAt!.month}/${request.reviewedAt!.year} ${request.reviewedAt!.hour}:${request.reviewedAt!.minute.toString().padLeft(2, '0')}',
                ),
              if (request.reviewedBy != null)
                _buildDetailRow(context, 'Reviewed By:', request.reviewedBy!),
              SizedBox(height: isMobile ? 12 : 16),

              // Additional details
              if (request.additionalDetails != null &&
                  request.additionalDetails!.isNotEmpty) ...[
                Text(
                  'Additional Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FDFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E6ED)),
                  ),
                  child: Text(
                    request.additionalDetails!,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],

              // Review notes
              if (request.reviewNotes != null &&
                  request.reviewNotes!.isNotEmpty) ...[
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  'Review Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Container(
                  width: double.infinity,
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
                  child: Text(
                    request.reviewNotes!,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],

             // Attachments
              if (request.hasAttachments) ...[
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  'Attachments (${request.attachments.length}):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                
                // NEW: Display images in a grid instead of just text
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: request.attachments.length,
                  itemBuilder: (context, index) {
                    final attachmentId = request.attachments[index];
                    final imageUrl = Get.find<AuthRepository>()
                        .appWriteProvider
                        .getImageUrl(attachmentId);
                    
                    return GestureDetector(
                      onTap: () {
                        // Show full image in dialog
                        _showFullImageDialog(context, imageUrl);
                      },
                      child: Container(
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
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.grey.shade400,
                                      size: isMobile ? 32 : 40,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Failed to load',
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              SizedBox(height: isMobile ? 20 : 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF517399),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isMobile = _isMobile(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 100 : 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7F8C8D),
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
      void _showFullImageDialog(BuildContext context, String imageUrl) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.grey.shade400,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
}

class DeleteRequestActionDialog extends StatefulWidget {
  final FeedbackDeletionRequest request;
  final String clinicName;
  final Function(String?) onApprove;
  final Function(String?) onDeny;

  const DeleteRequestActionDialog({
    super.key,
    required this.request,
    required this.clinicName,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  State<DeleteRequestActionDialog> createState() =>
      _DeleteRequestActionDialogState();
}

class _DeleteRequestActionDialogState extends State<DeleteRequestActionDialog> {
  final TextEditingController _reviewNotesController = TextEditingController();
  bool _showReviewForm = false;
  bool _isApproving = true;

  @override
  void dispose() {
    _reviewNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.gavel, color: Color(0xFF517399)),
          SizedBox(width: 8),
          Text('Process Deletion Request'),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review the deletion request for "${widget.clinicName}":',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FDFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E6ED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason: ${widget.request.reason}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (widget.request.additionalDetails != null &&
                      widget.request.additionalDetails!.isNotEmpty) ...[
                    const Text('Details:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      widget.request.additionalDetails!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_showReviewForm) ...[
              const Text(
                'What would you like to do with this request?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ] else ...[
              Text(
                _isApproving
                    ? 'Add review notes (optional):'
                    : 'Please provide a reason for rejection:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isApproving
                      ? 'Enter optional notes...'
                      : 'Enter rejection reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF517399), width: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_showReviewForm) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF95A5A6)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _showReviewForm = true;
                _isApproving = false;
              });
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFE74C3C)),
            child: const Text('Reject Request'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showReviewForm = true;
                _isApproving = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve Deletion'),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              setState(() {
                _showReviewForm = false;
                _reviewNotesController.clear();
              });
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF95A5A6)),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_isApproving) {
                widget.onApprove(_reviewNotesController.text.trim().isEmpty
                    ? null
                    : _reviewNotesController.text.trim());
              } else {
                if (_reviewNotesController.text.trim().isNotEmpty) {
                  widget.onDeny(_reviewNotesController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a rejection reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isApproving
                  ? const Color(0xFF2ECC71)
                  : const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child:
                Text(_isApproving ? 'Confirm Approval' : 'Confirm Rejection'),
          ),
        ],
      ],
    );
  }
}
