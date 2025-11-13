import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_deletion_request_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
class VetDeletionRequestController extends GetxController {
  final AuthRepository authRepository;

  VetDeletionRequestController({required this.authRepository});

  // Observable lists
  var allRequests = <FeedbackDeletionRequest>[].obs;
  var filteredRequests = <FeedbackDeletionRequest>[].obs;

  // Cache for reviews
  var reviewsCache = <String, RatingAndReview>{}.obs;

  // Cache for clinic names using adminId as key
  var clinicNamesCache = <String, String>{}.obs;
  
  // Cache mapping adminId -> actual clinic document ID
  var adminToClinicDocIdCache = <String, String>{}.obs;

  // NEW: Pinned request IDs for quick access
  var pinnedRequestIds = <String>{}.obs;

  // Loading states
  var isLoading = false.obs;
  var isProcessing = false.obs;

  // Filter states
  var selectedStatus = 'All'.obs;
  var selectedReason = 'All'.obs;
  var searchQuery = ''.obs;

  // Statistics
  var stats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _runMigration();
    _initializeClinicCache().then((_) => loadAllDeletionRequests());
  }

  /// Run migration to add pin fields
  Future<void> _runMigration() async {
    try {
      await authRepository.appWriteProvider.migrateDeletionRequestPinFields();
    } catch (e) {
    }
  }

  /// Initialize clinic name cache
  Future<void> _initializeClinicCache() async {
    try {
      
      final clinics = await authRepository.getAllClinics();

      for (var clinic in clinics) {
        final adminId = clinic.adminId;
        final clinicName = clinic.clinicName;
        final clinicDocId = clinic.documentId;

        clinicNamesCache[adminId] = clinicName;
        
        if (clinicDocId != null) {
          adminToClinicDocIdCache[adminId] = clinicDocId;
          clinicNamesCache[clinicDocId] = clinicName;
        }

      }

    } catch (e) {
    }
  }

