import 'package:capstone_app/mobile/user/controllers/messaging_controller.dart';
import 'package:capstone_app/mobile/user/pages/messages_next_page.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> with WidgetsBindingObserver {
  final MessagingController _messagingController = Get.find<MessagingController>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final TextEditingController _searchController = TextEditingController();
  
  final Map<String, dynamic> _clinicCache = {}; // Cache clinic data
  final Map<String, dynamic> _userCache = {}; // Cache user data

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load conversations and set up real-time updates
    _messagingController.loadUserConversations();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh conversations when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _messagingController.loadUserConversations();
    }
  }

  void _setupRealtimeUpdates() {
    // Subscribe to conversation updates to get real-time message notifications
    _messagingController.subscribeToConversationUpdates();
    
    // Periodically refresh conversations (fallback for real-time)
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    // Refresh conversations every 10 seconds when on messages page
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _messagingController.loadUserConversations();
        _startPeriodicRefresh(); // Schedule next refresh
      }
    });
  }

  Future<Map<String, dynamic>> _getConversationData(Conversation conversation) async {
    String cacheKey = conversation.clinicId;
    
    if (_clinicCache.containsKey(cacheKey)) {
      return _clinicCache[cacheKey];
    }

    try {
      final clinicDoc = await _authRepository.getClinicById(conversation.clinicId);
      if (clinicDoc != null) {
        final clinic = Clinic.fromMap(clinicDoc.data);
        clinic.documentId = clinicDoc.$id;
        
        final conversationData = {
          'name': clinic.clinicName,
          'image': clinic.image,
          'isOnline': false, // Will be updated with real status
        };
        
        _clinicCache[cacheKey] = conversationData;
        return conversationData;
      }
    } catch (e) {
      print('Error loading clinic data: $e');
    }

    return {
      'name': 'Unknown Clinic',
      'image': '',
      'isOnline': false,
    };
  }

  Widget _buildConversationTile(Conversation conversation) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getConversationData(conversation),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'name': 'Loading...', 'image': '', 'isOnline': false};
        
        return InkWell(
          onTap: () async {
            // Navigate to conversation
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessagesNextPage(
                  conversation: conversation,
                  receiverId: conversation.clinicId,
                  receiverType: 'clinic',
                  receiverName: data['name'],
                  receiverImage: data['image'],
                ),
              ),
            );
            // Refresh conversations when returning
            _messagingController.loadUserConversations();
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
                // Profile Image with Online Status
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: data['image'].isNotEmpty
                          ? Image.network(
                              data['image'],
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 81, 115, 153),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      data['name'][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 81, 115, 153),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  data['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    // Online status indicator
                    if (data['isOnline'])
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
                
                // Conversation Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['name'],
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          // Header with refresh button
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
                // Add refresh button
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _messagingController.loadUserConversations();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 248, 253, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Search Bar
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
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search conversations...",
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (value) {
                          // Implement search functionality
                        },
                      ),
                    ),
                  ),
                  
                  // Conversations List
                  Expanded(
                    child: Obx(() {
                      if (_messagingController.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        );
                      }

                      if (_messagingController.conversations.isEmpty) {
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
                                "Start a conversation with a clinic\nto ask questions or book appointments",
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
                          await _messagingController.loadUserConversations();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _messagingController.conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _messagingController.conversations[index];
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
    );
  }
}