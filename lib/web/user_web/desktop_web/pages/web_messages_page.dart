import 'package:capstone_app/mobile/user/controllers/messaging_controller.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/conversation_starter_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebMessagesPage extends StatefulWidget {
  const WebMessagesPage({super.key});

  @override
  State<WebMessagesPage> createState() => _WebMessagesPageState();
}

class _WebMessagesPageState extends State<WebMessagesPage> {
  late final MessagingController _controller;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final Map<String, dynamic> _clinicCache = {};
  
  bool _showStarters = false;

  @override
  void initState() {
    super.initState();
    _initializeMessaging();
  }

  void _initializeMessaging() {
    if (Get.isRegistered<MessagingController>()) {
      _controller = Get.find<MessagingController>();
    } else {
      _controller = Get.put(MessagingController());
    }
    
    _controller.loadUserConversations();
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
          'address': clinic.address,
        };
        _clinicCache[clinicId] = clinicData;
        return clinicData;
      }
    } catch (e) {
      print('Error loading clinic: $e');
    }

    return {'name': 'Unknown Clinic', 'image': '', 'address': ''};
  }

  void _selectConversation(Conversation conversation, String clinicId, String clinicName, String clinicImage) async {
    setState(() {
      _showStarters = false;
    });
    await _controller.openConversation(conversation, clinicId, 'clinic');
    
    // Load conversation starters for this clinic
    await _controller.loadConversationStarters(clinicId);
  }

  @override
  Widget build(BuildContext context) {
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
            child: Obx(() {
              // Use controller's currentConversation instead of local state
              return _controller.currentConversation.value == null
                  ? _buildEmptyState()
                  : _buildMessagesPanel();
            }),
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

              return ListView.builder(
                itemCount: _controller.conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _controller.conversations[index];
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getClinicData(conversation.clinicId),
                    builder: (context, snapshot) {
                      final clinicData = snapshot.data ?? {
                        'name': 'Loading...',
                        'image': '',
                        'address': ''
                      };
                      // Check if this conversation is selected using controller's state
                      final isSelected = _controller.currentConversation.value?.documentId == conversation.documentId;
                      
                      return _buildConversationTile(conversation, clinicData, isSelected);
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

  Widget _buildConversationTile(Conversation conversation, Map<String, dynamic> clinicData, bool isSelected) {
    final hasUnread = conversation.userUnreadCount > 0;
    
    return Material(
      color: isSelected ? Colors.blue.shade100 : Colors.white,
      child: InkWell(
        onTap: () => _selectConversation(
          conversation,
          conversation.clinicId,
          clinicData['name'],
          clinicData['image'],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: clinicData['image'].isNotEmpty
                    ? Image.network(
                        clinicData['image'],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(clinicData['name']);
                        },
                      )
                    : _buildDefaultAvatar(clinicData['name']),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 81, 115, 153),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
    return Obx(() {
      // Get current conversation data from controller
      final conversation = _controller.currentConversation.value;
      final clinicId = _controller.currentReceiverId.value;
      
      return FutureBuilder<Map<String, dynamic>>(
        future: _getClinicData(clinicId),
        builder: (context, snapshot) {
          final clinicData = snapshot.data ?? {
            'name': 'Loading...',
            'image': '',
          };
          
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildMessagesHeader(clinicData['name'], clinicData['image']),
                if (_showStarters) _buildConversationStarters(),
                Expanded(child: _buildMessagesList()),
                _buildMessageInput(),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildMessagesHeader(String clinicName, String clinicImage) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: clinicImage.isNotEmpty
                ? Image.network(
                    clinicImage,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar(clinicName);
                    },
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 81, 115, 153),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        clinicName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              clinicName,
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
        if (_controller.conversationStarters.isEmpty) {
          return const Center(
            child: Text(
              'No conversation starters available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _controller.conversationStarters.length,
          itemBuilder: (context, index) {
            final starter = _controller.conversationStarters[index];
            return _buildStarterChip(starter);
          },
        );
      }),
    );
  }

  Widget _buildStarterChip(ConversationStarter starter) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          _controller.sendStarterMessage(starter);
          setState(() {
            _showStarters = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color.fromARGB(255, 81, 115, 153),
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
              Text(
                starter.triggerText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
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