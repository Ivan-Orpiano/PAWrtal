enum NotificationType {
  appointmentBooked,
  appointmentAccepted,
  appointmentDeclined,
  appointmentCancelled,
  appointmentCompleted,
  appointmentReminder,
  newMessage,
  paymentReceived,
  systemAlert,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationModel {
  final String? documentId;
  final String recipientId; // clinicId for admin notifications
  final String recipientType; // 'admin', 'staff', 'user'
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Additional context data
  final String? actionUrl; // Deep link or navigation route
  final String? imageUrl;
  final bool isRead;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? archivedAt;
  
  // Related entity IDs for quick filtering
  final String? appointmentId;
  final String? conversationId;
  final String? messageId;
  final String? userId; // The user who triggered this notification
  final String? petId;

  NotificationModel({
    this.documentId,
    required this.recipientId,
    required this.recipientType,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.title,
    required this.message,
    this.data,
    this.actionUrl,
    this.imageUrl,
    this.isRead = false,
    this.isArchived = false,
    DateTime? createdAt,
    this.readAt,
    this.archivedAt,
    this.appointmentId,
    this.conversationId,
    this.messageId,
    this.userId,
    this.petId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      documentId: map['\$id'],
      recipientId: map['recipientId'] ?? '',
      recipientType: map['recipientType'] ?? 'admin',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: map['data'],
      actionUrl: map['actionUrl'],
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
      isArchived: map['isArchived'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      archivedAt: map['archivedAt'] != null ? DateTime.parse(map['archivedAt']) : null,
      appointmentId: map['appointmentId'],
      conversationId: map['conversationId'],
      messageId: map['messageId'],
      userId: map['userId'],
      petId: map['petId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'recipientType': recipientType,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'title': title,
      'message': message,
      'data': data,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'appointmentId': appointmentId,
      'conversationId': conversationId,
      'messageId': messageId,
      'userId': userId,
      'petId': petId,
    };
  }

  NotificationModel copyWith({
    String? documentId,
    String? recipientId,
    String? recipientType,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
    bool? isRead,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? archivedAt,
    String? appointmentId,
    String? conversationId,
    String? messageId,
    String? userId,
    String? petId,
  }) {
    return NotificationModel(
      documentId: documentId ?? this.documentId,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      archivedAt: archivedAt ?? this.archivedAt,
      appointmentId: appointmentId ?? this.appointmentId,
      conversationId: conversationId ?? this.conversationId,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
    );
  }

  // Helper methods
  bool get isUnread => !isRead;
  bool get isUrgent => priority == NotificationPriority.urgent;
  bool get isHigh => priority == NotificationPriority.high;
  
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Factory methods for common notification types
  factory NotificationModel.appointmentBooked({
    required String clinicId,
    required String appointmentId,
    required String userId,
    required String petName,
    required String ownerName,
    required String service,
    required DateTime appointmentTime,
  }) {
    return NotificationModel(
      recipientId: clinicId,
      recipientType: 'admin',
      type: NotificationType.appointmentBooked,
      priority: NotificationPriority.high,
      title: 'New Appointment Booked',
      message: '$ownerName booked an appointment for $petName',
      actionUrl: '/appointments/pending',
      appointmentId: appointmentId,
      userId: userId,
      data: {
        'service': service,
        'appointmentTime': appointmentTime.toIso8601String(),
        'petName': petName,
        'ownerName': ownerName,
      },
    );
  }

  factory NotificationModel.newMessage({
    required String clinicId,
    required String conversationId,
    required String messageId,
    required String userId,
    required String senderName,
    required String messagePreview,
  }) {
    return NotificationModel(
      recipientId: clinicId,
      recipientType: 'admin',
      type: NotificationType.newMessage,
      priority: NotificationPriority.normal,
      title: 'New Message',
      message: '$senderName: $messagePreview',
      actionUrl: '/messages?conversation=$conversationId',
      conversationId: conversationId,
      messageId: messageId,
      userId: userId,
      data: {
        'senderName': senderName,
        'messagePreview': messagePreview,
      },
    );
  }

  factory NotificationModel.appointmentStatusUpdate({
    required String userId,
    required String appointmentId,
    required String petName,
    required String clinicName,
    required String status,
    String? notes,
  }) {
    String title;
    String message;
    NotificationPriority priority;

    switch (status) {
      case 'accepted':
        title = 'Appointment Accepted';
        message = 'Your appointment for $petName has been accepted by $clinicName';
        priority = NotificationPriority.high;
        break;
      case 'declined':
        title = 'Appointment Declined';
        message = 'Your appointment for $petName has been declined by $clinicName';
        priority = NotificationPriority.high;
        break;
      case 'completed':
        title = 'Appointment Completed';
        message = 'Your appointment for $petName has been completed';
        priority = NotificationPriority.normal;
        break;
      default:
        title = 'Appointment Updated';
        message = 'Your appointment for $petName has been updated';
        priority = NotificationPriority.normal;
    }

    return NotificationModel(
      recipientId: userId,
      recipientType: 'user',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().contains(status),
        orElse: () => NotificationType.systemAlert,
      ),
      priority: priority,
      title: title,
      message: message,
      actionUrl: '/appointments',
      appointmentId: appointmentId,
      data: {
        'status': status,
        'clinicName': clinicName,
        'petName': petName,
        'notes': notes,
      },
    );
  }
}