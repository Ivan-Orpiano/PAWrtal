import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/daily_report_tracker_model.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/utils/feedback_spam_detector.dart';

class WebFeedbackController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  WebFeedbackController({
    required this.authRepository,
    required this.session,
  });
  

  final Rx<UserDailyReportTracker?> dailyTracker =
      Rx<UserDailyReportTracker?>(null);
  final RxBool isCheckingLimit = false.obs;

  // User-side properties
  RxList<PlatformFile> selectedFiles = <PlatformFile>[].obs;
  RxBool isSubmitting = false.obs;
  Rx<FeedbackType> selectedType = FeedbackType.bug.obs;
  Rx<FeedbackCategory> selectedCategory = FeedbackCategory.other.obs;
  RxString subject = ''.obs;
  RxString description = ''.obs;

  // Admin-side properties
  RxList<FeedbackAndReport> allFeedback = <FeedbackAndReport>[].obs;
  RxList<FeedbackAndReport> filteredFeedback = <FeedbackAndReport>[].obs;
  RxBool isLoadingFeedback = false.obs;
  final Rxn<FeedbackStatus> statusFilter = Rxn<FeedbackStatus>();
  final Rxn<FeedbackType> typeFilter = Rxn<FeedbackType>();
  final Rxn<FeedbackCategory> categoryFilter = Rxn<FeedbackCategory>();
  final Rxn<Priority> priorityFilter = Rxn<Priority>();
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  final RxInt spamDetectedCount = 0.obs;
  final RxInt autoArchivedCount = 0.obs;
  final RxBool isCleaningSpam = false.obs;

  StreamSubscription<RealtimeMessage>? _feedbackSubscription;

  Timer? _autoRefreshTimer;

  // Pinned feedback IDs
  final RxSet<String> pinnedFeedbackIds = <String>{}.obs;

  /// Toggle pin status
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
      final userName =
          session.userName.isNotEmpty ? session.userName : 'System';

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

      _showSuccess(newPinStatus ? 'Pinned' : 'Unpinned');

      print('>>> Pin toggle successful');
    } catch (e) {
      print('>>> Error toggling pin: $e');
      _showError('Failed to toggle pin');
    }
  }

  // Check if feedback is pinned
  bool isPinned(String feedbackId) {
    return pinnedFeedbackIds.contains(feedbackId);
  }

  // Statistics
  RxMap<String, int> feedbackStats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Only load feedback if user is admin/staff
    final role = session.userRole;
    if (role == 'admin' || role == 'staff') {
      loadAllFeedback();
      _loadDailyReportTracker();

      //Auto-clean spam
      Future.delayed(const Duration(seconds: 2), () {
        autoCleanSpamFeedback();
      });

      _setupRealtimeFeedbackSubscription();

      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        filterFeedback(); // Re-sort with updated time calculations
      });
    }
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
     _feedbackSubscription?.cancel(); 
    super.onClose();
  }


  /// Setup real-time subscription for feedback changes
void _setupRealtimeFeedbackSubscription() {
  try {
    print('>>> Setting up real-time feedback subscription...');
    
    _feedbackSubscription = authRepository.appWriteProvider
        .subscribeToFeedbackChanges()
        .listen((event) {
      print('>>> ============================================');
      print('>>> REAL-TIME FEEDBACK EVENT RECEIVED');
      print('>>> Event type: ${event.events}');
      print('>>> ============================================');

      // Handle different event types
      if (event.events.contains('databases.*.collections.*.documents.*.create')) {
        print('>>> New feedback created');
        _handleFeedbackCreated(event);
      } else if (event.events.contains('databases.*.collections.*.documents.*.update')) {
        print('>>> Feedback updated');
        _handleFeedbackUpdated(event);
      } else if (event.events.contains('databases.*.collections.*.documents.*.delete')) {
        print('>>> Feedback deleted');
        _handleFeedbackDeleted(event);
      }
    }, onError: (error) {
      print('>>> Real-time subscription error: $error');
    });

    print('>>> Real-time subscription active');
  } catch (e) {
    print('>>> Error setting up real-time subscription: $e');
  }
}

