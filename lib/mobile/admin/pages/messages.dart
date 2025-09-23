import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/mobile/admin/components/admin_message_tile.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessagesPage extends StatefulWidget {
  final String clinicId;
  
  const MessagesPage({
    super.key,
    required this.clinicId,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late final AdminMessagingController _messagingController;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final Map<String, dynamic> _userCache = {}; // Cache user data

  @override
  void initState() {
    super.initState();
    
    // Initialize or get messaging controller
    if (Get.isRegistered<AdminMessagingController>()) {
      _messagingController = Get.find<AdminMessagingController>();
    } else {
      _messagingController = Get.put(AdminMessagingController());
    }
    
    // Initialize with clinic data
    _messagingController.initializeForClinic(widget.clinicId);
  }

  @override
  void dispose() {
    super.dispose();
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
        final userData = snapshot.data ?? {
          'name': 'Loading...',
          'email': '',
          'phone': '',
          'isOnline': false,
        };
        
        return AdminMessageTile(
          conversation: conversation,
          userData: userData,
          onTap: () {
            _messagingController.openConversation(conversation);
            _showConversationDialog(conversation, userData);
          },
        );
      },
    );
  }

  void _showConversationDialog(Conversation conversation, Map<String, dynamic> userData) {
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
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 75, bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Messages",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          // Show notifications
                        },
                      ),
                      Obx(() {
                        final unreadCount = _messagingController.getTotalUnreadCount();
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
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
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
          
          // Main Content
          Expanded(
            child: Container(
              width: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 248, 253, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      controller: _messagingController.searchController,
                      cursorColor: Colors.grey,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Search conversations...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _showConversationStartersDialog();
                          },
                        ),
                      ),
                      onChanged: (value) {
                        // Trigger search
                        setState(() {});
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Conversations List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Obx(() {
                        if (_messagingController.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color.fromARGB(255, 81, 115, 153),
                            ),
                          );
                        }

                        final conversations = _messagingController.filteredConversations;

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

                        return ListView.builder(
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            return _buildConversationTile(conversation);
                          },
                        );
                      }),
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Space for bottom navigation
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

// Conversation Dialog Widget
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
                          final status = messagingController.getUserStatus(conversation.userId);
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
                    final isCurrentUser = messagingController.isCurrentUser(message.senderId);
                    
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
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
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
                              if (messagingController.messageController.text.trim().isNotEmpty) {
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
                            messagingController.selectedCategory.value = value!;
                          },
                        )),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          messagingController.addConversationStarter();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 81, 115, 153),
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
                    final starter = messagingController.conversationStarters[index];
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
                                messagingController.toggleStarterStatus(starter);
                              },
                              activeColor: const Color.fromARGB(255, 81, 115, 153),
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