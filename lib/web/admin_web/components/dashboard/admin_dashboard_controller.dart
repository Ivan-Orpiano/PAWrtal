import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

class AdminDashboardController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  AdminDashboardController({
    required this.authRepository,
    required this.session,
  });

  RealtimeSubscription? _conversationSubscription;
  RealtimeSubscription? _messageSubscription;

  var isLoading = false.obs;
  var clinicData = Rxn<Clinic>();
  var appointments = <Appointment>[].obs;
  var appointmentStats = <String, int>{}.obs;
  var todayAppointments = <Appointment>[].obs;
  var upcomingAppointments = <Appointment>[].obs;
  var recentMessages = <Map<String, dynamic>>[].obs;
  var monthlyStats = <String, int>{}.obs;
  var petsCache = <String, Pet>{}.obs;
  var ownersCache = <String, Map<String, dynamic>>{}.obs;

  var selectedDate = DateTime.now().obs;
  var calendarAppointments = <DateTime, List<Appointment>>{}.obs;

  RealtimeSubscription? _appointmentSubscription;
  Timer? _fallbackTimer;
  var lastUpdateTime = DateTime.now().obs;
  var isRealTimeConnected = false.obs;

  var currentMessages = <Message>[].obs;
  var isLoadingConversation = false.obs;
  var isSendingMessage = false.obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final appointmentController = Get.find<WebAppointmentController>();

  var petProfilePictures = <String, String?>{}.obs;
  var petImageLoadingStates = <String, bool>{}.obs;

  var isDashboardCached = false.obs;
  var lastCacheTime = Rxn<DateTime>();
  final int cacheValidityMinutes = 30;

  // ============================================
// CRITICAL FIX: Dashboard should NOT reload when cached
// Replace these methods in admin_dashboard_controller.dart
// ============================================

