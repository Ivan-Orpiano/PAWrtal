import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_deletion_request_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';

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
      print('>>> Migration error: $e');
    }
  }

  /// Initialize clinic name cache
  Future<void> _initializeClinicCache() async {
    try {
      print('>>> Initializing clinic name cache');
      
      final clinics = await authRepository.getAllClinics();
      print('>>> Found ${clinics.length} clinics');

      for (var clinic in clinics) {
        final adminId = clinic.adminId;
        final clinicName = clinic.clinicName;
        final clinicDocId = clinic.documentId;

        clinicNamesCache[adminId] = clinicName;
        
        if (clinicDocId != null) {
          adminToClinicDocIdCache[adminId] = clinicDocId;
          clinicNamesCache[clinicDocId] = clinicName;
        }

        print('>>> Cached: $adminId -> $clinicName');
      }

      print('>>> Cache initialized with ${clinicNamesCache.length} entries');
    } catch (e) {
      print('>>> ERROR initializing clinic cache: $e');
    }
  }

  /// Load all deletion requests
  Future<void> loadAllDeletionRequests() async {
    try {
      isLoading.value = true;
      print('>>> Loading all deletion requests');

      final allDeletionRequestDocs =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
        queries: [
          Query.orderDesc('requestedAt'),
          Query.limit(500),
        ],
      );

      print('>>> Found ${allDeletionRequestDocs.documents.length} deletion requests');

      if (allDeletionRequestDocs.documents.isEmpty) {
        allRequests.value = [];
        filterRequests();
        calculateStatistics();
        isLoading.value = false;
        return;
      }

      List<FeedbackDeletionRequest> allRequestsTemp = [];

      for (var doc in allDeletionRequestDocs.documents) {
        try {
          final request = FeedbackDeletionRequest.fromMap(doc.data);
          final requestWithId = request.copyWith(documentId: doc.$id);

          final adminId = requestWithId.clinicId;

          print('>>> Processing deletion request ${doc.$id}');
          print('>>>   - Pinned: ${requestWithId.isPinned}');

          // NEW: Track pinned requests
          if (requestWithId.isPinned) {
            pinnedRequestIds.add(doc.$id);
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
          print('>>>   ✗ Error processing deletion request ${doc.$id}: $e');
        }
      }

      allRequests.value = allRequestsTemp;
      print('>>> ✅ Total deletion requests loaded: ${allRequests.length}');
      print('>>> Pinned requests: ${pinnedRequestIds.length}');

      filterRequests();
      calculateStatistics();
    } catch (e, stackTrace) {
      print('>>> ✗ ERROR LOADING DELETION REQUESTS: $e');
      print('>>> Stack trace: $stackTrace');
      _showSnackBar('Failed to load deletion requests: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  /// NEW: Toggle pin status with database persistence
  Future<void> togglePin(String requestId) async {
    try {
      print('>>> Toggling pin for deletion request: $requestId');

      final requestIndex = allRequests.indexWhere((r) => r.documentId == requestId);

      if (requestIndex == -1) {
        print('>>> Error: Request not found');
        return;
      }

      final request = allRequests[requestIndex];
      final newPinStatus = !request.isPinned;

      final pinnedBy = 'Developer'; // You can get this from session/storage

      print('>>> New pin status: $newPinStatus');
      print('>>> Pinned by: $pinnedBy');

      // Update in database
      await authRepository.toggleDeletionRequestPin(
        requestId,
        newPinStatus,
        pinnedBy,
      );

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

      print('>>> Pin toggle successful');
    } catch (e) {
      print('>>> Error toggling pin: $e');
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

      if (reviewDoc != null) {
        final review = RatingAndReview.fromMap(reviewDoc.data);
        reviewsCache[reviewId] = review.copyWith(documentId: reviewDoc.$id);
      }
    } catch (e) {
      print('>>> Warning: Could not fetch review $reviewId: $e');
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

  /// Filter requests - UPDATED to sort pinned first
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

    // NEW: Sort pinned items first, then by date
    filteredRequests.sort((a, b) {
      // Primary sort: Pinned first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // Secondary sort: By requested date
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

    print('>>> ============================================');
    print('>>> CONTROLLER: Approving deletion request');
    print('>>> Request ID: ${request.documentId}');
    print('>>> Review ID: ${request.reviewId}');
    print('>>> ============================================');

    // CRITICAL: Debug to find the correct admin ID
    await _debugClinicAdminId(request);

    // Step 1: Get the ACTUAL admin ID from the review's clinic
    String? actualAdminId;
    String clinicName = 'Unknown Clinic';
    
    try {
      print('>>> Step 1: Finding actual admin ID...');
      
      // Get the review to find which clinic it belongs to
      final review = await getReview(request.reviewId);
      
      if (review != null) {
        print('>>> Found review, clinic ID: ${review.clinicId}');
        
        // Get the clinic document using the review's clinicId
        final clinic = await authRepository.getClinicById(review.clinicId);
        
        if (clinic != null) {
          actualAdminId = clinic.data['adminId'] as String?;
          clinicName = clinic.data['clinicName'] ?? 'Unknown Clinic';
          
          print('>>> ✅ Found actual admin ID: $actualAdminId');
          print('>>> ✅ Clinic name: $clinicName');
        } else {
          print('>>> ❌ Could not find clinic by ID: ${review.clinicId}');
        }
      } else {
        print('>>> ❌ Could not find review: ${request.reviewId}');
      }
    } catch (e) {
      print('>>> ❌ Error finding admin ID: $e');
    }
    
    // If we couldn't find the admin ID, show error and return
    if (actualAdminId == null || actualAdminId.isEmpty) {
      print('>>> ❌ CRITICAL ERROR: Cannot find admin ID to send notification');
      _showSnackBar(
        'Error: Cannot identify clinic admin to notify. Please check the data.',
        Colors.red,
      );
      return;
    }

    // Step 2: Approve the deletion request
    print('>>> Step 2: Approving deletion request...');
    final result = await authRepository.approveDeletionRequest(
      request.documentId!,
      request.reviewId,
      reviewedBy,
      reviewNotes,
    );

    if (result['success'] == true) {
      print('>>> ✅ Deletion approved successfully');
      
      // Step 3: Send notification to the CORRECT admin
      try {
        print('>>> Step 3: Sending notification...');
        print('>>> Recipient admin ID: $actualAdminId');
        
        // Build notification message
        final notificationTitle = 'Review Deletion Request Approved ✅';
        final notificationMessage = reviewNotes != null && reviewNotes.isNotEmpty
            ? 'Your review deletion request has been approved. Admin notes: $reviewNotes'
            : 'Your review deletion request for "$clinicName" has been approved.';
        
        print('>>> Creating notification with:');
        print('>>>   - Title: $notificationTitle');
        print('>>>   - Recipient: $actualAdminId');
        print('>>>   - Clinic Name: $clinicName');
        
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
        
        print('>>> ✅ Notification created successfully');
        
        // Verify notification was created
        final notificationCount = await authRepository.getUnreadNotificationCount(actualAdminId);
        print('>>> Admin now has $notificationCount unread notifications');
        
      } catch (notifError) {
        print('>>> ❌ ERROR sending notification: $notifError');
        print('>>> Stack trace: ${StackTrace.current}');
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
      
      print('>>> ✅ Process complete');
    } else {
      _showSnackBar('Failed to approve request: ${result['error']}', Colors.red);
      print('>>> ❌ Approval failed: ${result['error']}');
    }
  } catch (e) {
    print('>>> ❌ Error approving deletion request: $e');
    print('>>> Stack trace: ${StackTrace.current}');
    _showSnackBar('Error: $e', Colors.red);
  } finally {
    isProcessing.value = false;
    print('>>> ============================================');
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

    print('>>> ============================================');
    print('>>> CONTROLLER: Rejecting deletion request');
    print('>>> Request ID: ${request.documentId}');
    print('>>> ============================================');

    // CRITICAL: Debug to find the correct admin ID
    await _debugClinicAdminId(request);

    // Step 1: Get the ACTUAL admin ID from the review's clinic
    String? actualAdminId;
    String clinicName = 'Unknown Clinic';
    
    try {
      print('>>> Step 1: Finding actual admin ID...');
      
      // Get the review to find which clinic it belongs to
      final review = await getReview(request.reviewId);
      
      if (review != null) {
        print('>>> Found review, clinic ID: ${review.clinicId}');
        
        // Get the clinic document using the review's clinicId
        final clinic = await authRepository.getClinicById(review.clinicId);
        
        if (clinic != null) {
          actualAdminId = clinic.data['adminId'] as String?;
          clinicName = clinic.data['clinicName'] ?? 'Unknown Clinic';
          
          print('>>> ✅ Found actual admin ID: $actualAdminId');
          print('>>> ✅ Clinic name: $clinicName');
        } else {
          print('>>> ❌ Could not find clinic by ID: ${review.clinicId}');
        }
      } else {
        print('>>> ❌ Could not find review: ${request.reviewId}');
      }
    } catch (e) {
      print('>>> ❌ Error finding admin ID: $e');
    }
    
    // If we couldn't find the admin ID, show error and return
    if (actualAdminId == null || actualAdminId.isEmpty) {
      print('>>> ❌ CRITICAL ERROR: Cannot find admin ID to send notification');
      _showSnackBar(
        'Error: Cannot identify clinic admin to notify. Please check the data.',
        Colors.red,
      );
      return;
    }

    // Step 2: Reject the deletion request
    print('>>> Step 2: Rejecting deletion request...');
    final result = await authRepository.rejectDeletionRequest(
      request.documentId!,
      reviewedBy,
      reviewNotes,
    );

    if (result['success'] == true) {
      print('>>> ✅ Deletion rejected successfully');
      
      // Step 3: Send notification to the CORRECT admin
      try {
        print('>>> Step 3: Sending rejection notification...');
        print('>>> Recipient admin ID: $actualAdminId');
        
        // Build notification message
        final notificationTitle = 'Review Deletion Request Rejected ❌';
        final notificationMessage = reviewNotes != null && reviewNotes.isNotEmpty
            ? 'Your review deletion request has been rejected. Reason: $reviewNotes'
            : 'Your review deletion request for "$clinicName" has been rejected.';
        
        print('>>> Creating notification with:');
        print('>>>   - Title: $notificationTitle');
        print('>>>   - Recipient: $actualAdminId');
        print('>>>   - Clinic Name: $clinicName');
        
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
        
        print('>>> ✅ Rejection notification created successfully');
        
        // Verify notification was created
        final notificationCount = await authRepository.getUnreadNotificationCount(actualAdminId);
        print('>>> Admin now has $notificationCount unread notifications');
        
      } catch (notifError) {
        print('>>> ❌ ERROR sending notification: $notifError');
        print('>>> Stack trace: ${StackTrace.current}');
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
      
      print('>>> ✅ Process complete');
    } else {
      _showSnackBar('Failed to reject request: ${result['error']}', Colors.red);
      print('>>> ❌ Rejection failed: ${result['error']}');
    }
  } catch (e) {
    print('>>> ❌ Error rejecting deletion request: $e');
    print('>>> Stack trace: ${StackTrace.current}');
    _showSnackBar('Error: $e', Colors.red);
  } finally {
    isProcessing.value = false;
    print('>>> ============================================');
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
  print('>>> ============================================');
  print('>>> DEBUGGING CLINIC ADMIN ID');
  print('>>> ============================================');
  print('>>> Request.clinicId (stored): ${request.clinicId}');
  
  // Check what's actually stored in the deletion request
  try {
    final requestDoc = await authRepository.appWriteProvider.databases!.getDocument(
      databaseId: AppwriteConstants.dbID,
      collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
      documentId: request.documentId!,
    );
    
    print('>>> Raw document data:');
    print('>>>   - clinicId field: ${requestDoc.data['clinicId']}');
    print('>>>   - userId field: ${requestDoc.data['userId']}');
    print('>>>   - requestedBy field: ${requestDoc.data['requestedBy']}');
  } catch (e) {
    print('>>> Error fetching request document: $e');
  }
  
  // Try to find the clinic by adminId
  try {
    print('>>> Attempting to find clinic by adminId: ${request.clinicId}');
    final clinicByAdmin = await authRepository.getClinicByAdminId(request.clinicId);
    
    if (clinicByAdmin != null) {
      print('>>> ✅ Found clinic by adminId:');
      print('>>>   - Clinic Name: ${clinicByAdmin.data['clinicName']}');
      print('>>>   - Clinic Doc ID: ${clinicByAdmin.$id}');
      print('>>>   - Admin ID: ${clinicByAdmin.data['adminId']}');
    } else {
      print('>>> ❌ No clinic found by adminId: ${request.clinicId}');
    }
  } catch (e) {
    print('>>> Error finding clinic by adminId: $e');
  }
  
  // Try to find the clinic by document ID
  try {
    print('>>> Attempting to find clinic by document ID: ${request.clinicId}');
    final clinicByDocId = await authRepository.getClinicById(request.clinicId);
    
    if (clinicByDocId != null) {
      print('>>> ✅ Found clinic by document ID:');
      print('>>>   - Clinic Name: ${clinicByDocId.data['clinicName']}');
      print('>>>   - Admin ID: ${clinicByDocId.data['adminId']}');
    } else {
      print('>>> ❌ No clinic found by document ID: ${request.clinicId}');
    }
  } catch (e) {
    print('>>> Error finding clinic by document ID: $e');
  }
  
  // Check the review to see which clinic it belongs to
  try {
    print('>>> Checking review for clinic information...');
    final review = await getReview(request.reviewId);
    
    if (review != null) {
      print('>>> ✅ Found review:');
      print('>>>   - Review Clinic ID: ${review.clinicId}');
      
      // Try to get clinic by review's clinicId
      final reviewClinic = await authRepository.getClinicById(review.clinicId);
      if (reviewClinic != null) {
        print('>>> ✅ Found clinic from review:');
        print('>>>   - Clinic Name: ${reviewClinic.data['clinicName']}');
        print('>>>   - Admin ID: ${reviewClinic.data['adminId']}');
        print('>>> ✅✅✅ THIS IS THE CORRECT ADMIN ID TO USE: ${reviewClinic.data['adminId']}');
      }
    }
  } catch (e) {
    print('>>> Error checking review: $e');
  }
  
  print('>>> ============================================');
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
// import 'package:appwrite/appwrite.dart';
// import 'package:get/get.dart';
// import 'package:capstone_app/data/models/feedback_deletion_request_model.dart';
// import 'package:capstone_app/data/models/ratings_and_review_model.dart';
// import 'package:capstone_app/data/repository/auth.repository.dart';
// import 'package:capstone_app/utils/appwrite_constant.dart';
// import 'package:flutter/material.dart';

// class VetDeletionRequestController extends GetxController {
//   final AuthRepository authRepository;

//   VetDeletionRequestController({required this.authRepository});

//   // Observable lists
//   var allRequests = <FeedbackDeletionRequest>[].obs;
//   var filteredRequests = <FeedbackDeletionRequest>[].obs;

//   // Cache for reviews (to display review content)
//   var reviewsCache = <String, RatingAndReview>{}.obs;

//   // Cache for clinic names
//   var clinicNamesCache = <String, String>{}.obs;

//   // Loading states
//   var isLoading = false.obs;
//   var isProcessing = false.obs;

//   // Filter states
//   var selectedStatus = 'All'.obs;
//   var selectedReason = 'All'.obs;
//   var searchQuery = ''.obs;

//   // Statistics
//   var stats = <String, int>{}.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     loadAllDeletionRequests();
//   }

//   /// Load all deletion requests from all clinics
//   Future<void> loadAllDeletionRequests() async {
//     try {
//       isLoading.value = true;
//       print('>>> ============================================');
//       print('>>> LOADING ALL DELETION REQUESTS');
//       print('>>> ============================================');

//       // CHANGE: Get ALL deletion requests first (not filtered by clinic)
//       final allDeletionRequestDocs =
//           await authRepository.appWriteProvider.databases!.listDocuments(
//         databaseId: AppwriteConstants.dbID,
//         collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
//         queries: [
//           Query.orderDesc('requestedAt'),
//           Query.limit(500),
//         ],
//       );

//       print(
//           '>>> Found ${allDeletionRequestDocs.documents.length} total deletion requests');

//       if (allDeletionRequestDocs.documents.isEmpty) {
//         print('>>> No deletion requests found in database');
//         allRequests.value = [];
//         filterRequests();
//         calculateStatistics();
//         isLoading.value = false;
//         return;
//       }

//       // Get all clinics to map adminId to clinic
//       final clinics = await authRepository.getAllClinics();
//       print('>>> Found ${clinics.length} clinics');

//       // Create a map: adminId -> Clinic
//       final Map<String, dynamic> adminIdToClinicMap = {};
//       for (var clinic in clinics) {
//         adminIdToClinicMap[clinic.adminId] = {
//           'documentId': clinic.documentId,
//           'clinicName': clinic.clinicName,
//         };
//         print(
//             '>>> Mapped Admin ID ${clinic.adminId} to Clinic: ${clinic.clinicName}');
//       }

//       List<FeedbackDeletionRequest> allRequestsTemp = [];

//       // Process each deletion request
//       for (var doc in allDeletionRequestDocs.documents) {
//         try {
//           final request = FeedbackDeletionRequest.fromMap(doc.data);
//           final requestWithId = request.copyWith(documentId: doc.$id);

//           // The "clinicId" field in FeedbackDeletionRequest is actually the adminId
//           final adminId = requestWithId.clinicId;

//           print('>>> Processing deletion request ${doc.$id}');
//           print('>>>   - AdminId (stored as clinicId): $adminId');
//           print('>>>   - Reason: ${requestWithId.reason}');
//           print('>>>   - Status: ${requestWithId.status}');

//           // Check if we have a clinic for this admin
//           if (adminIdToClinicMap.containsKey(adminId)) {
//             final clinicInfo = adminIdToClinicMap[adminId];
//             final actualClinicDocId = clinicInfo['documentId'];
//             final clinicName = clinicInfo['clinicName'];

//             print(
//                 '>>>   ✅ Found clinic: $clinicName (Doc ID: $actualClinicDocId)');

//             // Cache the clinic name using the ADMIN ID (which is stored as clinicId)
//             clinicNamesCache[adminId] = clinicName;

//             // Also cache using the actual clinic document ID for flexibility
//             clinicNamesCache[actualClinicDocId] = clinicName;

//             allRequestsTemp.add(requestWithId);

//             // Fetch and cache the review
//             await _fetchAndCacheReview(requestWithId.reviewId);
//           } else {
//             print('>>>   ⚠️ WARNING: No clinic found for admin ID: $adminId');
//             // Still add the request but mark clinic as unknown
//             clinicNamesCache[adminId] = 'Unknown Clinic';
//             allRequestsTemp.add(requestWithId);
//           }
//         } catch (e) {
//           print('>>>   ❌ Error processing deletion request ${doc.$id}: $e');
//         }
//       }

//       allRequests.value = allRequestsTemp;
//       print('>>> ============================================');
//       print('>>> ✅ Total deletion requests loaded: ${allRequests.length}');
//       print('>>> ============================================');

//       filterRequests();
//       calculateStatistics();
//     } catch (e, stackTrace) {
//       print('>>> ============================================');
//       print('>>> ❌ ERROR LOADING DELETION REQUESTS: $e');
//       print('>>> Stack trace: $stackTrace');
//       print('>>> ============================================');
//       _showSnackBar('Failed to load deletion requests: $e', Colors.red);
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Fetch and cache a review by ID
//   Future<void> _fetchAndCacheReview(String reviewId) async {
//     try {
//       if (reviewsCache.containsKey(reviewId)) {
//         print('>>> Review $reviewId already cached');
//         return;
//       }

//       print('>>> Fetching review: $reviewId');

//       // Fetch review from ratings collection using reviewId as documentId
//       final reviewDoc =
//           await authRepository.appWriteProvider.databases!.getDocument(
//         databaseId: AppwriteConstants.dbID,
//         collectionId: AppwriteConstants.ratingsAndReviewsCollectionID,
//         documentId: reviewId,
//       );

//       if (reviewDoc != null) {
//         final review = RatingAndReview.fromMap(reviewDoc.data);
//         reviewsCache[reviewId] = review.copyWith(documentId: reviewDoc.$id);
//         print('>>> Review cached: ${review.userName} - ${review.rating} stars');
//       }
//     } catch (e) {
//       print('>>> Warning: Could not fetch review $reviewId: $e');
//       // Don't fail the entire operation if one review fetch fails
//     }
//   }

//   /// Get cached review or fetch it
//   Future<RatingAndReview?> getReview(String reviewId) async {
//     if (reviewsCache.containsKey(reviewId)) {
//       return reviewsCache[reviewId];
//     }

//     await _fetchAndCacheReview(reviewId);
//     return reviewsCache[reviewId];
//   }

//   /// Filter requests based on search, status, and reason
//   void filterRequests() {
//     filteredRequests.value = allRequests.where((request) {
//       // Search filter - search in reason, clinic name, and cached review content
//       bool matchesSearch = searchQuery.value.isEmpty ||
//           request.reason
//               .toLowerCase()
//               .contains(searchQuery.value.toLowerCase()) ||
//           (clinicNamesCache[request.clinicId] ?? '')
//               .toLowerCase()
//               .contains(searchQuery.value.toLowerCase()) ||
//           request.requestedBy
//               .toLowerCase()
//               .contains(searchQuery.value.toLowerCase()) ||
//           // Also search in review content if cached
//           (reviewsCache[request.reviewId]?.reviewText ?? '')
//               .toLowerCase()
//               .contains(searchQuery.value.toLowerCase());

//       // Status filter
//       bool matchesStatus = selectedStatus.value == 'All' ||
//           request.status.toLowerCase() == selectedStatus.value.toLowerCase();

//       // Reason filter
//       bool matchesReason = selectedReason.value == 'All' ||
//           request.reason == selectedReason.value;

//       return matchesSearch && matchesStatus && matchesReason;
//     }).toList();

//     // Sort by date (newest first)
//     filteredRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

//     print('>>> Filtered to ${filteredRequests.length} requests');
//   }

//   /// Calculate statistics
//   void calculateStatistics() {
//     stats.value = {
//       'total': allRequests.length,
//       'pending': allRequests.where((r) => r.status == 'pending').length,
//       'approved': allRequests.where((r) => r.status == 'approved').length,
//       'rejected': allRequests.where((r) => r.status == 'rejected').length,
//     };

//     print('>>> Stats: ${stats.value}');
//   }

//   /// Update search query
//   void updateSearchQuery(String query) {
//     searchQuery.value = query.toLowerCase();
//     filterRequests();
//   }

//   /// Update status filter
//   void updateStatusFilter(String status) {
//     selectedStatus.value = status;
//     filterRequests();
//   }

//   /// Update reason filter
//   void updateReasonFilter(String reason) {
//     selectedReason.value = reason;
//     filterRequests();
//   }

//   /// Approve deletion request
//   Future<void> approveDeletionRequest(
//     FeedbackDeletionRequest request,
//     String reviewedBy,
//     String? reviewNotes,
//   ) async {
//     try {
//       isProcessing.value = true;

//       print('>>> Approving deletion request: ${request.documentId}');

//       final result = await authRepository.approveDeletionRequest(
//         request.documentId!,
//         request.reviewId,
//         reviewedBy,
//         reviewNotes,
//       );

//       if (result['success'] == true) {
//         _showSnackBar('Deletion request approved successfully', Colors.green);

//         // Remove the cached review since it's now archived
//         reviewsCache.remove(request.reviewId);

//         await loadAllDeletionRequests(); // Reload data
//       } else {
//         _showSnackBar(
//             'Failed to approve request: ${result['error']}', Colors.red);
//       }
//     } catch (e) {
//       print('>>> Error approving deletion request: $e');
//       _showSnackBar('Error: $e', Colors.red);
//     } finally {
//       isProcessing.value = false;
//     }
//   }

//   /// Reject deletion request
//   Future<void> rejectDeletionRequest(
//     FeedbackDeletionRequest request,
//     String reviewedBy,
//     String? reviewNotes,
//   ) async {
//     try {
//       isProcessing.value = true;

//       print('>>> Rejecting deletion request: ${request.documentId}');

//       final result = await authRepository.rejectDeletionRequest(
//         request.documentId!,
//         reviewedBy,
//         reviewNotes,
//       );

//       if (result['success'] == true) {
//         _showSnackBar('Deletion request rejected', Colors.orange);
//         await loadAllDeletionRequests(); // Reload data
//       } else {
//         _showSnackBar(
//             'Failed to reject request: ${result['error']}', Colors.red);
//       }
//     } catch (e) {
//       print('>>> Error rejecting deletion request: $e');
//       _showSnackBar('Error: $e', Colors.red);
//     } finally {
//       isProcessing.value = false;
//     }
//   }

//   /// Delete a processed request (approved/rejected)
//   Future<void> deleteProcessedRequest(FeedbackDeletionRequest request) async {
//     try {
//       isProcessing.value = true;

//       print('>>> Deleting processed request: ${request.documentId}');

//       // Delete the deletion request document
//       await authRepository.appWriteProvider.databases!.deleteDocument(
//         databaseId: AppwriteConstants.dbID,
//         collectionId: AppwriteConstants.feedbackDeletionRequestCollectionID,
//         documentId: request.documentId!,
//       );

//       allRequests.removeWhere((r) => r.documentId == request.documentId);
//       filterRequests();
//       calculateStatistics();

//       _showSnackBar('Request deleted successfully', Colors.green);
//     } catch (e) {
//       print('>>> Error deleting request: $e');
//       _showSnackBar('Error: $e', Colors.red);
//     } finally {
//       isProcessing.value = false;
//     }
//   }

//   /// Get clinic name by ID (handles both adminId and clinicDocumentId)
//   Future<String> getClinicName(String id) async {
//     // Check cache first (works for both adminId and clinicDocId)
//     if (clinicNamesCache.containsKey(id)) {
//       return clinicNamesCache[id]!;
//     }

//     print('>>> Getting clinic name for ID: $id');

//     // Try to find clinic by adminId FIRST (since that's what's stored)
//     try {
//       final clinic = await authRepository.getClinicByAdminId(id);
//       if (clinic != null) {
//         final name = clinic.data['clinicName'] ?? 'Unknown Clinic';
//         clinicNamesCache[id] = name;
//         print('>>> Found clinic by adminId: $name');
//         return name;
//       }
//     } catch (e) {
//       print('>>> Not found by adminId, trying as clinic document ID...');
//     }

//     // If not found by adminId, try by document ID
//     try {
//       final clinic = await authRepository.getClinicById(id);
//       if (clinic != null) {
//         final name = clinic.data['clinicName'] ?? 'Unknown Clinic';
//         clinicNamesCache[id] = name;
//         print('>>> Found clinic by document ID: $name');
//         return name;
//       }
//     } catch (e) {
//       print('>>> Error fetching clinic by document ID: $e');
//     }

//     print('>>> Could not find clinic for ID: $id');
//     return 'Unknown Clinic';
//   }

//   void _showSnackBar(String message, Color color) {
//     Get.snackbar(
//       color == Colors.red ? 'Error' : 'Success',
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: color,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 3),
//     );
//   }

//   @override
//   void onClose() {
//     // Clear caches
//     reviewsCache.clear();
//     clinicNamesCache.clear();
//     super.onClose();
//   }
// }
