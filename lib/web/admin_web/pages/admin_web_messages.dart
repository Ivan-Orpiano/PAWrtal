import 'package:capstone_app/mobile/admin/controllers/admin_messaging_controller.dart';
import 'package:capstone_app/mobile/admin/pages/conversation_starters_page.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AdminWebMessages extends StatefulWidget {
  const AdminWebMessages({super.key});

  @override
  State<AdminWebMessages> createState() => _AdminWebMessagesState();
}

class _AdminWebMessagesState extends State<AdminWebMessages> {
  final GetStorage _getStorage = GetStorage();
  late final AdminMessagingController _controller;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserSessionService _userSession = Get.find<UserSessionService>();
  final Map<String, dynamic> _userCache = {};

  String? _clinicId;
  String? _userRole;
  Conversation? _selectedConversation;
  String? _selectedUserId;
  String? _selectedUserName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _initializeMessaging();
  }

  void _loadUserRole() {
    _userRole = _getStorage.read("role") as String?;
    print('>>> ============================================');
    print('>>> ADMIN_WEB_MESSAGES: Loading user role');
    print('>>> User role: $_userRole');
    print('>>> ============================================');
  }

  Future<void> _initializeMessaging() async {
    if (Get.isRegistered<AdminMessagingController>()) {
      _controller = Get.find<AdminMessagingController>();
    } else {
      _controller = Get.put(AdminMessagingController());
    }

    try {
      print('>>> ============================================');
      print('>>> ADMIN_WEB_MESSAGES: Initializing...');
      print('>>> ============================================');

      // CRITICAL FIX: Read clinicId directly from storage FIRST
      // This was stored during login for both admin and staff
      String? clinicId = _getStorage.read('clinicId') as String?;

      print('>>> Step 1: Checking storage for clinicId');
      print('>>>   - clinicId from storage: $clinicId');
      print('>>>   - user role: $_userRole');
      print('>>>   - user ID: ${_userSession.userId}');

      // If no clinicId in storage, try to fetch it
      if (clinicId == null || clinicId.isEmpty) {
        print('>>> Step 2: No clinicId in storage, attempting to fetch...');

        if (_userRole == 'admin') {
          print('>>>   - Mode: ADMIN - Looking up by admin ID');
          final clinicDoc =
              await _authRepository.getClinicByAdminId(_userSession.userId);

          if (clinicDoc != null) {
            clinicId = clinicDoc.$id;
            // Store it for future use
            await _getStorage.write('clinicId', clinicId);
            print('>>>   - Found and stored clinic ID: $clinicId');
          } else {
            print(
                '>>>   - ERROR: No clinic found for admin ID: ${_userSession.userId}');
          }
        } else if (_userRole == 'staff') {
          print('>>>   - Mode: STAFF - Should have clinicId in storage');
          print('>>>   - ERROR: Staff account missing clinicId in storage!');

          // Try to look up staff record to get clinicId
          final staff =
              await _authRepository.getStaffByUserId(_userSession.userId);
          if (staff != null) {
            clinicId = staff.clinicId;
            await _getStorage.write('clinicId', clinicId);
            print(
                '>>>   - Found and stored clinic ID from staff record: $clinicId');
          }
        }
      } else {
        print('>>> Step 2: Using clinicId from storage: $clinicId');
      }

      if (clinicId != null && clinicId.isNotEmpty) {
        setState(() {
          _clinicId = clinicId;
          _isLoading = false;
        });

        print('>>> Step 3: Initializing controller with clinic ID: $_clinicId');
        await _controller.initializeForClinic(_clinicId!);
        print('>>> ============================================');
        print('>>> INITIALIZATION SUCCESSFUL');
        print('>>> Clinic ID: $_clinicId');
        print('>>> ============================================');
      } else {
        print('>>> ============================================');
        print('>>> ERROR: No clinic ID found');
        print('>>> User role: $_userRole');
        print('>>> User ID: ${_userSession.userId}');
        print('>>> Storage dump:');
        print('>>>   - role: ${_getStorage.read("role")}');
        print('>>>   - clinicId: ${_getStorage.read("clinicId")}');
        print('>>>   - userId: ${_getStorage.read("userId")}');
        print('>>> ============================================');

        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR initializing messaging: $e');
      print('>>> ============================================');
      setState(() => _isLoading = false);
    }
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
        };
        _userCache[userId] = userData;
        return userData;
      }
    } catch (e) {
      print('Error loading user: $e');
    }

    return {'name': 'Unknown User', 'email': '', 'phone': ''};
  }

  void _selectConversation(
      Conversation conversation, String userId, String userName) {
    setState(() {
      _selectedConversation = conversation;
      _selectedUserId = userId;
      _selectedUserName = userName;
    });
    _controller.openConversation(conversation, userId, 'user');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_clinicId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Clinic not found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Role: $_userRole',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Try to reinitialize
                  setState(() => _isLoading = true);
                  _initializeMessaging();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: Row(
        children: [
          // Left Panel - Conversations List
          SizedBox(
            width: 350,
            child: _buildConversationsList(),
          ),

          // Right Panel - Messages
          Expanded(
            child: _selectedConversation == null
                ? _buildEmptyState()
                : _buildMessagesPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Manage Starters',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConversationStartersPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // Conversations
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: _controller.conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _controller.conversations[index];
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getUserData(conversation.userId),
                    builder: (context, snapshot) {
                      final userData =
                          snapshot.data ?? {'name': 'Loading...', 'email': ''};
                      final isSelected = _selectedConversation?.documentId ==
                          conversation.documentId;

                      return _buildConversationTile(
                          conversation, userData, isSelected);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation,
      Map<String, dynamic> userData, bool isSelected) {
    final hasUnread = conversation.clinicUnreadCount > 0;

    return Material(
      color: isSelected ? Colors.blue.shade100 : Colors.white,
      child: InkWell(
        onTap: () => _selectConversation(
            conversation, conversation.userId, userData['name']),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    child: Text(
                      userData['name'][0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Obx(() {
                    final status =
                        _controller.getUserStatus(conversation.userId);
                    if (status?.isOnline == true) {
                      return Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userData['name'],
                            style: TextStyle(
                              fontWeight:
                                  hasUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.lastMessageTime != null)
                          Text(
                            conversation.timeAgo,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
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
                              fontSize: 13,
                              color:
                                  hasUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 81, 115, 153),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation.clinicUnreadCount.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Select a conversation to start messaging',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildMessagesHeader(),
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color.fromARGB(255, 81, 115, 153),
            child: Text(
              _selectedUserName![0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedUserName!,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Obx(() {
                  final status = _controller.getUserStatus(_selectedUserId!);
                  return Text(
                    status?.statusText ?? 'Offline',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  );
                }),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Obx(() {
      if (_controller.isLoadingConversation.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.currentMessages.isEmpty) {
        return const Center(child: Text('No messages yet'));
      }

      return ListView.builder(
        controller: _controller.scrollController,
        padding: const EdgeInsets.all(16),
        reverse: true,
        itemCount: _controller.currentMessages.length,
        itemBuilder: (context, index) {
          final reversedIndex = _controller.currentMessages.length - 1 - index;
          final message = _controller.currentMessages[reversedIndex];
          return _buildMessageBubble(message);
        },
      );
    });
  }

  Widget _buildMessageBubble(Message message) {
    final isCurrentUser = _controller.isCurrentUser(message.senderId);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? const Color.fromARGB(255, 81, 115, 153)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.messageText,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.timeFormatted,
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller.messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _controller.sendMessage();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => IconButton(
                icon: _controller.isSendingMessage.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                color: const Color.fromARGB(255, 81, 115, 153),
                onPressed: _controller.isSendingMessage.value
                    ? null
                    : () {
                        if (_controller.messageController.text
                            .trim()
                            .isNotEmpty) {
                          _controller.sendMessage();
                        }
                      },
              )),
        ],
      ),
    );
  }
}