// ============================================
// 1. FIXED onInit() - Instant display with cache
// ============================================
  @override
  void onInit() {
    super.onInit();
    print('>>> ============================================');
    print('>>> DASHBOARD CONTROLLER: onInit()');
    print('>>> ============================================');

    // CRITICAL: Check cache FIRST
    if (_isCacheValid()) {
      print('>>> ✓ Valid cache found - displaying immediately');
      print(
          '>>> Cache age: ${DateTime.now().difference(lastCacheTime.value!).inMinutes} minutes');

      // CRITICAL: Don't set loading - data is already there!
      isLoading.value = false;

      // Reconnect real-time in background (non-blocking)
      Future.microtask(() {
        print('>>> Reconnecting real-time in background...');
        _initializeRealTimeUpdates().then((_) {
          print('>>> ✓ Real-time reconnected');
        }).catchError((e) {
          print('>>> ⚠️ Real-time reconnection failed: $e');
        });
      });

      print('>>> ✓ Dashboard ready with cached data');
    } else {
      print('>>> ⚠️ No valid cache - performing full initialization');
      isLoading.value = true;
      initializeDashboard();
    }

    // Setup date change listener
    ever(selectedDate, (_) => fetchAppointmentsForDate(selectedDate.value));

    print('>>> ============================================');
  }

  @override
  void onClose() {
    print('>>> ============================================');
    print('>>> DASHBOARD CONTROLLER: onClose()');
    print(
        '>>> Cache status: ${isDashboardCached.value ? "PRESERVED" : "None"}');
    print('>>> ============================================');

    // CRITICAL: Only close real-time connections, DON'T clear data
    try {
      _appointmentSubscription?.close();
      print('>>> Appointment subscription closed');
    } catch (e) {
      print('>>> Error closing appointment subscription: $e');
    }

    try {
      _conversationSubscription?.close();
      print('>>> Conversation subscription closed');
    } catch (e) {
      print('>>> Error closing conversation subscription: $e');
    }

    try {
      _messageSubscription?.close();
      print('>>> Message subscription closed');
    } catch (e) {
      print('>>> Error closing message subscription: $e');
    }

    try {
      _fallbackTimer?.cancel();
      print('>>> Fallback timer cancelled');
    } catch (e) {
      print('>>> Error cancelling fallback timer: $e');
    }

    // CRITICAL: DON'T clear cached data - it will be reused on next init
    // DON'T call cleanupOnLogout() here - only call it from LogoutHelper

    print('>>> ℹ️ Cache preserved for fast re-initialization');
    print(
        '>>> Cache age: ${lastCacheTime.value != null ? DateTime.now().difference(lastCacheTime.value!).inMinutes : 0} minutes');
    print('>>> Cached items:');
    print('>>>   - Clinic: ${clinicData.value?.clinicName ?? "None"}');
    print('>>>   - Today appointments: ${todayAppointments.length}');
    print('>>>   - Upcoming appointments: ${upcomingAppointments.length}');
    print('>>>   - Recent messages: ${recentMessages.length}');
    print('>>>   - Appointment stats: ${appointmentStats.length}');
    print('>>> ============================================');

    super.onClose();
  }

  bool _isCacheValid() {
    // Check if cache flag is set
    if (!isDashboardCached.value) {
      print('>>> Cache check: No cache exists');
      return false;
    }

    // Check if cache timestamp exists
    if (lastCacheTime.value == null) {
      print('>>> Cache check: No cache timestamp');
      return false;
    }

    // Check cache age
    final cacheAge = DateTime.now().difference(lastCacheTime.value!);
    final isValid = cacheAge.inMinutes < cacheValidityMinutes;

    print(
        '>>> Cache check: ${isValid ? "VALID" : "EXPIRED"} (${cacheAge.inMinutes}m old, max ${cacheValidityMinutes}m)');

    // If valid by time, check if we have essential data
    if (isValid) {
      final hasClinic = clinicData.value != null;
      final hasStats = appointmentStats.isNotEmpty;

      print('>>> Cache data check:');
      print('>>>   - Clinic: $hasClinic');
      print('>>>   - Today appointments: ${todayAppointments.length}');
      print('>>>   - Upcoming appointments: ${upcomingAppointments.length}');
      print('>>>   - Recent messages: ${recentMessages.length}');
      print('>>>   - Stats: $hasStats');

      // Must have clinic data at minimum
      if (!hasClinic) {
        print('>>> Cache check: Missing essential clinic data');
        return false;
      }

      return true;
    }

    return false;
  }

  void invalidateCache() {
    print('>>> 🗑️ Invalidating dashboard cache');
    isDashboardCached.value = false;
    lastCacheTime.value = null;
  }

  @override
  Future<void> initializeDashboard() async {
    try {
      print('>>> ============================================');
      print('>>> INITIALIZING DASHBOARD (NO CACHE)');
      print('>>> ============================================');

      // Step 1: Fetch clinic data FIRST
      print('>>> Step 1: Fetching clinic data...');
      await fetchClinicData();

      if (clinicData.value == null || clinicData.value?.documentId == null) {
        print('>>> ERROR: No clinic data loaded!');
        isLoading.value = false;
        Get.snackbar(
          "Error",
          "Unable to load clinic data. Please check your permissions and try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      print('>>> ✓ Clinic loaded: ${clinicData.value!.clinicName}');
      print('>>> ✓ Clinic ID: ${clinicData.value!.documentId}');

      // Step 2: Fetch MINIMAL data in parallel
      print('>>> Step 2: Fetching minimal dashboard data...');
      try {
        await Future.wait([
          fetchTodaysAppointments(force: true), // Force fetch
          fetchUpcomingAppointments(force: true), // Force fetch
          fetchRecentMessages(), // Already optimized
          fetchAppointmentStats(), // Counts only
        ]);
        print('>>> ✓ Dashboard data loaded');

        // CRITICAL: Mark cache as valid AFTER data is loaded
        isDashboardCached.value = true;
        lastCacheTime.value = DateTime.now();
        print('>>> ✓ Cache created at: ${lastCacheTime.value}');
      } catch (e) {
        print('>>> WARNING: Error fetching dashboard data: $e');
      }

      // Step 3: Generate calendar data
      print('>>> Step 3: Generating calendar data...');
      try {
        await generateCalendarData();
        print('>>> ✓ Calendar generated');
      } catch (e) {
        print('>>> WARNING: Error generating calendar: $e');
      }

      // Step 4: Initialize real-time updates LAST
      print('>>> Step 4: Initializing real-time updates...');
      try {
        await _initializeRealTimeUpdates();
        print('>>> ✓ Real-time subscriptions active');
      } catch (e) {
        print('>>> WARNING: Error initializing real-time: $e');
      }

      print('>>> ============================================');
      print('>>> DASHBOARD INITIALIZATION COMPLETE');
      print('>>> - Clinic: ${clinicData.value?.clinicName ?? "Unknown"}');
      print('>>> - Today\'s Appointments: ${todayAppointments.length}');
      print('>>> - Upcoming Appointments: ${upcomingAppointments.length}');
      print('>>> - Recent Messages: ${recentMessages.length}');
      print(
          '>>> - Cache Valid Until: ${lastCacheTime.value?.add(Duration(minutes: cacheValidityMinutes))}');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR: Failed to load dashboard data: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      Get.snackbar(
        "Error",
        "Failed to load dashboard: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

// Add this method to refresh messages separately if needed
  Future<void> refreshMessages() async {
    try {
      await fetchRecentMessages();
      print('>>> Messages refreshed: ${recentMessages.length} recent messages');
    } catch (e) {
      print('>>> Error refreshing messages: $e');
    }
  }

  Future<void> _subscribeToAppointmentUpdates() async {
    try {
      // Ensure old subscription is closed
      await _appointmentSubscription?.close();
      _appointmentSubscription = null;

      print('>>> Creating new appointment subscription...');
      print('>>> Monitoring clinic: ${clinicData.value!.documentId}');

      final realtime = Realtime(authRepository.client);

      _appointmentSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.appointmentCollectionID}.documents'
      ]);

      _appointmentSubscription!.stream.listen(
        (response) {
          try {
            print('>>> ============================================');
            print('>>> REAL-TIME APPOINTMENT UPDATE RECEIVED');
            print('>>> Events: ${response.events}');
            print('>>> ============================================');

            // CRITICAL: Verify this update is for OUR clinic
            final updateClinicId = response.payload['clinicId'];
            final ourClinicId = clinicData.value?.documentId;

            print('>>> Update clinic: $updateClinicId');
            print('>>> Our clinic: $ourClinicId');

            if (updateClinicId != ourClinicId) {
              print('>>> ⚠️ Ignoring update for different clinic');
              return;
            }

            print('>>> ✓ Processing update for our clinic');
            _handleAppointmentRealTimeUpdate(response);

            // Update connection status
            isRealTimeConnected.value = true;
            lastUpdateTime.value = DateTime.now();

            print('>>> ============================================');
          } catch (e) {
            print('>>> ERROR processing real-time update: $e');
          }
        },
        onError: (error) {
          print('>>> ============================================');
          print('>>> REAL-TIME SUBSCRIPTION ERROR: $error');
          print('>>> ============================================');

          isRealTimeConnected.value = false;

          // Try to reconnect after delay
          Future.delayed(const Duration(seconds: 5), () {
            print('>>> Attempting to reconnect real-time subscription...');
            _subscribeToAppointmentUpdates().catchError((e) {
              print('>>> Reconnection failed: $e');
            });
          });

          // Increase fallback polling frequency
          _setupFallbackPolling(interval: 10);
        },
        onDone: () {
          print('>>> ============================================');
          print('>>> REAL-TIME SUBSCRIPTION CLOSED');
          print('>>> ============================================');

          isRealTimeConnected.value = false;

          // Try to reconnect
          Future.delayed(const Duration(seconds: 3), () {
            if (clinicData.value?.documentId != null) {
              print('>>> Attempting to reconnect...');
              _subscribeToAppointmentUpdates().catchError((e) {
                print('>>> Reconnection failed: $e');
              });
            }
          });
        },
      );

      print('>>> ✓ Appointment subscription stream listening');
    } catch (e, stackTrace) {
      print('>>> ERROR setting up appointment subscription: $e');
      print('>>> Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _handleAppointmentRealTimeUpdate(RealtimeMessage response) {
    try {
      print('>>> ============================================');
      print('>>> PROCESSING APPOINTMENT UPDATE');
      print('>>> Events: ${response.events}');
      print('>>> ============================================');

      final payload = response.payload;
      final appointmentId = payload['\$id'];

      print('>>> Appointment ID: $appointmentId');
      print('>>> Status: ${payload['status']}');
      print('>>> Service: ${payload['service']}');

      final appointment = Appointment.fromMap(payload);

      // Determine event type
      bool isCreate = false;
      bool isUpdate = false;
      bool isDelete = false;

      for (String event in response.events) {
        if (event.contains('.create')) {
          isCreate = true;
        } else if (event.contains('.update')) {
          isUpdate = true;
        } else if (event.contains('.delete')) {
          isDelete = true;
        }
      }

      print(
          '>>> Event type - Create: $isCreate, Update: $isUpdate, Delete: $isDelete');

      // Handle the update
      if (isDelete) {
        print('>>> Handling DELETE event');
        _handleDeletedAppointment(appointment);
      } else if (isCreate) {
        print('>>> Handling CREATE event');
        _handleNewAppointment(appointment);
      } else if (isUpdate) {
        print('>>> Handling UPDATE event');
        _handleUpdatedAppointment(appointment);
      }

      // Update timestamp
      lastUpdateTime.value = DateTime.now();

      // Show notification for new appointments
      if (isCreate && appointment.status == 'pending') {
        print('>>> Showing new appointment notification');
        _showNewAppointmentNotification(appointment);
      }

      print('>>> ✓ Update processed successfully');
      print('>>> ============================================');
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ERROR handling real-time update: $e');
      print('>>> Stack trace: $stackTrace');
      print('>>> ============================================');
    }
  }

  void _handleNewAppointment(Appointment appointment) {
    try {
      print('>>> ============================================');
      print('>>> HANDLING NEW APPOINTMENT');
      print('>>> Appointment ID: ${appointment.documentId}');
      print('>>> Status: ${appointment.status}');
      print(
          '>>> Date: ${DateFormat('yyyy-MM-dd HH:mm').format(appointment.dateTime)}');
      print('>>> Current today count: ${todayAppointments.length}');
      print('>>> ============================================');

      // Check if appointment already exists in main list
      final existingIndex = appointments.indexWhere(
        (a) => a.documentId == appointment.documentId,
      );

      if (existingIndex == -1) {
        // Add to main list
        appointments.add(appointment);
        appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        print('>>> ✓ Added to main appointments list');
      } else {
        // Update existing
        appointments[existingIndex] = appointment;
        print('>>> ✓ Updated existing appointment in main list');
      }

      // Check if this appointment is for today
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final appointmentDate = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );

      if (appointmentDate.isAtSameMomentAs(todayDate)) {
        print('>>> ✓ Appointment is for today - adding to today\'s list');

        // FIXED: Work with current list, don't rebuild from scratch
        final currentList = List<Appointment>.from(todayAppointments);

        // Check if appointment already exists in today's list
        final existingTodayIndex = currentList.indexWhere(
          (a) => a.documentId == appointment.documentId,
        );

        if (existingTodayIndex != -1) {
          // Remove old version
          currentList.removeAt(existingTodayIndex);
          print('>>> Removed old version from position $existingTodayIndex');
        }

        // Insert at the correct position based on priority
        int insertIndex = 0;

        // Find correct position: pending appointments first, then by time
        for (int i = 0; i < currentList.length; i++) {
          final current = currentList[i];

          // If new appointment is pending and current is not, insert here
          if (appointment.status == 'pending' && current.status != 'pending') {
            insertIndex = i;
            break;
          }

          // If both same priority, sort by time
          if ((appointment.status == 'pending' &&
                  current.status == 'pending') ||
              (appointment.status != 'pending' &&
                  current.status != 'pending')) {
            if (appointment.dateTime.isBefore(current.dateTime)) {
              insertIndex = i;
              break;
            }
          }

          insertIndex = i + 1;
        }

        // Insert at calculated position
        currentList.insert(insertIndex, appointment);
        print('>>> Inserted at position $insertIndex');

        // Keep only top 3
        final top3 = currentList.take(3).toList();

        print('>>> Current list after insertion (showing ${top3.length}):');
        for (var i = 0; i < top3.length; i++) {
          print(
              '>>>   [$i] ${top3[i].documentId}: ${top3[i].status} at ${DateFormat('HH:mm').format(top3[i].dateTime)}');
        }

        // Update with smooth transition
        todayAppointments.value = List.from(top3);
        print(
            '>>> ✓ Today\'s appointments smoothly updated: ${todayAppointments.length}');
      } else {
        print(
            '>>> ⚠️ Appointment is NOT for today - skipping today\'s list update');
      }

      // Update other lists
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _updateCalendarData(appointment, isNew: true);

      // Fetch related data if not cached
      if (!petsCache.containsKey(appointment.petId)) {
        _fetchOwnerData(appointment.userId);
        preloadPetImagesForAppointments([appointment]);
      }

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();

      print('>>> ✓ New appointment fully processed');
      print('>>> Final today count: ${todayAppointments.length}');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR handling new appointment: $e');
      print('>>> Stack trace: ${StackTrace.current}');
    }
  }

  void _handleUpdatedAppointment(Appointment appointment) {
    try {
      print('>>> ============================================');
      print('>>> HANDLING UPDATED APPOINTMENT');
      print('>>> Appointment ID: ${appointment.documentId}');
      print('>>> New status: ${appointment.status}');
      print('>>> Current today count: ${todayAppointments.length}');
      print('>>> ============================================');

      // Update in main list
      final index = appointments.indexWhere(
        (a) => a.documentId == appointment.documentId,
      );

      if (index != -1) {
        final oldStatus = appointments[index].status;
        appointments[index] = appointment;
        print(
            '>>> ✓ Updated in main list (status: $oldStatus → ${appointment.status})');
      } else {
        appointments.add(appointment);
        print('>>> ⚠️ Not found in main list, added as new');
      }

      // Check if this appointment is for today
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final appointmentDate = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );

      if (appointmentDate.isAtSameMomentAs(todayDate)) {
        print('>>> ✓ Appointment is for today - updating today\'s list');

        // FIXED: Work with current list, update in place
        final currentList = List<Appointment>.from(todayAppointments);

        // Find if appointment exists in current list
        final existingIndex = currentList.indexWhere(
          (a) => a.documentId == appointment.documentId,
        );

        if (existingIndex != -1) {
          print('>>> Found in today\'s list at position $existingIndex');

          // Remove from current position
          currentList.removeAt(existingIndex);

          // Find new correct position based on updated status/time
          int insertIndex = 0;

          for (int i = 0; i < currentList.length; i++) {
            final current = currentList[i];

            // If updated appointment is pending and current is not, insert here
            if (appointment.status == 'pending' &&
                current.status != 'pending') {
              insertIndex = i;
              break;
            }

            // If both same priority, sort by time
            if ((appointment.status == 'pending' &&
                    current.status == 'pending') ||
                (appointment.status != 'pending' &&
                    current.status != 'pending')) {
              if (appointment.dateTime.isBefore(current.dateTime)) {
                insertIndex = i;
                break;
              }
            }

            insertIndex = i + 1;
          }

          // Reinsert at new position
          currentList.insert(insertIndex, appointment);
          print('>>> Moved from position $existingIndex to $insertIndex');
        } else {
          print('>>> Not in today\'s list - checking if should be added');

          // Not in today's list - check if it should be in top 3
          // Get all today's appointments to determine if this should be shown
          final allTodayAppts = appointments.where((appt) {
            final apptDate = DateTime(
              appt.dateTime.year,
              appt.dateTime.month,
              appt.dateTime.day,
            );
            return apptDate.isAtSameMomentAs(todayDate);
          }).toList();

          // Sort by priority
          allTodayAppts.sort((a, b) {
            if (a.status == 'pending' && b.status != 'pending') return -1;
            if (b.status == 'pending' && a.status != 'pending') return 1;
            return a.dateTime.compareTo(b.dateTime);
          });

          // Take top 3
          final top3 = allTodayAppts.take(3).toList();

          // Check if updated appointment made it to top 3
          final isInTop3 =
              top3.any((a) => a.documentId == appointment.documentId);

          if (isInTop3) {
            print('>>> Updated appointment is now in top 3 - rebuilding list');
            todayAppointments.value = List.from(top3);
            print(
                '>>> ✓ Today\'s appointments rebuilt: ${todayAppointments.length}');
          } else {
            print(
                '>>> Updated appointment is not in top 3 - keeping current list');
          }

          // Early return since we already updated
          _processUpcomingAppointments();
          _updateAppointmentStats();
          _updateCalendarData(appointment, isUpdate: true);
          lastCacheTime.value = DateTime.now();
          return;
        }

        // Keep only top 3
        final top3 = currentList.take(3).toList();

        print('>>> Current list after update (showing ${top3.length}):');
        for (var i = 0; i < top3.length; i++) {
          print(
              '>>>   [$i] ${top3[i].documentId}: ${top3[i].status} at ${DateFormat('HH:mm').format(top3[i].dateTime)}');
        }

        // Update smoothly
        todayAppointments.value = List.from(top3);
        print(
            '>>> ✓ Today\'s appointments smoothly updated: ${todayAppointments.length}');
      } else {
        print('>>> ⚠️ Appointment is NOT for today');

        // Remove from today's list if it was moved to a different day
        final wasInToday = todayAppointments.any(
          (a) => a.documentId == appointment.documentId,
        );

        if (wasInToday) {
          print('>>> Removing from today\'s list (moved to different day)');
          final currentList = List<Appointment>.from(todayAppointments);
          currentList
              .removeWhere((a) => a.documentId == appointment.documentId);

          // If we now have less than 3, try to fill from main list
          if (currentList.length < 3) {
            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);

            final allTodayAppts = appointments.where((appt) {
              final apptDate = DateTime(
                appt.dateTime.year,
                appt.dateTime.month,
                appt.dateTime.day,
              );
              return apptDate.isAtSameMomentAs(todayDate);
            }).toList();

            allTodayAppts.sort((a, b) {
              if (a.status == 'pending' && b.status != 'pending') return -1;
              if (b.status == 'pending' && a.status != 'pending') return 1;
              return a.dateTime.compareTo(b.dateTime);
            });

            final top3 = allTodayAppts.take(3).toList();
            todayAppointments.value = List.from(top3);
            print('>>> Refilled today\'s list: ${todayAppointments.length}');
          } else {
            todayAppointments.value = List.from(currentList);
            print('>>> Updated today\'s list: ${todayAppointments.length}');
          }
        }
      }

      // Update other lists
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _updateCalendarData(appointment, isUpdate: true);

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();

      print('>>> ✓ Updated appointment fully processed');
      print('>>> Final today count: ${todayAppointments.length}');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR handling updated appointment: $e');
      print('>>> Stack trace: ${StackTrace.current}');
    }
  }

  void _handleDeletedAppointment(Appointment appointment) {
    try {
      print('>>> ============================================');
      print('>>> HANDLING DELETED APPOINTMENT');
      print('>>> Appointment ID: ${appointment.documentId}');
      print('>>> Current today count: ${todayAppointments.length}');
      print('>>> ============================================');

      // Remove from main list
      final removedCount = appointments.length;
      appointments.removeWhere((a) => a.documentId == appointment.documentId);
      final actuallyRemoved = removedCount - appointments.length;

      if (actuallyRemoved > 0) {
        print('>>> ✓ Removed from main appointments list');

        // Check if it was in today's list
        final wasInToday = todayAppointments.any(
          (a) => a.documentId == appointment.documentId,
        );

        if (wasInToday) {
          print('>>> ✓ Was in today\'s list - reprocessing');

          // Reprocess today's appointments to get new top 3
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          final allTodayAppts = appointments.where((appt) {
            final apptDate = DateTime(
              appt.dateTime.year,
              appt.dateTime.month,
              appt.dateTime.day,
            );
            return apptDate.isAtSameMomentAs(todayDate);
          }).toList();

          print(
              '>>> Found ${allTodayAppts.length} remaining today appointments');

          // Sort by priority
          allTodayAppts.sort((a, b) {
            if (a.status == 'pending' && b.status != 'pending') return -1;
            if (b.status == 'pending' && a.status != 'pending') return 1;
            return a.dateTime.compareTo(b.dateTime);
          });

          // Take top 3
          final top3 = allTodayAppts.take(3).toList();

          print('>>> Selected top ${top3.length} for display');

          // Create new list
          final newList = <Appointment>[];
          for (var appt in top3) {
            newList.add(appt);
          }

          todayAppointments.value = newList;
          print(
              '>>> ✓ Today\'s appointments updated: ${todayAppointments.length}');
        }
      }

      // Update other lists
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _removeFromCalendarData(appointment);

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();

      print('>>> ✓ Deleted appointment fully processed');
      print('>>> Final today count: ${todayAppointments.length}');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR handling deleted appointment: $e');
      print('>>> Stack trace: ${StackTrace.current}');
    }
  }

  void _updateCalendarData(Appointment appointment,
      {bool isNew = false, bool isUpdate = false}) {
    final date = DateTime(
      appointment.dateTime.year,
      appointment.dateTime.month,
      appointment.dateTime.day,
    );

    if (isNew || isUpdate) {
      if (calendarAppointments[date] == null) {
        calendarAppointments[date] = [];
      }

      if (isUpdate) {
        calendarAppointments[date]!
            .removeWhere((a) => a.documentId == appointment.documentId);
      }

      calendarAppointments[date]!.add(appointment);
    }

    calendarAppointments.refresh();
  }

  void _removeFromCalendarData(Appointment appointment) {
    final date = DateTime(
      appointment.dateTime.year,
      appointment.dateTime.month,
      appointment.dateTime.day,
    );

    calendarAppointments[date]
        ?.removeWhere((a) => a.documentId == appointment.documentId);
    if (calendarAppointments[date]?.isEmpty ?? false) {
      calendarAppointments.remove(date);
    }
    calendarAppointments.refresh();
  }

  void _updateAppointmentStats() {
    try {
      final stats = <String, int>{
        'total': appointments.length,
        'pending': appointments.where((a) => a.status == 'pending').length,
        'accepted': appointments.where((a) => a.status == 'accepted').length,
        'completed': appointments.where((a) => a.status == 'completed').length,
        'cancelled': appointments.where((a) => a.status == 'cancelled').length,
        'declined': appointments.where((a) => a.status == 'declined').length,
        'today': todayAppointments.length,
      };

      appointmentStats.assignAll(stats);
      appointmentStats.refresh();

      print(
          '>>> ✓ Stats updated: ${stats['total']} total, ${stats['pending']} pending, ${stats['today']} today');
    } catch (e) {
      print('>>> ERROR updating stats: $e');
    }
  }

  void _showNewAppointmentNotification(Appointment appointment) {
    Get.snackbar(
      "New Appointment",
      "New appointment from ${getOwnerName(appointment.userId)} for ${getPetName(appointment.petId)}",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.TOP,
      mainButton: TextButton(
        onPressed: () {
          navigateToAppointments('pending');
        },
        child: const Text("View", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Setup more aggressive fallback polling for messages
  void _setupFallbackPolling({int interval = 30}) {
    _fallbackTimer?.cancel();

    print('>>> Setting up fallback polling with ${interval}s interval');

    _fallbackTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (!isRealTimeConnected.value) {
        print(">>> Fallback polling: refreshing data...");
        // Refresh both appointments and messages
        Future.wait([
          fetchAllAppointments(),
          fetchRecentMessages(),
        ]);
      }
    });
  }

  @override
  Future<void> refreshDashboard() async {
    print('>>> ============================================');
    print('>>> MANUAL DASHBOARD REFRESH (SMART)');
    print('>>> ============================================');

    try {
      // Check if cache is still valid and real-time is connected
      if (_isCacheValid() && isRealTimeConnected.value) {
        print('>>> ℹ️ Cache is valid and real-time is connected');
        print('>>> Just updating timestamp, no need to refetch');

        lastUpdateTime.value = DateTime.now();

        Get.snackbar(
          "Already Up-to-Date",
          "Dashboard is showing live data",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(8),
        );

        return;
      }

      print('>>> 🔄 Performing smart refresh');

      // Silently refresh in background (no loading spinner)
      await Future.wait([
        fetchTodaysAppointments(force: true),
        fetchUpcomingAppointments(force: true),
        fetchRecentMessages(),
        fetchAppointmentStats(),
      ]);

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
      lastUpdateTime.value = DateTime.now();
      isDashboardCached.value = true;

      print('>>> ✓ Dashboard refreshed and cache updated');

      Get.snackbar(
        "Refreshed",
        "Dashboard data updated",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(8),
      );
    } catch (e) {
      print('>>> ERROR refreshing dashboard: $e');

      Get.snackbar(
        "Refresh Failed",
        "Could not update dashboard data",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }

    // Try to reconnect real-time if disconnected
    if (!isRealTimeConnected.value) {
      print('>>> Attempting to reconnect real-time...');
      try {
        await _initializeRealTimeUpdates();
      } catch (e) {
        print('>>> Failed to reconnect real-time: $e');
      }
    }

    print('>>> ============================================');
  }

  /// Send a message in the current conversation
  Future<void> sendMessageInConversation({
    required String conversationId,
    required String messageText,
    bool isStarterMessage = false,
  }) async {
    try {
      if (messageText.trim().isEmpty) {
        print('>>> ERROR: Empty message text');
        return;
      }

      isSendingMessage.value = true;

      print('>>> ============================================');
      print('>>> SENDING MESSAGE');
      print('>>> Conversation: $conversationId');
      print('>>> Sender: ${session.userId}');
      print('>>> Message: $messageText');
      print('>>> ============================================');

      // Send the message using the updated repository method
      final message = await authRepository.sendMessage(
        conversationId: conversationId,
        senderId: session.userId,
        messageText: messageText,
      );

      print('>>> Message sent successfully: ${message.documentId}');
      print('>>> Sent at: ${message.detailedTimeFormatted}');

      // Add to current messages list
      currentMessages.add(message);
      currentMessages.refresh();

      // Clear input
      messageController.clear();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR sending message: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      print('>>> Marking conversation as read: $conversationId');

      await authRepository.markMessagesAsRead(conversationId, session.userId);

      print('>>> Conversation marked as read');
    } catch (e) {
      print('>>> Error marking conversation as read: $e');
    }
  }

  /// Open a specific conversation and load its messages
  Future<void> openConversation(
    Conversation conversation,
    String userId,
    String userType,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> OPENING CONVERSATION');
      print('>>> Conversation ID: ${conversation.documentId}');
      print('>>> User ID: $userId');
      print('>>> User Type: $userType');
      print('>>> ============================================');

      isLoadingConversation.value = true;

      // Load messages for this conversation
      final messages = await authRepository.getConversationMessages(
        conversation.documentId!,
        limit: 50,
      );

      print('>>> Loaded ${messages.length} messages');

      currentMessages.assignAll(messages);
      currentMessages.refresh();

      // Mark as read
      await markConversationAsRead(conversation.documentId!);

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });

      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR opening conversation: $e');
      Get.snackbar('Error', 'Failed to open conversation');
    } finally {
      isLoadingConversation.value = false;
    }
  }

  /// Check if a user ID belongs to current admin
  bool isCurrentUser(String userId) {
    return userId == session.userId;
  }

  /// Get user status by user ID
  UserStatus? getUserStatus(String userId) {
    try {
      // This would typically fetch from a cache or provider
      // For now, return offline status
      return UserStatus.offline(userId);
    } catch (e) {
      print('Error getting user status: $e');
      return null;
    }
  }

  /// Handle incoming real-time message
  void _handleIncomingMessage(Message message) {
    try {
      print('>>> ============================================');
      print('>>> INCOMING MESSAGE RECEIVED');
      print('>>> Message ID: ${message.documentId}');
      print('>>> From: ${message.senderId}');
      print('>>> Text: ${message.messageText}');
      print('>>> ============================================');

      // Check if message already exists
      final exists =
          currentMessages.any((m) => m.documentId == message.documentId);

      if (!exists) {
        currentMessages.add(message);
        currentMessages.refresh();

        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // Mark as read
        markConversationAsRead(message.conversationId);
      }

      // Refresh recent messages if needed
      Future.delayed(const Duration(milliseconds: 500), () {
        refreshMessages();
      });

      print('>>> ============================================');
    } catch (e) {
      print('>>> Error handling incoming message: $e');
    }
  }

  /// Subscribe to conversation updates for real-time message refreshes
  Future<void> _subscribeToConversationUpdates() async {
    try {
      await _conversationSubscription?.close();

      if (clinicData.value?.documentId == null) {
        print('>>> ERROR: Cannot subscribe - no clinic ID');
        return;
      }

      final realtime = Realtime(authRepository.client);

      _conversationSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.conversationsCollectionID}.documents'
      ]);

      _conversationSubscription!.stream.listen(
        (response) {
          _handleConversationRealTimeUpdate(response);
        },
        onError: (error) {
          print(">>> Conversation subscription error: $error");
          print(">>> Attempting to resubscribe in 3 seconds...");
          Future.delayed(const Duration(seconds: 3), () {
            if (clinicData.value?.documentId != null) {
              _subscribeToConversationUpdates();
            }
          });
        },
        onDone: () {
          print(">>> Conversation subscription stream closed");
        },
      );

      print(
          ">>> Subscribed to conversation updates for clinic: ${clinicData.value!.documentId}");
    } catch (e) {
      print(">>> Error setting up conversation subscription: $e");
    }
  }

  Future<void> _initializeRealTimeUpdates() async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      print('>>> WARNING: Cannot initialize real-time - no clinic ID');
      return;
    }

    try {
      print('>>> ============================================');
      print('>>> INITIALIZING REAL-TIME UPDATES (ENHANCED)');
      print('>>> Clinic ID: ${clinicData.value!.documentId}');
      print('>>> ============================================');

      // Close old subscriptions first
      await _appointmentSubscription?.close();
      _appointmentSubscription = null;

      await _conversationSubscription?.close();
      _conversationSubscription = null;

      await _messageSubscription?.close();
      _messageSubscription = null;

      _fallbackTimer?.cancel();
      _fallbackTimer = null;

      print('>>> Old subscriptions closed');

      // Subscribe to appointments
      await _subscribeToAppointmentUpdates();
      print('>>> ✓ Appointment subscription active');

      // Subscribe to conversations (for message updates)
      await _subscribeToConversationUpdates();
      print('>>> ✓ Conversation subscription active');

      // Setup fallback polling (safety net)
      _setupFallbackPolling(interval: 30); // 30 seconds as backup
      print('>>> ✓ Fallback polling setup (30s interval)');

      isRealTimeConnected.value = true;
      lastUpdateTime.value = DateTime.now();

      print('>>> ============================================');
      print('>>> REAL-TIME UPDATES INITIALIZED SUCCESSFULLY');
      print('>>> ============================================');
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ERROR initializing real-time updates: $e');
      print('>>> Stack trace: $stackTrace');
      print('>>> ============================================');

      isRealTimeConnected.value = false;

      // Setup more frequent fallback polling on error
      _setupFallbackPolling(interval: 15);
    }
  }

  void _handleConversationRealTimeUpdate(RealtimeMessage response) {
    try {
      final payload = response.payload;

      // Only process if this is for our clinic
      final conversationClinicId = payload['clinicId'];
      if (conversationClinicId != clinicData.value?.documentId) {
        print('>>> Conversation not for this clinic - skipping');
        return;
      }

      print('>>> ============================================');
      print('>>> CONVERSATION UPDATE RECEIVED');
      print('>>> Events: ${response.events}');
      print('>>> Conversation ID: ${payload['\$id']}');
      print('>>> Last Message: ${payload['lastMessageText']}');
      print('>>> ============================================');

      // Check if this is a create or update event (new or updated message)
      final isCreateEvent = response.events.any(
        (event) =>
            event.contains('databases.*.collections.*.documents.*.create'),
      );

      final isUpdateEvent = response.events.any(
        (event) =>
            event.contains('databases.*.collections.*.documents.*.update'),
      );

      if (isCreateEvent || isUpdateEvent) {
        print(
            '>>> Message event detected - updating recent messages immediately');

        // Update immediately with the new conversation data
        _updateRecentMessagesFromPayload(payload);

        // Also refresh from database after a delay for consistency
        Future.delayed(const Duration(milliseconds: 500), () {
          print('>>> Performing full refresh from database');
          fetchRecentMessages();
        });
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> Error handling conversation update: $e');
    }
  }

  /// Helper method to fetch user profile picture
  Future<Map<String, dynamic>> _fetchUserProfilePicture(String userId) async {
    try {
      if (userId.isEmpty) {
        return {
          'url': '',
          'hasProfilePicture': false,
        };
      }

      final userDoc = await authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);
        if (user.hasProfilePicture && user.profilePictureId != null) {
          try {
            final profilePictureUrl =
                authRepository.getUserProfilePictureUrl(user.profilePictureId!);
            return {
              'url': profilePictureUrl,
              'hasProfilePicture': true,
            };
          } catch (e) {
            print('>>> Error generating profile picture URL: $e');
            return {
              'url': '',
              'hasProfilePicture': false,
            };
          }
        }
      }
      return {
        'url': '',
        'hasProfilePicture': false,
      };
    } catch (e) {
      print('>>> Error fetching profile picture for $userId: $e');
      return {
        'url': '',
        'hasProfilePicture': false,
      };
    }
  }

  /// Update recent messages immediately from payload without waiting for database
  void _updateRecentMessagesFromPayload(Map<String, dynamic> payload) {
    try {
      print('>>> Updating recent messages from real-time payload');

      // Validate payload has required fields
      if (payload['lastMessageText'] == null ||
          payload['lastMessageTime'] == null ||
          payload['\$id'] == null ||
          payload['userId'] == null) {
        print('>>> Missing required fields in payload - skipping');
        return;
      }

      final conversationId = payload['\$id'] as String;
      final userId = payload['userId'] as String;
      final lastMessageText = payload['lastMessageText'] as String;
      final lastMessageTime =
          DateTime.parse(payload['lastMessageTime'] as String);
      final clinicUnreadCount = payload['clinicUnreadCount'] as int? ?? 0;

      print('>>> Looking up user data for: $userId');

      // Fetch user data for name and profile picture
      String senderName = 'Unknown User';
      String profilePictureUrl = '';
      bool hasProfilePicture = false;

      if (_userNamesCache.containsKey(userId)) {
        senderName = _userNamesCache[userId]!;
        print('>>> Using cached user name: $senderName');
      } else {
        // Fetch user name asynchronously
        _getUserName(userId).then((name) {
          print('>>> Fetched user name: $name');
          // Update the message with fetched name
          final index = recentMessages.indexWhere(
            (m) => m['senderId'] == userId,
          );
          if (index != -1) {
            recentMessages[index]['senderName'] = name;
            recentMessages.refresh();
          }
        }).catchError((e) {
          print('>>> Error fetching user name: $e');
        });
        senderName = userId.length > 6
            ? 'User #${userId.substring(0, 6)}'
            : 'Unknown User';
      }

      // Fetch profile picture asynchronously
      _fetchUserProfilePicture(userId).then((profileData) {
        print('>>> Fetched profile picture for user: $userId');
        final index = recentMessages.indexWhere(
          (m) => m['senderId'] == userId,
        );
        if (index != -1) {
          recentMessages[index]['profilePictureUrl'] = profileData['url'] ?? '';
          recentMessages[index]['hasProfilePicture'] =
              profileData['hasProfilePicture'] ?? false;
          recentMessages.refresh();
        }
      }).catchError((e) {
        print('>>> Error fetching profile picture: $e');
      });

      final newMessage = {
        'id': conversationId,
        'senderName': senderName,
        'senderId': userId,
        'message': lastMessageText,
        'time': lastMessageTime,
        'isRead': clinicUnreadCount == 0,
        'unreadCount': clinicUnreadCount,
        'conversationId': conversationId,
        'profilePictureUrl': profilePictureUrl,
        'hasProfilePicture': hasProfilePicture,
      };

      print('>>> New message data created');

      // Find if this conversation already exists in recent messages
      final existingIndex = recentMessages.indexWhere(
        (m) => m['conversationId'] == conversationId,
      );

      if (existingIndex != -1) {
        print('>>> Updating existing message at index $existingIndex');
        recentMessages[existingIndex] = newMessage;
      } else {
        print('>>> Adding as new message');
        recentMessages.insert(0, newMessage);
      }

      // Keep only the 3 most recent
      if (recentMessages.length > 3) {
        print('>>> Trimming to 3 most recent messages');
        recentMessages.value = recentMessages.take(3).toList();
      }

      // Sort by time to ensure most recent is first
      recentMessages.sort((a, b) {
        final timeA = a['time'] as DateTime;
        final timeB = b['time'] as DateTime;
        return timeB.compareTo(timeA);
      });

      print('>>> Recent messages updated. Total: ${recentMessages.length}');
      recentMessages.refresh();
    } catch (e, stackTrace) {
      print('>>> Error updating recent messages from payload: $e');
      print('>>> Stack trace: $stackTrace');
    }
  }

  void _removeDuplicateAppointments() {
    final uniqueAppointments = <Appointment>[];
    final seenIds = <String>{};

    for (var appointment in appointments) {
      if (appointment.documentId != null &&
          !seenIds.contains(appointment.documentId)) {
        seenIds.add(appointment.documentId!);
        uniqueAppointments.add(appointment);
      }
    }

    if (uniqueAppointments.length != appointments.length) {
      appointments.assignAll(uniqueAppointments);
      print(
          "Removed ${appointments.length - uniqueAppointments.length} duplicate appointments");
    }
  }

  Future<void> fetchClinicData() async {
    try {
      print('>>> ============================================');
      print('>>> FETCHING CLINIC DATA');
      print('>>> ============================================');

      final user = await authRepository.getUser();
      if (user == null) {
        print('>>> ERROR: No user found');
        throw Exception('User not authenticated');
      }

      print('>>> User ID: ${user.$id}');

      // Get user role from storage
      final storage = GetStorage();
      final userRole = storage.read('role') as String?;

      print('>>> User Role: $userRole');

      String? clinicId;

      if (userRole == 'staff') {
        // Staff: Get clinicId from storage
        clinicId = storage.read('clinicId') as String?;
        print('>>> DASHBOARD: Staff mode - using stored clinicId: $clinicId');

        if (clinicId == null || clinicId.isEmpty) {
          print('>>> ERROR: Staff has no clinicId assigned');
          throw Exception('No clinic assigned to staff account');
        }
      } else {
        // Admin: Get clinic by admin ID
        print('>>> DASHBOARD: Admin mode - looking up clinic');
        final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
        if (clinicDoc != null) {
          clinicId = clinicDoc.$id;
          print('>>> Found clinic by admin ID: $clinicId');
        } else {
          print('>>> ERROR: No clinic found for admin');
          throw Exception('No clinic found for this admin account');
        }
      }

      if (clinicId != null && clinicId.isNotEmpty) {
        print('>>> Fetching clinic document for ID: $clinicId');
        final clinicDoc = await authRepository.getClinicById(clinicId);

        if (clinicDoc != null) {
          clinicData.value = Clinic.fromMap(clinicDoc.data);
          clinicData.value!.documentId = clinicDoc.$id;
          print(
              '>>> ✓ DASHBOARD: Clinic loaded: ${clinicData.value!.clinicName}');
          print('>>> ✓ DASHBOARD: Clinic ID: ${clinicData.value!.documentId}');
        } else {
          print('>>> ERROR: Clinic document not found for ID: $clinicId');
          throw Exception('Clinic document not found');
        }
      } else {
        print('>>> ERROR: No valid clinicId available');
        throw Exception('No clinic ID available');
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR fetching clinic data: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      clinicData.value = null; // Ensure it's null on error
      rethrow; // Re-throw to be caught by initializeDashboard
    }
  }

  Future<void> fetchAllAppointments() async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      print('>>> ERROR: Cannot fetch appointments - no clinic ID');
      return; // DON'T clear appointments
    }

    try {
      print(
          '>>> Fetching all appointments for clinic: ${clinicData.value!.documentId}');
      final result = await authRepository.getClinicAppointments(
        clinicData.value!.documentId!,
      );
      print('>>> Found ${result.length} appointments');

      appointments.assignAll(result);

      // DON'T call _fetchRelatedData() here - it's expensive
      // Only fetch when needed

      _processTodayAppointments();
      _processUpcomingAppointments();

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
    } catch (e) {
      print(">>> ERROR fetching appointments: $e");
      // DON'T clear on error
    }
  }

  Future<void> fetchAppointmentStats() async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      print('>>> ERROR: Cannot fetch stats - no clinic ID');
      appointmentStats.clear();
      return;
    }

    try {
      print('>>> ============================================');
      print('>>> FETCHING APPOINTMENT STATS (OPTIMIZED - COUNTS ONLY)');
      print('>>> Clinic: ${clinicData.value!.documentId}');
      print('>>> ============================================');

      // OPTIMIZATION: Use Appwrite's count functionality instead of fetching all documents
      // Fetch counts for each status in parallel
      final futures = await Future.wait([
        // Pending count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'pending'),
            Query.limit(1), // We only need the total count
          ],
        ),
        // Accepted count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'accepted'),
            Query.limit(1),
          ],
        ),
        // Completed count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'completed'),
            Query.limit(1),
          ],
        ),
        // Cancelled count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'cancelled'),
            Query.limit(1),
          ],
        ),
        // Declined count
        authRepository.appWriteProvider.databases!.listDocuments(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.appointmentCollectionID,
          queries: [
            Query.equal('clinicId', clinicData.value!.documentId!),
            Query.equal('status', 'declined'),
            Query.limit(1),
          ],
        ),
      ]);

      final pendingCount = futures[0].total;
      final acceptedCount = futures[1].total;
      final completedCount = futures[2].total;
      final cancelledCount = futures[3].total;
      final declinedCount = futures[4].total;

      final totalCount = pendingCount +
          acceptedCount +
          completedCount +
          cancelledCount +
          declinedCount;

      final stats = <String, int>{
        'total': totalCount,
        'pending': pendingCount,
        'accepted': acceptedCount,
        'completed': completedCount,
        'cancelled': cancelledCount,
        'declined': declinedCount,
        'today': todayAppointments.length, // Use already fetched today's count
      };

      appointmentStats.assignAll(stats);

      print('>>> Stats fetched:');
      print('>>>   - Total: $totalCount');
      print('>>>   - Pending: $pendingCount');
      print('>>>   - Accepted: $acceptedCount');
      print('>>>   - Completed: $completedCount');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR fetching appointment stats: $e');
      appointmentStats.clear();
    }
  }

  Future<void> _fetchOwnerData(String userId) async {
    if (!ownersCache.containsKey(userId)) {
      try {
        final ownerDoc = await authRepository.getUserById(userId);
        if (ownerDoc != null) {
          // Create a proper User object
          final user = User.fromMap(ownerDoc.data);
          ownersCache[userId] = {
            'name': user.name,
            'email': user.email,
            'phone': user.phone,
          };
        } else {
          // Add fallback data to prevent repeated fetching
          ownersCache[userId] = {
            'name': 'User #${userId.substring(0, 6)}',
            'email': 'N/A',
            'phone': 'N/A',
          };
        }
      } catch (e) {
        print("Error fetching owner $userId: $e");
        // Add fallback data
        ownersCache[userId] = {
          'name': 'User #${userId.substring(0, 6)}',
          'email': 'N/A',
          'phone': 'N/A',
        };
      }
    }
  }

  Future<void> _fetchRelatedData() async {
    for (var appointment in appointments) {
      // Skip if pet is already cached
      if (petsCache.containsKey(appointment.petId)) {
        continue;
      }

      // Skip empty petId
      if (appointment.petId.isEmpty) {
        print(
            ">>> Skipping empty petId for appointment ${appointment.documentId}");
        continue;
      }

      try {
        print(">>> Fetching pet data for: ${appointment.petId}");

        // Try to get pet by ID if it looks like a valid document ID
        Pet? pet;

        if (_isValidDocumentId(appointment.petId)) {
          print(">>>   Trying to fetch by document ID...");
          try {
            final petDoc = await authRepository.getPetById(appointment.petId);
            if (petDoc != null) {
              pet = Pet.fromMap(petDoc.data);
              pet.documentId = petDoc.$id;
              print(">>>   ✓ Found pet by ID: ${pet.name}");
            }
          } catch (e) {
            print(">>>   ✗ Pet not found by ID: $e");
          }
        }

        // If not found by ID, try by name
        if (pet == null) {
          print(">>>   Trying to fetch by name...");
          try {
            final petByName =
                await authRepository.getPetByName(appointment.petId);
            if (petByName != null) {
              pet = Pet.fromMap(petByName.data);
              pet.documentId = petByName.$id;
              print(">>>   ✓ Found pet by name: ${pet.name}");
            }
          } catch (e) {
            print(">>>   ✗ Pet not found by name: $e");
          }
        }

        // If still not found, create fallback
        if (pet == null) {
          print(">>>   Creating fallback pet data");
          pet = Pet(
            petId: appointment.petId,
            userId: appointment.userId,
            name: _formatPetName(appointment.petId),
            type: 'Unknown',
            breed: 'Unknown',
          );
        }

        // Cache the pet
        petsCache[appointment.petId] = pet;
        print(">>>   ✓ Pet cached successfully");
      } catch (e) {
        print(">>> Error fetching pet ${appointment.petId}: $e");
        // Create fallback pet
        petsCache[appointment.petId] = Pet(
          petId: appointment.petId,
          userId: appointment.userId,
          name: _formatPetName(appointment.petId),
          type: 'Unknown',
          breed: 'Unknown',
        );
      }

      // Fetch owner data
      if (!ownersCache.containsKey(appointment.userId)) {
        await _fetchOwnerData(appointment.userId);
      }
    }
  }

  String _formatPetName(String rawName) {
    if (rawName.isEmpty) return 'Unknown Pet';

    // If it looks like a document ID, create a generic name
    if (_isValidDocumentId(rawName) && !rawName.contains(' ')) {
      return 'Pet #${rawName.substring(0, 6)}';
    }

    // Remove any special characters except spaces
    final cleaned = rawName.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Split by camelCase, underscores, dashes, or multiple spaces
    final words = cleaned.split(RegExp(r'(?=[A-Z])|[_\-\s]+'));

    // Capitalize each word and join with spaces
    final formatted = words
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ')
        .trim();

    return formatted.isEmpty ? 'Unknown Pet' : formatted;
  }

  bool _isValidDocumentId(String id) {
    // Basic checks
    if (id.isEmpty) return false;

    // Appwrite document IDs are typically 20-36 characters
    if (id.length < 20 || id.length > 36) return false;

    // Check if it contains only valid characters
    // Appwrite IDs use alphanumeric characters and may include underscore, dot, dash
    final validIdRegex = RegExp(r'^[a-zA-Z0-9_.-]+$');
    if (!validIdRegex.hasMatch(id)) return false;

    // Check if it doesn't look like a pet name (no spaces, not too many special chars)
    if (id.contains(' ')) return false;

    // If it has more than 2 consecutive special characters, it's likely not a valid ID
    if (RegExp(r'[_.-]{3,}').hasMatch(id)) return false;

    return true;
  }

  void _processTodayAppointments() {
    try {
      print('>>> ============================================');
      print('>>> PROCESSING TODAY\'S APPOINTMENTS');
      print('>>> Current today count: ${todayAppointments.length}');
      print('>>> Total appointments: ${appointments.length}');
      print('>>> ============================================');

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Filter today's appointments from main list
      final allTodayAppts = appointments.where((appointment) {
        final appointmentDate = DateTime(
          appointment.dateTime.year,
          appointment.dateTime.month,
          appointment.dateTime.day,
        );
        return appointmentDate.isAtSameMomentAs(todayDate);
      }).toList();

      print(
          '>>> Found ${allTodayAppts.length} today appointments from main list');

      // Sort by priority
      allTodayAppts.sort((a, b) {
        // Pending appointments first
        if (a.status == 'pending' && b.status != 'pending') return -1;
        if (b.status == 'pending' && a.status != 'pending') return 1;

        // Then by time
        return a.dateTime.compareTo(b.dateTime);
      });

      // Take top 3
      final top3 = allTodayAppts.take(3).toList();

      print('>>> Selected top ${top3.length} appointments');
      for (var appt in top3) {
        print('>>>   - ${appt.documentId}: ${appt.status}');
      }

      // FIXED: Create new list instance
      todayAppointments.value = List.from(top3);

      print(
          '>>> ✓ Today\'s appointments processed: ${todayAppointments.length}');
      print('>>> ============================================');

      // Pre-load images if needed
      if (top3.isNotEmpty) {
        preloadPetImagesForAppointments(top3);
      }
    } catch (e) {
      print('>>> ERROR processing today\'s appointments: $e');
    }
  }

  void _processUpcomingAppointments() {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      final upcomingAppts = appointments.where((appointment) {
        // Only accepted appointments
        if (appointment.status != 'accepted') return false;

        // Only future dates (not today)
        final appointmentDate = DateTime(
          appointment.dateTime.year,
          appointment.dateTime.month,
          appointment.dateTime.day,
        );

        return appointmentDate.isAfter(DateTime(now.year, now.month, now.day));
      }).toList();

      // Sort by date/time (nearest first)
      upcomingAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      // Take only first 5
      final limitedUpcoming = upcomingAppts.take(3).toList();

      upcomingAppointments.assignAll(limitedUpcoming);
      upcomingAppointments.refresh();

      print('>>> ✓ Upcoming appointments updated: ${limitedUpcoming.length}');
    } catch (e) {
      print('>>> ERROR processing upcoming appointments: $e');
    }
  }

  Future<void> generateCalendarData() async {
    Map<DateTime, List<Appointment>> calendarData = {};

    for (var appointment in appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );

      if (calendarData[date] == null) {
        calendarData[date] = [];
      }
      calendarData[date]!.add(appointment);
    }

    calendarAppointments.assignAll(calendarData);
  }

  Future<void> fetchAppointmentsForDate(DateTime date) async {
    // Placeholder for future implementation
  }

  Future<void> fetchRecentMessages() async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      print('>>> ERROR: Cannot fetch messages - no clinic ID');
      recentMessages.clear();
      return;
    }

    try {
      print('>>> ============================================');
      print('>>> FETCHING RECENT MESSAGES (OPTIMIZED - MAX 3)');
      print('>>> Clinic: ${clinicData.value!.documentId}');
      print('>>> ============================================');

      // OPTIMIZATION: Fetch ONLY 3 most recent conversations with messages
      final conversations =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.conversationsCollectionID,
        queries: [
          Query.equal('clinicId', clinicData.value!.documentId!),
          Query.equal('isActive', true),
          Query.notEqual('lastMessageText',
              ''), // CRITICAL: Only conversations with messages
          Query.isNotNull(
              'lastMessageTime'), // CRITICAL: Must have lastMessageTime
          Query.orderDesc('lastMessageTime'),
          Query.limit(3), // OPTIMIZATION: Fetch ONLY 3 conversations
        ],
      );

      print('>>> Found ${conversations.documents.length} recent conversations');

      if (conversations.documents.isEmpty) {
        print('>>> No recent conversations with messages');
        recentMessages.clear();
        recentMessages.refresh();
        return;
      }

      final List<Map<String, dynamic>> messages = [];

      // Process each conversation
      for (var doc in conversations.documents) {
        print('>>> Processing conversation ${doc.$id}...');

        final userId = doc.data['userId'] as String;
        final lastMessageText = doc.data['lastMessageText'] as String?;
        final lastMessageTime = doc.data['lastMessageTime'] as String?;
        final clinicUnreadCount = doc.data['clinicUnreadCount'] as int? ?? 0;

        // Skip if no message data
        if (lastMessageText == null ||
            lastMessageText.isEmpty ||
            lastMessageTime == null) {
          print('>>>   - Skipping: incomplete message data');
          continue;
        }

        // Fetch user data
        String senderName = 'Unknown User';
        String profilePictureUrl = '';
        bool hasProfilePicture = false;

        try {
          final userDoc = await authRepository.getUserById(userId);

          if (userDoc != null) {
            final user = User.fromMap(userDoc.data);
            senderName = user.name.isNotEmpty ? user.name : 'Unknown User';

            if (user.hasProfilePicture && user.profilePictureId != null) {
              try {
                profilePictureUrl = authRepository
                    .getUserProfilePictureUrl(user.profilePictureId!);
                hasProfilePicture = true;
                print('>>>   ✓ Got profile picture for: $senderName');
              } catch (e) {
                print('>>>   ✗ Error getting profile picture: $e');
              }
            }
          }
        } catch (e) {
          print('>>> Error fetching user $userId: $e');
          senderName = userId.length > 6
              ? 'User #${userId.substring(0, 6)}'
              : 'Unknown User';
        }

        final messageData = {
          'id': doc.$id,
          'senderName': senderName,
          'senderId': userId,
          'message': lastMessageText,
          'time': DateTime.parse(lastMessageTime),
          'isRead': clinicUnreadCount == 0,
          'unreadCount': clinicUnreadCount,
          'conversationId': doc.$id,
          'profilePictureUrl': profilePictureUrl,
          'hasProfilePicture': hasProfilePicture,
        };

        messages.add(messageData);
        print('>>> ✓ Added message from $senderName');
      }

      // Update observable (should be exactly 3 or less)
      recentMessages.assignAll(messages);
      recentMessages.refresh();

      print('>>> ============================================');
      print('>>> ✓ FETCHED ${recentMessages.length} RECENT MESSAGES');
      print('>>> ============================================');
    } catch (e, stackTrace) {
      print('>>> ERROR fetching recent messages: $e');
      print('>>> Stack trace: $stackTrace');
      recentMessages.clear();
      recentMessages.refresh();
    }
  }

