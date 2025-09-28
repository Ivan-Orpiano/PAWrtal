class Conversation {
  final String? documentId;
  final String userId;
  final String clinicId;
  final String? lastMessageId;
  final String? lastMessageText;
  final DateTime? lastMessageTime;
  final int unreadCount; // Keep for backward compatibility
  final int userUnreadCount; // New field for user's unread count
  final int clinicUnreadCount; // New field for clinic's unread count
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    this.documentId,
    required this.userId,
    required this.clinicId,
    this.lastMessageId,
    this.lastMessageText,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.userUnreadCount = 0,
    this.clinicUnreadCount = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      documentId: map['\$id'],
      userId: map['userId'] ?? '',
      clinicId: map['clinicId'] ?? '',
      lastMessageId: map['lastMessageId'],
      lastMessageText: map['lastMessageText'],
      lastMessageTime: map['lastMessageTime'] != null 
          ? DateTime.parse(map['lastMessageTime']) 
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      userUnreadCount: map['userUnreadCount'] ?? 0,
      clinicUnreadCount: map['clinicUnreadCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clinicId': clinicId,
      'lastMessageId': lastMessageId,
      'lastMessageText': lastMessageText,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'userUnreadCount': userUnreadCount,
      'clinicUnreadCount': clinicUnreadCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? documentId,
    String? userId,
    String? clinicId,
    String? lastMessageId,
    String? lastMessageText,
    DateTime? lastMessageTime,
    int? unreadCount,
    int? userUnreadCount,
    int? clinicUnreadCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      userUnreadCount: userUnreadCount ?? this.userUnreadCount,
      clinicUnreadCount: clinicUnreadCount ?? this.clinicUnreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get hasMessages => lastMessageId != null;
  
  String get conversationPreview {
    if (lastMessageText != null && lastMessageText!.isNotEmpty) {
      return lastMessageText!.length > 50 
          ? '${lastMessageText!.substring(0, 50)}...'
          : lastMessageText!;
    }
    return 'No messages yet';
  }

  String get timeAgo {
    if (lastMessageTime == null) return '';
    
    final difference = DateTime.now().difference(lastMessageTime!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'today';
    }
  }

  // Get unread count for specific user type
  int getUnreadCountForUser(String currentUserId, String currentUserType) {
    if (currentUserType == 'admin' || currentUserId == clinicId) {
      return clinicUnreadCount;
    } else {
      return userUnreadCount;
    }
  }

  // Check if conversation has unread messages for specific user
  bool hasUnreadMessagesForUser(String currentUserId, String currentUserType) {
    return getUnreadCountForUser(currentUserId, currentUserType) > 0;
  }
}