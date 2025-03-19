class Staff {
  late String name;
  late String department;
  String? createdBy;
  late String image;
  late String createdAt;
  late String documentId;

  Staff.fromMap(Map<String, dynamic> map) {
    
    name = map["name"] ?? 'Unknown';
    department = map["department"] ?? 'Unknown'; 
    createdBy = map["createdBy"]?.toString() ?? 'Unknown';
    image = map["image"] ?? '';
    createdAt = map["createdAt"] ?? '';
    documentId = map["\$id"] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "department": department,
      "createdBy": createdBy ?? 'Unknown',
      "image": image,
      "createdAt": createdAt,
      "documentId" : documentId
    };
  }
}