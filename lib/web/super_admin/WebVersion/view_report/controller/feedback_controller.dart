import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AdminFeedbackController extends GetxController {
  final AuthRepository authRepository;
  final GetStorage _storage = GetStorage();

  AdminFeedbackController(this.authRepository);
  final isLoadingFeedback = false.obs;
  final RxList<FeedbackAndReport> allFeedback = <FeedbackAndReport>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Track pinned feedback IDs in memory for quick access
  final RxSet<String> pinnedFeedbackIds = <String>{}.obs;


  @override
  void onInit() {
    super.onInit();
    _runMigration();
    loadAllFeedback();
  }

  Future<void> _runMigration() async {
    try {
      await Get.find<AppWriteProvider>().migrateFeedbackPinFields();
    } catch (e) {
      print('Migration error: $e');
    }
  }

  Future<void> updateStatus(String documentId, FeedbackStatus newStatus) async {
  try {
    isLoading.value = true;
    
    await authRepository.updateFeedbackStatus(documentId, newStatus);
    
    // Update local state
    final index = allFeedback.indexWhere((f) => f.documentId == documentId);
    if (index != -1) {
      allFeedback[index] = allFeedback[index].copyWith(status: newStatus);
      allFeedback.refresh();
    }
    
    // Reload to get fresh data
    await loadAllFeedback();
    
    Get.snackbar(
      'Success',
      'Feedback status updated to ${newStatus.displayName}',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
    );
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to update status: $e',
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
    );
  } finally {
    isLoading.value = false;
  }
}