Future<void> loadAllDeletionRequests() async {
  try {
    isLoading.value = true;

    final allDeletionRequestDocs =
        await authRepository.appWriteProvider.databases!.listDocuments(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
      queries: [
        Query.orderDesc('requestedAt'),
        Query.limit(500),
      ],
    );

    if (allDeletionRequestDocs.documents.isEmpty) {
      // FIXED: Schedule state update after build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        allRequests.value = [];
        filterRequests();
        calculateStatistics();
        isLoading.value = false;
      });
      return;
    }

    List<FeedbackDeletionRequest> allRequestsTemp = [];
    Set<String> pinnedIdsTemp = {}; // Use temp variable

    for (var doc in allDeletionRequestDocs.documents) {
      try {
        final request = FeedbackDeletionRequest.fromMap(doc.data);
        final requestWithId = request.copyWith(documentId: doc.$id);

        final adminId = requestWithId.clinicId;

        // Track pinned requests in temp variable
        if (requestWithId.isPinned) {
          pinnedIdsTemp.add(doc.$id);
        }

        final clinicName = clinicNamesCache[adminId] ?? 'Unknown Clinic';
        
        if (clinicName == 'Unknown Clinic') {
          final fetchedName = await _fetchClinicNameByAdminId(adminId);
          if (fetchedName != 'Unknown Clinic') {
            clinicNamesCache[adminId] = fetchedName;
          }
        }

        allRequestsTemp.add(requestWithId);
        await _fetchAndCacheReview(requestWithId.reviewId);
      } catch (e) {
        debugPrint('Error processing request: $e');
      }
    }

    // FIXED: Schedule all state updates after build phase
    SchedulerBinding.instance.addPostFrameCallback((_) {
      allRequests.value = allRequestsTemp;
      pinnedRequestIds.value = pinnedIdsTemp; // Update observable here
      filterRequests();
      calculateStatistics();
      isLoading.value = false;
    });

  } catch (e, stackTrace) {
    debugPrint('Failed to load deletion requests: $e\n$stackTrace');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _showSnackBar('Failed to load deletion requests: $e', Colors.red);
      isLoading.value = false;
    });
  }
}

   Future<void> togglePin(String requestId) async {
  try {
    final requestIndex = allRequests.indexWhere((r) => r.documentId == requestId);

    if (requestIndex == -1) {
      return;
    }

    final request = allRequests[requestIndex];
    final newPinStatus = !request.isPinned;
    const pinnedBy = 'Developer';

    // Update in database first
    await authRepository.toggleDeletionRequestPin(
      requestId,
      newPinStatus,
      pinnedBy,
    );

    // FIXED: Schedule state updates after current frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Update local state
      if (newPinStatus) {
        pinnedRequestIds.add(requestId);
      } else {
        pinnedRequestIds.remove(requestId);
      }

      // Update the request object
      allRequests[requestIndex] = request.copyWith(
        isPinned: newPinStatus,
        pinnedAt: newPinStatus ? DateTime.now() : null,
        pinnedBy: newPinStatus ? pinnedBy : null,
      );

      allRequests.refresh();
      filterRequests();

      _showSnackBar(
        newPinStatus ? 'Request pinned successfully' : 'Request unpinned successfully',
        newPinStatus ? Colors.amber : Colors.grey,
      );
    });

  } catch (e) {
    _showSnackBar('Failed to toggle pin: $e', Colors.red);
  }
}

  /// NEW: Check if request is pinned
  bool isPinned(String requestId) {
    return pinnedRequestIds.contains(requestId);
  }

  /// Fetch clinic name by adminId
  Future<String> _fetchClinicNameByAdminId(String adminId) async {
    try {
      final clinic = await authRepository.getClinicByAdminId(adminId);
      
      if (clinic != null) {
        final clinicName = clinic.data['clinicName'] ?? 'Unknown Clinic';
        final clinicDocId = clinic.$id;
        
        clinicNamesCache[adminId] = clinicName;
        adminToClinicDocIdCache[adminId] = clinicDocId;
        clinicNamesCache[clinicDocId] = clinicName;
        
        return clinicName;
      }
      
      return 'Unknown Clinic';
    } catch (e) {
      return 'Unknown Clinic';
    }
  }

  /// Fetch and cache a review
  Future<void> _fetchAndCacheReview(String reviewId) async {
    try {
      if (reviewsCache.containsKey(reviewId)) {
        return;
      }

      final reviewDoc = await authRepository.appWriteProvider.databases!.getDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
        documentId: reviewId,
      );

      final review = RatingAndReview.fromMap(reviewDoc.data);
      reviewsCache[reviewId] = review.copyWith(documentId: reviewDoc.$id);
        } catch (e) {
    }
  }

  /// Get cached review
  Future<RatingAndReview?> getReview(String reviewId) async {
    if (reviewsCache.containsKey(reviewId)) {
      return reviewsCache[reviewId];
    }

    await _fetchAndCacheReview(reviewId);
    return reviewsCache[reviewId];
  }

  /// Filter requests - Sorts pinned first, then by date
void filterRequests() {
  filteredRequests.value = allRequests.where((request) {
    final clinicName = clinicNamesCache[request.clinicId] ?? 'Unknown Clinic';
    
    bool matchesSearch = searchQuery.value.isEmpty ||
        request.reason.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        clinicName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        request.requestedBy.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        (reviewsCache[request.reviewId]?.reviewText ?? '')
            .toLowerCase()
            .contains(searchQuery.value.toLowerCase());

    bool matchesStatus = selectedStatus.value == 'All' ||
        request.status.toLowerCase() == selectedStatus.value.toLowerCase();

    bool matchesReason = selectedReason.value == 'All' ||
        request.reason == selectedReason.value;

    return matchesSearch && matchesStatus && matchesReason;
  }).toList();

  // 🎯 IMPORTANT: Sort pinned items first, then by date
  filteredRequests.sort((a, b) {
    // Primary sort: Pinned first
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;

    // Secondary sort: By requested date (newest first)
    return b.requestedAt.compareTo(a.requestedAt);
  });

}
  /// Calculate statistics
  void calculateStatistics() {
    stats.value = {
      'total': allRequests.length,
      'pending': allRequests.where((r) => r.status == 'pending').length,
      'approved': allRequests.where((r) => r.status == 'approved').length,
      'rejected': allRequests.where((r) => r.status == 'rejected').length,
    };
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query.toLowerCase();
    filterRequests();
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    filterRequests();
  }

  void updateReasonFilter(String reason) {
    selectedReason.value = reason;
    filterRequests();
  }

 /// Approve deletion request with rating recalculation AND notifications (FIXED)
