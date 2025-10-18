import 'dart:async';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

/// Service for managing clinic archive and scheduled deletions
class ClinicArchiveService extends GetxService {
  final AuthRepository _authRepository;
  Timer? _deletionTimer;
  
  final RxBool isRunning = false.obs;
  final RxInt lastProcessedCount = 0.obs;
  final RxString lastRunTime = ''.obs;
  final RxList<String> processingErrors = <String>[].obs;

  ClinicArchiveService(this._authRepository);

  static ClinicArchiveService get instance => Get.find<ClinicArchiveService>();

  @override
  void onInit() {
    super.onInit();
    print('>>> ============================================');
    print('>>> CLINIC ARCHIVE SERVICE INITIALIZED');
    print('>>> ============================================');
    startScheduledDeletionService();
  }

  @override
  void onClose() {
    stopScheduledDeletionService();
    super.onClose();
  }

  /// Start the background service
  /// Runs every hour to check for clinics due for deletion
  void startScheduledDeletionService() {
    print('>>> Starting clinic scheduled deletion service...');
    print('>>> Check interval: Every 1 hour');

    // Run immediately on start
    _processScheduledDeletions();

    // Then run every hour
    _deletionTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => _processScheduledDeletions(),
    );

    print('>>> Clinic scheduled deletion service started');
  }

  /// Stop the background service
  void stopScheduledDeletionService() {
    print('>>> Stopping clinic scheduled deletion service...');
    _deletionTimer?.cancel();
    _deletionTimer = null;
    isRunning.value = false;
    print('>>> Clinic scheduled deletion service stopped');
  }

  /// Process scheduled deletions
  Future<void> _processScheduledDeletions() async {
    if (isRunning.value) {
      print('>>> Clinic deletion process already running, skipping...');
      return;
    }

    try {
      isRunning.value = true;
      processingErrors.clear();
      lastRunTime.value = DateTime.now().toIso8601String();

      print('>>> ============================================');
      print('>>> PROCESSING SCHEDULED CLINIC DELETIONS');
      print('>>> Time: ${DateTime.now()}');
      print('>>> ============================================');

      final result = await _authRepository.processScheduledClinicDeletions();

      lastProcessedCount.value = result['totalProcessed'] ?? 0;

      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        processingErrors.value = List<String>.from(result['errors']);
        print('>>> Errors encountered: ${processingErrors.length}');
        for (var error in processingErrors) {
          print('>>>   - $error');
        }
      }

      print('>>> ============================================');
      print('>>> SCHEDULED CLINIC DELETIONS COMPLETE');
      print('>>> Total processed: ${result['totalProcessed']}');
      print('>>> Successful: ${result['successfulDeletions']}');
      print('>>> Failed: ${result['failedDeletions']}');
      print('>>> ============================================');

      _logDeletionActivity(result);
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR IN CLINIC SCHEDULED DELETION SERVICE: $e');
      print('>>> ============================================');
      processingErrors.add('Service error: ${e.toString()}');
    } finally {
      isRunning.value = false;
    }
  }

  /// Manual trigger for processing deletions (for admin dashboard)
  Future<Map<String, dynamic>> processNow() async {
    print('>>> Manual clinic deletion process triggered');
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

  /// Get clinics that will be deleted soon (within 7 days)
  Future<List<Map<String, dynamic>>> getClinicsDueSoon() async {
    try {
      final allArchived = await _authRepository.getAllArchivedClinics(
        includePermanentlyDeleted: false,
        limit: 1000,
      );

      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      final dueSoon = allArchived.where((clinic) {
        return clinic.scheduledDeletionAt.isBefore(sevenDaysFromNow) &&
               clinic.scheduledDeletionAt.isAfter(now) &&
               !clinic.isPermanentlyDeleted &&
               !clinic.isRecovered;
      }).map((clinic) {
        return {
          'clinicId': clinic.clinicId,
          'clinicName': clinic.clinicName,
          'email': clinic.email,
          'scheduledDeletionAt': clinic.scheduledDeletionAt.toIso8601String(),
          'daysLeft': clinic.daysUntilDeletion,
          'archivedBy': clinic.archivedBy,
          'archiveReason': clinic.archiveReason,
        };
      }).toList();

      return dueSoon;
    } catch (e) {
      print('>>> Error getting clinics due soon: $e');
      return [];
    }
  }

  /// Get archive statistics
  Future<Map<String, int>> getArchiveStats() async {
    try {
      return await _authRepository.getClinicArchiveStatistics();
    } catch (e) {
      print('>>> Error getting clinic archive stats: $e');
      return {
        'total': 0,
        'activeArchives': 0,
        'recovered': 0,
        'permanentlyDeleted': 0,
        'dueSoon': 0,
      };
    }
  }

  /// Log deletion activity
  void _logDeletionActivity(Map<String, dynamic> result) {
    print('>>> Clinic Deletion Activity Log:');
    print('>>>   Time: ${DateTime.now()}');
    print('>>>   Processed: ${result['totalProcessed']}');
    print('>>>   Successful: ${result['successfulDeletions']}');
    print('>>>   Failed: ${result['failedDeletions']}');
  }

  /// Check if a specific clinic is due for deletion
  Future<bool> isClinicDueForDeletion(String clinicId) async {
    try {
      final archivedClinic = await _authRepository.getArchivedClinicByClinicId(clinicId);
      if (archivedClinic == null) return false;
      
      return archivedClinic.isDeletionDue && 
             !archivedClinic.isPermanentlyDeleted &&
             !archivedClinic.isRecovered;
    } catch (e) {
      print('>>> Error checking clinic deletion status: $e');
      return false;
    }
  }

  /// Get time remaining until deletion for a clinic
  Future<String?> getTimeUntilDeletion(String clinicId) async {
    try {
      final archivedClinic = await _authRepository.getArchivedClinicByClinicId(clinicId);
      if (archivedClinic == null) return null;

      if (archivedClinic.isPermanentlyDeleted) {
        return 'Already deleted';
      }

      if (archivedClinic.isRecovered) {
        return 'Recovered';
      }

      final daysLeft = archivedClinic.daysUntilDeletion;

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
}