import 'dart:async';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// User-side appointment reminder service
/// Schedules notifications for upcoming appointments
/// Works even when app is closed (uses local scheduled notifications)
class AppointmentReminderService extends GetxService {
  final AuthRepository authRepository;
  final AppWriteProvider appwriteProvider;
  final UserSessionService session;
  final FlutterLocalNotificationsPlugin _localNotifications;

  AppointmentReminderService({
    required this.authRepository,
    required this.appwriteProvider,
    required this.session,
  }) : _localNotifications = FlutterLocalNotificationsPlugin();

  // Track scheduled notifications
  final Map<String, int> _scheduledNotifications = {};

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeLocalNotifications();
    await _scheduleAllUpcomingAppointments();
  }

  @override
  void onClose() {
    _scheduledNotifications.clear();
    super.onClose();
  }

  /// Initialize local notifications with timezone support
  Future<void> _initializeLocalNotifications() async {
    try {
      // Initialize timezones
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

    } catch (e) {
    }
  }

  void _handleNotificationTap(NotificationResponse response) {

    if (response.payload != null) {
      // Navigate to appointments page
      try {
        // You can parse the payload to get appointment details
        // Get.toNamed('/userHome'); // Adjust route as needed
      } catch (e) {
      }
    }
  }

  /// Schedule notifications for all upcoming accepted appointments
  Future<void> _scheduleAllUpcomingAppointments() async {
    try {
      final userId = session.userId;
      if (userId.isEmpty) {
        return;
      }

      final appointments = await authRepository.getUserAppointments(userId);

      // Filter for accepted appointments in the future
      final upcomingAccepted = appointments.where((apt) {
        return apt.status == 'accepted' && apt.dateTime.isAfter(DateTime.now());
      }).toList();


      // Schedule notification for each
      for (var appointment in upcomingAccepted) {
        await scheduleAppointmentReminder(appointment);
      }

    } catch (e) {
    }
  }

  /// Schedule a reminder notification for an appointment
  /// Called when:
  /// 1. Appointment is accepted by admin
  /// 2. User logs in and has upcoming accepted appointments
  Future<void> scheduleAppointmentReminder(Appointment appointment) async {
    try {
      if (appointment.documentId == null) return;

      // Calculate reminder time (1 hour before appointment)
      final reminderTime =
          appointment.dateTime.subtract(const Duration(hours: 1));

      // Don't schedule if reminder time is in the past
      if (reminderTime.isBefore(DateTime.now())) {
        return;
      }


      // Get pet and clinic details
      final petName = await _getPetName(appointment.petId);
      final clinicName = await _getClinicName(appointment.clinicId);

      // Generate unique notification ID
      final notificationId = appointment.documentId.hashCode;

      // Schedule local notification
      await _scheduleLocalNotification(
        notificationId: notificationId,
        scheduledTime: reminderTime,
        title: '⏰ Appointment Reminder',
        body: '$petName\'s appointment at $clinicName is in 1 hour!',
        payload: appointment.documentId!,
        appointment: appointment,
      );

      // Track scheduled notification
      _scheduledNotifications[appointment.documentId!] = notificationId;

      // Also create in-app notification (will be delivered at reminder time)
      await _scheduleInAppNotification(
        appointment: appointment,
        reminderTime: reminderTime,
        petName: petName,
        clinicName: clinicName,
      );

    } catch (e) {
    }
  }

  /// Schedule local notification (works even when app is closed)
  Future<void> _scheduleLocalNotification({
    required int notificationId,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required String payload,
    required Appointment appointment,
  }) async {
    try {
      // Convert to timezone-aware datetime
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders',
        'Appointment Reminders',
        channelDescription: 'Reminders for upcoming appointments',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

    } catch (e) {

      // Fallback: If timezone scheduling fails, show immediate notification (for testing)
      if (kDebugMode) {
        await _localNotifications.show(
          notificationId,
          title,
          '⚠️ Fallback: $body',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'appointment_reminders',
              'Appointment Reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: payload,
        );
      }
    }
  }

  /// Schedule in-app notification (stored in database)
  Future<void> _scheduleInAppNotification({
    required Appointment appointment,
    required DateTime reminderTime,
    required String petName,
    required String clinicName,
  }) async {
    try {
      // We'll create the notification record now, but with a future timestamp
      // The InAppNotificationService will display it when fetching notifications

      final notification = AppNotification.appointmentReminder(
        userId: appointment.userId,
        appointmentId: appointment.documentId!,
        clinicId: appointment.clinicId,
        clinicName: clinicName,
        petName: petName,
        service: appointment.service,
        appointmentDateTime: appointment.dateTime,
        minutesUntil: 60,
      );

      // Create the notification record
      await authRepository.createNotification(notification);

    } catch (e) {
    }
  }

  /// Cancel scheduled reminder for an appointment
  /// Called when:
  /// 1. Appointment is cancelled by user
  /// 2. Appointment is declined by admin
  /// 3. Appointment is rescheduled
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    try {

      // Get notification ID
      final notificationId = _scheduledNotifications[appointmentId];

      if (notificationId != null) {
        // Cancel local notification
        await _localNotifications.cancel(notificationId);

        // Remove from tracking
        _scheduledNotifications.remove(appointmentId);

      } else {
      }

    } catch (e) {
    }
  }

  /// Reschedule reminder (when appointment time is changed)
  Future<void> rescheduleAppointmentReminder(Appointment appointment) async {
    if (appointment.documentId == null) return;

    // Cancel existing reminder
    await cancelAppointmentReminder(appointment.documentId!);

    // Schedule new reminder
    await scheduleAppointmentReminder(appointment);
  }

  /// Get pet name for display
  Future<String> _getPetName(String petId) async {
    try {
      final petDoc = await authRepository.getPetById(petId);
      return petDoc?.data['name'] ?? petId;
    } catch (e) {
      return petId;
    }
  }

  /// Get clinic name for display
  Future<String> _getClinicName(String clinicId) async {
    try {
      final clinicDoc = await authRepository.getClinicById(clinicId);
      return clinicDoc?.data['clinicName'] ?? 'Unknown Clinic';
    } catch (e) {
      return 'Unknown Clinic';
    }
  }

  /// Check for pending scheduled notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      for (var notification in pending) {
      }
      return pending;
    } catch (e) {
      return [];
    }
  }

  /// Cancel all scheduled notifications (for logout)
  Future<void> cancelAllReminders() async {
    try {
      await _localNotifications.cancelAll();
      _scheduledNotifications.clear();
    } catch (e) {
    }
  }

  /// Manual refresh - reschedule all upcoming appointments
  Future<void> refreshAllReminders() async {

    // Cancel existing
    await cancelAllReminders();

    // Reschedule
    await _scheduleAllUpcomingAppointments();

  }

  /// Get service statistics
  Map<String, dynamic> getStatistics() {
    return {
      'scheduledReminders': _scheduledNotifications.length,
      'appointments': _scheduledNotifications.keys.toList(),
    };
  }
}
