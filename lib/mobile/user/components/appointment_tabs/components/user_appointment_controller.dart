import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/notifications/controllers/user_notification_controller.dart';
import 'package:capstone_app/notifications/components/toast_notification_system.dart';

class EnhancedUserAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;
  
  // CRITICAL FIX: Add notification controller reference
  late final UserNotificationController _notificationController;

  EnhancedUserAppointmentController({
    required this.authRepository,
    required this.session,
  });

  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;
  var clinics = <String, Clinic>{}.obs;
  var pets = <String, Pet>{}.obs;
  var ownersCache = <String, Map<String, dynamic>>{}.obs;

  var appointmentReviews = <String, bool>{}.obs;

  StreamSubscription<RealtimeMessage>? _appointmentSubscription;
  StreamSubscription<RealtimeMessage>? _reviewSubscription;

  @override
  void onInit() {
    super.onInit();
    
    // CRITICAL FIX: Initialize notification controller reference
    try {
      _notificationController = Get.find<UserNotificationController>(tag: 'user');
      print('>>> User notification controller connected to appointment controller');
    } catch (e) {
      print('>>> ERROR: Could not find UserNotificationController: $e');
    }
    
    fetchAppointments();
    _setupRealtimeSubscription();
    _setupReviewSubscription();
  }

  @override
  void onClose() {
    _appointmentSubscription?.cancel();
    _reviewSubscription?.cancel();
    super.onClose();
  }

  void _setupRealtimeSubscription() {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      _appointmentSubscription =
          authRepository.subscribeToUserAppointments(userId).listen((message) {
        _handleRealtimeUpdate(message);
      });
    } catch (e) {
      print('Error setting up realtime subscription: $e');
    }
  }

  void _setupReviewSubscription() {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      _reviewSubscription =
          authRepository.subscribeToClinicReviews('').listen((message) {
        _handleReviewUpdate(message);
      });
    } catch (e) {
      print('Error setting up review subscription: $e');
    }
  }

  void _handleReviewUpdate(RealtimeMessage message) {
    final payload = message.payload;
    final eventType = message.events.first;
    final appointmentId = payload['appointmentId'] as String?;

    if (appointmentId == null) return;

    print('Review update received for appointment: $appointmentId');
    print('Event type: $eventType');

    if (eventType.contains('create')) {
      appointmentReviews[appointmentId] = true;
      print('Review created for appointment: $appointmentId');
    } else if (eventType.contains('delete')) {
      appointmentReviews[appointmentId] = false;
      print('Review deleted for appointment: $appointmentId');
    }

    appointments.refresh();
  }

  void _handleRealtimeUpdate(RealtimeMessage message) {
    final payload = message.payload;
    final eventType = message.events.first;

    print('>>> User Appointment Realtime update: $eventType');
    print('>>> Payload: $payload');

    if (eventType.contains('create')) {
      _addOrUpdateAppointment(payload);
      print('>>> Added new appointment');
    } else if (eventType.contains('update')) {
      _addOrUpdateAppointment(payload);
      
      // CRITICAL FIX: Show notification for appointment status updates
      final appointment = Appointment.fromMap(payload);
      _handleAppointmentStatusChange(appointment);
      
      print('>>> Updated appointment');
    } else if (eventType.contains('delete')) {
      appointments.removeWhere((a) => a.documentId == payload['\$id']);
      print('>>> Deleted appointment');
    }

    appointments.refresh();
  }

  // CRITICAL FIX: Handle appointment status changes with notifications
  void _handleAppointmentStatusChange(Appointment appointment) {
    try {
      final existingIndex = appointments.indexWhere((a) => a.documentId == appointment.documentId);
      
      if (existingIndex != -1) {
        final oldAppointment = appointments[existingIndex];
        
        // Check if status changed
        if (oldAppointment.status != appointment.status) {
          print('>>> Appointment status changed: ${oldAppointment.status} -> ${appointment.status}');
          
          // Show appropriate notification based on new status
          switch (appointment.status) {
            case 'accepted':
              _showAppointmentAcceptedNotification(appointment);
              break;
            case 'declined':
              _showAppointmentDeclinedNotification(appointment);
              break;
            case 'completed':
              _showAppointmentCompletedNotification(appointment);
              break;
            case 'in_progress':
              _showAppointmentInProgressNotification(appointment);
              break;
            case 'cancelled':
              if (appointment.cancelledBy == 'clinic') {
                _showAppointmentCancelledByClinicNotification(appointment);
              }
              break;
            case 'no_show':
              _showAppointmentNoShowNotification(appointment);
              break;
          }
        }
      }
    } catch (e) {
      print('>>> Error handling appointment status change: $e');
    }
  }

  void _showAppointmentAcceptedNotification(Appointment appointment) {
    ToastNotificationService.showSuccessToast(
      'Appointment Accepted',
      'Your appointment for ${getPetName(appointment)} has been accepted!',
    );
  }

  void _showAppointmentDeclinedNotification(Appointment appointment) {
    ToastNotificationService.showErrorToast(
      'Appointment Declined',
      'Your appointment for ${getPetName(appointment)} was declined by the clinic.',
    );
  }

  void _showAppointmentCompletedNotification(Appointment appointment) {
    ToastNotificationService.showSuccessToast(
      'Appointment Completed',
      'Your appointment for ${getPetName(appointment)} has been completed!',
    );
  }

  void _showAppointmentInProgressNotification(Appointment appointment) {
    ToastNotificationService.showInfoToast(
      'Treatment Started',
      '${getPetName(appointment)} is now being treated.',
    );
  }

  void _showAppointmentCancelledByClinicNotification(Appointment appointment) {
    ToastNotificationService.showErrorToast(
      'Appointment Cancelled',
      'The clinic cancelled your appointment for ${getPetName(appointment)}.',
    );
  }

  void _showAppointmentNoShowNotification(Appointment appointment) {
    ToastNotificationService.showErrorToast(
      'Missed Appointment',
      'You missed your appointment for ${getPetName(appointment)}.',
    );
  }

  void _addOrUpdateAppointment(Map<String, dynamic> payload) {
    final appointment = Appointment.fromMap(payload);
    final index =
        appointments.indexWhere((a) => a.documentId == appointment.documentId);

    if (index != -1) {
      appointments[index] = appointment;
    } else {
      appointments.add(appointment);
    }

    _fetchRelatedDataForAppointment(appointment);
    _checkAppointmentReview(appointment.documentId!);
  }

  Future<void> _checkAppointmentReview(String appointmentId) async {
    try {
      final hasReview =
          await authRepository.hasUserReviewedAppointment(appointmentId);
      appointmentReviews[appointmentId] = hasReview;
    } catch (e) {
      print('Error checking appointment review: $e');
    }
  }

  Future<void> fetchAppointments() async {
    try {
      isLoading.value = true;
      final userId = session.userId;

      if (userId.isEmpty) {
        Get.snackbar("Error", "User not logged in.");
        return;
      }

      final result = await authRepository.getUserAppointments(userId);
      appointments.assignAll(result);

      await _fetchRelatedData();
      await _checkAllAppointmentReviews();
    } catch (e) {
      Get.snackbar("Error", "Failed to load appointments: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _checkAllAppointmentReviews() async {
    for (var appointment in appointments) {
      if (appointment.documentId != null && appointment.isCompleted) {
        await _checkAppointmentReview(appointment.documentId!);
      }
    }
  }

  Future<void> _fetchRelatedData() async {
    final clinicIds = appointments.map((a) => a.clinicId).toSet();
    final petNames = appointments.map((a) => a.petId).toSet();

    for (final clinicId in clinicIds) {
      if (!clinics.containsKey(clinicId) && clinicId.isNotEmpty) {
        try {
          final clinicDoc = await authRepository.getClinicById(clinicId);
          if (clinicDoc != null) {
            final clinic = Clinic.fromMap(clinicDoc.data);
            clinic.documentId = clinicDoc.$id;
            clinics[clinicId] = clinic;
          }
        } catch (e) {
          print('Error fetching clinic $clinicId: $e');
        }
      }
    }

    for (final petName in petNames) {
      if (!pets.containsKey(petName) && petName.isNotEmpty) {
        try {
          final petDoc = await authRepository.getPetByName(petName);
          if (petDoc != null) {
            final pet = Pet.fromMap(petDoc.data);
            pet.documentId = petDoc.$id;
            pets[petName] = pet;
          }
        } catch (e) {
          print('Error fetching pet $petName: $e');
        }
      }
    }
  }

  Future<void> _fetchRelatedDataForAppointment(Appointment appointment) async {
    if (!clinics.containsKey(appointment.clinicId) &&
        appointment.clinicId.isNotEmpty) {
      try {
        final clinicDoc =
            await authRepository.getClinicById(appointment.clinicId);
        if (clinicDoc != null) {
          final clinic = Clinic.fromMap(clinicDoc.data);
          clinic.documentId = clinicDoc.$id;
          clinics[appointment.clinicId] = clinic;
        }
      } catch (e) {
        print('Error fetching clinic: $e');
      }
    }

    if (!pets.containsKey(appointment.petId) && appointment.petId.isNotEmpty) {
      try {
        final petDoc = await authRepository.getPetByName(appointment.petId);
        if (petDoc != null) {
          final pet = Pet.fromMap(petDoc.data);
          pet.documentId = petDoc.$id;
          pets[appointment.petId] = pet;
        }
      } catch (e) {
        print('Error fetching pet: $e');
      }
    }
  }

  List<Appointment> get upcoming {
    final now = DateTime.now();
    return appointments
        .where((a) => a.status == 'accepted' && a.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Appointment> get pending {
    return appointments.where((a) => a.status == 'pending').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Appointment> get completed {
    return appointments.where((a) {
      if (a.status != 'completed') return false;

      final hasReview = appointmentReviews[a.documentId] ?? false;
      return !hasReview;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Appointment> get history {
    return appointments.where((a) {
      if (a.status == 'cancelled' ||
          a.status == 'declined' ||
          a.status == 'no_show') {
        return true;
      }

      if (a.status == 'completed') {
        final hasReview = appointmentReviews[a.documentId] ?? false;
        return hasReview;
      }

      return false;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Appointment> get inProgress {
    return appointments.where((a) => a.status == 'in_progress').toList();
  }

  List<Appointment> get todayAppointments {
    final today = DateTime.now();
    return appointments.where((appointment) {
      final appointmentDate = appointment.dateTime;
      return appointmentDate.year == today.year &&
          appointmentDate.month == today.month &&
          appointmentDate.day == today.day;
    }).toList();
  }

  // CRITICAL FIX: Cancel pending appointment with notification
  Future<void> cancelPendingAppointment(String appointmentId) async {
    try {
      isLoading.value = true;

      final appointment =
          appointments.firstWhere((a) => a.documentId == appointmentId);

      // Update appointment status
      await authRepository.updateAppointmentStatus(appointmentId, 'cancelled');

      // CRITICAL: Create notification for admin
      await _createAdminNotificationForUserCancellation(
        appointment,
        'User cancelled pending appointment request',
      );

      // Remove from local list
      appointments.removeWhere((a) => a.documentId == appointmentId);

      ToastNotificationService.showSuccessToast(
        'Request Cancelled',
        'Appointment request cancelled successfully',
      );
    } catch (e) {
      ToastNotificationService.showErrorToast(
        'Error',
        'Failed to cancel appointment: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // CRITICAL FIX: Cancel accepted appointment with reason and notification
  Future<void> cancelAcceptedAppointment(
    String appointmentId,
    String cancellationReason,
  ) async {
    try {
      isLoading.value = true;

      final appointment =
          appointments.firstWhere((a) => a.documentId == appointmentId);

      // Update appointment with cancellation details
      await authRepository.updateFullAppointment(appointmentId, {
        'status': 'cancelled',
        'cancellationReason': cancellationReason,
        'cancelledBy': 'user',
        'cancelledAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // CRITICAL: Create notification for admin
      await _createAdminNotificationForUserCancellation(
          appointment, cancellationReason);

      ToastNotificationService.showSuccessToast(
        'Appointment Cancelled',
        'The clinic has been notified',
      );
    } catch (e) {
      ToastNotificationService.showErrorToast(
        'Error',
        'Failed to cancel appointment: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // CRITICAL FIX: Create admin notification for user cancellation
  Future<void> _createAdminNotificationForUserCancellation(
    Appointment appointment,
    String cancellationReason,
  ) async {
    try {
      final ownerName = getOwnerName(appointment.userId);
      final petName = getPetName(appointment);

      print('>>> Creating admin notification for user cancellation');
      print('>>> Clinic ID: ${appointment.clinicId}');
      print('>>> User: $ownerName, Pet: $petName');

      final adminNotification = NotificationModel(
        recipientId: appointment.clinicId,
        recipientType: 'admin',
        type: NotificationType.appointmentCancelled,
        priority: NotificationPriority.high,
        title: 'Appointment Cancelled by User',
        message: '$ownerName cancelled appointment for $petName',
        appointmentId: appointment.documentId,
        userId: appointment.userId,
        actionUrl: '/appointments',
        data: {
          'cancellationReason': cancellationReason,
          'petName': petName,
          'ownerName': ownerName,
          'service': appointment.service,
          'appointmentTime': appointment.dateTime.toIso8601String(),
          'cancelledBy': 'user',
        },
      );

      await authRepository.createNotification(adminNotification);
      print('>>> ✓ Admin notification created for user cancellation');
    } catch (e) {
      print('>>> ERROR creating admin notification for user cancellation: $e');
    }
  }

  // Helper methods
  Clinic? getClinicForAppointment(Appointment appointment) {
    return clinics[appointment.clinicId];
  }

  Pet? getPetForAppointment(Appointment appointment) {
    return pets[appointment.petId];
  }

  String getPetNameForAppointment(Appointment appointment) {
    final pet = pets[appointment.petId];
    return pet?.name ?? appointment.petId;
  }

  String getPetName(Appointment appointment) {
    final pet = pets[appointment.petId];
    return pet?.name ?? appointment.petId;
  }

  String getOwnerName(String userId) {
    if (!ownersCache.containsKey(userId)) {
      _fetchOwnerData(userId);
      return 'Loading...';
    }
    return ownersCache[userId]?['name'] ?? 'User #${userId.substring(0, 6)}';
  }

  Future<void> _fetchOwnerData(String userId) async {
    if (!ownersCache.containsKey(userId)) {
      try {
        final ownerDoc = await authRepository.getUserById(userId);
        if (ownerDoc != null) {
          final user = User.fromMap(ownerDoc.data);
          ownersCache[userId] = {
            'name': user.name,
            'email': user.email,
            'phone': user.phone,
          };
        } else {
          ownersCache[userId] = {
            'name': 'User #${userId.substring(0, 6)}',
            'email': 'N/A',
            'phone': 'N/A',
          };
        }
      } catch (e) {
        print("Error fetching owner $userId: $e");
        ownersCache[userId] = {
          'name': 'User #${userId.substring(0, 6)}',
          'email': 'N/A',
          'phone': 'N/A',
        };
      }
    }
  }

  String getClinicNameForAppointment(Appointment appointment) {
    final clinic = clinics[appointment.clinicId];
    return clinic?.clinicName ?? 'Unknown Clinic';
  }

  String getAppointmentStage(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 'Waiting for clinic approval';
      case 'accepted':
        return 'Confirmed - Please arrive on time';
      case 'in_progress':
        if (appointment.checkedInAt != null &&
            appointment.serviceStartedAt == null) {
          return 'Checked in - Waiting for treatment';
        } else if (appointment.serviceStartedAt != null) {
          return 'Currently receiving treatment';
        }
        return 'Treatment in progress';
      case 'completed':
        final hasReview = appointmentReviews[appointment.documentId] ?? false;
        return hasReview ? 'Reviewed' : 'Treatment completed';
      case 'no_show':
        return 'Missed appointment';
      case 'declined':
        return 'Not approved by clinic';
      case 'cancelled':
        return appointment.cancelledBy == 'user'
            ? 'Cancelled by you'
            : 'Cancelled by clinic';
      default:
        return appointment.status;
    }
  }

  String getUserFriendlyStatus(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 'Pending Approval';
      case 'accepted':
        return 'Confirmed';
      case 'in_progress':
        return 'In Treatment';
      case 'completed':
        final hasReview = appointmentReviews[appointment.documentId] ?? false;
        return hasReview ? 'Reviewed' : 'Completed';
      case 'no_show':
        return 'Missed';
      case 'declined':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      default:
        return appointment.status.toUpperCase();
    }
  }

  bool canCancelAppointment(Appointment appointment) {
    if (appointment.status == 'pending') {
      return true;
    }

    if (appointment.status == 'accepted') {
      return appointment.dateTime
          .isAfter(DateTime.now().add(const Duration(hours: 2)));
    }

    return false;
  }

  bool needsCancellationReason(Appointment appointment) {
    return appointment.status == 'accepted';
  }

  double getAppointmentProgress(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 0.25;
      case 'accepted':
        return 0.5;
      case 'in_progress':
        if (appointment.serviceStartedAt != null) return 0.85;
        return 0.7;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Map<String, int> get userStats {
    return {
      'total': appointments.length,
      'pending': pending.length,
      'upcoming': upcoming.length,
      'completed': completed.length,
      'today': todayAppointments.length,
      'history': history.length,
    };
  }

  bool hasReview(String appointmentId) {
    return appointmentReviews[appointmentId] ?? false;
  }

  Future<void> refreshAfterReview(String appointmentId) async {
    await _checkAppointmentReview(appointmentId);
    appointments.refresh();
  }
}