Future<void> approveDeletionRequest(
  FeedbackDeletionRequest request,
  String reviewedBy,
  String? reviewNotes,
) async {
  try {
    isProcessing.value = true;


    // CRITICAL: Debug to find the correct admin ID
    await _debugClinicAdminId(request);

    // Step 1: Get the ACTUAL admin ID from the review's clinic
    String? actualAdminId;
    String clinicName = 'Unknown Clinic';
    
    try {
      
      // Get the review to find which clinic it belongs to
      final review = await getReview(request.reviewId);
      
      if (review != null) {
        
        // Get the clinic document using the review's clinicId
        final clinic = await authRepository.getClinicById(review.clinicId);
        
        if (clinic != null) {
          actualAdminId = clinic.data['adminId'] as String?;
          clinicName = clinic.data['clinicName'] ?? 'Unknown Clinic';
          
        } else {
        }
      } else {
      }
    } catch (e) {
    }
    
    // If we couldn't find the admin ID, show error and return
    if (actualAdminId == null || actualAdminId.isEmpty) {
      _showSnackBar(
        'Error: Cannot identify clinic admin to notify. Please check the data.',
        Colors.red,
      );
      return;
    }

    // Step 2: Approve the deletion request
    final result = await authRepository.approveDeletionRequest(
      request.documentId!,
      request.reviewId,
      reviewedBy,
      reviewNotes,
    );

    if (result['success'] == true) {
      
      // Step 3: Send notification to the CORRECT admin
      try {
        
        // Build notification message
        const notificationTitle = 'Review Deletion Request Approved ✅';
        final notificationMessage = reviewNotes != null && reviewNotes.isNotEmpty
            ? 'Your review deletion request has been approved. Admin notes: $reviewNotes'
            : 'Your review deletion request for "$clinicName" has been approved.';
        
        
        // Create in-app notification using the ACTUAL admin ID
        await authRepository.createDeletionRequestNotification(
          clinicAdminId: actualAdminId, // FIXED: Use actual admin ID from clinic document
          title: notificationTitle,
          message: notificationMessage,
          status: 'approved',
          requestId: request.documentId!,
          clinicId: request.clinicId,
          reviewId: request.reviewId,
          metadata: {
            'clinicName': clinicName,
            'reason': request.reason,
            'reviewedBy': reviewedBy,
            'reviewNotes': reviewNotes ?? '',
            'approvedAt': DateTime.now().toIso8601String(),
          },
        );
        
        
        // Verify notification was created
        final notificationCount = await authRepository.getUnreadNotificationCount(actualAdminId);
        
      } catch (notifError) {
        // Show error but don't fail the approval
        _showSnackBar(
          'Request approved but notification failed: $notifError',
          Colors.orange,
        );
      }
      
      _showSnackBar(
        'Deletion request approved! Notification sent to $clinicName.',
        Colors.green,
      );
      
      // Remove the cached review
      reviewsCache.remove(request.reviewId);
      
      // Reload all deletion requests to update UI
      await loadAllDeletionRequests();
      
    } else {
      _showSnackBar('Failed to approve request: ${result['error']}', Colors.red);
    }
  } catch (e) {
    _showSnackBar('Error: $e', Colors.red);
  } finally {
    isProcessing.value = false;
  }
}


   /// Reject deletion request AND send notification (FIXED)
