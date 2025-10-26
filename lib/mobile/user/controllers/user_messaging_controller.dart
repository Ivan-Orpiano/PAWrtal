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
  final currentReceiverType = ''.obs;

  final shouldAutoSelectConversation = false.obs;
  final selectedConversationData = Rxn<Map<String, dynamic>>();


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

    // Clear current conversation
    currentConversation.value = null;
    currentReceiverId.value = '';
    currentReceiverType.value = '';

    // Set user offline
    setUserOffline().then((_) {
      print('User status set to offline');
    }).catchError((e) {
      print('Error setting user offline: $e');
    });

    super.onClose();
    print('MessagingController cleanup complete');
  }

  // ADDED: Method to clear all data (call this on logout)
  void clearAllData() {
    print('=== Clearing MessagingController data ===');
    
    // Cancel subscriptions
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _conversationSubscription?.cancel();
    _conversationSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;

    // Clear all observable data
    conversations.clear();
    currentMessages.clear();
    conversationStarters.clear();
    userStatuses.clear();
    
    // Clear current conversation state
    currentConversation.value = null;
    currentReceiverId.value = '';
    currentReceiverType.value = '';
    
    // Clear text input
    messageController.clear();
    
    print('MessagingController data cleared');
  }

  // ============= CONVERSATION METHODS =============

  Future<void> loadUserConversations() async {
    try {
      isLoading.value = true;
      final userConversations =
          await _authRepository.getUserConversations(_userSession.userId);

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

    if (conversation == null) {
      print('ERROR: Failed to create/get conversation - conversation is null');
      Get.snackbar(
        'Error',
        'Failed to create conversation. Please check your internet connection and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return null;
    }

    print('SUCCESS: Conversation created/found: ${conversation.documentId}');
    
    // Update conversations list - add to TOP or move existing to TOP
    final existingIndex = conversations.indexWhere(
      (c) => c.documentId == conversation.documentId
    );
    
    if (existingIndex != -1) {
      print('Conversation exists, moving to top');
      conversations.removeAt(existingIndex);
    } else {
      print('New conversation, adding to top');
    }
    conversations.insert(0, conversation);
    
    // CRITICAL: Set as current conversation IMMEDIATELY
    currentConversation.value = conversation;
    currentReceiverId.value = clinicId;
    currentReceiverType.value = 'clinic';
    
    print('Current conversation set: ${currentConversation.value?.documentId}');

    // Subscribe to real-time messages FIRST (so we catch any incoming messages)
    print('Subscribing to messages...');
    subscribeToMessages(conversation.documentId!);

    // Load conversation data
    print('Loading conversation data...');
    await Future.wait([
      loadConversationMessages(conversation.documentId!),
      loadConversationStarters(clinicId),
    ]);

    print('SUCCESS: Conversation setup complete');
    print('Messages loaded: ${currentMessages.length}');
    print('Starters loaded: ${conversationStarters.length}');
    
    return conversation;
  } catch (e) {
    print('ERROR: Exception in startConversationWithClinic: $e');
    print('Stack trace: ${StackTrace.current}');
    Get.snackbar(
      'Error',
      'Failed to start conversation: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
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

      String senderType = 'user';

      print('>>> SenderType: $senderType');

      // Send message
      final sentMessage = await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: _userSession.userId,
        messageText: messageText,
        attachment: attachmentUrl,
      );

      print('>>> Message sent successfully: ${sentMessage.documentId}');

      // Update conversation - user sent message so their unread count stays 0
      final updatedConversation = currentConversation.value!.copyWith(
        lastMessageId: sentMessage.documentId,
        lastMessageText: messageText,
        lastMessageTime: sentMessage.createdAt,
        userUnreadCount: 0,
      );
      currentConversation.value = updatedConversation;

      // FIXED: Update in conversations list and move to top
      final index = conversations
          .indexWhere((c) => c.documentId == updatedConversation.documentId);
      if (index != -1) {
        conversations.removeAt(index);
      }
      conversations.insert(0, updatedConversation);

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

  Future<void> sendStarterMessage(ConversationStarter starter) async {
    print('>>> ═══════════════════════════════════════════════════════');
    print('>>> SENDSTARTERMESSAGE CALLED');
    print('>>> Time: ${DateTime.now().millisecondsSinceEpoch}');
    print('>>> Trigger: ${starter.triggerText}');
    print('>>> isSendingMessage BEFORE: ${isSendingMessage.value}');
    print('>>> ═══════════════════════════════════════════════════════');

    if (currentConversation.value == null) {
      print('>>> ERROR: No conversation selected');
      return;
    }

    // CRITICAL: Check if already sending
    if (isSendingMessage.value) {
      print('>>> ⚠️ BLOCKED: Already sending a message!');
      print('>>> This call will be ignored to prevent duplicates');
      return;
    }

    try {
      // Set flag IMMEDIATELY
      isSendingMessage.value = true;
      print('>>> ✓ isSendingMessage set to TRUE');

      // Wait a tiny bit to ensure state propagates
      await Future.delayed(const Duration(milliseconds: 50));

      print('>>> Step 1: User sending trigger message...');
      await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: _userSession.userId,
        messageText: starter.triggerText,
      );
      print('>>> ✓ User trigger message sent');

      // Wait for message to be delivered
      await Future.delayed(const Duration(milliseconds: 500));

      print('>>> Step 2: Sending clinic auto-response...');
      await _authRepository.sendConversationStarterResponse(
        conversationId: currentConversation.value!.documentId!,
        clinicId: currentReceiverId.value,
        responseText: starter.responseText,
      );
      print('>>> ✓ Clinic auto-response sent');

      // Wait before reloading
      await Future.delayed(const Duration(milliseconds: 300));

      print('>>> Step 3: Reloading messages...');
      await loadConversationMessages(currentConversation.value!.documentId!);
      print('>>> ✓ Messages reloaded');

      // Scroll to bottom
      _scrollToBottom();

      print('>>> ═══════════════════════════════════════════════════════');
      print('>>> CONVERSATION STARTER COMPLETE');
      print('>>> ═══════════════════════════════════════════════════════');
    } catch (e) {
      print('>>> ═══════════════════════════════════════════════════════');
      print('>>> ERROR in sendStarterMessage: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ═══════════════════════════════════════════════════════');

      Get.snackbar(
        'Error',
        'Failed to send starter message',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSendingMessage.value = false;
      print('>>> ✓ isSendingMessage set to FALSE');
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
        conversations.removeAt(index);
        conversations.insert(0, resetUserUnread);
        currentConversation.value = resetUserUnread;
      } else {
        conversations.removeAt(index);
        // FIXED: Always move updated conversations to top
        conversations.insert(0, updatedConversation);
      }
    }
  }

  void _handleNewConversation(Conversation newConversation) {
    final exists =
        conversations.any((c) => c.documentId == newConversation.documentId);
    if (!exists) {
      // FIXED: Add new conversations to the TOP
      conversations.insert(0, newConversation);
    }
  }

  void subscribeToMessages(String conversationId) {
    print('>>> ═══════════════════════════════════════════════════════');
    print('>>> SUBSCRIBING TO MESSAGES');
    print('>>> Conversation ID: $conversationId');
    print('>>> ═══════════════════════════════════════════════════════');

    _messageSubscription?.cancel();
    _messageSubscription = _authRepository
        .subscribeToMessages(conversationId)
        .listen((realtimeMessage) {
      print('>>> ═══════════════════════════════════════════════════════');
      print('>>> REAL-TIME MESSAGE EVENT RECEIVED');
      print('>>> Time: ${DateTime.now().millisecondsSinceEpoch}');
      print('>>> Events: ${realtimeMessage.events}');
      print('>>> ═══════════════════════════════════════════════════════');

      if (realtimeMessage.events
          .contains('databases.*.collections.*.documents.*.create')) {
        try {
          final messageData = realtimeMessage.payload;
          final message = Message.fromMap(messageData);
          final messageWithId =
              message.copyWith(documentId: messageData['\$id']);

          print('>>> New message from real-time:');
          print('>>>   - Message ID: ${messageWithId.documentId}');
          print('>>>   - Sender: ${messageWithId.senderId}');
          print('>>>   - Text: ${messageWithId.messageText}');
          print('>>>   - Timestamp: ${messageWithId.messageTimestamp}');

          // CRITICAL: Check for duplicates in currentMessages
          final existingIndex = currentMessages.indexWhere((m) {
            // Check by ID first
            if (m.documentId == messageWithId.documentId) {
              print('>>>   ⚠️ Duplicate found by ID: ${m.documentId}');
              return true;
            }

            // Check by content + sender + time (within 2 seconds)
            if (m.messageText == messageWithId.messageText &&
                m.senderId == messageWithId.senderId &&
                m.messageTimestamp
                        .difference(messageWithId.messageTimestamp)
                        .abs()
                        .inSeconds <
                    2) {
              print('>>>   ⚠️ Duplicate found by content');
              print('>>>   - Existing ID: ${m.documentId}');
              print(
                  '>>>   - Time diff: ${m.messageTimestamp.difference(messageWithId.messageTimestamp).inSeconds}s');
              return true;
            }

            return false;
          });

          if (existingIndex == -1) {
            print('>>>   ✓ No duplicate found, adding message to list');
            print('>>>   - Current message count: ${currentMessages.length}');

            currentMessages.add(messageWithId);
            currentMessages.refresh();

            print('>>>   - New message count: ${currentMessages.length}');

            // Auto-scroll to bottom for new messages
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });

            // If this is from clinic and user is viewing, mark as read
            if (messageWithId.senderId != _userSession.userId &&
                currentConversation.value?.documentId == conversationId) {
              print('>>>   - Auto-marking incoming message as read');
              markConversationAsRead(conversationId);
            }
          } else {
            print(
                '>>>   ⚠️ DUPLICATE BLOCKED - Message already exists at index $existingIndex');
          }

          print('>>> ═══════════════════════════════════════════════════════');
        } catch (e) {
          print('>>> ═══════════════════════════════════════════════════════');
          print('>>> ERROR processing real-time message: $e');
          print('>>> Stack trace: ${StackTrace.current}');
          print('>>> ═══════════════════════════════════════════════════════');
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

  /// Preserve conversation data for layout transitions
void preserveConversationForTransition() {
  if (currentConversation.value != null) {
    selectedConversationData.value = {
      'conversation': currentConversation.value,
      'receiverId': currentReceiverId.value,
      'receiverType': currentReceiverType.value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    shouldAutoSelectConversation.value = true;
    print('>>> Preserved conversation: ${currentConversation.value?.documentId}');
  }
}

/// Clear preserved conversation data after it's been used
void clearPreservedConversation() {
  selectedConversationData.value = null;
  shouldAutoSelectConversation.value = false;
  print('>>> Cleared preserved conversation');
}

/// Check if we should restore a preserved conversation
bool shouldRestoreConversation() {
  if (selectedConversationData.value == null) return false;
  
  // Only restore if preserved within last 5 seconds (to prevent stale data)
  final timestamp = selectedConversationData.value!['timestamp'] as int;
  final age = DateTime.now().millisecondsSinceEpoch - timestamp;
  return age < 5000; // 5 seconds
}

/// Restore the preserved conversation
Future<void> restorePreservedConversation() async {
  if (!shouldRestoreConversation()) {
    clearPreservedConversation();
    return;
  }

  final data = selectedConversationData.value!;
  final conversation = data['conversation'] as Conversation;
  final receiverId = data['receiverId'] as String;
  final receiverType = data['receiverType'] as String;

  print('>>> Restoring conversation: ${conversation.documentId}');
  
  await openConversation(conversation, receiverId, receiverType);
  clearPreservedConversation();
}
}