class ConversationStarter {
  final String? documentId;
  final String clinicId;
  final String triggerText;
  final String responseText;
  final String category; // 'appointment', 'general', 'services', 'emergency'
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationStarter({
    this.documentId,
    required this.clinicId,
    required this.triggerText,
    required this.responseText,
    this.category = 'general',
    this.isActive = true,
    this.displayOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ConversationStarter.fromMap(Map<String, dynamic> map) {
    return ConversationStarter(
      documentId: map['\$id'],
      clinicId: map['clinicId'] ?? '',
      triggerText: map['triggerText'] ?? '',
      responseText: map['responseText'] ?? '',
      category: map['category'] ?? 'general',
      isActive: map['isActive'] ?? true,
      displayOrder: map['displayOrder'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    // Don't include starterId in the data we send - AppWrite will auto-generate the document ID
    return {
      'clinicId': clinicId,
      'triggerText': triggerText,
      'responseText': responseText,
      'category': category,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ConversationStarter copyWith({
    String? documentId,
    String? clinicId,
    String? triggerText,
    String? responseText,
    String? category,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationStarter(
      documentId: documentId ?? this.documentId,
      clinicId: clinicId ?? this.clinicId,
      triggerText: triggerText ?? this.triggerText,
      responseText: responseText ?? this.responseText,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get category display name
  String get categoryDisplayName {
    switch (category) {
      case 'appointment':
        return 'Appointment';
      case 'services':
        return 'Services';
      case 'emergency':
        return 'Emergency';
      case 'general':
      default:
        return 'General';
    }
  }

  // Default conversation starters factory methods
  static List<ConversationStarter> getDefaultStarters(String clinicId) {
    return [
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "Book an appointment",
        responseText: "I'd be happy to help you book an appointment! What type of service do you need for your pet?",
        category: 'appointment',
        displayOrder: 1,
      ),
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "What services do you offer?",
        responseText: "We offer comprehensive veterinary services including general checkups, vaccinations, surgery, dental care, and emergency services. What specific service are you interested in?",
        category: 'services',
        displayOrder: 2,
      ),
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "Emergency help",
        responseText: "This is an emergency situation. Please call our emergency line immediately or bring your pet to our clinic right away. For immediate assistance, contact us at our emergency number.",
        category: 'emergency',
        displayOrder: 3,
      ),
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "What are your operating hours?",
        responseText: "Our regular operating hours vary by day. You can check our current hours in the clinic information. For emergencies, we have extended support available.",
        category: 'general',
        displayOrder: 4,
      ),
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "How much does it cost?",
        responseText: "Our pricing depends on the specific service your pet needs. I'd be happy to provide an estimate once I know more about what you're looking for. What service are you interested in?",
        category: 'general',
        displayOrder: 5,
      ),
      ConversationStarter(
        clinicId: clinicId,
        triggerText: "My pet is sick",
        responseText: "I'm sorry to hear your pet isn't feeling well. Can you describe the symptoms? If this is urgent, please don't hesitate to bring them in immediately or call our emergency line.",
        category: 'general',
        displayOrder: 6,
      ),
    ];
  }
}