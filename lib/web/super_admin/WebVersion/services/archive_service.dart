import 'dart:async';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

class ArchiveService extends GetxService {
  final AuthRepository _authRepository;
  Timer? _deletionTimer;
  
  final RxBool isRunning = false.obs;
  final RxInt lastProcessedCount = 0.obs;
  final RxString lastRunTime = ''.obs;
  final RxList<String> processingErrors = <String>[].obs;

  ArchiveService(this._authRepository);

  static ArchiveService get instance => Get.find<ArchiveService>();

  @override
  void onInit() {
    super.onInit();
    print('>>> ============================================');
    print('>>> ARCHIVE SERVICE INITIALIZED');
    print('>>> ============================================');
    startScheduledDeletionService();
  }

  @override
  void onClose() {
    stopScheduledDeletionService();
    super.onClose();
  }

  /// Start the background service
  /// Runs every hour to check for users due for deletion
  void startScheduledDeletionService() {
    print('>>> Starting scheduled deletion service...');
    print('>>> Check interval: Every 1 hour');

    // Run immediately on start
    _processScheduledDeletions();

    // Then run every hour
    _deletionTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => _processScheduledDeletions(),
    );

    print('>>> Scheduled deletion service started');
  }

  /// Stop the background service
  void stopScheduledDeletionService() {
    print('>>> Stopping scheduled deletion service...');
    _deletionTimer?.cancel();
    _deletionTimer = null;
    isRunning.value = false;
    print('>>> Scheduled deletion service stopped');
  }

  /// Process scheduled deletions
  Future<void> _processScheduledDeletions() async {
    if (isRunning.value) {
      print('>>> Deletion process already running, skipping...');
      return;
    }

    try {
      isRunning.value = true;
      processingErrors.clear();
      lastRunTime.value = DateTime.now().toIso8601String();

      print('>>> ============================================');
      print('>>> PROCESSING SCHEDULED DELETIONS');
      print('>>> Time: ${DateTime.now()}');
      print('>>> ============================================');

      final result = await _authRepository.processScheduledDeletions();

      lastProcessedCount.value = result['totalProcessed'] ?? 0;

      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        processingErrors.value = List<String>.from(result['errors']);
        print('>>> Errors encountered: ${processingErrors.length}');
        for (var error in processingErrors) {
          print('>>>   - $error');
        }
      }

      print('>>> ============================================');
      print('>>> SCHEDULED DELETIONS COMPLETE');
      print('>>> Total processed: ${result['totalProcessed']}');
      print('>>> Successful: ${result['successfulDeletions']}');
      print('>>> Failed: ${result['failedDeletions']}');
      print('>>> ============================================');

      // Log to system
      _logDeletionActivity(result);
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR IN SCHEDULED DELETION SERVICE: $e');
      print('>>> ============================================');
      processingErrors.add('Service error: ${e.toString()}');
    } finally {
      isRunning.value = false;
    }
  }

  /// Manual trigger for processing deletions (for admin dashboard)
  Future<Map<String, dynamic>> processNow() async {
    print('>>> Manual deletion process triggered');
    await _processScheduledDeletions();
    
    return {
      'processed': lastProcessedCount.value,
      'errors': processingErrors.toList(),
      'lastRun': lastRunTime.value,
    };
  }

  /// Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'isRunning': isRunning.value,
      'lastProcessedCount': lastProcessedCount.value,
      'lastRunTime': lastRunTime.value,
      'hasErrors': processingErrors.isNotEmpty,
      'errorCount': processingErrors.length,
      'errors': processingErrors.toList(),
      'timerActive': _deletionTimer?.isActive ?? false,
    };
  }

  /// Get users that will be deleted soon (within 7 days)
  Future<List<Map<String, dynamic>>> getUsersDueSoon() async {
    try {
      final allArchived = await _authRepository.getAllArchivedUsers(
        includePermanentlyDeleted: false,
        limit: 1000,
      );

      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      final dueSoon = allArchived.where((user) {
        return user.scheduledDeletionAt.isBefore(sevenDaysFromNow) &&
               user.scheduledDeletionAt.isAfter(now) &&
               !user.isPermanentlyDeleted &&
               !user.isRecovered;
      }).map((user) {
        return {
          'userId': user.userId,
          'name': user.name,
          'email': user.email,
          'scheduledDeletionAt': user.scheduledDeletionAt.toIso8601String(),
          'daysLeft': user.daysUntilDeletion,
          'archivedBy': user.archivedBy,
          'archiveReason': user.archiveReason,
        };
      }).toList();

      return dueSoon;
    } catch (e) {
      print('>>> Error getting users due soon: $e');
      return [];
    }
  }

  /// Get archive statistics
  Future<Map<String, int>> getArchiveStats() async {
    try {
      return await _authRepository.getArchiveStatistics();
    } catch (e) {
      print('>>> Error getting archive stats: $e');
      return {
        'total': 0,
        'activeArchives': 0,
        'recovered': 0,
        'permanentlyDeleted': 0,
        'dueSoon': 0,
      };
    }
  }

  /// Log deletion activity (can be expanded to save to database)
  void _logDeletionActivity(Map<String, dynamic> result) {
    // You can implement logging to a separate collection here
    // For now, just console logging
    print('>>> Deletion Activity Log:');
    print('>>>   Time: ${DateTime.now()}');
    print('>>>   Processed: ${result['totalProcessed']}');
    print('>>>   Successful: ${result['successfulDeletions']}');
    print('>>>   Failed: ${result['failedDeletions']}');
  }

  /// Check if a specific user is due for deletion
  Future<bool> isUserDueForDeletion(String userId) async {
    try {
      final archivedUser = await _authRepository.getArchivedUserByUserId(userId);
      if (archivedUser == null) return false;
      
      return archivedUser.isDeletionDue && 
             !archivedUser.isPermanentlyDeleted &&
             !archivedUser.isRecovered;
    } catch (e) {
      print('>>> Error checking deletion status: $e');
      return false;
    }
  }

  /// Get time remaining until deletion for a user
  Future<String?> getTimeUntilDeletion(String userId) async {
    try {
      final archivedUser = await _authRepository.getArchivedUserByUserId(userId);
      if (archivedUser == null) return null;

      if (archivedUser.isPermanentlyDeleted) {
        return 'Already deleted';
      }

      if (archivedUser.isRecovered) {
        return 'Recovered';
      }

      final daysLeft = archivedUser.daysUntilDeletion;

      if (daysLeft <= 0) {
        return 'Due for deletion now';
      } else if (daysLeft == 1) {
        return '1 day remaining';
      } else {
        return '$daysLeft days remaining';
      }
    } catch (e) {
      print('>>> Error getting time until deletion: $e');
      return null;
    }
  }

  /// Send warning notifications for users due for deletion soon
  Future<void> sendDeletionWarnings() async {
    try {
      final usersDueSoon = await getUsersDueSoon();

      print('>>> Sending deletion warnings to ${usersDueSoon.length} users');

      for (var user in usersDueSoon) {
        final daysLeft = user['daysLeft'] as int;

        // Send warning at 7 days, 3 days, and 1 day
        if (daysLeft == 7 || daysLeft == 3 || daysLeft == 1) {
          print('>>> Warning sent to: ${user['email']} ($daysLeft days left)');
          
          // Here you can implement email/notification sending
          // await _sendDeletionWarningEmail(user);
          // await _sendDeletionWarningNotification(user);
        }
      }
    } catch (e) {
      print('>>> Error sending deletion warnings: $e');
    }
  }
}