Future<void> addReply(String documentId, String reply) async {
  try {
    final adminName = GetStorage().read('name') ?? 'Admin';
    
    await authRepository.addFeedbackReply(
      documentId,
      reply,
      adminName,
    );
    
    await loadAllFeedback();
    
    Get.snackbar(
      'Success',
      'Reply added successfully',
      duration: const Duration(seconds: 2),
    );
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to add reply: $e',
      duration: const Duration(seconds: 3),
    );
  }
}

  Future<void> loadAllFeedback() async {
    try {
      isLoadingFeedback.value = true;
      errorMessage.value = '';

      final feedbackList = await authRepository.getAllFeedback(limit: 500);
     
      // 🔥 ENHANCED SORTING: Pinned first, then by date (newest first)
      feedbackList.sort((a, b) {
        // 1. Pinned items always come first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        // 2. If both pinned or both not pinned, sort by date
        if (a.submittedAt == null && b.submittedAt == null) return 0;
        if (a.submittedAt == null) return 1;
        if (b.submittedAt == null) return -1;

        return b.submittedAt.compareTo(a.submittedAt);
      });

      allFeedback.value = feedbackList;

      // Update pinned IDs
      pinnedFeedbackIds.value = feedbackList
          .where((f) => f.isPinned)
          .map((f) => f.documentId!)
          .toSet();
    } catch (e) {
      errorMessage.value = 'Error loading feedback: $e';
    } finally {
      isLoadingFeedback.value = false; 
    }
  }

  /// Toggle pin status with database persistence
  Future<void> togglePin(String feedbackId) async {
    try {
      print('>>> Toggling pin for feedback: $feedbackId');

      // Find the feedback item
      final feedbackIndex =
          allFeedback.indexWhere((f) => f.documentId == feedbackId);

      if (feedbackIndex == -1) {
        print('>>> Error: Feedback not found');
        return;
      }

      final feedback = allFeedback[feedbackIndex];
      final newPinStatus = !feedback.isPinned;

      // Get current admin/user info
      final userId = _storage.read('userId') ?? '';
      final userName = _storage.read('name') ?? 'System';

      print('>>> New pin status: $newPinStatus');
      print('>>> Pinned by: $userName');

      // Update in database
      await authRepository.toggleFeedbackPin(
        feedbackId,
        newPinStatus,
        userName,
      );

      // Update local state
      if (newPinStatus) {
        pinnedFeedbackIds.add(feedbackId);
      } else {
        pinnedFeedbackIds.remove(feedbackId);
      }

      // Update the feedback object
      allFeedback[feedbackIndex] = feedback.copyWith(
        isPinned: newPinStatus,
        pinnedAt: newPinStatus ? DateTime.now() : null,
        pinnedBy: newPinStatus ? userName : null,
      );

      allFeedback.refresh();

      Get.snackbar(
        newPinStatus ? 'Pinned' : 'Unpinned',
        newPinStatus
            ? 'Feedback pinned successfully'
            : 'Feedback unpinned successfully',
        duration: const Duration(seconds: 2),
      );

      print('>>> Pin toggle successful');
    } catch (e) {
      print('>>> Error toggling pin: $e');
      Get.snackbar(
        'Error',
        'Failed to toggle pin: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Archive feedback with confirmation
Future<void> archiveFeedback(String documentId) async {
  try {
    isLoading.value = true;
    
    // Get current admin/user info
    final userName = _storage.read('name') ?? 'System';
    
    print('>>> Archiving feedback: $documentId by $userName');
    
    await authRepository.archiveFeedback(documentId, userName);
    
    // Remove from local list
    allFeedback.removeWhere((f) => f.documentId == documentId);
    
    // Remove from pinned IDs if it was pinned
    pinnedFeedbackIds.remove(documentId);
    
    allFeedback.refresh();
    
    Get.snackbar(
      'Success',
      'Feedback archived successfully',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
      icon: const Icon(Icons.archive, color: Colors.green),
    );
    
    print('>>> Archive successful');
  } catch (e) {
    print('>>> Error archiving feedback: $e');
    Get.snackbar(
      'Error',
      'Failed to archive feedback: $e',
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      icon: const Icon(Icons.error, color: Colors.red),
    );
  } finally {
    isLoading.value = false;
  }
}

/// Delete feedback permanently
Future<void> deleteFeedback(String documentId, List<String> attachmentIds) async {
  try {
    isLoading.value = true;
    
    print('>>> Deleting feedback permanently: $documentId');
    
    await authRepository.deleteFeedback(documentId, attachmentIds);
    
    // Remove from local list
    allFeedback.removeWhere((f) => f.documentId == documentId);
    pinnedFeedbackIds.remove(documentId);
    
    allFeedback.refresh();
    
    Get.snackbar(
      'Success',
      'Feedback deleted permanently',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[900],
      icon: const Icon(Icons.delete_forever, color: Colors.orange),
    );
    
    print('>>> Delete successful');
  } catch (e) {
    print('>>> Error deleting feedback: $e');
    Get.snackbar(
      'Error',
      'Failed to delete feedback: $e',
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
    );
  } finally {
    isLoading.value = false;
  }
}




  /// Check if feedback is pinned
  bool isPinned(String feedbackId) {
    return pinnedFeedbackIds.contains(feedbackId);
  }

  /// Get pinned feedback (sorted by pinnedAt)
  List<FeedbackAndReport> get pinnedFeedback {
    final pinned = allFeedback.where((f) => f.isPinned).toList();

    // Sort by pinnedAt (most recent first)
    pinned.sort((a, b) {
      if (a.pinnedAt == null && b.pinnedAt == null) return 0;
      if (a.pinnedAt == null) return 1;
      if (b.pinnedAt == null) return -1;
      return b.pinnedAt!.compareTo(a.pinnedAt!);
    });

    return pinned;
  }

  /// Get unpinned feedback
  List<FeedbackAndReport> get unpinnedFeedback {
    return allFeedback.where((f) => !f.isPinned).toList();
  }

  /// Get sorted feedback (pinned first, then by date)
  List<FeedbackAndReport> get sortedFeedback {
    final pinned = pinnedFeedback;
    final unpinned = unpinnedFeedback;

    // Sort unpinned by submission date (newest first)
    unpinned.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return [...pinned, ...unpinned];
  }
}