/// Handle feedback created event
void _handleFeedbackCreated(RealtimeMessage event) {
  try {
    final feedbackData = event.payload;
    final feedback = FeedbackAndReport.fromMap(feedbackData);
    
    // Add to list if not already present
    if (!allFeedback.any((f) => f.documentId == feedback.documentId)) {
      allFeedback.insert(0, feedback);
      
      // Update pinned IDs if it's pinned
      if (feedback.isPinned) {
        pinnedFeedbackIds.add(feedback.documentId!);
        print('>>> ✅ New pinned feedback added: ${feedback.documentId}');
      }
      
      // Re-apply filters and update stats
      filterFeedback();
      updateStatistics();
      
      print('>>> ✅ New feedback added to local list');
    }
  } catch (e) {
    print('>>> Error handling feedback created: $e');
  }
}

/// Handle feedback updated event
void _handleFeedbackUpdated(RealtimeMessage event) {
  try {
    final feedbackData = event.payload;
    final updatedFeedback = FeedbackAndReport.fromMap(feedbackData);
    
    // Find and update existing feedback
    final index = allFeedback.indexWhere(
      (f) => f.documentId == updatedFeedback.documentId,
    );
    
    if (index != -1) {
      final oldFeedback = allFeedback[index];
      allFeedback[index] = updatedFeedback;
      
      // CRITICAL: Handle pin status change
      if (oldFeedback.isPinned != updatedFeedback.isPinned) {
        if (updatedFeedback.isPinned) {
          // Feedback was just pinned
          pinnedFeedbackIds.add(updatedFeedback.documentId!);
          print('>>> 📌 Feedback pinned: ${updatedFeedback.documentId}');
        } else {
          // Feedback was just unpinned
          pinnedFeedbackIds.remove(updatedFeedback.documentId!);
          print('>>> 📍 Feedback unpinned: ${updatedFeedback.documentId}');
        }
      }
      
      // Handle archive status change
      if (!oldFeedback.isArchived && updatedFeedback.isArchived) {
        // Feedback was archived - remove from both lists
        allFeedback.removeAt(index);
        filteredFeedback.removeWhere((f) => f.documentId == updatedFeedback.documentId);
        pinnedFeedbackIds.remove(updatedFeedback.documentId);
        print('>>> 🗄️ Feedback archived and removed: ${updatedFeedback.documentId}');
      }
      // Force refresh
      allFeedback.refresh();
      // Re-apply filters and update stats
      filterFeedback();
      updateStatistics();
    }
  } catch (e) {
  }
}

