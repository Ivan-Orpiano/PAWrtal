import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/notification_preferences_service.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppointmentReminderService extends GetxService {
  final AuthRepository authRepository;
  final NotificationPreferencesService notificationPrefsService;
  final AppWriteProvider appWriteProvider;

  AppointmentReminderService(
      {required this.authRepository,
      required this.notificationPrefsService,
      required this.appWriteProvider});

  Timer? _reminderTimer;
  final Set<String> _remindedAppointments = {};
  final GetStorage _storage = GetStorage();

  // Configuration
  static const Duration checkInterval =
      Duration(minutes: 10); // Check every 10 minutes
  static const Duration reminderWindow =
      Duration(hours: 1); // Remind 1 hour before

  @override
  void onInit() {
    super.onInit();
    _loadRemindedAppointments();
    _startReminderService();
  }

  @override
  void onClose() {
    _reminderTimer?.cancel();
    super.onClose();
  }

  /// Start the reminder service
  void _startReminderService() {
    print('🔔 Appointment Reminder Service: STARTED');
    print(
        '⏰ Checking every ${checkInterval.inMinutes} minutes for appointments within ${reminderWindow.inMinutes} minutes');

    // Run initial check
    _checkAndSendReminders();

    // Schedule periodic checks
    _reminderTimer = Timer.periodic(checkInterval, (timer) {
      _checkAndSendReminders();
    });
  }

  /// Stop the reminder service
  void stopReminderService() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
    print('🔔 Appointment Reminder Service: STOPPED');
  }

  /// Main method to check and send reminders
  Future<void> _checkAndSendReminders() async {
    try {
      print('\n🔍 Checking for upcoming appointments...');
      // CRITICAL: Use local time for comparison (Philippines timezone)
      final now = DateTime.now();
      print('⏰ Current time (Local): $now');
      print('⏰ Current time (UTC): ${now.toUtc()}');

      // Get all accepted appointments from all clinics
      final allAppointments = await _getAllAcceptedAppointments();

      if (allAppointments.isEmpty) {
        print('✓ No accepted appointments found');
        return;
      }

      print('📋 Found ${allAppointments.length} accepted appointment(s)');

      int remindersCount = 0;

      for (var appointment in allAppointments) {
        // Skip if already reminded
        if (_remindedAppointments.contains(appointment.documentId)) {
          continue;
        }

        // CRITICAL WORKAROUND: Appointments are stored incorrectly (PH time as UTC)
        // So we treat the stored UTC time as if it's actually PH local time

        // Get the stored datetime (which has Z suffix but is actually PH time)
        final storedDateTime = appointment.dateTime;

        // Remove the UTC marker and treat as local PH time
        final actualLocalTime = DateTime(
          storedDateTime.year,
          storedDateTime.month,
          storedDateTime.day,
          storedDateTime.hour,
          storedDateTime.minute,
          storedDateTime.second,
        ); // This creates a local DateTime with the same values

        final nowLocal = now;

        print('\n📅 Checking appointment ${appointment.documentId}:');
        print('   - Appointment time (stored): ${appointment.dateTime}');
        print('   - Appointment time (CORRECTED as local): $actualLocalTime');
        print('   - Current time (local): $nowLocal');

        // Calculate time until appointment using corrected local times
        final timeUntilAppointment = actualLocalTime.difference(nowLocal);
        print('   - Time until: ${timeUntilAppointment.inMinutes} minutes');

        // Check if appointment is within reminder window (1 hour)
        // and hasn't passed yet
        if (timeUntilAppointment > Duration.zero &&
            timeUntilAppointment <= reminderWindow) {
          print('\n⏰ Appointment within reminder window:');
          print('   - Pet: ${appointment.petId}');
          print('   - Time until: ${timeUntilAppointment.inMinutes} minutes');
          print('   - Appointment ID: ${appointment.documentId}');

          await _sendAppointmentReminder(
              appointment, timeUntilAppointment.inMinutes);
          remindersCount++;

          // Mark as reminded
          _remindedAppointments.add(appointment.documentId!);
          _saveRemindedAppointments();
        }
      }

      if (remindersCount > 0) {
        print('\n✉️ Sent $remindersCount appointment reminder(s)');
      } else {
        print('✓ No appointments need reminders at this time');
      }

      // Cleanup old reminded appointments (older than 24 hours)
      _cleanupRemindedAppointments(allAppointments);
    } catch (e) {
      print('❌ Error checking reminders: $e');
    }
  }

  /// Get all accepted appointments from all clinics
  Future<List<Appointment>> _getAllAcceptedAppointments() async {
    try {
      // CRITICAL: Import Query class at the top of the file
      // Add this import: import 'package:appwrite/appwrite.dart';

      // Get all appointments with status 'accepted'
      final result = await appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal("status", "accepted"), // ✅ FIXED - Use Query object
          Query.limit(1000), // ✅ FIXED - Use Query object
        ],
      );

      print('✅ Fetched ${result.documents.length} accepted appointments');

      return result.documents
          .map((doc) => Appointment.fromMap(doc.data))
          .toList();
    } catch (e) {
      print('❌ Error fetching accepted appointments: $e');
      return [];
    }
  }

  /// Send appointment reminder (both in-app and push)
  Future<void> _sendAppointmentReminder(
    Appointment appointment,
    int minutesUntil,
  ) async {
    try {
      print(
          '\n📤 Sending reminder for appointment ${appointment.documentId}...');

      // Get user details
      final userDoc = await authRepository.getUserById(appointment.userId);
      if (userDoc == null) {
        print('❌ User not found: ${appointment.userId}');
        return;
      }

      final userDocId = userDoc.data['\$id'] ?? appointment.userId;

      // Get user's notification preferences
      final userPreferences =
          await notificationPrefsService.getPreferencesForUser(userDocId);

      print('👤 User: ${userDoc.data['name'] ?? 'Unknown'}');
      print('📧 Email: ${userDoc.data['email'] ?? 'N/A'}');
      print('🔔 Push enabled: ${userPreferences.pushNotificationsEnabled}');
      print('📬 Email enabled: ${userPreferences.emailNotificationsEnabled}');

      // Get clinic and pet details
      final clinicDoc =
          await authRepository.getClinicById(appointment.clinicId);
      final clinicName = clinicDoc?.data['clinicName'] ?? 'Clinic';

      // Try to get pet name
      String petName = appointment.petId;
      try {
        final petDoc = await authRepository.getPetById(appointment.petId);
        if (petDoc != null) {
          petName = petDoc.data['name'] ?? appointment.petId;
        }
      } catch (e) {
        print('⚠️ Could not fetch pet name, using petId: $e');
      }

      // 1. Create in-app notification (ALWAYS create)
      print('📱 Creating in-app notification...');
      final notification = AppNotification.appointmentReminder(
        userId: appointment.userId,
        appointmentId: appointment.documentId!,
        clinicId: appointment.clinicId,
        clinicName: clinicName,
        petName: petName,
        service: appointment.service,
        appointmentDateTime: appointment.dateTime,
        minutesUntil: minutesUntil,
      );

      await authRepository.createNotification(notification);
      print('✓ In-app notification created');

      // 2. Send push notification (only if user has it enabled)
      if (userPreferences.pushNotificationsEnabled) {
        print('📲 Sending push notification...');

        String timeMessage;
        if (minutesUntil < 60) {
          timeMessage = 'in $minutesUntil minutes';
        } else {
          final hours = (minutesUntil / 60).floor();
          timeMessage = 'in $hours hour${hours > 1 ? 's' : ''}';
        }

        await authRepository.appWriteProvider.sendPushNotification(
          title: '⏰ Appointment Reminder',
          body:
              '$petName\'s appointment at $clinicName is coming up $timeMessage!',
          userIds: [appointment.userId],
          data: {
            'type': 'appointment_reminder',
            'appointmentId': appointment.documentId!,
            'petName': petName,
            'clinicName': clinicName,
            'minutesUntil': minutesUntil.toString(),
          },
        );
        print('✓ Push notification sent');
      } else {
        print('⊘ Push notification skipped (user disabled)');
      }

      print('✅ Reminder sent successfully!');
    } catch (e) {
      print('❌ Error sending reminder: $e');
      // Don't throw - continue with other reminders
    }
  }

  /// Load reminded appointments from storage
  void _loadRemindedAppointments() {
    try {
      final reminded = _storage.read<List>('reminded_appointments');
      if (reminded != null) {
        _remindedAppointments.addAll(reminded.cast<String>());
        print(
            '📝 Loaded ${_remindedAppointments.length} reminded appointment(s) from storage');
      }
    } catch (e) {
      print('⚠️ Error loading reminded appointments: $e');
    }
  }

  /// Save reminded appointments to storage
  void _saveRemindedAppointments() {
    try {
      _storage.write('reminded_appointments', _remindedAppointments.toList());
    } catch (e) {
      print('⚠️ Error saving reminded appointments: $e');
    }
  }

  /// Cleanup old reminded appointments
  void _cleanupRemindedAppointments(List<Appointment> currentAppointments) {
    final appointmentIds = currentAppointments
        .map((a) => a.documentId)
        .where((id) => id != null)
        .toSet();

    // Remove reminded appointments that are no longer in current appointments
    _remindedAppointments.removeWhere((id) => !appointmentIds.contains(id));

    // Also remove appointments older than 24 hours
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    final toRemove = <String>[];

    for (var id in _remindedAppointments) {
      final appointment = currentAppointments.firstWhereOrNull(
        (a) => a.documentId == id,
      );
      if (appointment != null && appointment.dateTime.isBefore(cutoffTime)) {
        toRemove.add(id);
      }
    }

    if (toRemove.isNotEmpty) {
      _remindedAppointments.removeAll(toRemove);
      _saveRemindedAppointments();
      print('🧹 Cleaned up ${toRemove.length} old reminded appointment(s)');
    }
  }

  /// Manually trigger reminder check (for testing)
  Future<void> manualCheckReminders() async {
    print('\n🔄 Manual reminder check triggered...');
    await _checkAndSendReminders();
  }

  /// Clear reminded appointments (for testing)
  void clearRemindedAppointments() {
    _remindedAppointments.clear();
    _saveRemindedAppointments();
    print('🗑️ Cleared all reminded appointments');
  }

  /// Get reminder statistics
  Map<String, dynamic> getReminderStats() {
    return {
      'isRunning': _reminderTimer != null && _reminderTimer!.isActive,
      'checkIntervalMinutes': checkInterval.inMinutes,
      'reminderWindowMinutes': reminderWindow.inMinutes,
      'remindedCount': _remindedAppointments.length,
    };
  }
}
