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
          print('>>> REAL-TIME EVENT RECEIVED');
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
            print('>>> User Unread: ${conversationWithId.userUnreadCount}');
            print('>>> Clinic Unread: ${conversationWithId.clinicUnreadCount}');

            if (conversationWithId.clinicId == clinicId) {
              print(
                  '>>> âœ" Conversation belongs to this clinic - processing...');

              if (realtimeMessage.events
                  .contains('databases.*.collections.*.documents.*.update')) {
                print('>>> Update event detected');
                _handleConversationUpdate(conversationWithId);
              } else if (realtimeMessage.events
                  .contains('databases.*.collections.*.documents.*.create')) {
                print('>>> Create event detected');
                _handleNewConversation(conversationWithId);
              }

              print('>>> âœ" Conversation list updated successfully');
              print('>>> Total conversations: ${conversations.length}');
            } else {
              print(
                  '>>> âœ— Conversation does not belong to this clinic - skipping');
            }
          } catch (e) {
            print('>>> ============================================');
            print('>>> ERROR processing conversation update: $e');
            print('>>> Stack trace: ${StackTrace.current}');
            print('>>> ============================================');
          }

          print('>>> ============================================');
        },
        onError: (error) {
          print('>>> ============================================');
          print('>>> SUBSCRIPTION ERROR: $error');
          print('>>> Attempting to resubscribe...');
          print('>>> ============================================');

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

      print('>>> Real-time subscription established successfully');
      print('>>> Listening for conversation updates...');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR setting up real-time subscription: $e');
      print('>>> ============================================');
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
      print('>>> Already subscribed to messages for this conversation');
      print('>>> ============================================');
      return;
    }

    _messageSubscription?.cancel();
    _activeConversationId = null;

    try {
      _activeConversationId = conversationId;
      _messageSubscription = _authRepository
          .subscribeToMessages(conversationId)
          .listen((realtimeMessage) {
        print('>>> ============================================');
        print('>>> REAL-TIME MESSAGE EVENT');
        print('>>> Events: ${realtimeMessage.events}');
        print('>>> ============================================');

        if (realtimeMessage.events
            .contains('databases.*.collections.*.documents.*.create')) {
          try {
            final messageData = realtimeMessage.payload;
            final message = Message.fromMap(messageData);
            final messageWithId =
                message.copyWith(documentId: messageData['\$id']);

            print('>>> New message received:');
            print('>>>   - ID: ${messageWithId.documentId}');
            print('>>>   - From: ${messageWithId.senderId}');
            print('>>>   - Text: ${messageWithId.messageText}');

            // Check for duplicates by ID and content
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

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              // Auto-mark as read if it's from the user and we're viewing the conversation
              if (messageWithId.senderId != _userSession.userId &&
                  currentConversation.value?.documentId == conversationId) {
                print('>>> Auto-marking incoming message as read');
                markConversationAsRead(conversationId);
              }
            } else {
              print(
                  '>>> Message already exists - skipping (index: $existingIndex)');
            }

            print('>>> ============================================');
          } catch (e) {
            print('>>> Error processing real-time message: $e');
            print('>>> Stack trace: ${StackTrace.current}');
            print('>>> ============================================');
          }
        }
      }, onError: (error) {
        print('>>> ============================================');
        print('>>> MESSAGE SUBSCRIPTION ERROR: $error');
        print('>>> ============================================');
        _activeConversationId = null;
      }, onDone: () {
        print('>>> Message subscription closed');
        _activeConversationId = null;
      });

      print('>>> Message subscription established successfully');
      print('>>> ============================================');
    } catch (e) {
      print('>>> Error setting up message subscription: $e');
      print('>>> ============================================');
      _activeConversationId = null;
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
