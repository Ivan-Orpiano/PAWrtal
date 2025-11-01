import 'package:capstone_app/data/models/daily_report_tracker_model.dart';
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

  final Rx<UserDailyReportTracker?> dailyTracker = Rx<UserDailyReportTracker?>(null);
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

final RxInt spamDetectedCount = 0.obs;
final RxInt autoArchivedCount = 0.obs;
final RxBool isCleaningSpam = false.obs;

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
    final userName = session.userName.isNotEmpty ? session.userName : 'System';

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
    }
  }

 Future<void> _loadDailyReportTracker() async {
    try {
      isCheckingLimit.value = true;
      
      final userId = session.userId;
      if (userId.isEmpty) {
        print('>>> No user ID, skipping tracker load');
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
      print('>>>   Time until reset: ${_formatDuration(dailyTracker.value!.timeUntilReset)}');
      
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
      print('>>> Time until reset: ${_formatDuration(dailyTracker.value!.timeUntilReset)}');
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

  /// Validate file before adding
  bool _validateFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';

    // Check if it's an image or video
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);

    if (!isImage && !isVideo) {
      _showError(
          "Only images (JPG, PNG, GIF) and videos (MP4, MOV, AVI) allowed");
      return false;
    }

    // Check file size limits
    if (isImage && file.size > 5 * 1024 * 1024) {
      _showError(
          "Image files must be under 5MB (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB)");
      return false;
    }

    if (isVideo && file.size > 25 * 1024 * 1024) {
      _showError(
          "Video files must be under 25MB (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB)");
      return false;
    }

    return true;
  }

  /// Pick files (images/videos)
  Future<void> pickFiles() async {
    if (selectedFiles.length >= 5) {
      _showError("You can only attach up to 5 files");
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
          'bmp',
          'mp4',
          'mov',
          'avi',
          'mkv',
          'webm'
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
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      return '🎥';
    }
    return '📄';
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
        'Daily limit reached (3/3). You can submit again in ${getTimeUntilReset()}.'
      );
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
        print('>>> Updated tracker: ${dailyTracker.value!.reportCount}/3 reports');
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
      _showSuccess(
        "Feedback submitted! ($remaining reports remaining today)"
      );

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
      status: null,  // Don't filter by status in database
      priority: null, // Don't filter by priority in database
    );

    allFeedback.value = feedback;
    
    // Load pinned IDs from database
    pinnedFeedbackIds.value = feedback
        .where((f) => f.isPinned)
        .map((f) => f.documentId!)
        .toSet();
    
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

    Future<void> autoCleanSpamFeedback() async {
    try {
      print('>>> ============================================');
      print('>>> STARTING AUTO SPAM CLEANUP');
      print('>>> ============================================');

      isCleaningSpam.value = true;
      int detectedCount = 0;
      int archivedCount = 0;

      final feedbackToCheck = allFeedback.where((f) {
        // Only check pending/new feedback (not already archived)
        return f.archivedAt == null && 
              (f.status == FeedbackStatus.pending || 
                f.status == FeedbackStatus.inProgress);
      }).toList();

      print('>>> Checking ${feedbackToCheck.length} feedbacks for spam...');

      for (var feedback in feedbackToCheck) {
        try {
          // Combine subject and description for analysis
          final textToAnalyze = '${feedback.subject} ${feedback.description}';
          
          // Run spam detection
          final isSpam = FeedbackSpamDetector.isSpamOrGibberish(textToAnalyze);

          if (isSpam) {
            detectedCount++;
            print('>>> 🚫 SPAM DETECTED: ${feedback.subject}');
            
            // Get detailed analysis
            final analysis = FeedbackSpamDetector.analyzeMessage(textToAnalyze);
            print('>>>   Spam Score: ${(analysis['spamScore'] * 100).toStringAsFixed(1)}%');

            // Auto-archive spam feedback
            await archiveFeedback(feedback.documentId!);
            archivedCount++;

            print('>>>   ✅ Auto-archived spam feedback');
          }
        } catch (e) {
          print('>>> Error checking feedback ${feedback.documentId}: $e');
        }
      }

      spamDetectedCount.value = detectedCount;
      autoArchivedCount.value = archivedCount;

      print('>>> ============================================');
      print('>>> SPAM CLEANUP COMPLETE');
      print('>>> Detected: $detectedCount');
      print('>>> Archived: $archivedCount');
      print('>>> ============================================');

      if (archivedCount > 0) {
        _showSuccess('Auto-cleaned $archivedCount spam feedback(s)');
        await loadAllFeedback(); // Refresh list
      } else {
        _showInfo('No spam detected - all feedbacks look good!');
      }

    } catch (e) {
      print('>>> Error in auto spam cleanup: $e');
      _showError('Spam cleanup failed: $e');
    } finally {
      isCleaningSpam.value = false;
    }
  }

  /// Manual spam check for single feedback
  Future<bool> checkIfSpam(FeedbackAndReport feedback) async {
    final textToAnalyze = '${feedback.subject} ${feedback.description}';
    return FeedbackSpamDetector.isSpamOrGibberish(textToAnalyze);
  }

  /// Get spam analysis details (for admin review)
  Map<String, dynamic> getSpamAnalysis(FeedbackAndReport feedback) {
    final textToAnalyze = '${feedback.subject} ${feedback.description}';
    return FeedbackSpamDetector.analyzeMessage(textToAnalyze);
  }









  /// Filter feedback based on current filters
  void filterFeedback() {
  var filtered = allFeedback.toList();

  // Apply search query
  if (searchQuery.value.isNotEmpty) {
    filtered = filtered.where((f) {
      final query = searchQuery.value.toLowerCase();

      final subjectMatch = f.subject.toLowerCase().contains(query);
      final categoryMatch = f.category.displayName.toLowerCase().contains(query);
      final typeMatch = f.feedbackType.displayName.toLowerCase().contains(query);
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
    filtered = filtered.where((f) => f.priority == priorityFilter.value).toList();
  }

  if (typeFilter.value != null) {
    filtered = filtered.where((f) => f.feedbackType == typeFilter.value).toList();
  }

  if (categoryFilter.value != null) {
    filtered = filtered.where((f) => f.category == categoryFilter.value).toList();
  }

  // Sort: Pinned items first, then by priority and date
  filtered.sort((a, b) {
    // Primary sort: Pinned items first
    final aPinned = pinnedFeedbackIds.contains(a.documentId);
    final bPinned = pinnedFeedbackIds.contains(b.documentId);
    
    if (aPinned && !bPinned) return -1;
    if (!aPinned && bPinned) return 1;

    // Secondary sort: Priority
    final priorityOrder = {
      Priority.critical: 0,
      Priority.high: 1,
      Priority.medium: 2,
      Priority.low: 3,
    };

    final aPriority = priorityOrder[a.priority] ?? 999;
    final bPriority = priorityOrder[b.priority] ?? 999;

    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }

    // Tertiary sort: Date
    return b.submittedAt.compareTo(a.submittedAt);
  });

  filteredFeedback.value = filtered;
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

  /// Archive feedback
  Future<void> archiveFeedback(String documentId) async {
    try {
      final archivedBy = session.userName;
      await authRepository.archiveFeedback(documentId, archivedBy);

      final index = allFeedback.indexWhere((f) => f.documentId == documentId);
      if (index != -1) {
        allFeedback[index] = allFeedback[index].copyWith(
          archivedAt: DateTime.now(),
          archivedBy: archivedBy,
        );
      }

      filterFeedback();
      updateStatistics();

      _showSuccess("Feedback has been archived");
    } catch (e) {
      _showError("Failed to archive feedback: $e");
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
