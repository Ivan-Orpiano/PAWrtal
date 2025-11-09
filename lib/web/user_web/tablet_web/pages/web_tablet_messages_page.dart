import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebTabletMessagesPage extends StatefulWidget {
  const WebTabletMessagesPage({super.key});

  @override
  State<WebTabletMessagesPage> createState() => _WebTabletMessagesPageState();
}

class _WebTabletMessagesPageState extends State<WebTabletMessagesPage> {
  late final MessagingController _controller;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final Map<String, dynamic> _clinicCache = {};
  
  Conversation? _selectedConversation;
  String? _selectedClinicId;
  String? _selectedClinicName;
  String? _selectedClinicImage;
  String? _selectedProfilePictureId;
  bool _showStarters = false;
  bool _showConversationsList = true; // Toggle between list and messages
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
void initState() {
  super.initState();
  _initializeMessaging();
  
  // Check if we need to restore a preserved conversation
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (_controller.shouldRestoreConversation()) {
      final data = _controller.selectedConversationData.value!;
      final conversation = data['conversation'] as Conversation;
      
      // Get clinic data
      final clinicData = await _getClinicData(conversation.clinicId);
      
      // Select the conversation
      _selectConversation(
        conversation,
        conversation.clinicId,
        clinicData['name'],
        clinicData['image'],
        clinicData['profilePictureId'],
      );
      
      _controller.clearPreservedConversation();
    }
  });
}

  @override
