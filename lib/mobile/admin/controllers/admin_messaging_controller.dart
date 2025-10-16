import 'dart:async';
import 'package:appwrite/appwrite.dart' as models;
import 'package:capstone_app/controllers/notification_controller.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminMessagingController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserSessionService _userSession = Get.find<UserSessionService>();
  late final NotificationController _notificationController;

  // Observable variables
  final conversations = <Conversation>[].obs;
  final currentMessages = <Message>[].obs;
  final conversationStarters = <ConversationStarter>[].obs;
  final userStatuses = <String, UserStatus>{}.obs;

  // Loading states
  final isLoading = false.obs;
  final isSendingMessage = false.obs;
  final isLoadingConversation = false.obs;
  final isLoadingStarters = false.obs;

  // Current conversation data
  final currentConversation = Rxn<Conversation>();
  final currentReceiverId = ''.obs;
  final currentReceiverType = ''.obs; // Always 'user' for admin
  final currentClinicId = ''.obs;

  // Text controllers
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final searchController = TextEditingController();

  // Conversation starters management
  final starterTriggerController = TextEditingController();
  final starterResponseController = TextEditingController();
  final selectedCategory = 'general'.obs;
  final categories = ['general', 'appointment', 'services', 'emergency'].obs;

  // Real-time subscriptions
  StreamSubscription<models.RealtimeMessage>? _messageSubscription;
  StreamSubscription<models.RealtimeMessage>? _conversationSubscription;
  StreamSubscription<models.RealtimeMessage>? _statusSubscription;

  @override
  void onInit() {
    super.onInit();

    if (!Get.isRegistered<NotificationController>()) {
      _notificationController = Get.put(NotificationController(
        authRepository: _authRepository,
        session: _userSession,
      ));
    } else {
      _notificationController = Get.find<NotificationController>();
    }

    setUserOnline();
  }

  @override
  void onClose() {
    print('=== AdminMessagingController onClose starting ===');

    try {
      // Cancel subscriptions immediately
      _cancelAllSubscriptions();

      // Dispose text controllers
      _disposeControllers();

      // Clear all observable data
      _clearAllData();

      // Set user offline (with timeout to prevent hanging)
      _setUserOfflineWithTimeout();
    } catch (e) {
      print('Error in AdminMessagingController onClose: $e');
    } finally {
      super.onClose();
      print('=== AdminMessagingController onClose completed ===');
    }
  }

  Future<void> cleanupBeforeLogout() async {
    print('=== AdminMessagingController manual cleanup starting ===');

    try {
      _cancelAllSubscriptions();
      _clearAllData();
      await _setUserOfflineWithTimeout();
      print('AdminMessagingController manual cleanup completed successfully');
    } catch (e) {
      print('Error during AdminMessagingController cleanup: $e');
    }
  }

  void _cancelAllSubscriptions() {
    print('Cancelling all subscriptions...');

    try {
      _messageSubscription?.cancel();
      _messageSubscription = null;
    } catch (e) {
      print('Error cancelling message subscription: $e');
    }

    try {
      _conversationSubscription?.cancel();
      _conversationSubscription = null;
    } catch (e) {
      print('Error cancelling conversation subscription: $e');
    }

    try {
      _statusSubscription?.cancel();
      _statusSubscription = null;
    } catch (e) {
      print('Error cancelling status subscription: $e');
    }

    print('Subscription cancellation completed');
  }

  void _disposeControllers() {
    print('Disposing text controllers...');

    try {
      messageController.dispose();
      scrollController.dispose();
      searchController.dispose();
      starterTriggerController.dispose();
      starterResponseController.dispose();
    } catch (e) {
      print('Error disposing controllers: $e');
    }

    print('Controller disposal completed');
  }

  void _clearAllData() {
    print('Clearing all observable data...');

    try {
      conversations.clear();
      currentMessages.clear();
      conversationStarters.clear();
      userStatuses.clear();

      // Reset current conversation state
      currentConversation.value = null;
      currentReceiverId.value = '';
      currentReceiverType.value = '';
      currentClinicId.value = '';
      selectedCategory.value = 'general';

      // Reset loading states
      isLoading.value = false;
      isSendingMessage.value = false;
      isLoadingConversation.value = false;
      isLoadingStarters.value = false;

      print('Data clearing completed');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  Future<void> _setUserOfflineWithTimeout() async {
    try {
      print('Setting user offline...');
      await setUserOffline().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('Set user offline timed out');
        },
      );
      print('User set offline successfully');
    } catch (e) {
      print('Error setting user offline: $e');
    }
  }

  // ============= CLINIC SETUP =============

  Future<void> initializeForClinic(String clinicId) async {
    try {
      currentClinicId.value = clinicId;

      print('=== Initializing Admin Messaging for Clinic: $clinicId ===');

      if (!AppwriteConstants.messagingCollectionsConfigured) {
        Get.snackbar(
          'Setup Required',
          'Please create messaging collections in AppWrite first.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Load initial data
      await Future.wait([
        loadClinicConversations(clinicId),
        initializeConversationStarters(clinicId),
      ]);

      // CRITICAL: Subscribe to real-time updates for the conversation list
      // This ensures the list updates even when not in a specific conversation
      print('>>> Setting up real-time subscriptions...');
      subscribeToClinicConversationUpdates(clinicId);
      print('>>> Real-time subscriptions active');

      print('Admin messaging initialized successfully');
    } catch (e) {
      print('Error initializing admin messaging: $e');
      Get.snackbar(
        'Initialization Error',
        'Failed to initialize messaging: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> initializeConversationStarters(String clinicId) async {
    try {
      isLoadingStarters.value = true;

      print('Loading conversation starters for clinic: $clinicId');

      final starters =
          await _authRepository.getClinicConversationStarters(clinicId);
      conversationStarters.value = starters;

      print('Found ${starters.length} existing starters');

      if (starters.isEmpty) {
        print('No starters found, creating default ones...');
        await _authRepository.initializeDefaultConversationStarters(clinicId);

        await Future.delayed(const Duration(milliseconds: 500));

        final newStarters =
            await _authRepository.getClinicConversationStarters(clinicId);
        conversationStarters.value = newStarters;

        print('Created ${newStarters.length} default starters');

        if (newStarters.isNotEmpty) {
          Get.snackbar(
            'Default Starters Created',
            '${newStarters.length} conversation starters have been set up for your clinic.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      print('Error initializing conversation starters: $e');
      Get.snackbar(
        'Starters Error',
        'Could not load conversation starters: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoadingStarters.value = false;
    }
  }

  // ============= CONVERSATION METHODS =============

  Future<void> loadClinicConversations(String clinicId) async {
    try {
      isLoading.value = true;
      final clinicConversations =
          await _authRepository.getClinicConversations(clinicId);
      conversations.value = clinicConversations;
      print('Loaded ${clinicConversations.length} clinic conversations');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load conversations: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openConversation(
      Conversation conversation, String receiverId, String receiverType) async {
    try {
      isLoadingConversation.value = true;

      currentConversation.value = conversation;
      currentReceiverId.value = receiverId;
      currentReceiverType.value = receiverType;

      // Load messages
      await loadConversationMessages(conversation.documentId!);

      // Subscribe to real-time messages
      subscribeToMessages(conversation.documentId!);

      // Mark messages as read ONLY when admin actually opens the conversation
      await markConversationAsRead(conversation.documentId!);

      // Load user status
      await loadUserStatus(receiverId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to open conversation: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoadingConversation.value = false;
    }
  }

  // ============= MESSAGE METHODS =============

  Future<void> loadConversationMessages(String conversationId) async {
    try {
      final messages =
          await _authRepository.getConversationMessages(conversationId);
      currentMessages.value = messages;

      // With reverse ListView, newest messages automatically appear at bottom
      // No need to scroll since reverse ListView starts at "top" (which is actually bottom)
    } catch (e) {
      Get.snackbar('Error', 'Failed to load messages: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _scrollToBottom() {
    // With reverse ListView, scrolling to 0 position shows newest messages
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomWithRetry() {
    // Not needed with reverse ListView, but keeping for compatibility
    _scrollToBottom();
  }

  Future<void> sendMessage({String? text, String? attachmentUrl}) async {
    final messageText = text ?? messageController.text.trim();
    if (messageText.isEmpty && attachmentUrl == null) return;

    if (currentConversation.value == null) return;

    try {
      isSendingMessage.value = true;

      // Clear input immediately for better UX
      if (text == null) messageController.clear();

      // Send message as admin
      final sentMessage = await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: _userSession.userId,
        senderType: 'admin',
        receiverId: currentReceiverId.value,
        messageText: messageText,
        messageType: attachmentUrl != null ? 'image' : 'text',
        attachmentUrl: attachmentUrl,
      );

      // Update conversation in local list - admin sent message so their unread count stays 0
      // The user's unread count will be incremented by the server
      final updatedConversation = currentConversation.value!.copyWith(
        lastMessageId: sentMessage.documentId,
        lastMessageText: messageText,
        lastMessageTime: sentMessage.timestamp,
        clinicUnreadCount:
            0, // Admin's unread count stays 0 since they sent the message
      );
      currentConversation.value = updatedConversation;

      // Update in conversations list and move to top
      final index = conversations
          .indexWhere((c) => c.documentId == updatedConversation.documentId);
      if (index != -1) {
        conversations.removeAt(index);
        conversations.insert(0, updatedConversation);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSendingMessage.value = false;
    }
  }

// Helper method to check if conversation has unread messages for current admin
  bool hasUnreadMessages(Conversation conversation) {
    return conversation.clinicUnreadCount > 0;
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      // Mark messages as read in database
      await _authRepository.markMessagesAsRead(
          conversationId, _userSession.userId);

      // Update local conversation unread count
      if (currentConversation.value != null &&
          currentConversation.value!.clinicUnreadCount > 0) {
        // Only reset the CLINIC's unread count, keep user unread count
        final updatedConversation =
            currentConversation.value!.copyWith(clinicUnreadCount: 0
                // Don't modify userUnreadCount
                );
        currentConversation.value = updatedConversation;

        // Update in conversations list
        final index =
            conversations.indexWhere((c) => c.documentId == conversationId);
        if (index != -1) {
          conversations[index] = updatedConversation;
        }
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // ============= CONVERSATION STARTERS MANAGEMENT =============

  Future<void> loadConversationStarters(String clinicId) async {
    try {
      isLoadingStarters.value = true;
      final starters =
          await _authRepository.getClinicConversationStarters(clinicId);
      conversationStarters.value = starters;

      if (starters.isEmpty) {
        await _authRepository.initializeDefaultConversationStarters(clinicId);
        final newStarters =
            await _authRepository.getClinicConversationStarters(clinicId);
        conversationStarters.value = newStarters;
      }
    } catch (e) {
      print('Error loading conversation starters: $e');
    } finally {
      isLoadingStarters.value = false;
    }
  }

  Future<void> addConversationStarter() async {
    if (starterTriggerController.text.trim().isEmpty ||
        starterResponseController.text.trim().isEmpty ||
        currentClinicId.value.isEmpty) {
      return;
    }

    try {
      final starter = ConversationStarter(
        clinicId: currentClinicId.value,
        triggerText: starterTriggerController.text.trim(),
        responseText: starterResponseController.text.trim(),
        category: selectedCategory.value,
        displayOrder: conversationStarters.length + 1,
      );

      final doc = await _authRepository.createConversationStarter(starter);
      final createdStarter = starter.copyWith(documentId: doc.$id);

      conversationStarters.add(createdStarter);

      // Clear form
      starterTriggerController.clear();
      starterResponseController.clear();
      selectedCategory.value = 'general';

      Get.snackbar('Success', 'Conversation starter added successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add conversation starter: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updateConversationStarter(ConversationStarter starter) async {
    try {
      await _authRepository.updateConversationStarter(starter);

      final index = conversationStarters
          .indexWhere((s) => s.documentId == starter.documentId);
      if (index != -1) {
        conversationStarters[index] = starter;
      }

      Get.snackbar('Success', 'Conversation starter updated successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update conversation starter: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteConversationStarter(String starterId) async {
    try {
      await _authRepository.deleteConversationStarter(starterId);
      conversationStarters.removeWhere((s) => s.documentId == starterId);

      Get.snackbar('Success', 'Conversation starter deleted successfully!',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete conversation starter: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void toggleStarterStatus(ConversationStarter starter) async {
    final updatedStarter = starter.copyWith(isActive: !starter.isActive);
    await updateConversationStarter(updatedStarter);
  }

  // ============= USER STATUS METHODS =============

  Future<void> setUserOnline() async {
    try {
      await _authRepository.setUserOnline(_userSession.userId);
    } catch (e) {
      print('Error setting user online: $e');
    }
  }

  Future<void> setUserOffline() async {
    try {
      await _authRepository.setUserOffline(_userSession.userId);
    } catch (e) {
      print('Error setting user offline: $e');
    }
  }

  Future<void> loadUserStatus(String userId) async {
    try {
      final status = await _authRepository.getUserStatus(userId);
      if (status != null) {
        userStatuses[userId] = status;
      }
    } catch (e) {
      print('Error loading user status: $e');
    }
  }

  // ============= REAL-TIME SUBSCRIPTION METHODS =============

  void subscribeToClinicConversationUpdates(String clinicId) {
    print('>>> ============================================');
    print('>>> SUBSCRIBING TO CLINIC CONVERSATIONS');
    print('>>> Clinic ID: $clinicId');
    print('>>> ============================================');

    // Cancel any existing subscription first
    _conversationSubscription?.cancel();

    // Subscribe to ALL conversation changes for this clinic
    _conversationSubscription =
        _authRepository.subscribeToConversations(clinicId).listen(
      (realtimeMessage) {
        print('>>> ============================================');
        print('>>> REAL-TIME EVENT RECEIVED');
        print('>>> Event: ${realtimeMessage.events}');
        print('>>> ============================================');

        try {
          final conversationData = realtimeMessage.payload;
          print('>>> Conversation data: $conversationData');

          final updatedConversation = Conversation.fromMap(conversationData);
          final conversationWithId = updatedConversation.copyWith(
            documentId: conversationData['\$id'],
          );

          print('>>> Conversation ID: ${conversationWithId.documentId}');
          print('>>> Clinic ID: ${conversationWithId.clinicId}');
          print('>>> User Unread: ${conversationWithId.userUnreadCount}');
          print('>>> Clinic Unread: ${conversationWithId.clinicUnreadCount}');

          // Only process conversations for this clinic
          if (conversationWithId.clinicId == clinicId) {
            print('>>> ✓ Conversation belongs to this clinic - processing...');

            if (realtimeMessage.events
                .contains('databases.*.collections.*.documents.*.update')) {
              print('>>> Update event detected');
              _handleConversationUpdate(conversationWithId);
            } else if (realtimeMessage.events
                .contains('databases.*.collections.*.documents.*.create')) {
              print('>>> Create event detected');
              _handleNewConversation(conversationWithId);
            }

            print('>>> ✓ Conversation list updated successfully');
            print('>>> Total conversations: ${conversations.length}');
          } else {
            print(
                '>>> ✗ Conversation does not belong to this clinic - skipping');
          }
        } catch (e) {
          print('>>> ============================================');
          print('>>> ERROR processing conversation update: $e');
          print('>>> ============================================');
        }

        print('>>> ============================================');
      },
      onError: (error) {
        print('>>> ============================================');
        print('>>> SUBSCRIPTION ERROR: $error');
        print('>>> ============================================');
      },
    );

    print('>>> Real-time subscription established successfully');
    print('>>> Listening for conversation updates...');
    print('>>> ============================================');
  }

  void _handleConversationUpdate(Conversation updatedConversation) {
    print('>>> _handleConversationUpdate called');
    print('>>> Conversation: ${updatedConversation.documentId}');
    print('>>> Last message: ${updatedConversation.lastMessageText}');

    final index = conversations.indexWhere(
      (c) => c.documentId == updatedConversation.documentId,
    );

    if (index != -1) {
      print('>>> Found existing conversation at index: $index');

      // Check if this is the current conversation the admin is viewing
      final isCurrentConversation = currentConversation.value?.documentId ==
          updatedConversation.documentId;

      if (isCurrentConversation) {
        print(
            '>>> This is the current conversation - keeping clinic unread at 0');
        // If admin is currently viewing this conversation, reset THEIR unread count to 0
        final resetClinicUnread =
            updatedConversation.copyWith(clinicUnreadCount: 0);
        conversations[index] = resetClinicUnread;
        currentConversation.value = resetClinicUnread;
      } else {
        print('>>> Not current conversation - using actual unread counts');
        print(
            '>>> Clinic unread count: ${updatedConversation.clinicUnreadCount}');
        // If admin is not viewing this conversation, use the actual unread counts from server
        conversations[index] = updatedConversation;

        if (updatedConversation.clinicUnreadCount > 0 &&
            updatedConversation.lastMessageText != null) {
          _createMessageNotification(updatedConversation);
        }
      }

      // Move updated conversation to top if it has new messages and it's not already at the top
      if (updatedConversation.clinicUnreadCount > 0 && index != 0) {
        print('>>> Moving conversation to top (has unread messages)');
        final conv = conversations.removeAt(index);
        conversations.insert(0, conv);
      }

      print('>>> Conversation updated successfully');
    } else {
      print('>>> Conversation not found in list - adding as new');
      // If conversation doesn't exist, add it
      _handleNewConversation(updatedConversation);
    }
  }

  Future<void> _createMessageNotification(Conversation conversation) async {
    try {
      final userData = await _getUserData(conversation.userId);

      await _notificationController.createNotification(
        NotificationModel(
          recipientId: conversation.clinicId,
          recipientType: 'admin',
          type: NotificationType.newMessage,
          title: 'New Message',
          message: '${userData['name']}: ${conversation.lastMessageText}',
          conversationId: conversation.documentId,
          userId: conversation.userId,
          actionUrl: '/messages?conversation=${conversation.documentId}',
        ),
      );
    } catch (e) {
      print('Error creating message notification: $e');
    }
  }

  void _handleNewConversation(Conversation newConversation) {
    print('>>> _handleNewConversation called');
    print('>>> New conversation ID: ${newConversation.documentId}');

    // Check if conversation already exists
    final exists =
        conversations.any((c) => c.documentId == newConversation.documentId);

    if (!exists) {
      print('>>> Adding new conversation to list at position 0');
      conversations.insert(0, newConversation);
      _createNewConversationNotification(newConversation);
      print('>>> New conversation added successfully');
      print('>>> Total conversations: ${conversations.length}');
    } else {
      print('>>> Conversation already exists - skipping');
    }
  }

  Future<void> _createNewConversationNotification(
      Conversation conversation) async {
    try {
      // Get user data for notification
      final userData = await _getUserData(conversation.userId);

      await _notificationController.createNotification(
        NotificationModel(
          recipientId: conversation.clinicId,
          recipientType: 'admin',
          type: NotificationType.newMessage,
          title: 'New Conversation Started',
          message: '${userData['name']} started a new conversation',
          conversationId: conversation.documentId,
          userId: conversation.userId,
          actionUrl: '/messages?conversation=${conversation.documentId}',
        ),
      );
    } catch (e) {
      print('Error creating new conversation notification: $e');
    }
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final userDoc = await _authRepository.getUserById(userId);
      if (userDoc != null) {
        return {
          'name': userDoc.data['name'] ?? 'Unknown User',
          'email': userDoc.data['email'] ?? '',
        };
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return {'name': 'Unknown User', 'email': ''};
  }

  void subscribeToMessages(String conversationId) {
    _messageSubscription?.cancel();
    _messageSubscription = _authRepository
        .subscribeToMessages(conversationId)
        .listen((realtimeMessage) {
      if (realtimeMessage.events
          .contains('databases.*.collections.*.documents.*.create')) {
        try {
          final messageData = realtimeMessage.payload;
          final message = Message.fromMap(messageData);
          final messageWithId =
              message.copyWith(documentId: messageData['\$id']);

          // More robust duplicate check
          final existingIndex = currentMessages.indexWhere((m) =>
              m.documentId == messageWithId.documentId ||
              (m.messageText == messageWithId.messageText &&
                  m.senderId == messageWithId.senderId &&
                  m.timestamp
                          .difference(messageWithId.timestamp)
                          .abs()
                          .inSeconds <
                      2));

          if (existingIndex == -1) {
            currentMessages.add(messageWithId);

            // Auto-scroll to bottom for new messages
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });

            // If this is a message TO the admin and they're viewing the conversation,
            // mark it as read immediately (but don't mark their own messages as read)
            if (messageWithId.receiverId == _userSession.userId &&
                messageWithId.senderId != _userSession.userId &&
                currentConversation.value?.documentId == conversationId) {
              markConversationAsRead(conversationId);
            }
          }
        } catch (e) {
          print('Error processing real-time message: $e');
        }
      }
    });
  }

  // ============= HELPER METHODS =============

  bool isCurrentUser(String senderId) {
    return senderId == _userSession.userId;
  }

  UserStatus? getUserStatus(String userId) {
    return userStatuses[userId];
  }

  int getTotalUnreadCount() {
    return conversations.fold(0, (total, conversation) {
      // For admin/clinic, only count their unread messages (clinicUnreadCount)
      return total + conversation.clinicUnreadCount;
    });
  }

  List<Conversation> get filteredConversations {
    if (searchController.text.isEmpty) {
      return conversations;
    }

    // You can implement search logic here based on user names or message content
    return conversations;
  }
}
