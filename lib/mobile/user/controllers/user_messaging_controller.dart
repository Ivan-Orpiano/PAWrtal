import 'dart:async';
import 'package:appwrite/appwrite.dart' as models;
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessagingController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserSessionService _userSession = Get.find<UserSessionService>();

  // Observable variables
  final conversations = <Conversation>[].obs;
  final currentMessages = <Message>[].obs;
  final conversationStarters = <ConversationStarter>[].obs;
  final userStatuses = <String, UserStatus>{}.obs;

  // Loading states
  final isLoading = false.obs;
  final isSendingMessage = false.obs;
  final isLoadingConversation = false.obs;

  // Current conversation data
  final currentConversation = Rxn<Conversation>();
  final currentReceiverId = ''.obs;
  final currentReceiverType = ''.obs; // 'clinic' or 'user'

  // Text controller for message input
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // Real-time subscriptions
  StreamSubscription<models.RealtimeMessage>? _messageSubscription;
  StreamSubscription<models.RealtimeMessage>? _conversationSubscription;
  StreamSubscription<models.RealtimeMessage>? _statusSubscription;

  @override
  void onInit() {
    super.onInit();
    loadUserConversations();
    subscribeToConversationUpdates();
    setUserOnline();
  }

  @override
  void onClose() {
    print('=== Cleaning up MessagingController ===');

    // Dispose controllers
    messageController.dispose();
    scrollController.dispose();

    // Cancel subscriptions
    _messageSubscription?.cancel();
    _messageSubscription = null;

    _conversationSubscription?.cancel();
    _conversationSubscription = null;

    _statusSubscription?.cancel();
    _statusSubscription = null;

    // Clear data
    conversations.clear();
    currentMessages.clear();
    conversationStarters.clear();
    userStatuses.clear();

    // Set user offline
    setUserOffline().then((_) {
      print('User status set to offline');
    }).catchError((e) {
      print('Error setting user offline: $e');
    });

    super.onClose();
    print('MessagingController cleanup complete');
  }

  // ============= CONVERSATION METHODS =============

  Future<void> loadUserConversations() async {
    try {
      isLoading.value = true;
      final userConversations =
          await _authRepository.getUserConversations(_userSession.userId);

      // Only update conversations list, don't mark anything as read
      conversations.value = userConversations;
      print('Loaded ${userConversations.length} conversations');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load conversations: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Conversation?> startConversationWithClinic(String clinicId) async {
    try {
      isLoading.value = true;

      print('=== DEBUG: User Starting conversation ===');
      print('User ID: ${_userSession.userId}');
      print('Clinic ID: $clinicId');

      if (!AppwriteConstants.messagingCollectionsConfigured) {
        Get.snackbar(
          'Setup Required',
          'Messaging collections need to be created in AppWrite database first.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return null;
      }

      if (_userSession.userId.isEmpty) {
        print('ERROR: User ID is empty');
        Get.snackbar(
          'Login Required',
          'Please log in first to start a conversation.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      if (clinicId.isEmpty) {
        print('ERROR: Clinic ID is empty');
        Get.snackbar(
          'Error',
          'Invalid clinic information.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      // Get or create conversation
      print('Creating/getting conversation...');
      final conversation = await _authRepository.getOrCreateConversation(
          _userSession.userId, clinicId);

      if (conversation != null) {
        print(
            'SUCCESS: Conversation created/found: ${conversation.documentId}');
        currentConversation.value = conversation;
        currentReceiverId.value = clinicId;
        currentReceiverType.value = 'clinic';

        print('Loading conversation data...');
        // Load conversation messages and starters
        await Future.wait([
          loadConversationMessages(conversation.documentId!),
          loadConversationStarters(clinicId),
        ]);

        // Subscribe to real-time messages for this conversation
        subscribeToMessages(conversation.documentId!);

        print('SUCCESS: Conversation setup complete');
        return conversation;
      } else {
        print(
            'ERROR: Failed to create/get conversation - conversation is null');
        Get.snackbar(
          'Error',
          'Failed to create conversation. Please check your internet connection and try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return null;
      }
    } catch (e) {
      print('ERROR: Exception in startConversationWithClinic: $e');
      Get.snackbar(
        'Debug Error',
        'Detailed error: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
      );
      return null;
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

      // Load messages and starters
      await Future.wait([
        loadConversationMessages(conversation.documentId!),
        if (receiverType == 'clinic') loadConversationStarters(receiverId),
      ]);

      // Subscribe to real-time messages
      subscribeToMessages(conversation.documentId!);

      // Mark as read ONLY when user actually opens the conversation
      await markConversationAsRead(conversation.documentId!);
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
    } catch (e) {
      Get.snackbar('Error', 'Failed to load messages: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Fixed: Removed senderType, receiverId, messageType, attachmentUrl parameters
  /// These don't exist in AuthRepository.sendMessage()
  Future<void> sendMessage({String? text, String? attachmentUrl}) async {
    final messageText = text ?? messageController.text.trim();
    if (messageText.isEmpty && attachmentUrl == null) return;

    if (currentConversation.value == null) return;

    try {
      isSendingMessage.value = true;

      if (text == null) messageController.clear();

      print('>>> ============================================');
      print('>>> USER CONTROLLER: Sending message');
      print('>>> Conversation: ${currentConversation.value!.documentId}');
      print('>>> Sender: ${_userSession.userId}');
      print('>>> Receiver: ${currentReceiverId.value}');
      print('>>> Message: $messageText');
      print('>>> ============================================');

      // CRITICAL FIX: Determine senderType before sending
      String senderType =
          'user'; // User is always sending as 'user' from this controller

      print('>>> SenderType: $senderType');

      // Send message with senderType
      final sentMessage = await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: _userSession.userId,
        messageText: messageText,
        isStarterMessage: false,
        attachment: attachmentUrl,
      );

      print('>>> Message sent successfully: ${sentMessage.documentId}');

      // Update conversation - user sent message so their unread count stays 0
      final updatedConversation = currentConversation.value!.copyWith(
        lastMessageId: sentMessage.documentId,
        lastMessageText: messageText,
        lastMessageTime: sentMessage.createdAt,
        userUnreadCount: 0, // User sent it, so user has 0 unread
      );
      currentConversation.value = updatedConversation;

      // Update in conversations list and move to top
      final index = conversations
          .indexWhere((c) => c.documentId == updatedConversation.documentId);
      if (index != -1) {
        conversations.removeAt(index);
        conversations.insert(0, updatedConversation);
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR sending message: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', 'Failed to send message: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Fixed: Removed senderType, receiverId, messageType parameters
  Future<void> sendStarterMessage(ConversationStarter starter) async {
    if (currentConversation.value == null) return;

    try {
      // First send the user's trigger message
      await sendMessage(text: starter.triggerText);

      // Wait a moment for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Then send the automated response
      // Note: In a real app, this should be sent from a backend function
      // For now, just send the response text as a regular message
      await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: currentReceiverId.value,
        messageText: starter.responseText,
        isStarterMessage: true,
      );

      print('>>> Starter message sent');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send starter message: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      // Mark messages as read in database
      await _authRepository.markMessagesAsRead(
          conversationId, _userSession.userId);

      // Update local conversation unread count
      if (currentConversation.value != null &&
          currentConversation.value!.userUnreadCount > 0) {
        final updatedConversation =
            currentConversation.value!.copyWith(userUnreadCount: 0);
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

  // ============= CONVERSATION STARTERS METHODS =============

  Future<void> loadConversationStarters(String clinicId) async {
    try {
      final starters =
          await _authRepository.getClinicConversationStarters(clinicId);
      conversationStarters.value = starters;
    } catch (e) {
      print('Error loading conversation starters: $e');
    }
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

  void subscribeToConversationUpdates() {
    _conversationSubscription?.cancel();
    _conversationSubscription = _authRepository
        .subscribeToConversations(_userSession.userId)
        .listen((realtimeMessage) {
      print('Real-time conversation event: ${realtimeMessage.events}');

      try {
        final conversationData = realtimeMessage.payload;
        final updatedConversation = Conversation.fromMap(conversationData);
        final conversationWithId =
            updatedConversation.copyWith(documentId: conversationData['\$id']);

        if (realtimeMessage.events
            .contains('databases.*.collections.*.documents.*.update')) {
          _handleConversationUpdate(conversationWithId);
        } else if (realtimeMessage.events
            .contains('databases.*.collections.*.documents.*.create')) {
          _handleNewConversation(conversationWithId);
        }
      } catch (e) {
        print('Error processing conversation update: $e');
      }
    });
  }

  void _handleConversationUpdate(Conversation updatedConversation) {
    final index = conversations
        .indexWhere((c) => c.documentId == updatedConversation.documentId);

    if (index != -1) {
      final isCurrentConversation = currentConversation.value?.documentId ==
          updatedConversation.documentId;

      if (isCurrentConversation) {
        final resetUserUnread =
            updatedConversation.copyWith(userUnreadCount: 0);
        conversations[index] = resetUserUnread;
        currentConversation.value = resetUserUnread;
      } else {
        conversations[index] = updatedConversation;
      }

      if (updatedConversation.userUnreadCount > 0 && index != 0) {
        final conv = conversations.removeAt(index);
        conversations.insert(0, conv);
      }
    }
  }

  void _handleNewConversation(Conversation newConversation) {
    final exists =
        conversations.any((c) => c.documentId == newConversation.documentId);
    if (!exists) {
      conversations.insert(0, newConversation);
    }
  }

  /// Fixed: Changed m.timestamp to m.messageTimestamp (getter from Message model)
  /// Removed m.receiverId reference - Message model doesn't have this field
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

          // Check for duplicates by ID and content similarity
          final existingIndex = currentMessages.indexWhere((m) =>
              m.documentId == messageWithId.documentId ||
              (m.messageText == messageWithId.messageText &&
                  m.senderId == messageWithId.senderId &&
                  m.messageTimestamp
                          .difference(messageWithId.messageTimestamp)
                          .abs()
                          .inSeconds <
                      2));

          if (existingIndex == -1) {
            print('>>> Adding new message to list');
            currentMessages.add(messageWithId);
            currentMessages.refresh();

            // Auto-scroll to bottom for new messages
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });

            // If this is a message from the clinic and user is viewing conversation, mark as read
            if (messageWithId.senderId != _userSession.userId &&
                currentConversation.value?.documentId == conversationId) {
              print('>>> Auto-marking incoming message as read');
              markConversationAsRead(conversationId);
            }
          }
        } catch (e) {
          print('Error processing real-time message: $e');
          print('Stack trace: ${StackTrace.current}');
        }
      }
    });
  }

  void subscribeToUserStatus(String userId) {
    _statusSubscription?.cancel();
    _statusSubscription =
        _authRepository.subscribeToUserStatus(userId).listen((realtimeMessage) {
      try {
        final statusData = realtimeMessage.payload;
        final status = UserStatus.fromMap(statusData);
        userStatuses[userId] = status;
      } catch (e) {
        print('Error processing user status update: $e');
      }
    });
  }

  // ============= HELPER METHODS =============

  String getOtherUserName(Conversation conversation) {
    if (currentReceiverType.value == 'clinic') {
      return 'Clinic';
    } else {
      return 'User';
    }
  }

  bool isCurrentUser(String senderId) {
    return senderId == _userSession.userId;
  }

  UserStatus? getUserStatus(String userId) {
    return userStatuses[userId];
  }

  int getTotalUnreadCount() {
    return conversations.fold(0, (total, conversation) {
      return total + conversation.userUnreadCount;
    });
  }
}
