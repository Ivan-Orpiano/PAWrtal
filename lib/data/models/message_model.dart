class Message {
  final String? documentId;
  final String conversationId;
  final String senderId;
  final String senderType; // 'user' or 'admin'
  final String receiverId;
  final String messageText;
  final String messageType; // 'text', 'image', 'starter'
  final String? attachmentUrl;
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;

  Message({
    this.documentId,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.receiverId,
    required this.messageText,
    this.messageType = 'text',
    this.attachmentUrl,
    DateTime? timestamp,
    this.isRead = false,
    this.isDeleted = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      documentId: map['\$id'],
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderType: map['senderType'] ?? 'user',
      receiverId: map['receiverId'] ?? '',
      messageText: map['messageText'] ?? '',
      messageType: map['messageType'] ?? 'text',
      attachmentUrl: map['attachmentUrl'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderType': senderType,
      'receiverId': receiverId,
      'messageText': messageText,
      'messageType': messageType,
      'attachmentUrl': attachmentUrl,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
  }

  Message copyWith({
    String? documentId,
    String? conversationId,
    String? senderId,
    String? senderType,
    String? receiverId,
    String? messageText,
    String? messageType,
    String? attachmentUrl,
    DateTime? timestamp,
    bool? isRead,
    bool? isDeleted,
  }) {
    return Message(
      documentId: documentId ?? this.documentId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      receiverId: receiverId ?? this.receiverId,
      messageText: messageText ?? this.messageText,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Helper methods
  bool get isSentByUser => senderType == 'user';
  bool get isSentByAdmin => senderType == 'admin';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
  bool get isStarterMessage => messageType == 'starter';
  
  String get timeFormatted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      // Today - show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Factory method for creating starter messages
  factory Message.createStarterMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String triggerText,
    required String responseText,
  }) {
    return Message(
      conversationId: conversationId,
      senderId: senderId,
      senderType: 'admin',
      receiverId: receiverId,
      messageText: responseText,
      messageType: 'starter',
    );
  }
}