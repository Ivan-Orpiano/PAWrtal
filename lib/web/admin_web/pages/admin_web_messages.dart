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
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void dispose() {
    super.dispose();
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

      String? clinicId = _getStorage.read('clinicId') as String?;

      print('>>> Step 1: Checking storage for clinicId');
      print('>>>   - clinicId from storage: $clinicId');
      print('>>>   - user role: $_userRole');
      print('>>>   - user ID: ${_userSession.userId}');

      if (clinicId == null || clinicId.isEmpty) {
        print('>>> Step 2: No clinicId in storage, attempting to fetch...');

        if (_userRole == 'admin') {
          print('>>>   - Mode: ADMIN - Looking up by admin ID');
          final clinicDoc =
              await _authRepository.getClinicByAdminId(_userSession.userId);

          if (clinicDoc != null) {
            clinicId = clinicDoc.$id;
            await _getStorage.write('clinicId', clinicId);
            print('>>>   - Found and stored clinic ID: $clinicId');
          } else {
            print(
                '>>>   - ERROR: No clinic found for admin ID: ${_userSession.userId}');
          }
        } else if (_userRole == 'staff') {
          print('>>>   - Mode: STAFF - Should have clinicId in storage');
          print('>>>   - ERROR: Staff account missing clinicId in storage!');

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

        print(
            '>>> Step 4: Activating real-time subscriptions for conversation list...');
        _controller.subscribeToClinicConversationUpdates(_clinicId!);

        print('>>> ============================================');
        print('>>> INITIALIZATION SUCCESSFUL');
        print('>>> Clinic ID: $_clinicId');
        print('>>> Real-time subscriptions ACTIVE');
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

  Future<void> _openConversationInMobile(
      Conversation conversation, String userId, String userName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AdminMobileMessagesPage(
          conversation: conversation,
          userId: userId,
          userName: userName,
          controller: _controller,
        ),
      ),
    );

    if (mounted) {
      await _controller.loadClinicConversations(_clinicId!);
    }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          Container(
            color: const Color.fromARGB(255, 248, 253, 255),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const SizedBox(
                    width: 56), // Balance the IconButton on the right
                Expanded(
                  child: Text(
                    "Messages",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
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
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 248, 253, 255),
              ),
              child: Column(
                children: [
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
                        controller: _controller.searchController,
                        decoration: const InputDecoration(
                          hintText: "Search conversations...",
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (_controller.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        );
                      }

                      if (_controller.conversations.isEmpty) {
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
                                "Conversations will appear here when\nusers message your clinic",
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
                          await _controller.loadClinicConversations(_clinicId!);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _controller.conversations.length,
                          itemBuilder: (context, index) {
                            final conversation =
                                _controller.conversations[index];
                            return FutureBuilder<Map<String, dynamic>>(
                              future: _getUserData(conversation.userId),
                              builder: (context, snapshot) {
                                final userData = snapshot.data ??
                                    {
                                      'name': 'Loading...',
                                      'email': '',
                                      'phone': ''
                                    };
                                return _buildMobileConversationTile(
                                  conversation,
                                  userData,
                                );
                              },
                            );
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
    );
  }

  Widget _buildMobileConversationTile(
      Conversation conversation, Map<String, dynamic> userData) {
    final hasUnreadMessages = conversation.clinicUnreadCount > 0;

    return InkWell(
      onTap: () async {
        await _openConversationInMobile(
          conversation,
          conversation.userId,
          userData['name'],
        );
        await _controller.loadClinicConversations(_clinicId!);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: hasUnreadMessages
              ? Border.all(
                  color: const Color.fromARGB(255, 81, 115, 153),
                  width: 2,
                )
              : null,
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  child: Text(
                    userData['name'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(() {
                  final status = _controller.getUserStatus(conversation.userId);
                  if (status?.isOnline == true) {
                    return Positioned(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          userData['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessageTime != null)
                        Text(
                          conversation.timeAgo,
                          style: TextStyle(
                            color: hasUnreadMessages
                                ? const Color.fromARGB(255, 81, 115, 153)
                                : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: hasUnreadMessages
                                ? FontWeight.bold
                                : FontWeight.normal,
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
                            color: hasUnreadMessages
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: hasUnreadMessages
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnreadMessages) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 81, 115, 153),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.clinicUnreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: Row(
        children: [
          SizedBox(
            width: 350,
            child: _buildConversationsList(),
          ),
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
                const SizedBox(
                    width: 48), // Balance the IconButton on the right
                Expanded(
                  child: Text(
                    'Messages',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
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

class _AdminMobileMessagesPage extends StatefulWidget {
  final Conversation conversation;
  final String userId;
  final String userName;
  final AdminMessagingController controller;

  const _AdminMobileMessagesPage({
    required this.conversation,
    required this.userId,
    required this.userName,
    required this.controller,
  });

  @override
  State<_AdminMobileMessagesPage> createState() =>
      _AdminMobileMessagesPageState();
}

class _AdminMobileMessagesPageState extends State<_AdminMobileMessagesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.openConversation(
        widget.conversation,
        widget.userId,
        'user',
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_left_rounded,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      child: Text(
                        widget.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Obx(() {
                      final status =
                          widget.controller.getUserStatus(widget.userId);
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Obx(() {
                        final status =
                            widget.controller.getUserStatus(widget.userId);
                        return Text(
                          status?.statusText ?? 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (widget.controller.isLoadingConversation.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 81, 115, 153),
                  ),
                );
              }

              if (widget.controller.currentMessages.isEmpty) {
                return _buildEmptyMessageState();
              }

              return ListView.builder(
                controller: widget.controller.scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                reverse: true,
                itemCount: widget.controller.currentMessages.length,
                itemBuilder: (context, index) {
                  final reversedIndex =
                      widget.controller.currentMessages.length - 1 - index;
                  final message =
                      widget.controller.currentMessages[reversedIndex];
                  return _buildMessageBubble(message);
                },
              );
            }),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyMessageState() {
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
            "Start a conversation",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Send a message to ${widget.userName}",
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

  Widget _buildMessageBubble(Message message) {
    final isCurrentUser = widget.controller.isCurrentUser(message.senderId);
    final isStarterMessage = message.isStarterMessage;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              child: Text(
                widget.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color.fromARGB(255, 81, 115, 153)
                    : isStarterMessage
                        ? Colors.blue[50]
                        : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
                border: isStarterMessage
                    ? Border.all(color: Colors.blue[200]!, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isStarterMessage)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "Auto-response",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  Text(
                    message.messageText,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeFormatted,
                        style: TextStyle(
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (isCurrentUser && message.isRead) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.camera_alt_rounded,
                color: Colors.grey[600],
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(
                Icons.photo,
                color: Colors.grey[600],
              ),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.grey.shade200,
                ),
                child: TextField(
                  controller: widget.controller.messageController,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      widget.controller.sendMessage();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  child: IconButton(
                    icon: widget.controller.isSendingMessage.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                    onPressed: widget.controller.isSendingMessage.value
                        ? null
                        : () {
                            if (widget.controller.messageController.text
                                .trim()
                                .isNotEmpty) {
                              widget.controller.sendMessage();
                            }
                          },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
