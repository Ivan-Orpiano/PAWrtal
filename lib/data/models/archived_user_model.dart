import 'dart:convert';

/// Model for archived users
/// This tracks users who have been soft-deleted and scheduled for permanent deletion
class ArchivedUser {
  String? documentId;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? originalDocumentId;
  
  // Archive metadata
  final String archivedBy; // Admin/Developer who archived
  final DateTime archivedAt;
  final DateTime scheduledDeletionAt; // 30 days after archival
  final String archiveReason;
  final bool isPermanentlyDeleted;
  
  // Original user data (stored as JSON for recovery if needed)
  final Map<String, dynamic>? originalUserData;
  
  // Recovery tracking
  final bool isRecovered;
  final DateTime? recoveredAt;
  final String? recoveredBy;

  ArchivedUser({
    this.documentId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.originalDocumentId,
    required this.archivedBy,
    DateTime? archivedAt,
    DateTime? scheduledDeletionAt,
    this.archiveReason = 'No reason provided',
    this.isPermanentlyDeleted = false,
    this.originalUserData,
    this.isRecovered = false,
    this.recoveredAt,
    this.recoveredBy,
  })  : archivedAt = archivedAt ?? DateTime.now(),
        scheduledDeletionAt = scheduledDeletionAt ?? 
            DateTime.now().add(const Duration(days: 30));

  // Convert from Appwrite document
  factory ArchivedUser.fromMap(Map<String, dynamic> map) {
    // Parse originalUserData from JSON string
    Map<String, dynamic>? parsedUserData;
    if (map['originalUserData'] != null && map['originalUserData'] is String) {
      try {
        final jsonString = map['originalUserData'] as String;
        if (jsonString.isNotEmpty && jsonString != '{}') {
          parsedUserData = Map<String, dynamic>.from(
            jsonDecode(jsonString)
          );
        }
      } catch (e) {
        print('>>> Error parsing originalUserData JSON: $e');
        parsedUserData = null;
      }
    } else if (map['originalUserData'] is Map) {
      // Fallback: if it's already a Map (shouldn't happen, but handle it)
      parsedUserData = Map<String, dynamic>.from(map['originalUserData']);
    }

    return ArchivedUser(
      documentId: map['\$id'],
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      phone: map['phone'],
      originalDocumentId: map['originalDocumentId'],
      archivedBy: map['archivedBy'] ?? 'system',
      archivedAt: DateTime.parse(map['archivedAt']),
      scheduledDeletionAt: DateTime.parse(map['scheduledDeletionAt']),
      archiveReason: map['archiveReason'] ?? 'No reason provided',
      isPermanentlyDeleted: map['isPermanentlyDeleted'] ?? false,
      originalUserData: parsedUserData,
      isRecovered: map['isRecovered'] ?? false,
      recoveredAt: map['recoveredAt'] != null 
          ? DateTime.parse(map['recoveredAt']) 
          : null,
      recoveredBy: map['recoveredBy'],
    );
  }

  // Convert to Appwrite document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone ?? '',
      'originalDocumentId': originalDocumentId,
      'archivedBy': archivedBy,
      'archivedAt': archivedAt.toIso8601String(),
      'scheduledDeletionAt': scheduledDeletionAt.toIso8601String(),
      'archiveReason': archiveReason,
      'isPermanentlyDeleted': isPermanentlyDeleted,
      'originalUserData': originalUserData,
      'isRecovered': isRecovered,
      'recoveredAt': recoveredAt?.toIso8601String(),
      'recoveredBy': recoveredBy,
    };
  }

  // Helper getters
  int get daysUntilDeletion {
    final now = DateTime.now();
    final difference = scheduledDeletionAt.difference(now);
    return difference.inDays;
  }

  bool get isDeletionDue {
    return DateTime.now().isAfter(scheduledDeletionAt) || 
           DateTime.now().isAtSameMomentAs(scheduledDeletionAt);
  }

  String get statusText {
    if (isPermanentlyDeleted) return 'Permanently Deleted';
    if (isRecovered) return 'Recovered';
    if (isDeletionDue) return 'Pending Permanent Deletion';
    return 'Archived (${daysUntilDeletion} days left)';
  }

  ArchivedUser copyWith({
    String? documentId,
    String? userId,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? originalDocumentId,
    String? archivedBy,
    DateTime? archivedAt,
    DateTime? scheduledDeletionAt,
    String? archiveReason,
    bool? isPermanentlyDeleted,
    Map<String, dynamic>? originalUserData,
    bool? isRecovered,
    DateTime? recoveredAt,
    String? recoveredBy,
  }) {
    return ArchivedUser(
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      originalDocumentId: originalDocumentId ?? this.originalDocumentId,
      archivedBy: archivedBy ?? this.archivedBy,
      archivedAt: archivedAt ?? this.archivedAt,
      scheduledDeletionAt: scheduledDeletionAt ?? this.scheduledDeletionAt,
      archiveReason: archiveReason ?? this.archiveReason,
      isPermanentlyDeleted: isPermanentlyDeleted ?? this.isPermanentlyDeleted,
      originalUserData: originalUserData ?? this.originalUserData,
      isRecovered: isRecovered ?? this.isRecovered,
      recoveredAt: recoveredAt ?? this.recoveredAt,
      recoveredBy: recoveredBy ?? this.recoveredBy,
    );
  }
}