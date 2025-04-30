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
    };
  }
}