Future<void> rejectDeletionRequest(
  FeedbackDeletionRequest request,
  String reviewedBy,
  String? reviewNotes,
) async {
  try {
    isProcessing.value = true;


    // CRITICAL: Debug to find the correct admin ID
    await _debugClinicAdminId(request);

    // Step 1: Get the ACTUAL admin ID from the review's clinic
    String? actualAdminId;
    String clinicName = 'Unknown Clinic';
    
    try {
      
      // Get the review to find which clinic it belongs to
      final review = await getReview(request.reviewId);
      
      if (review != null) {
        
        // Get the clinic document using the review's clinicId
        final clinic = await authRepository.getClinicById(review.clinicId);
        
        if (clinic != null) {
          actualAdminId = clinic.data['adminId'] as String?;
          clinicName = clinic.data['clinicName'] ?? 'Unknown Clinic';
          
        } else {
        }
      } else {
      }
    } catch (e) {
    }
    
    // If we couldn't find the admin ID, show error and return
    if (actualAdminId == null || actualAdminId.isEmpty) {
      _showSnackBar(
        'Error: Cannot identify clinic admin to notify. Please check the data.',
        Colors.red,
      );
      return;
    }

    // Step 2: Reject the deletion request
    final result = await authRepository.rejectDeletionRequest(
      request.documentId!,
      reviewedBy,
      reviewNotes,
    );

    if (result['success'] == true) {
      
      // Step 3: Send notification to the CORRECT admin
      try {
        
        // Build notification message
        const notificationTitle = 'Review Deletion Request Rejected ❌';
        final notificationMessage = reviewNotes != null && reviewNotes.isNotEmpty
            ? 'Your review deletion request has been rejected. Reason: $reviewNotes'
            : 'Your review deletion request for "$clinicName" has been rejected.';
        
        
        // Create in-app notification using the ACTUAL admin ID
        await authRepository.createDeletionRequestNotification(
          clinicAdminId: actualAdminId, // FIXED: Use actual admin ID from clinic document
          title: notificationTitle,
          message: notificationMessage,
          status: 'rejected',
          requestId: request.documentId!,
          clinicId: request.clinicId,
          reviewId: request.reviewId,
          metadata: {
            'clinicName': clinicName,
            'reason': request.reason,
            'reviewedBy': reviewedBy,
            'reviewNotes': reviewNotes ?? '',
            'rejectedAt': DateTime.now().toIso8601String(),
          },
        );
        
        
        // Verify notification was created
        final notificationCount = await authRepository.getUnreadNotificationCount(actualAdminId);
        
      } catch (notifError) {
        _showSnackBar(
          'Request rejected but notification failed: $notifError',
          Colors.orange,
        );
      }
      
      _showSnackBar(
        'Deletion request rejected. Notification sent to $clinicName.',
        Colors.orange,
      );
      
      await loadAllDeletionRequests();
      
    } else {
      _showSnackBar('Failed to reject request: ${result['error']}', Colors.red);
    }
  } catch (e) {
    _showSnackBar('Error: $e', Colors.red);
  } finally {
    isProcessing.value = false;
  }
}
  /// Delete a processed request
  Future<void> deleteProcessedRequest(FeedbackDeletionRequest request) async {
    try {
      isProcessing.value = true;

      await authRepository.appWriteProvider.databases!.deleteDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        documentId: request.documentId!,
      );

      allRequests.removeWhere((r) => r.documentId == request.documentId);
      pinnedRequestIds.remove(request.documentId);
      filterRequests();
      calculateStatistics();

      _showSnackBar('Request deleted successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      isProcessing.value = false;
    }
  }

  /// Debug method to verify clinic admin ID
Future<void> _debugClinicAdminId(FeedbackDeletionRequest request) async {
  
  // Check what's actually stored in the deletion request
  try {
    final requestDoc = await authRepository.appWriteProvider.databases!.getDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
      documentId: request.documentId!,
    );
    
  } catch (e) {
  }
  
  // Try to find the clinic by adminId
  try {
    final clinicByAdmin = await authRepository.getClinicByAdminId(request.clinicId);
    
    if (clinicByAdmin != null) {
    } else {
    }
  } catch (e) {
  }
  
  // Try to find the clinic by document ID
  try {
    final clinicByDocId = await authRepository.getClinicById(request.clinicId);
    
    if (clinicByDocId != null) {
    } else {
    }
  } catch (e) {
  }
  
  // Check the review to see which clinic it belongs to
  try {
    final review = await getReview(request.reviewId);
    
    if (review != null) {
      
      // Try to get clinic by review's clinicId
      final reviewClinic = await authRepository.getClinicById(review.clinicId);
      if (reviewClinic != null) {
      }
    }
  } catch (e) {
  }
  
}

  /// Get clinic name
  Future<String> getClinicName(String adminId) async {
    if (clinicNamesCache.containsKey(adminId)) {
      return clinicNamesCache[adminId]!;
    }

    return await _fetchClinicNameByAdminId(adminId);
  }

  void _showSnackBar(String message, Color color) {
    Get.snackbar(
      color == Colors.red ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    reviewsCache.clear();
    clinicNamesCache.clear();
    adminToClinicDocIdCache.clear();
    pinnedRequestIds.clear();
    super.onClose();
  }
}