import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
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