/// Handle feedback deleted event
void _handleFeedbackDeleted(RealtimeMessage event) {
  try {
    final documentId = event.payload['\$id'];
    
    // Remove from all lists
    allFeedback.removeWhere((f) => f.documentId == documentId);
    filteredFeedback.removeWhere((f) => f.documentId == documentId);
    pinnedFeedbackIds.remove(documentId);
    
    // Force refresh
    allFeedback.refresh();
    filteredFeedback.refresh();
    
    // Re-apply filters and update stats
    filterFeedback();
    updateStatistics();
  } catch (e) {
  }
}

  Future<void> _loadDailyReportTracker() async {
    try {
      isCheckingLimit.value = true;

      final userId = session.userId;
      if (userId.isEmpty) {

        return;
      }

      print('>>> Loading daily report tracker for user: $userId');

      // Get user's feedback submissions from last 24 hours
      final allFeedback = await authRepository.getUserFeedback(userId);

      final now = DateTime.now();
      final last24Hours = now.subtract(Duration(hours: 24));

      // Count reports in last 24 hours
      final recentReports = allFeedback.where((feedback) {
        return feedback.submittedAt.isAfter(last24Hours);
      }).toList();

      print('>>> Found ${recentReports.length} reports in last 24 hours');

      // Find the oldest report timestamp to use as reset time
      DateTime lastResetAt = now.subtract(Duration(hours: 24));
      DateTime? lastReportAt;

      if (recentReports.isNotEmpty) {
        // Sort by submission time
        recentReports.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
        lastResetAt = recentReports.first.submittedAt;
        lastReportAt = recentReports.last.submittedAt;
      }

      // Create tracker
      final tracker = UserDailyReportTracker(
        userId: userId,
        reportCount: recentReports.length,
        lastResetAt: lastResetAt,
        lastReportAt: lastReportAt ?? now,
      );

      // Check if needs reset
      if (tracker.needsReset) {
        print('>>> Tracker needs reset (>24 hours old)');
        dailyTracker.value = tracker.reset();
      } else {
        dailyTracker.value = tracker;
      }

      print('>>> Daily tracker loaded:');
      print('>>>   Reports today: ${dailyTracker.value!.reportCount}/3');
      print('>>>   Remaining: ${dailyTracker.value!.remainingReports}');
      print(
          '>>>   Time until reset: ${_formatDuration(dailyTracker.value!.timeUntilReset)}');
    } catch (e) {
      print('>>> Error loading daily tracker: $e');
    } finally {
      isCheckingLimit.value = false;
    }
  }

  bool canSubmitFeedback() {
    if (dailyTracker.value == null) {
      print('>>> No tracker loaded, allowing submission');
      return true;
    }

    // Check if needs reset first
    if (dailyTracker.value!.needsReset) {
      print('>>> Tracker needs reset, resetting now...');
      dailyTracker.value = dailyTracker.value!.reset();
      return true;
    }

    final canSubmit = !dailyTracker.value!.hasExceededLimit;

    if (!canSubmit) {
      print('>>> Daily limit exceeded: ${dailyTracker.value!.reportCount}/3');
      print(
          '>>> Time until reset: ${_formatDuration(dailyTracker.value!.timeUntilReset)}');
    }

    return canSubmit;
  }

  /// Get remaining reports count
  int getRemainingReports() {
    if (dailyTracker.value == null) return 3;

    if (dailyTracker.value!.needsReset) {
      return 3;
    }

    return dailyTracker.value!.remainingReports;
  }

  /// Get time until reset as formatted string
  String getTimeUntilReset() {
    if (dailyTracker.value == null) return 'N/A';

    if (dailyTracker.value!.needsReset) {
      return 'Ready to reset';
    }

    return _formatDuration(dailyTracker.value!.timeUntilReset);
  }

  /// Format duration to readable string
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Less than 1 minute';
    }
  }
  // ============= NOTIFICATION HELPER =============

  /// Show compact toast notification at top right
  void _showCompactNotification(String message,
      {required Color bgColor,
      required IconData icon,
      required Color iconColor}) {
    Get.rawSnackbar(
      messageText: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      snackPosition: SnackPosition.TOP,
      borderRadius: 4,
      margin: const EdgeInsets.only(top: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      maxWidth: 300,
    );
  }

  void _showSuccess(String message) {
    _showCompactNotification(message,
        bgColor: Colors.green[600]!,
        icon: Icons.check_circle_outline,
        iconColor: Colors.white);
  }

  void _showError(String message) {
    _showCompactNotification(message,
        bgColor: Colors.red[600]!,
        icon: Icons.error_outline,
        iconColor: Colors.white);
  }

  void _showInfo(String message) {
    _showCompactNotification(message,
        bgColor: Colors.blue[600]!,
        icon: Icons.info_outline,
        iconColor: Colors.white);
  }

  void _showWarning(String message) {
    _showCompactNotification(message,
        bgColor: Colors.amber[700]!,
        icon: Icons.warning_amber,
        iconColor: Colors.white);
  }

  // ============= USER-SIDE METHODS =============

 /// Validate file before adding (IMAGES ONLY - NO VIDEOS)
bool _validateFile(PlatformFile file) {
  final extension = file.extension?.toLowerCase() ?? '';

  // ✅ ONLY ALLOW IMAGES (VIDEOS REMOVED)
  final isImage =
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);

  if (!isImage) {
    _showError(
        "Only image files are allowed (JPG, PNG, GIF, WEBP, BMP)");
    return false;
  }

  // Check file size limit (5MB for images)
  if (file.size > 5 * 1024 * 1024) {
    _showError(
        "Image files must be under 5MB (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB)");
    return false;
  }

  return true;
}
  /// Pick files (images/videos)
  Future<void> pickFiles() async {
     if (selectedFiles.length >= 5) {
      _showError("You can only attach up to 5 images");
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp'
        ],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (selectedFiles.length >= 5) {
            _showWarning("Maximum 5 files allowed. Remaining files not added.");
            break;
          }

          if (_validateFile(file)) {
            selectedFiles.add(file);
          }
        }
      }
    } catch (e) {
      _showError("Failed to pick files: $e");
    }
  }

  /// Remove a file from selection
  void removeFile(PlatformFile file) {
    selectedFiles.remove(file);
  }

  /// Clear all selected files
  void clearFiles() {
    selectedFiles.clear();
  }

  /// Get file icon based on extension
 String getFileIcon(String? extension) {
  final ext = extension?.toLowerCase() ?? '';
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
    return '🖼️';
  }
  return '📄'; // Fallback (shouldn't happen with image-only validation)
}

  /// Get file size in readable format
  String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validate feedback form
  bool validateForm() {
    if (subject.value.trim().isEmpty) {
      _showError("Please enter a subject");
      return false;
    }

    if (subject.value.trim().length < 5) {
      _showError("Subject must be at least 5 characters long");
      return false;
    }

    if (description.value.trim().isEmpty) {
      _showError("Please provide details about your feedback");
      return false;
    }

    if (description.value.trim().length < 20) {
      _showError("Please provide at least 20 characters of description");
      return false;
    }

    // REMOVED: Attachment requirement check
    // Attachments are now OPTIONAL

    return true;
  }

  /// Submit feedback
  Future<bool> submitFeedback() async {
    if (!canSubmitFeedback()) {
      _showError(
          'Daily limit reached (3/3). You can submit again in ${getTimeUntilReset()}.');
      return false;
    }
    if (!validateForm()) return false;
    isSubmitting.value = true;

    try {
      // Get user information
      final userId = session.userId;
      final userName = session.userName;
      final userEmail = session.userEmail;

      print('=== SUBMITTING FEEDBACK ===');
      print('User ID: $userId');
      print('User Name: $userName');
      print('User Email: $userEmail');
      print('Subject: ${subject.value}');
      print('Description: ${description.value}');
      print('Type: ${selectedType.value}');
      print('Category: ${selectedCategory.value}');
      print('Files: ${selectedFiles.length}');

      if (userId.isEmpty) {
        _showError("User session data is missing. Please log in again.");
        isSubmitting.value = false;
        return false;
      }

      List<String> attachmentIds = [];

      // Upload attachments if provided
      if (selectedFiles.isNotEmpty) {
        _showInfo("Uploading ${selectedFiles.length} file(s)...");
        final uploadedFiles =
            await authRepository.uploadFeedbackAttachments(selectedFiles);
        attachmentIds = uploadedFiles.map((f) => f.$id).toList();
      }

      final platform = 'web';
      final appVersion = '1.0.0';
      final deviceInfo = 'Web Browser';
      final now = DateTime.now();

      final feedback = FeedbackAndReport(
        userId: userId,
        userName: userName.isNotEmpty ? userName : 'Unknown User',
        userEmail: userEmail.isNotEmpty ? userEmail : 'unknown@email.com',
        feedbackType: selectedType.value,
        category: selectedCategory.value,
        subject: subject.value.trim(),
        description: description.value.trim(),
        attachments: attachmentIds,
        priority: Priority.medium,
        status: FeedbackStatus.pending,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
        platform: platform,
        submittedAt: now,
      );

      // Submit to database
      final createdFeedback =
          await authRepository.createFeedbackAndReport(feedback);

      print('Feedback created successfully: ${createdFeedback.documentId}');

      // STEP 3: Update daily tracker AFTER successful submission
      if (dailyTracker.value != null) {
        dailyTracker.value = dailyTracker.value!.incrementCount();
        print(
            '>>> Updated tracker: ${dailyTracker.value!.reportCount}/3 reports');
      } else {
        // Create new tracker if doesn't exist
        dailyTracker.value = UserDailyReportTracker(
          userId: userId,
          reportCount: 1,
          lastResetAt: now,
          lastReportAt: now,
        );
      }

      // Clear form
      clearForm();

      // Show success with remaining count
      final remaining = getRemainingReports();
      _showSuccess("Feedback submitted! ($remaining reports remaining today)");

      return true;
    } catch (e, stackTrace) {
      print('=== ERROR SUBMITTING FEEDBACK ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      _showError("Failed to submit feedback. Please try again.");
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Clear the feedback form completely
  void clearForm() {
    print('=== CLEARING FORM ===');

    // Clear text values
    subject.value = '';
    description.value = '';

    // Clear file selections
    selectedFiles.clear();

    // Reset to DEFAULT selections
    selectedType.value = FeedbackType.bug;
    selectedCategory.value = FeedbackCategory.other;

    // Force refresh
    subject.refresh();
    description.refresh();
    selectedFiles.refresh();
    selectedType.refresh();
    selectedCategory.refresh();

    print('Form cleared successfully');
    print('Type: ${selectedType.value.displayName}');
    print('Category: ${selectedCategory.value.displayName}');
    print('====================');
  }

  /// Debug helper method
  void debugFeedbackData() {
    print('=== FEEDBACK FORM DATA ===');
    print('Subject: ${subject.value}');
    print('Description: ${description.value}');
    print('Type: ${selectedType.value}');
    print('Category: ${selectedCategory.value}');
    print('Files: ${selectedFiles.length}');
    print('User ID: ${session.userId}');
    print('User Name: ${session.userName}');
    print('User Email: ${session.userEmail}');
    print('========================');
  }

  // ============= ADMIN-SIDE METHODS =============

  /// Load all feedback for admin
  /// Load all feedback for admin
  Future<void> loadAllFeedback() async {
    isLoadingFeedback.value = true;

    try {
      // ✅ CHANGED: Pass null to load ALL feedback, then filter locally
      final feedback = await authRepository.getAllFeedback(
        status: null, // Don't filter by status in database
        priority: null, // Don't filter by priority in database
      );

      allFeedback.value = feedback;

      // Load pinned IDs from database
      pinnedFeedbackIds.value =
          feedback.where((f) => f.isPinned).map((f) => f.documentId!).toSet();

      print('>>> Loaded ${pinnedFeedbackIds.length} pinned feedback items');

      // ✅ IMPORTANT: Apply filters AFTER loading (preserves user's filter selections)
      filterFeedback();
      updateStatistics();
    } catch (e) {
      _showError("Failed to load feedback: $e");
    } finally {
      isLoadingFeedback.value = false;
    }
  }

  /// Checks subject + description for gibberish, scrambled words, and duplicates per user
  Future<void> autoCleanSpamFeedback() async {
    try {
      print('>>> ============================================');
      print('>>> STARTING ENHANCED SPAM & REDUNDANCY CLEANUP');
      print('>>> ============================================');

      isCleaningSpam.value = true;
      int spamDetected = 0;
      int redundantDetected = 0;
      int totalArchived = 0;

      final feedbackToCheck = allFeedback.where((f) {
        // Only check non-archived, active feedback
        return f.archivedAt == null;
      }).toList();

      print('>>> Checking ${feedbackToCheck.length} feedbacks...');

      // Group feedback by user for redundancy check
      final Map<String, List<FeedbackAndReport>> feedbackByUser = {};
      for (var feedback in feedbackToCheck) {
        feedbackByUser.putIfAbsent(feedback.userId, () => []).add(feedback);
      }

      print('>>> Total users: ${feedbackByUser.length}');

      // Process each user's feedback
      for (var userId in feedbackByUser.keys) {
        final userFeedbacks = feedbackByUser[userId]!;
        print(
            '\n>>> 👤 Checking user: $userId (${userFeedbacks.length} feedbacks)');

        // Sort by submission time (oldest first)
        userFeedbacks.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));

        for (int i = 0; i < userFeedbacks.length; i++) {
          final currentFeedback = userFeedbacks[i];

          try {
            // STEP 1: Check for gibberish/scrambled words
            final isSpam = FeedbackSpamDetector.isSpamOrGibberish(
              subject: currentFeedback.subject,
              description: currentFeedback.description,
            );

            if (isSpam) {
              spamDetected++;
              print('>>>   🚫 SPAM DETECTED: "${currentFeedback.subject}"');

              await _archiveWithReason(
                currentFeedback.documentId!,
                'Auto-archived: Gibberish/Scrambled content detected',
              );
              totalArchived++;
              continue; // Skip to next feedback
            }

            // STEP 2: Check for redundant submissions (compare with previous feedbacks)
            if (i > 0) {
              final previousFeedbacks = userFeedbacks
                  .sublist(0, i)
                  .map((f) => {
                        'subject': f.subject,
                        'description': f.description,
                      })
                  .toList();

              final isRedundant = FeedbackSpamDetector.hasRedundantSubmissions(
                userId: userId,
                currentSubject: currentFeedback.subject,
                currentDescription: currentFeedback.description,
                userPreviousFeedbacks: previousFeedbacks,
              );

              if (isRedundant) {
                redundantDetected++;
                print(
                    '>>>   🔄 REDUNDANT DETECTED: "${currentFeedback.subject}"');

                await _archiveWithReason(
                  currentFeedback.documentId!,
                  'Auto-archived: Duplicate/Redundant submission',
                );
                totalArchived++;
              }
            }
          } catch (e) {
            print(
                '>>>   ❌ Error checking feedback ${currentFeedback.documentId}: $e');
          }
        }
      }

      spamDetectedCount.value = spamDetected;
      autoArchivedCount.value = totalArchived;

      print('\n>>> ============================================');
      print('>>> CLEANUP COMPLETE');
      print('>>> Spam Detected: $spamDetected');
      print('>>> Redundant Detected: $redundantDetected');
      print('>>> Total Archived: $totalArchived');
      print('>>> ============================================');

      if (totalArchived > 0) {
        _showSuccess('Auto-cleaned $totalArchived spam/redundant feedback(s)');
        await loadAllFeedback(); // Refresh list
      } else {
        _showInfo('✅ All feedbacks look good - no spam detected!');
      }
    } catch (e) {
      print('>>> ❌ Error in auto spam cleanup: $e');
      _showError('Spam cleanup failed: $e');
    } finally {
      isCleaningSpam.value = false;
    }
  }

  /// Helper: Archive feedback with custom reason
  Future<void> _archiveWithReason(String documentId, String reason) async {
    try {
      await authRepository.appWriteProvider.databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.feedbackAndReportCollectionID,
        documentId: documentId,
        data: {
          'archivedAt': DateTime.now().toIso8601String(),
          'archivedBy': 'System (Auto-cleanup)',
          'archiveReason': reason,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('>>> Error archiving feedback: $e');
      rethrow;
    }
  }

  /// Manual check if feedback is spam (subject + description)
  Future<bool> checkIfSpam(FeedbackAndReport feedback) async {
    return FeedbackSpamDetector.isSpamOrGibberish(
      subject: feedback.subject,
      description: feedback.description,
    );
  }

  /// Get detailed spam analysis
  Map<String, dynamic> getSpamAnalysis(FeedbackAndReport feedback) {
    return FeedbackSpamDetector.analyzeMessage(
      subject: feedback.subject,
      description: feedback.description,
    );
  }

  /// Check if user has redundant submissions
  Future<bool> checkUserRedundancy(FeedbackAndReport currentFeedback) async {
    final userFeedbacks = allFeedback
        .where((f) =>
            f.userId == currentFeedback.userId &&
            f.documentId != currentFeedback.documentId &&
            f.archivedAt == null)
        .toList();

    if (userFeedbacks.isEmpty) return false;

    final previousFeedbacks = userFeedbacks
        .map((f) => {
              'subject': f.subject,
              'description': f.description,
            })
        .toList();

    return FeedbackSpamDetector.hasRedundantSubmissions(
      userId: currentFeedback.userId,
      currentSubject: currentFeedback.subject,
      currentDescription: currentFeedback.description,
      userPreviousFeedbacks: previousFeedbacks,
    );
  }

  /// Filter feedback based on current filters
  void filterFeedback() {
    var filtered = allFeedback.toList();

    // Apply search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((f) {
        final query = searchQuery.value.toLowerCase();

        final subjectMatch = f.subject.toLowerCase().contains(query);
        final categoryMatch =
            f.category.displayName.toLowerCase().contains(query);
        final typeMatch =
            f.feedbackType.displayName.toLowerCase().contains(query);
        final nameMatch = f.userName.toLowerCase().contains(query);
        final emailMatch = f.userEmail.toLowerCase().contains(query);
        final descriptionMatch = f.description.toLowerCase().contains(query);

        return subjectMatch ||
            categoryMatch ||
            typeMatch ||
            nameMatch ||
            emailMatch ||
            descriptionMatch;
      }).toList();
    }

    // Apply filters
    if (statusFilter.value != null) {
      filtered = filtered.where((f) => f.status == statusFilter.value).toList();
    }

    if (priorityFilter.value != null) {
      filtered =
          filtered.where((f) => f.priority == priorityFilter.value).toList();
    }

    if (typeFilter.value != null) {
      filtered =
          filtered.where((f) => f.feedbackType == typeFilter.value).toList();
    }

    if (categoryFilter.value != null) {
      filtered =
          filtered.where((f) => f.category == categoryFilter.value).toList();
    }

    filtered.sort((a, b) {
      // ═══════════════════════════════════════════════════════
      // PRIORITY 1: Pinned items ALWAYS appear first
      // ═══════════════════════════════════════════════════════
      final aPinned = pinnedFeedbackIds.contains(a.documentId);
      final bPinned = pinnedFeedbackIds.contains(b.documentId);

      if (aPinned && !bPinned)
        return -1; // a is pinned, b is not → a comes first
      if (!aPinned && bPinned)
        return 1; // b is pinned, a is not → b comes first

      // ═══════════════════════════════════════════════════════
      // PRIORITY 2: Critical priority items (within pinned group or unpinned group)
      // ═══════════════════════════════════════════════════════
      final priorityOrder = <Priority, int>{
        Priority.critical: 0, // Highest priority
        Priority.high: 1,
        Priority.medium: 2,
        Priority.low: 3, // Lowest priority
      };

      final aPriority = priorityOrder[a.priority] ?? 999;
      final bPriority = priorityOrder[b.priority] ?? 999;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority); // Lower number = higher priority
      }

      // ═══════════════════════════════════════════════════════
      // PRIORITY 3: Latest submission date (NEWEST FIRST)
      // ═══════════════════════════════════════════════════════
      // b.compareTo(a) gives DESCENDING order (latest first)
      return b.submittedAt.compareTo(a.submittedAt);
    });

    filteredFeedback.value = filtered;

    // Debug log for verification
    if (filtered.isNotEmpty) {
      print('>>> Filtered ${filtered.length} feedbacks');
      print('>>> Top 3 items:');
      for (int i = 0; i < (filtered.length > 3 ? 3 : filtered.length); i++) {
        final f = filtered[i];
        print(
            '>>>   ${i + 1}. ${f.subject} | ${f.isPinned ? "📌 PINNED" : "⚪"} | ${f.priority.displayName} | ${_formatDebugDate(f.submittedAt)}');
      }
    }
  }

  /// Helper method for debug logging (add this to your controller)
  String _formatDebugDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  /// Update feedback statistics
  void updateStatistics() {
    feedbackStats.value = {
      'total': allFeedback.length,
      'pending':
          allFeedback.where((f) => f.status == FeedbackStatus.pending).length,
      'inProgress': allFeedback
          .where((f) => f.status == FeedbackStatus.inProgress)
          .length,
      'resolved':
          allFeedback.where((f) => f.status == FeedbackStatus.completed).length,
      'closed':
          allFeedback.where((f) => f.status == FeedbackStatus.closed).length,
      'critical':
          allFeedback.where((f) => f.priority == Priority.critical).length,
      'high': allFeedback.where((f) => f.priority == Priority.high).length,
    };
  }

  /// Update feedback status
  Future<void> updateStatus(String documentId, FeedbackStatus status) async {
    try {
      await authRepository.updateFeedbackStatus(documentId, status);

      final index = allFeedback.indexWhere((f) => f.documentId == documentId);
      if (index != -1) {
        allFeedback[index] = allFeedback[index].copyWith(status: status);
      }

      filterFeedback();
      updateStatistics();

      _showSuccess("Feedback status updated to ${status.displayName}");
    } catch (e) {
      _showError("Failed to update status: $e");
    }
  }

  /// Update feedback priority
  Future<void> updatePriority(String documentId, Priority priority) async {
    try {
      await authRepository.updateFeedbackPriority(documentId, priority);

      final index = allFeedback.indexWhere((f) => f.documentId == documentId);
      if (index != -1) {
        allFeedback[index] = allFeedback[index].copyWith(priority: priority);
      }

      filterFeedback();
      updateStatistics();

      _showSuccess("Feedback priority updated to ${priority.displayName}");
    } catch (e) {
      _showError("Failed to update priority: $e");
    }
  }

  /// Add admin reply
  Future<void> addReply(String documentId, String reply) async {
    try {
      final adminName = session.userName;
      await authRepository.addFeedbackReply(documentId, reply, adminName);

      await loadAllFeedback();

      _showSuccess("Reply sent successfully");
    } catch (e) {
      _showError("Failed to send reply: $e");
    }
  }

 /// Archive feedback with confirmation