// Add this helper method to cache user data
  final Map<String, String> _userNamesCache = {};

  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) {
      return 'Unknown User';
    }

    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }

    try {
      final userDoc = await authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);
        final name = user.name.isNotEmpty ? user.name : 'Unknown User';
        _userNamesCache[userId] = name;
        return name;
      }
    } catch (e) {
      print('Error fetching user name for $userId: $e');
    }

    final fallback =
        userId.length > 6 ? 'User #${userId.substring(0, 6)}' : 'Unknown User';
    _userNamesCache[userId] = fallback;
    return fallback;
  }

  String getOwnerName(String userId) {
    if (!ownersCache.containsKey(userId)) {
      // Trigger a fetch if we don't have the data
      _fetchOwnerData(userId);
      return 'Loading...';
    }
    return ownersCache[userId]?['name'] ?? 'User #${userId.substring(0, 6)}';
  }

  String getPetName(String petId) {
    if (petId.isEmpty) return 'Unknown Pet';

    final pet = petsCache[petId];
    if (pet != null) {
      if (pet.name.isNotEmpty && pet.name != 'Unknown') {
        return pet.name;
      }
    }

    // If pet not in cache or has no name, format the ID
    return _formatPetName(petId);
  }

  String getPetType(String petId) {
    if (petId.isEmpty) return 'Unknown';

    final pet = petsCache[petId];
    if (pet != null && pet.type.isNotEmpty && pet.type != 'Unknown') {
      return pet.type;
    }

    return 'Not Available';
  }

  Pet? getPetForAppointment(String petId) {
    if (petId.isEmpty) return null;
    return petsCache[petId];
  }

  /// Force refresh pet data for a specific appointment
  Future<void> refreshPetData(String petId) async {
    if (petId.isEmpty) return;

    try {
      print(">>> Force refreshing pet data for: $petId");

      Pet? pet;

      // Try by ID first
      if (_isValidDocumentId(petId)) {
        try {
          final petDoc = await authRepository.getPetById(petId);
          if (petDoc != null) {
            pet = Pet.fromMap(petDoc.data);
            pet.documentId = petDoc.$id;
          }
        } catch (e) {
          print(">>> Pet not found by ID: $e");
        }
      }

      // Try by name if not found
      if (pet == null) {
        try {
          final petByName = await authRepository.getPetByName(petId);
          if (petByName != null) {
            pet = Pet.fromMap(petByName.data);
            pet.documentId = petByName.$id;
          }
        } catch (e) {
          print(">>> Pet not found by name: $e");
        }
      }

      // Update cache
      if (pet != null) {
        petsCache[petId] = pet;
        petsCache.refresh();
        print(">>> ✓ Pet data refreshed and cached");
      } else {
        print(">>> Could not refresh pet data - creating fallback");
        petsCache[petId] = Pet(
          petId: petId,
          userId: '',
          name: _formatPetName(petId),
          type: 'Unknown',
          breed: 'Unknown',
        );
      }
    } catch (e) {
      print(">>> Error refreshing pet data: $e");
    }
  }

  int get pendingCount => appointmentStats['pending'] ?? 0;
  int get acceptedCount => appointmentStats['accepted'] ?? 0;
  int get completedCount => appointmentStats['completed'] ?? 0;
  int get cancelledCount => appointmentStats['cancelled'] ?? 0;
  int get declinedCount => appointmentStats['declined'] ?? 0;
  int get totalAppointments => appointmentStats['total'] ?? 0;

  Future<void> quickAcceptAppointment(Appointment appointment) async {
    try {
      await appointmentController.acceptAppointment(appointment);
      Get.snackbar("Success", "Appointment accepted!");
    } catch (e) {
      Get.snackbar("Error", "Failed to accept appointment: $e");
    }
  }

  // ✅ FIXED: Dynamic index lookup for Appointments
  void navigateToAppointments([String? filter]) {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final appointmentsIndex =
          homeController.navigationLabels.indexOf('Appointments');

      if (appointmentsIndex != -1) {
        print('>>> Navigating to Appointments at index $appointmentsIndex');
        homeController.setSelectedIndex(appointmentsIndex);

        if (filter != null) {
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              appointmentController.setSelectedTab(filter);
            } catch (e) {
              print("Appointment controller not ready for filter: $filter");
            }
          });
        }
      } else {
        print('>>> ERROR: Appointments page not available in navigation');
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  // ✅ FIXED: Dynamic index lookup for Messages
  void navigateToMessages() {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final messagesIndex = homeController.navigationLabels.indexOf('Messages');

      if (messagesIndex != -1) {
        print('>>> Navigating to Messages at index $messagesIndex');
        homeController.setSelectedIndex(messagesIndex);
      } else {
        print('>>> ERROR: Messages page not available in navigation');
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  // ✅ FIXED: Dynamic index lookup for Clinic
  void navigateToClinic() {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final clinicIndex = homeController.navigationLabels.indexOf('Clinic');

      if (clinicIndex != -1) {
        print('>>> Navigating to Clinic at index $clinicIndex');
        homeController.setSelectedIndex(clinicIndex);
      } else {
        print('>>> ERROR: Clinic page not available in navigation');
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  String get connectionStatus =>
      isRealTimeConnected.value ? "Connected" : "Polling";
  String get lastUpdateDisplay =>
      "Last update: ${DateFormat('hh:mm:ss a').format(lastUpdateTime.value)}";

  /// Check if user can view appointments widget
  bool canViewAppointmentsWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('appointments');
    } catch (e) {
      print('Error checking appointments permission: $e');
      return false;
    }
  }

  /// Check if user can view messages widget
  bool canViewMessagesWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('messages');
    } catch (e) {
      print('Error checking messages permission: $e');
      return false;
    }
  }

  /// Check if user can view clinic widget
  bool canViewClinicWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('clinic_info');
    } catch (e) {
      print('Error checking clinic permission: $e');
      return false;
    }
  }

  /// NEW: Get only visible stats based on permissions
  List<Map<String, dynamic>> getVisibleStats() {
    final allStats = [
      {
        'title': 'Today\'s Appointments',
        'value': todayAppointments.length.toString(),
        'subtitle': 'Scheduled today',
        'icon': Icons.event_available,
        'color': Colors.blue,
        'permission': 'appointments',
      },
      {
        'title': 'Pending Appointments',
        'value': pendingCount.toString(),
        'subtitle': 'Need approval',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
        'permission': 'appointments',
      },
      {
        'title': 'Today\'s In Progress',
        'value': todayAppointments
            .where((a) => a.status == 'in_progress')
            .length
            .toString(),
        'subtitle': 'Currently being treated',
        'icon': Icons.medical_services,
        'color': Colors.purple,
        'permission': 'appointments',
      },
      {
        'title': 'Today\'s Completed',
        'value': todayAppointments
            .where((a) => a.status == 'completed')
            .length
            .toString(),
        'subtitle': 'Finished appointments today',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'permission': 'appointments',
      },
    ];

    try {
      final homeController = Get.find<WebAdminHomeController>();
      return allStats
          .where((stat) =>
              homeController.canAccessFeature(stat['permission'] as String))
          .toList();
    } catch (e) {
      print('Error filtering stats: $e');
      return allStats;
    }
  }

  /// NEW: Get count of visible widgets for layout purposes
  Map<String, bool> getVisibleWidgets() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return {
        'appointments': homeController.canAccessFeature('appointments'),
        'messages': homeController.canAccessFeature('messages'),
        'clinic': homeController.canAccessFeature('clinic_info'),
      };
    } catch (e) {
      print('Error getting visible widgets: $e');
      return {
        'appointments': true,
        'messages': true,
        'clinic': true,
      };
    }
  }
  // Add these methods to AdminDashboardController class

  /// Confirm before accepting appointment from dashboard
  Future<void> confirmQuickAcceptAppointment(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Accept Appointment?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to accept this appointment.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getPetName(appointment.petId)} • ${appointment.service}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${getOwnerName(appointment.userId)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(appointment.dateTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The time slot will be reserved and the client will be notified.',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await quickAcceptAppointment(appointment);
    }
  }

  /// Confirm before declining appointment from dashboard
  Future<void> confirmQuickDeclineAppointment(Appointment appointment) async {
    String selectedReason = '';
    final customReasonController = TextEditingController();
    bool hasChanges = false;

    final predefinedReasons = [
      'Time slot already booked',
      'Clinic at full capacity',
      'Service not available',
      'Emergency override needed',
      'Insufficient information provided',
      'Other (specify below)',
    ];

    final result = await Get.dialog<Map<String, String>?>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async {
                  customReasonController.dispose();
                  return true;
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cancel,
                              color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Decline Appointment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Please select or provide a reason for declining:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ...predefinedReasons.map((reason) {
                      return RadioListTile<String>(
                        title:
                            Text(reason, style: const TextStyle(fontSize: 14)),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                            hasChanges = true;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 81, 115, 153),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: 'Custom reason (optional)',
                        hintText: 'Enter additional details...',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          hasChanges = true;
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            customReasonController.dispose();
                            Get.back();
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedReason.isEmpty
                              ? null
                              : () {
                                  String finalReason = selectedReason;
                                  if (customReasonController.text.isNotEmpty) {
                                    finalReason = selectedReason ==
                                            'Other (specify below)'
                                        ? customReasonController.text
                                        : '$selectedReason - ${customReasonController.text}';
                                  }

                                  Get.back(result: {
                                    'reason': finalReason,
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Decline Appointment',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    if (result != null && result['reason'] != null) {
      await quickDeclineAppointment(appointment, result['reason']!);
      customReasonController.dispose();
    } else {
      customReasonController.dispose();
    }
  }

  /// Quick decline appointment
  Future<void> quickDeclineAppointment(
      Appointment appointment, String reason) async {
    try {
      await appointmentController.declineAppointment(appointment, reason);

      // Update the appointment in the local list if needed
      final index = appointments
          .indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment.copyWith(
          status: 'declined',
          updatedAt: DateTime.now(),
        );
        appointments.refresh();
      }

      Get.snackbar(
        "Success",
        "Appointment declined. Patient will be notified.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to decline appointment: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Add this method to fetch pet profile picture
  Future<String?> getPetProfilePictureUrl(String petId) async {
    // Check cache first
    if (petProfilePictures.containsKey(petId)) {
      return petProfilePictures[petId];
    }

    try {
      print('>>> Dashboard: Fetching profile picture for pet: $petId');

      // Fetch pet document
      final petDoc = await authRepository.getPetById(petId);

      if (petDoc != null) {
        final imageUrl = petDoc.data['image'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Cache the URL
          petProfilePictures[petId] = imageUrl;
          print(
              '>>> Dashboard: Pet profile picture cached: $petId -> $imageUrl');
          return imageUrl;
        }
      }

      // No image found, cache null
      petProfilePictures[petId] = null;
      return null;
    } catch (e) {
      print('>>> Dashboard: Error fetching pet profile picture: $e');
      petProfilePictures[petId] = null;
      return null;
    }
  }

// Add this method to fetch pet image by userId (same as in WebAppointmentController)
  Future<String?> getPetImageByUserId(String petId, String userId) async {
    try {
      // Return immediately if already cached
      if (petProfilePictures.containsKey(petId)) {
        return petProfilePictures[petId];
      }

      // Prevent duplicate fetches
      if (petImageLoadingStates[petId] == true) {
        print('>>> Dashboard: Already loading image for pet: $petId');
        return null;
      }

      petImageLoadingStates[petId] = true;

      print(
          '>>> Dashboard: Fetching pet image for petId: $petId, userId: $userId');

      // Fetch all pets for this user
      final userPets = await authRepository.getUserPets(userId);

      if (userPets.isEmpty) {
        print('>>> Dashboard: No pets found for user: $userId');
        petProfilePictures[petId] = null;
        petImageLoadingStates[petId] = false;
        return null;
      }

      // Find the specific pet by petId
      Pet? targetPet;

      for (var petDoc in userPets) {
        final pet = Pet.fromMap(petDoc.data);
        pet.documentId = petDoc.$id;

        // Match by petId (document ID or petId field)
        if (petDoc.$id == petId || pet.petId == petId || pet.name == petId) {
          targetPet = pet;
          print('>>> Dashboard: ✅ Found matching pet: ${pet.name}');
          break;
        }
      }

      if (targetPet == null) {
        print('>>> Dashboard: ⚠️ Pet not found for this user');
        petProfilePictures[petId] = null;
        petImageLoadingStates[petId] = false;
        return null;
      }

      // Cache the pet
      petsCache[petId] = targetPet;

      // Cache the image
      if (targetPet.image != null && targetPet.image!.isNotEmpty) {
        petProfilePictures[petId] = targetPet.image;
        print('>>> Dashboard: Pet image URL cached: ${targetPet.image}');
        petImageLoadingStates[petId] = false;
        return targetPet.image;
      }

      petProfilePictures[petId] = null;
      petImageLoadingStates[petId] = false;
      return null;
    } catch (e) {
      print('>>> Dashboard: Error fetching pet image: $e');
      petProfilePictures[petId] = null;
      petImageLoadingStates[petId] = false;
      return null;
    }
  }

  Future<void> preloadPetImagesForAppointments(
      List<Appointment> appointments) async {
    print(
        '>>> Dashboard: Pre-loading pet images for ${appointments.length} appointments');

    final futures = <Future>[];

    for (var appointment in appointments) {
      // Skip if already cached
      if (petProfilePictures.containsKey(appointment.petId)) {
        continue;
      }

      // Add to batch
      futures.add(getPetImageByUserId(appointment.petId, appointment.userId)
          .catchError((e) {
        print('>>> Error pre-loading pet ${appointment.petId}: $e');
      }));
    }

    // Wait for all images to load
    await Future.wait(futures);
    print('>>> Dashboard: Pet images pre-loaded');
  }

  void clearPetProfilePicturesCache() {
    petProfilePictures.clear();
    petImageLoadingStates.clear();
  }

// Add this method to refresh pet images
  Future<void> refreshPetImages() async {
    print('>>> Dashboard: Refreshing pet images cache...');
    petProfilePictures.clear();
    petImageLoadingStates.clear();
    await _fetchRelatedData();
    print('>>> Dashboard: Pet images cache refreshed');
  }

  // new shits

  Future<void> fetchTodaysAppointments({bool force = false}) async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      print('>>> ERROR: Cannot fetch appointments - no clinic ID');
      return; // DON'T clear - keep existing data
    }

    // CRITICAL: Skip fetch if cache is valid and not forced
    if (!force && _isCacheValid() && todayAppointments.isNotEmpty) {
      print('>>> Skipping today\'s appointments fetch - using cache');
      print('>>> Cached count: ${todayAppointments.length}');
      return;
    }

    try {
      print('>>> ============================================');
      print('>>> FETCHING TODAY\'S APPOINTMENTS');
      print('>>> Force: $force');
      print('>>> Current count: ${todayAppointments.length}');
      print('>>> ============================================');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day, 0, 0, 0);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Fetch ALL today's appointments
      final result =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal('clinicId', clinicData.value!.documentId!),
          Query.greaterThanEqual('dateTime', startOfDay.toIso8601String()),
          Query.lessThanEqual('dateTime', endOfDay.toIso8601String()),
          Query.limit(100), // Get all today's appointments
        ],
      );

      print('>>> Found ${result.documents.length} total appointments today');

      // Parse all appointments
      final List<Appointment> allTodayAppts = [];
      for (var doc in result.documents) {
        try {
          final appointment = Appointment.fromMap(doc.data);
          allTodayAppts.add(appointment);
        } catch (e) {
          print('>>> Error parsing appointment: $e');
        }
      }

      // Sort by priority: pending first, then by time
      allTodayAppts.sort((a, b) {
        // Pending appointments first
        if (a.status == 'pending' && b.status != 'pending') return -1;
        if (b.status == 'pending' && a.status != 'pending') return 1;

        // Then by time (upcoming first for same status)
        return a.dateTime.compareTo(b.dateTime);
      });

      // Take exactly 3 (or less if not enough)
      final top3 = allTodayAppts.take(3).toList();

      print('>>> Selected top ${top3.length} appointments');
      for (var appt in top3) {
        print(
            '>>>   - ${appt.documentId}: ${appt.status} at ${DateFormat('HH:mm').format(appt.dateTime)}');
      }

      // Update with new list instance
      todayAppointments.value = List.from(top3);

      print('>>> ✓ Today\'s appointments updated: ${todayAppointments.length}');
      print('>>> ============================================');

      // Pre-load images
      if (top3.isNotEmpty) {
        preloadPetImagesForAppointments(top3);
      }

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
      isDashboardCached.value = true;
    } catch (e) {
      print('>>> ERROR fetching today\'s appointments: $e');
      // DON'T clear on error - keep existing data
    }
  }

  Future<void> fetchUpcomingAppointments({bool force = false}) async {
    if (clinicData.value == null || clinicData.value?.documentId == null) {
      print('>>> ERROR: Cannot fetch appointments - no clinic ID');
      return; // DON'T clear
    }

    // CRITICAL: Skip fetch if cache is valid and not forced
    if (!force && _isCacheValid() && upcomingAppointments.isNotEmpty) {
      print('>>> Skipping upcoming appointments fetch - using cache');
      print('>>> Cached count: ${upcomingAppointments.length}');
      return;
    }

    try {
      print('>>> ============================================');
      print('>>> FETCHING UPCOMING APPOINTMENTS');
      print('>>> Force: $force');
      print('>>> Clinic: ${clinicData.value!.documentId}');
      print('>>> ============================================');

      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);

      // Fetch ONLY 5 upcoming accepted appointments
      final result =
          await authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.appointmentCollectionID,
        queries: [
          Query.equal('clinicId', clinicData.value!.documentId!),
          Query.equal('status', 'accepted'),
          Query.greaterThanEqual('dateTime', tomorrow.toIso8601String()),
          Query.orderAsc('dateTime'),
          Query.limit(5),
        ],
      );

      print('>>> Found ${result.documents.length} upcoming appointments');

      final List<Appointment> upcomingAppts = [];
      for (var doc in result.documents) {
        try {
          final appointment = Appointment.fromMap(doc.data);
          upcomingAppts.add(appointment);
        } catch (e) {
          print('>>> Error parsing appointment: $e');
        }
      }

      upcomingAppointments.assignAll(upcomingAppts);
      upcomingAppointments.refresh();

      // Pre-load images
      if (upcomingAppts.isNotEmpty) {
        preloadPetImagesForAppointments(upcomingAppts);
      }

      print(
          '>>> ✓ FETCHED ${upcomingAppointments.length} UPCOMING APPOINTMENTS');
      print('>>> ============================================');

      // Update cache timestamp
      lastCacheTime.value = DateTime.now();
      isDashboardCached.value = true;
    } catch (e) {
      print('>>> ERROR fetching upcoming appointments: $e');
      // DON'T clear on error
    }
  }

  Future<void> forceRefreshAppointments() async {
    if (clinicData.value?.documentId == null) {
      print('>>> Cannot force refresh - no clinic ID');
      return;
    }

    // Check if we really need a force refresh
    if (_isCacheValid() && isRealTimeConnected.value) {
      print('>>> Force refresh skipped - cache valid and real-time connected');
      return;
    }

    try {
      print('>>> ============================================');
      print('>>> FORCE REFRESHING ALL APPOINTMENTS');
      print('>>> ============================================');

      // Fetch fresh from database
      final freshAppointments = await authRepository.getClinicAppointments(
        clinicData.value!.documentId!,
      );

      print(
          '>>> Fetched ${freshAppointments.length} appointments from database');

      // Replace all data
      appointments.assignAll(freshAppointments);

      // Update all filtered views
      _processTodayAppointments();
      _processUpcomingAppointments();
      _updateAppointmentStats();
      await generateCalendarData();

      // Update cache
      lastCacheTime.value = DateTime.now();
      isDashboardCached.value = true;

      print('>>> ✓ Force refresh complete');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR in force refresh: $e');
    }
  }

  void cleanupOnLogout() {
    print('>>> ============================================');
    print('>>> CLEANING UP DASHBOARD ON LOGOUT');
    print('>>> ============================================');

    // Cancel all subscriptions
    try {
      _appointmentSubscription?.close();
      _conversationSubscription?.close();
      _messageSubscription?.close();
      _fallbackTimer?.cancel();
    } catch (e) {
      print('>>> Error closing subscriptions: $e');
    }

    // Clear ALL cached data
    clinicData.value = null;
    appointments.clear();
    appointmentStats.clear();
    todayAppointments.clear();
    upcomingAppointments.clear();
    recentMessages.clear();
    monthlyStats.clear();
    petsCache.clear();
    ownersCache.clear();
    calendarAppointments.clear();
    _userNamesCache.clear();
    petProfilePictures.clear();
    petImageLoadingStates.clear();

    // Invalidate cache
    isDashboardCached.value = false;
    lastCacheTime.value = null;
    isRealTimeConnected.value = false;

    print('>>> ✓ All resources cleaned up');
    print('>>> ============================================');
  }

  String get cacheStatus {
    if (!isDashboardCached.value) {
      return 'No cache';
    }

    if (lastCacheTime.value == null) {
      return 'Invalid cache';
    }

    final age = DateTime.now().difference(lastCacheTime.value!);
    final remainingMinutes = cacheValidityMinutes - age.inMinutes;

    if (remainingMinutes <= 0) {
      return 'Cache expired';
    }

    return 'Cache valid (${remainingMinutes}m left)';
  }

  /// Check if cache needs refresh soon
  bool get shouldRefreshSoon {
    if (!isDashboardCached.value || lastCacheTime.value == null) {
      return true;
    }

    final age = DateTime.now().difference(lastCacheTime.value!);
    final remainingMinutes = cacheValidityMinutes - age.inMinutes;

    return remainingMinutes <= 1; // Refresh if less than 1 minute left
  }
}
