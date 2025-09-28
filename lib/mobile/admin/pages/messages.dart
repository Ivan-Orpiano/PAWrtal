import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MessagesPage extends StatefulWidget {
  final String clinicId;

  const MessagesPage({
    super.key,
    required this.clinicId,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with WidgetsBindingObserver {
  late final AdminMessagingController _messagingController;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final Map<String, dynamic> _userCache = {}; // Cache user data

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize or get messaging controller
    if (Get.isRegistered<AdminMessagingController>()) {
      _messagingController = Get.find<AdminMessagingController>();
    } else {
      _messagingController = Get.put(AdminMessagingController());
    }

    // Initialize with clinic data
    _messagingController.initializeForClinic(widget.clinicId);
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _messagingController.loadClinicConversations(widget.clinicId);
    }
  }

  void _setupRealtimeUpdates() {
    _messagingController.subscribeToClinicConversations(widget.clinicId);
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _messagingController.loadClinicConversations(widget.clinicId);
        _startPeriodicRefresh();
      }
    });
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final userDoc = await _authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);

        final userData = {
          'name': user.name,
          'email': user.email,
          'phone': user.phone ?? '',
          'isOnline': false, // Will be updated with real status
        };

        _userCache[userId] = userData;
        return userData;
      }
    } catch (e) {
      print('Error loading user data: $e');
    }

    return {
      'name': 'Unknown User',
      'email': '',
      'phone': '',
      'isOnline': false,
    };
  }

  Widget _buildConversationTile(Conversation conversation) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(conversation.userId),
      builder: (context, snapshot) {
        final userData = snapshot.data ??
            {
              'name': 'Loading...',
              'email': '',
              'phone': '',
              'isOnline': false,
            };

        return InkWell(
          onTap: () {
            _messagingController.openConversation(conversation);
            _showConversationDialog(conversation, userData);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // User Avatar with Status - Match user UI
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      child: Text(
                        userData['name'].isNotEmpty
                            ? userData['name'][0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Online status indicator
                    if (userData['isOnline'] == true)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Conversation Details - Match user UI
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userData['name'].isNotEmpty
                                ? userData['name']
                                : 'Unknown User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (conversation.lastMessageTime != null)
                            Text(
                              conversation.timeAgo,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.conversationPreview,
                              style: TextStyle(
                                fontSize: 14,
                                color: conversation.unreadCount > 0
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 81, 115, 153),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConversationDialog(
      Conversation conversation, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => _ConversationDialog(
        conversation: conversation,
        userData: userData,
        messagingController: _messagingController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50, // Match user UI
      body: Column(
        children: [
          // Header - Match user UI style
          Container(
            height: 75,
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Messages",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                // Notifications with unread count
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          _messagingController
                              .loadClinicConversations(widget.clinicId);
                        },
                      ),
                      Obx(() {
                        final unreadCount =
                            _messagingController.getTotalUnreadCount();
                        if (unreadCount > 0) {
                          return Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content - Match user UI
          Expanded(
            child: Container(
              width: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 248, 253, 255), // Match user UI
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Search Bar - Match user UI
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade400,
                            spreadRadius: 2,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _messagingController.searchController,
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () {
                              _showConversationStartersDialog();
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),

                  // Conversations List - Match user UI
                  Expanded(
                    child: Obx(() {
                      if (_messagingController.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        );
                      }

                      final conversations =
                          _messagingController.filteredConversations;

                      if (conversations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No conversations yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Users will appear here when they\nstart conversations with your clinic",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await _messagingController
                              .loadClinicConversations(widget.clinicId);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            return _buildConversationTile(conversation);
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        onPressed: () {
          _showConversationStartersDialog();
        },
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showConversationStartersDialog() {
    showDialog(
      context: context,
      builder: (context) => _ConversationStartersDialog(
        messagingController: _messagingController,
      ),
    );
  }
}

class _ConversationDialog extends StatelessWidget {
  final Conversation conversation;
  final Map<String, dynamic> userData;
  final AdminMessagingController messagingController;

  const _ConversationDialog({
    required this.conversation,
    required this.userData,
    required this.messagingController,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 81, 115, 153),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      userData['name'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 81, 115, 153),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Obx(() {
                          final status = messagingController
                              .getUserStatus(conversation.userId);
                          return Text(
                            status?.statusText ?? 'Offline',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: Obx(() {
                if (messagingController.isLoadingConversation.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 81, 115, 153),
                    ),
                  );
                }

                if (messagingController.currentMessages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: messagingController.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messagingController.currentMessages.length,
                  itemBuilder: (context, index) {
                    final message = messagingController.currentMessages[index];
                    final isCurrentUser =
                        messagingController.isCurrentUser(message.senderId);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isCurrentUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isCurrentUser) ...[
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                userData['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? const Color.fromARGB(255, 81, 115, 153)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.messageText,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.timeFormatted,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white70
                                          : Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),

            // Message Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messagingController.messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          messagingController.sendMessage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => CircleAvatar(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        child: IconButton(
                          icon: messagingController.isSendingMessage.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 18,
                                ),
                          onPressed: messagingController.isSendingMessage.value
                              ? null
                              : () {
                                  if (messagingController.messageController.text
                                      .trim()
                                      .isNotEmpty) {
                                    messagingController.sendMessage();
                                  }
                                },
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Conversation Starters Management Dialog
class _ConversationStartersDialog extends StatelessWidget {
  final AdminMessagingController messagingController;

  const _ConversationStartersDialog({
    required this.messagingController,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conversation Starters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Add new starter form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: messagingController.starterTriggerController,
                    decoration: const InputDecoration(
                      labelText: 'Trigger Text',
                      hintText: 'What users will click on',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messagingController.starterResponseController,
                    decoration: const InputDecoration(
                      labelText: 'Response Text',
                      hintText: 'Automated response message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: messagingController.selectedCategory.value,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: messagingController.categories
                                  .map((category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                messagingController.selectedCategory.value =
                                    value!;
                              },
                            )),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          messagingController.addConversationStarter();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 81, 115, 153),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Existing starters list
            const Text(
              'Current Starters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Obx(() {
                if (messagingController.isLoadingStarters.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 81, 115, 153),
                    ),
                  );
                }

                if (messagingController.conversationStarters.isEmpty) {
                  return const Center(
                    child: Text('No conversation starters yet'),
                  );
                }

                return ListView.builder(
                  itemCount: messagingController.conversationStarters.length,
                  itemBuilder: (context, index) {
                    final starter =
                        messagingController.conversationStarters[index];
                    return Card(
                      child: ListTile(
                        title: Text(starter.triggerText),
                        subtitle: Text(
                          '${starter.categoryDisplayName} • ${starter.responseText}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: starter.isActive,
                              onChanged: (value) {
                                messagingController
                                    .toggleStarterStatus(starter);
                              },
                              activeColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                messagingController.deleteConversationStarter(
                                  starter.documentId!,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
