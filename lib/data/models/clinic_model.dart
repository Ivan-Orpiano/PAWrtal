class Clinic {
  String? documentId;
  late String clinicName;
  late String address;
  late String contact;
  late String createdAt;
  late String adminId;
  late String createdBy;
  late String role;
  late String email;
  late String services;
  late String description;
  late String image;
  String? profilePictureId; // ADD THIS LINE

  Clinic({
    this.documentId,
    required this.clinicName,
    required this.address,
    required this.contact,
    required this.createdAt,
    required this.adminId,
    required this.createdBy,
    required this.role,
    required this.email,
    required this.services,
    required this.description,
    required this.image,
    this.profilePictureId, // ADD THIS LINE
  });

  Clinic.fromMap(Map<String, dynamic> map) {
    documentId = map['\$id'] ?? '';
    clinicName = map['clinicName'] ?? 'Unknown Clinic';
    address = map['address'] ?? 'Unknown Address';
    contact = map['contact'] ?? 'Unknown Contact';
    createdAt = map['createdAt'] ?? DateTime.now().toString();
    adminId = map['adminId'] ?? 'Unknown Admin';
    createdBy = map['createdBy'] ?? '';
    role = map['role'] ?? '';
    email = map['email'] ?? 'Unknown Email';
    services = map['services'] ?? 'No services available';
    description = map['description'] ?? '';
    image = map['image'] ?? '';
    profilePictureId = map['profilePictureId'] ?? ''; // ADD THIS LINE
  }

  Map<String, dynamic> toMap() {
    return {
      'clinicName': clinicName,
      'address': address,
      'contact': contact,
      'createdAt': createdAt,
      'adminId': adminId,
      'createdBy': createdBy,
      'role': role,
      'email': email,
      'services': services,
      'description': description,
      'image': image,
      'profilePictureId': profilePictureId ?? '', // ADD THIS LINE
    };
  }

  Clinic copyWith({
    String? documentId,
    String? clinicName,
    String? address,
    String? contact,
    String? createdAt,
    String? adminId,
    String? createdBy,
    String? role,
    String? email,
    String? services,
    String? description,
    String? image,
    String? profilePictureId, // ADD THIS LINE
  }) {
    return Clinic(
      documentId: documentId ?? this.documentId,
      clinicName: clinicName ?? this.clinicName,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
      adminId: adminId ?? this.adminId,
      createdBy: createdBy ?? this.createdBy,
      role: role ?? this.role,
      email: email ?? this.email,
      services: services ?? this.services,
      description: description ?? this.description,
      image: image ?? this.image,
      profilePictureId:
          profilePictureId ?? this.profilePictureId, // ADD THIS LINE
    );
  }
}
