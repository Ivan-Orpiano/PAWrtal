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

class AdminMessagingController extends GetxController {
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
  final isLoadingStarters = false.obs;

  // Current conversation data
  final currentConversation = Rxn<Conversation>();
  final currentReceiverId = ''.obs;
  final currentReceiverType = ''.obs;
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

  // Track active subscriptions
  String? _activeConversationId;
  String? _activeClinicId;

  @override
  void onInit() {
    super.onInit();
    setUserOnline();
  }

  @override
  void onClose() {
    print('=== AdminMessagingController onClose starting ===');

    try {
      _cancelAllSubscriptions();
      _disposeControllers();
      _clearAllData();
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
      _activeConversationId = null;
    } catch (e) {
      print('Error cancelling message subscription: $e');
    }

    try {
      _conversationSubscription?.cancel();
      _conversationSubscription = null;
      _activeClinicId = null;
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

      currentConversation.value = null;
      currentReceiverId.value = '';
      currentReceiverType.value = '';
      currentClinicId.value = '';
      selectedCategory.value = 'general';

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

      await Future.wait([
        loadClinicConversations(clinicId),
        initializeConversationStarters(clinicId),
      ]);

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

      // ADDED: Run migration for existing starters
      try {
        await _authRepository.migrateConversationStarters();
      } catch (e) {
        print('Warning: Migration failed (non-critical): $e');
      }

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
      print('>>> ============================================');
      print('>>> OPENING CONVERSATION');
      print('>>> Conversation ID: ${conversation.documentId}');
      print('>>> Receiver ID: $receiverId');
      print('>>> Receiver Type: $receiverType');
      print('>>> Admin ID: ${_userSession.userId}');
      print('>>> ============================================');

      isLoadingConversation.value = true;

      currentConversation.value = conversation;
      currentReceiverId.value = receiverId;
      currentReceiverType.value = receiverType;

      print('>>> Loading messages...');
      await loadConversationMessages(conversation.documentId!);
      print('>>> Loaded ${currentMessages.length} messages');

      print('>>> Setting up real-time message subscription...');
      subscribeToMessages(conversation.documentId!);

      print('>>> Marking messages as read...');
      await markConversationAsRead(conversation.documentId!);

      print('>>> Loading user status...');
      await loadUserStatus(receiverId);

      print('>>> ============================================');
      print('>>> CONVERSATION OPENED SUCCESSFULLY');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR opening conversation: $e');
      print('>>> Stack trace: ${StackTrace.current}');
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
      print('>>> ADMIN CONTROLLER: Sending message');
      print('>>> Conversation: ${currentConversation.value!.documentId}');
      print('>>> Sender: ${_userSession.userId}');
      print('>>> Receiver: ${currentReceiverId.value}');
      print('>>> Message: $messageText');
      print('>>> ============================================');

      final sentMessage = await _authRepository.sendMessage(
        conversationId: currentConversation.value!.documentId!,
        senderId: _userSession.userId,
        messageText: messageText,
        attachment: attachmentUrl,
      );

      print('>>> Message sent successfully: ${sentMessage.documentId}');

      final updatedConversation = currentConversation.value!.copyWith(
        lastMessageId: sentMessage.documentId,
        lastMessageText: messageText,
        lastMessageTime: sentMessage.createdAt,
        clinicUnreadCount: 0,
      );
      currentConversation.value = updatedConversation;

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

  bool hasUnreadMessages(Conversation conversation) {
    return conversation.clinicUnreadCount > 0;
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      print('>>> ============================================');
      print('>>> MARKING CONVERSATION AS READ');
      print('>>> Conversation ID: $conversationId');
      print('>>> User ID: ${_userSession.userId}');
      print('>>> User Role: admin');
      print('>>> ============================================');

      await _authRepository.markMessagesAsRead(
          conversationId, _userSession.userId);

      if (currentConversation.value != null &&
          currentConversation.value!.documentId == conversationId &&
          currentConversation.value!.clinicUnreadCount > 0) {
        print('>>> Resetting clinic unread count to 0');

        final updatedConversation = currentConversation.value!.copyWith(
          clinicUnreadCount: 0,
        );
        currentConversation.value = updatedConversation;

        final index =
            conversations.indexWhere((c) => c.documentId == conversationId);
        if (index != -1) {
          conversations[index] = updatedConversation;
          conversations.refresh();
        }

        print('>>> Conversation marked as read successfully');
      } else {
        print('>>> No unread messages to mark');
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR marking messages as read: $e');
      print('>>> ============================================');
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

  /// Set a conversation starter as the auto-reply for first messages
  Future<void> setAutoReplyStarter(String starterId) async {
    try {
      print('>>> Setting auto-reply starter: $starterId');

      // First, unset any existing auto-reply starter
      final currentAutoReply = conversationStarters.firstWhereOrNull(
        (s) => s.isAutoReply == true,
      );

      if (currentAutoReply != null &&
          currentAutoReply.documentId != starterId) {
        print(
            '>>> Unsetting previous auto-reply: ${currentAutoReply.documentId}');
        final unsetStarter = currentAutoReply.copyWith(isAutoReply: false);
        await _authRepository.updateConversationStarter(unsetStarter);

        // Update local list
        final index = conversationStarters.indexWhere(
          (s) => s.documentId == currentAutoReply.documentId,
        );
        if (index != -1) {
          conversationStarters[index] = unsetStarter;
        }
      }

      // Set the new auto-reply starter
      final starterIndex = conversationStarters.indexWhere(
        (s) => s.documentId == starterId,
      );

      if (starterIndex != -1) {
        final updatedStarter = conversationStarters[starterIndex].copyWith(
          isAutoReply: true,
          isActive: true, // Ensure it's active
        );

        await _authRepository.updateConversationStarter(updatedStarter);
        conversationStarters[starterIndex] = updatedStarter;
        conversationStarters.refresh();

        print('>>> Auto-reply starter set successfully');
        Get.snackbar(
          'Success',
          'Auto-reply message configured',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error setting auto-reply starter: $e');
      Get.snackbar(
        'Error',
        'Failed to set auto-reply: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Unset auto-reply for a starter
  Future<void> unsetAutoReplyStarter(String starterId) async {
    try {
      final starterIndex = conversationStarters.indexWhere(
        (s) => s.documentId == starterId,
      );

      if (starterIndex != -1) {
        final updatedStarter = conversationStarters[starterIndex].copyWith(
          isAutoReply: false,
        );

        await _authRepository.updateConversationStarter(updatedStarter);
        conversationStarters[starterIndex] = updatedStarter;
        conversationStarters.refresh();

        Get.snackbar(
          'Success',
          'Auto-reply disabled',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error unsetting auto-reply: $e');
    }
  }

  /// Get the current auto-reply starter
  ConversationStarter? getAutoReplyStarter() {
    try {
      print('>>> 🔍 CHECKING AUTO-REPLY CONFIGURATION');
      print('>>> Total starters: ${conversationStarters.length}');

      for (var starter in conversationStarters) {
        print('>>> Starter: "${starter.triggerText}"');
        print('>>>   - isActive: ${starter.isActive}');
        print('>>>   - isAutoReply: ${starter.isAutoReply}');
        print('>>>   - category: ${starter.category}');
      }

      final autoReply = conversationStarters.firstWhereOrNull(
        (s) => (s.isAutoReply == true) && (s.isActive == true),
      );

      if (autoReply != null) {
        print('>>> ✅ AUTO-REPLY FOUND: "${autoReply.triggerText}"');
        print('>>> Response: "${autoReply.responseText}"');
      } else {
        print('>>> ❌ NO AUTO-REPLY CONFIGURED');
      }

      return autoReply;
    } catch (e) {
      print('>>> ❌ ERROR getting auto-reply starter: $e');
      return null;
    }
  }

  /// Check if a conversation is new (first message from user)
  Future<bool> isFirstUserMessage(String conversationId) async {
    try {
      print('>>> 🔍 Checking if first user message...');
      print('>>> Getting messages for conversation: $conversationId');

      final messages = await _authRepository.getConversationMessages(
        conversationId,
        limit: 100,
      );

      print('>>> Total messages in conversation: ${messages.length}');
      print('>>>');
      print('>>> 📋 Analyzing each message:');

      int userMessageCount = 0;
      int clinicMessageCount = 0;

      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final isFromClinic = msg.senderId == currentClinicId.value;
        final isFromAdmin = msg.senderId == _userSession.userId;
        final isFromUser = !isFromClinic && !isFromAdmin;

        print('>>> Message ${i + 1}:');
        print('>>>   - Sender ID: ${msg.senderId}');
        print(
            '>>>   - Text: "${msg.messageText.substring(0, msg.messageText.length > 30 ? 30 : msg.messageText.length)}..."');
        print('>>>   - From Clinic: $isFromClinic');
        print('>>>   - From Admin: $isFromAdmin');
        print('>>>   - From User: $isFromUser');

        if (isFromClinic || isFromAdmin) {
          clinicMessageCount++;
        } else if (isFromUser) {
          userMessageCount++;
        }
      }

      print('>>>');
      print('>>> 📊 SUMMARY:');
      print('>>> Total messages: ${messages.length}');
      print('>>> User messages: $userMessageCount');
      print('>>> Clinic/Admin messages: $clinicMessageCount');
      print('>>>');

      // If clinic has NEVER replied = first user message
      final isFirst = clinicMessageCount == 0;

      if (isFirst) {
        print('>>> ✅ RESULT: This IS the first user message!');
        print('>>> (Clinic has never replied yet)');
      } else {
        print('>>> ❌ RESULT: NOT the first user message');
        print('>>> (Clinic has already replied $clinicMessageCount time(s))');
      }

      return isFirst;
    } catch (e) {
      print('>>> ❌ ERROR checking first message: $e');
      return false;
    }
  }

  /// Send auto-reply if it's the first user message
  Future<void> sendAutoReplyIfFirstMessage(String conversationId) async {
    // This method is now mainly for manual/UI triggers
    // Background auto-reply is handled by _checkAndSendAutoReply
    await _checkAndSendAutoReply(conversationId);
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

    if (_activeClinicId == clinicId && _conversationSubscription != null) {
      print('>>> Already subscribed to this clinic');
      return;
    }

    _conversationSubscription?.cancel();
    _activeClinicId = null;

    try {
      _conversationSubscription =
          _authRepository.subscribeToConversations(clinicId).listen(
        (realtimeMessage) {
          print('>>> ============================================');
          print('>>> REAL-TIME CONVERSATION EVENT');
          print('>>> Event: ${realtimeMessage.events}');
          print('>>> ============================================');

          try {
            final conversationData = realtimeMessage.payload;
            final updatedConversation = Conversation.fromMap(conversationData);
            final conversationWithId = updatedConversation.copyWith(
              documentId: conversationData['\$id'],
            );

            print('>>> Conversation ID: ${conversationWithId.documentId}');
            print('>>> Clinic ID: ${conversationWithId.clinicId}');

            if (conversationWithId.clinicId == clinicId) {
              print('>>> ✅ Conversation belongs to this clinic');

              if (realtimeMessage.events
                  .contains('databases.*.collections.*.documents.*.update')) {
                print('>>> UPDATE event');
                _handleConversationUpdate(conversationWithId);

                // CRITICAL FIX: Check for auto-reply on conversation UPDATE
                // This catches when user sends a message (conversation gets updated)
                if (conversationWithId.lastMessageId != null) {
                  print('>>> 🤖 Checking auto-reply on conversation UPDATE...');
                  _checkAndSendAutoReply(conversationWithId.documentId!);
                }
              } else if (realtimeMessage.events
                  .contains('databases.*.collections.*.documents.*.create')) {
                print('>>> CREATE event - NEW CONVERSATION');
                _handleNewConversation(conversationWithId);

                // CRITICAL: Check for auto-reply on NEW conversation
                if (conversationWithId.lastMessageId != null) {
                  print('>>> 🤖 Checking auto-reply on NEW CONVERSATION...');
                  _checkAndSendAutoReply(conversationWithId.documentId!);
                }
              }
            } else {
              print('>>> ✗ Conversation does not belong to this clinic');
            }
          } catch (e) {
            print('>>> ERROR processing conversation update: $e');
          }
        },
        onError: (error) {
          print('>>> SUBSCRIPTION ERROR: $error');
          Future.delayed(const Duration(seconds: 2), () {
            if (_activeClinicId == clinicId) {
              subscribeToClinicConversationUpdates(clinicId);
            }
          });
        },
        onDone: () {
          print('>>> Conversation subscription stream closed');
          _activeClinicId = null;
        },
      );

      _activeClinicId = clinicId;
      print('>>> Real-time subscription established');
    } catch (e) {
      print('>>> ERROR setting up subscription: $e');
    }
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

      final isCurrentConversation = currentConversation.value?.documentId ==
          updatedConversation.documentId;

      if (isCurrentConversation) {
        print(
            '>>> This is the current conversation - keeping clinic unread at 0');
        final resetClinicUnread =
            updatedConversation.copyWith(clinicUnreadCount: 0);
        conversations[index] = resetClinicUnread;
        currentConversation.value = resetClinicUnread;
      } else {
        print('>>> Not current conversation - using actual unread counts');
        print(
            '>>> Clinic unread count: ${updatedConversation.clinicUnreadCount}');
        conversations[index] = updatedConversation;
      }

      if (updatedConversation.clinicUnreadCount > 0 && index != 0) {
        print('>>> Moving conversation to top (has unread messages)');
        final conv = conversations.removeAt(index);
        conversations.insert(0, conv);
      }

      // CRITICAL: Trigger auto-reply check when conversation is updated with new message
      if (updatedConversation.lastMessageId != null) {
        print('>>> Checking for auto-reply trigger (UPDATE)...');
        sendAutoReplyIfFirstMessage(updatedConversation.documentId!);
      }

      print('>>> Conversation updated successfully');
    } else {
      print('>>> Conversation not found in list - adding as new');
      _handleNewConversation(updatedConversation);
    }
  }

  void _handleNewConversation(Conversation newConversation) {
    print('>>> _handleNewConversation called');
    print('>>> New conversation ID: ${newConversation.documentId}');

    final exists =
        conversations.any((c) => c.documentId == newConversation.documentId);

    if (!exists) {
      print('>>> Adding new conversation to list at position 0');
      conversations.insert(0, newConversation);
      print('>>> New conversation added successfully');
      print('>>> Total conversations: ${conversations.length}');

      // CRITICAL: Trigger auto-reply for NEW conversations
      if (newConversation.lastMessageId != null) {
        print('>>> Checking for auto-reply trigger (NEW CONVERSATION)...');
        sendAutoReplyIfFirstMessage(newConversation.documentId!);
      }
    } else {
      print('>>> Conversation already exists - skipping');
    }
  }

  void subscribeToMessages(String conversationId) {
    print('>>> ============================================');
    print('>>> SUBSCRIBING TO MESSAGES');
    print('>>> Conversation ID: $conversationId');
    print('>>> ============================================');

    if (_activeConversationId == conversationId &&
        _messageSubscription != null) {
      print('>>> Already subscribed - skipping');
      return;
    }

    _messageSubscription?.cancel();
    _activeConversationId = null;

    try {
      _activeConversationId = conversationId;
      _messageSubscription = _authRepository
          .subscribeToMessages(conversationId)
          .listen((realtimeMessage) {
        print('>>> ════════════════════════════════════════');
        print('>>> REAL-TIME MESSAGE EVENT RECEIVED');
        print('>>> Events: ${realtimeMessage.events}');
        print('>>> Time: ${DateTime.now()}');

        if (realtimeMessage.events
            .contains('databases.*.collections.*.documents.*.create')) {
          try {
            final messageData = realtimeMessage.payload;
            final message = Message.fromMap(messageData);
            final messageWithId =
                message.copyWith(documentId: messageData['\$id']);

            print('>>> 📨 NEW MESSAGE DETAILS:');
            print('>>>   - Message ID: ${messageWithId.documentId}');
            print('>>>   - Sender ID: ${messageWithId.senderId}');
            print('>>>   - Message Text: "${messageWithId.messageText}"');

            // Check for duplicates
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
              print('>>> ✅ Adding message to list');
              currentMessages.add(messageWithId);
              currentMessages.refresh();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              if (messageWithId.senderId != _userSession.userId &&
                  currentConversation.value?.documentId == conversationId) {
                markConversationAsRead(conversationId);
              }

              // REMOVED: Auto-reply check from here
              // It's now handled in subscribeToClinicConversationUpdates
            } else {
              print('>>> ⚠️ Duplicate message detected - skipping');
            }
          } catch (e) {
            print('>>> ❌ ERROR processing message: $e');
            print('>>> Stack: ${StackTrace.current}');
          }
        } else {
          print('>>> ℹ️ Not a create event - ignoring');
        }
        print('>>> ────────────────────────────────────────');
      }, onError: (error) {
        print('>>> ❌ SUBSCRIPTION ERROR: $error');
        _activeConversationId = null;
      });

      print('>>> ✅ Message subscription established');
    } catch (e) {
      print('>>> ❌ Error setting up subscription: $e');
      _activeConversationId = null;
    }
  }

  Future<void> _checkAndSendAutoReply(String conversationId) async {
    try {
      print('>>> ═══════════════════════════════════════════');
      print('>>> 🔍 AUTO-REPLY CHECK (BACKGROUND)');
      print('>>> Conversation ID: $conversationId');
      print('>>> ═══════════════════════════════════════════');

      // Get auto-reply starter
      final autoReplyStarter = getAutoReplyStarter();

      if (autoReplyStarter == null) {
        print('>>> ❌ No auto-reply configured - skipping');
        return;
      }

      print(
          '>>> ✅ Auto-reply starter found: "${autoReplyStarter.triggerText}"');

      // Check if this is the first user message
      final isFirst = await isFirstUserMessage(conversationId);

      if (!isFirst) {
        print('>>> ❌ Not first message - clinic already replied');
        return;
      }

      print('>>> ✅ This IS the first user message!');
      print('>>> 📤 Sending auto-reply...');

      // Send the auto-reply
      await _authRepository.sendConversationStarterResponse(
        conversationId: conversationId,
        clinicId: currentClinicId.value,
        responseText: autoReplyStarter.responseText,
      );

      print('>>> ✅ AUTO-REPLY SENT SUCCESSFULLY');
      print('>>> ═══════════════════════════════════════════');

      // If the conversation is currently open, reload messages
      if (currentConversation.value?.documentId == conversationId) {
        await Future.delayed(const Duration(milliseconds: 500));
        await loadConversationMessages(conversationId);
        print('>>> ✅ Messages reloaded for current conversation');
      }
    } catch (e) {
      print('>>> ═══════════════════════════════════════════');
      print('>>> ❌ AUTO-REPLY ERROR: $e');
      print('>>> Stack: ${StackTrace.current}');
      print('>>> ═══════════════════════════════════════════');
    }
  }

  // ============= HELPER METHODS =============

  bool isCurrentUser(String senderId) {
    // Admin can send messages as:
    // 1. Their own user ID (admin user ID)
    // 2. The clinic ID (when sending clinic responses)

    final isAdminUserId = senderId == _userSession.userId;
    final isClinicId = senderId == currentClinicId.value;

    print('>>> Checking if current user:');
    print('>>>   senderId: $senderId');
    print('>>>   adminUserId: ${_userSession.userId}');
    print('>>>   clinicId: ${currentClinicId.value}');
    print('>>>   isAdminUserId: $isAdminUserId');
    print('>>>   isClinicId: $isClinicId');
    print('>>>   Result: ${isAdminUserId || isClinicId}');

    return isAdminUserId || isClinicId;
  }

  UserStatus? getUserStatus(String userId) {
    return userStatuses[userId];
  }

  int getTotalUnreadCount() {
    return conversations.fold(0, (total, conversation) {
      return total + conversation.clinicUnreadCount;
    });
  }

  List<Conversation> get filteredConversations {
    if (searchController.text.isEmpty) {
      return conversations;
    }
    return conversations;
  }

  void disposeMessageSubscriptions() {
    _cancelAllSubscriptions();
  }
}