void dispose() {
  _searchController.dispose();
  
  // Preserve conversation state when switching layouts
  if (_selectedConversation != null) {
    _controller.preserveConversationForTransition();
  }
  
  super.dispose();
}

  void _initializeMessaging() {
    if (Get.isRegistered<MessagingController>()) {
      _controller = Get.find<MessagingController>();
    } else {
      _controller = Get.put(MessagingController());
    }
    
    _controller.loadUserConversations();
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) {
      return _controller.conversations;
    }

    final query = _searchQuery.toLowerCase();
    return _controller.conversations.where((conversation) {
      final clinicData = _clinicCache[conversation.clinicId];
      final clinicName = clinicData?['name']?.toString().toLowerCase() ?? '';
      final lastMessage = conversation.lastMessageText?.toLowerCase() ?? '';

      return clinicName.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  Future<Map<String, dynamic>> _getClinicData(String clinicId) async {
    if (_clinicCache.containsKey(clinicId)) {
      return _clinicCache[clinicId];
    }

    try {
      final clinicDoc = await _authRepository.getClinicById(clinicId);
      if (clinicDoc != null) {
        final clinic = Clinic.fromMap(clinicDoc.data);
        final clinicData = {
          'name': clinic.clinicName,
          'image': clinic.image,
          'profilePictureId': clinic.profilePictureId ?? '',
          'address': clinic.address,
        };
        _clinicCache[clinicId] = clinicData;
        return clinicData;
      }
    } catch (e) {
    }

    return {
      'name': 'Unknown Clinic',
      'image': '',
      'profilePictureId': '',
      'address': ''
    };
  }

  void _selectConversation(Conversation conversation, String clinicId,
      String clinicName, String clinicImage, String profilePictureId) async {
    setState(() {
      _selectedConversation = conversation;
      _selectedClinicId = clinicId;
      _selectedClinicName = clinicName;
      _selectedClinicImage = clinicImage;
      _selectedProfilePictureId = profilePictureId;
      _showStarters = false;
      _showConversationsList = false; // Switch to messages view
    });
    await _controller.openConversation(conversation, clinicId, 'clinic');
    await _controller.loadConversationStarters(clinicId);
  }

  void _backToConversations() {
    setState(() {
      _showConversationsList = true;
    });
  }

  String _getProfileImageUrl(String profilePictureId) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: _showConversationsList
          ? _buildConversationsList()
          : _buildMessagesPanel(),
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
            child: const Row(
              children: [
                Text(
                  'Messages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
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
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation\nwith a clinic',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final filteredConversations = _filteredConversations;

              if (filteredConversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredConversations.length,
                itemBuilder: (context, index) {
                  final conversation = filteredConversations[index];
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getClinicData(conversation.clinicId),
                    builder: (context, snapshot) {
                      final clinicData = snapshot.data ?? {
                        'name': 'Loading...',
                        'image': '',
                        'profilePictureId': '',
                        'address': ''
                      };
                      
                      return _buildConversationTile(conversation, clinicData);
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

  Widget _buildConversationTile(Conversation conversation, Map<String, dynamic> clinicData) {
    final hasUnread = conversation.userUnreadCount > 0;
    
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _selectConversation(
          conversation,
          conversation.clinicId,
          clinicData['name'],
          clinicData['image'],
          clinicData['profilePictureId'],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              _buildProfileImage(clinicData, 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            clinicData['name'],
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.lastMessageTime != null)
                          Text(
                            conversation.timeAgo,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                              color: hasUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 81, 115, 153),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation.userUnreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(Map<String, dynamic> clinicData, double size) {
    final profilePictureId = clinicData['profilePictureId'] as String? ?? '';
    final fallbackImage = clinicData['image'] as String? ?? '';
    final clinicName = clinicData['name'] as String? ?? 'Clinic';

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: profilePictureId.isNotEmpty
          ? Image.network(
              _getProfileImageUrl(profilePictureId),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return fallbackImage.isNotEmpty
                    ? Image.network(
                        fallbackImage,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(clinicName, size);
                        },
                      )
                    : _buildDefaultAvatar(clinicName, size);
              },
            )
          : fallbackImage.isNotEmpty
              ? Image.network(
                  fallbackImage,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar(clinicName, size);
                  },
                )
              : _buildDefaultAvatar(clinicName, size),
    );
  }

  Widget _buildDefaultAvatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 81, 115, 153),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          if (_showStarters) _buildConversationStarters(),
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesHeader() {
    final clinicData = {
      'name': _selectedClinicName,
      'image': _selectedClinicImage,
      'profilePictureId': _selectedProfilePictureId,
    };

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
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _backToConversations,
          ),
          const SizedBox(width: 8),
          _buildProfileImage(clinicData, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedClinicName!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(_showStarters ? Icons.close : Icons.auto_awesome),
            tooltip: _showStarters ? 'Hide Starters' : 'Show Starters',
            onPressed: () {
              setState(() {
                _showStarters = !_showStarters;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConversationStarters() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Obx(() {
        final isSending = _controller.isSendingMessage.value;

        if (_controller.conversationStarters.isEmpty) {
          return const Center(
            child: Text(
              'No conversation starters available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSending)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 81, 115, 153),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sending message...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _controller.conversationStarters.length,
                itemBuilder: (context, index) {
                  final starter = _controller.conversationStarters[index];
                  return _buildStarterChip(starter);
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStarterChip(ConversationStarter starter) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Obx(() {
        final isSending = _controller.isSendingMessage.value;

        return InkWell(
          onTap: isSending
              ? null
              : () {
                  _controller.sendStarterMessage(starter);
                  setState(() {
                    _showStarters = false;
                  });
                },
          child: Opacity(
            opacity: isSending ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSending
                      ? Colors.grey
                      : const Color.fromARGB(255, 81, 115, 153),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      starter.categoryDisplayName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 81, 115, 153),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          starter.triggerText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSending) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 81, 115, 153),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMessagesList() {
    return Obx(() {
      if (_controller.isLoadingConversation.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.currentMessages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Start a conversation'),
              const SizedBox(height: 8),
              Text(
                'Use the sparkle button to see conversation starters',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
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
    final isStarterMessage = message.isStarterMessage;
    
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isCurrentUser 
              ? const Color.fromARGB(255, 81, 115, 153)
              : isStarterMessage
                  ? Colors.blue[50]
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: isStarterMessage 
              ? Border.all(color: Colors.blue[200]!, width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isStarterMessage)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Auto-response',
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
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.timeFormatted,
                  style: TextStyle(
                    fontSize: 10,
                    color: isCurrentUser ? Colors.white70 : Colors.grey[600],
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    if (_controller.messageController.text.trim().isNotEmpty) {
                      _controller.sendMessage();
                    }
                  },
          )),
        ],
      ),
    );
  }
}