Future<void> archiveFeedback(String documentId) async {
  try {
    isLoading.value = true;
    
    // Get current admin/user info
    final userName = session.userName.isNotEmpty ? session.userName : 'System';
    
    print('>>> Archiving feedback: $documentId by $userName');
    
    await authRepository.archiveFeedback(documentId, userName);
    
    // CRITICAL: Remove from BOTH lists
    allFeedback.removeWhere((f) => f.documentId == documentId);
    filteredFeedback.removeWhere((f) => f.documentId == documentId);
    
    // Remove from pinned IDs if it was pinned
    pinnedFeedbackIds.remove(documentId);
    
    // Force refresh both lists
    allFeedback.refresh();
    filteredFeedback.refresh();
    
    // Update statistics
    updateStatistics();
    
    _showSuccess('Feedback archived successfully');
    
    print('>>> Archive successful');
  } catch (e) {
    print('>>> Error archiving feedback: $e');
    _showError('Failed to archive feedback: $e');
  } finally {
    isLoading.value = false;
  }
}

  /// Delete feedback permanently
  Future<void> deleteFeedback(
      String documentId, List<String> attachmentIds) async {
    try {
      await authRepository.deleteFeedback(documentId, attachmentIds);

      allFeedback.removeWhere((f) => f.documentId == documentId);

      filterFeedback();
      updateStatistics();

      _showSuccess("Feedback has been permanently deleted");
    } catch (e) {
      _showError("Failed to delete feedback: $e");
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    filterFeedback();
  }

  /// Update filters
  /// Update filters
  void updateFilters({
    FeedbackStatus? status,
    Priority? priority,
    FeedbackType? type,
    FeedbackCategory? category,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearType = false,
    bool clearCategory = false,
  }) {
    // Clear filters if explicitly requested OR if null value is passed
    if (clearStatus || status == null) {
      statusFilter.value = null;
    } else {
      statusFilter.value = status;
    }

    if (clearPriority || priority == null) {
      priorityFilter.value = null;
    } else {
      priorityFilter.value = priority;
    }

    if (clearType || type == null) {
      typeFilter.value = null;
    } else {
      typeFilter.value = type;
    }

    if (clearCategory || category == null) {
      categoryFilter.value = null;
    } else {
      categoryFilter.value = category;
    }

    filterFeedback();
  }

  /// Clear all filters
  void clearFilters() {
    statusFilter.value = null;
    priorityFilter.value = null;
    typeFilter.value = null;
    categoryFilter.value = null;
    searchQuery.value = '';
    filterFeedback();
  }

  /// Get attachment URL
  String getAttachmentUrl(String fileId) {
    return authRepository.getFeedbackAttachmentUrl(fileId);
  }
}
