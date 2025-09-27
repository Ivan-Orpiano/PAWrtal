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
      conversations.value = userConversations;
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
      print(
          'Collections configured: ${AppwriteConstants.messagingCollectionsConfigured}');

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

        // Mark messages as read
        await markConversationAsRead();

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

// Helper method to initialize default starters for a clinic
  Future<void> initializeDefaultStartersForClinic(String clinicId) async {
    try {
      print('Initializing default starters for clinic: $clinicId');
      await _authRepository.initializeDefaultConversationStarters(clinicId);
      await loadConversationStarters(clinicId);
      print('Default starters initialized successfully');
    } catch (e) {
      print('Error initializing default starters: $e');
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

      // Mark as read
      await markConversationAsRead();
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

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load messages: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> sendMessage({String? text, String? attachmentUrl}) async {
    final messageText = text ?? messageController.text.trim();
    if (messageText.isEmpty && attachmentUrl == null) return;

    if (currentConversation.value == null) return;

    try {
      isSendingMessage.value = true;

      // Clear input immediately for better UX
      if (text == null) messageController.clear();

      // Send message to server (DON'T add to UI immediately - wait for real-time)
      final sentMessage = await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: _userSession.userId,
        senderType: 'user', // Change to 'admin' for AdminMessagingController
        receiverId: currentReceiverId.value,
        messageText: messageText,
        messageType: attachmentUrl != null ? 'image' : 'text',
        attachmentUrl: attachmentUrl,
      );

      // Update conversation in local list
      final updatedConversation = currentConversation.value!.copyWith(
        lastMessageId: sentMessage.documentId,
        lastMessageText: messageText,
        lastMessageTime: sentMessage.timestamp,
      );
      currentConversation.value = updatedConversation;

      // Update in conversations list
      final index = conversations
          .indexWhere((c) => c.documentId == updatedConversation.documentId);
      if (index != -1) {
        conversations[index] = updatedConversation;
        conversations.removeAt(index);
        conversations.insert(0, updatedConversation);
      }

      // Message will appear in UI when real-time subscription receives it
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> sendStarterMessage(ConversationStarter starter) async {
    if (currentConversation.value == null) return;

    try {
      // First send the user's trigger message
      await sendMessage(text: starter.triggerText);

      // Wait a moment for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Then send the automated response as if from the clinic
      final responseMessage = await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: currentReceiverId.value,
        senderType: 'admin',
        receiverId: _userSession.userId,
        messageText: starter.responseText,
        messageType: 'starter',
      );

      // Add to current messages
      currentMessages.add(responseMessage);
    } catch (e) {
      Get.snackbar('Error', 'Failed to send starter message: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> markConversationAsRead() async {
    if (currentConversation.value == null) return;

    try {
      await _authRepository.markMessagesAsRead(
        currentConversation.value!.documentId!,
        _userSession.userId,
      );

      // Update local conversation
      if (currentConversation.value!.unreadCount > 0) {
        final updatedConversation =
            currentConversation.value!.copyWith(unreadCount: 0);
        currentConversation.value = updatedConversation;

        // Update in list
        final index = conversations
            .indexWhere((c) => c.documentId == updatedConversation.documentId);
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
    _conversationSubscription = _authRepository
        .subscribeToConversations(_userSession.userId)
        .listen((realtimeMessage) {
      print('Conversation update received: ${realtimeMessage.events}');

      // Reload conversations when there's an update
      if (realtimeMessage.events
          .contains('databases.*.collections.*.documents.*')) {
        loadUserConversations();
      }
    });
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

          // Simple duplicate check - just by document ID
          final existingIndex = currentMessages
              .indexWhere((m) => m.documentId == messageWithId.documentId);
          if (existingIndex == -1) {
            currentMessages.add(messageWithId);

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
          }
        } catch (e) {
          print('Error processing real-time message: $e');
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
    // This would typically fetch the clinic or user name
    // For now, return a placeholder
    if (currentReceiverType.value == 'clinic') {
      return 'Clinic'; // You can fetch actual clinic name
    } else {
      return 'User'; // You can fetch actual user name
    }
  }

  bool isCurrentUser(String senderId) {
    return senderId == _userSession.userId;
  }

  UserStatus? getUserStatus(String userId) {
    return userStatuses[userId];
  }

  int getTotalUnreadCount() {
    return conversations.fold(
        0, (total, conversation) => total + conversation.unreadCount);
  }
}
