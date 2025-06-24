class Pet {
  late String petId;
  late String userId;
  late String name;
  late String type;
  late String breed;
  String? color;
  String? image;
  String? notes;    
  double? weight;
  String? createdAt;
  String? documentId;

  Pet({
    required this.petId,
    required this.userId,
    required this.name,
    required this.type,
    required this.breed,
    this.color,
    this.image,
    this.notes,
    this.weight,
    this.createdAt,
    this.documentId,
  });

  Pet.fromMap(Map<String, dynamic> map) {
    petId = map['petId'] ?? '';
    userId = map['userId'] ?? '';
    name = map['name'] ?? '';
    type = map['type'] ?? '';
    breed = map['breed'] ?? '';
    color = map['color'] ?? '';
    image = map['imageUrl'];
    notes = map['notes'];
    weight = (map['weight'] as num?)?.toDouble() ?? 0.0;
    createdAt = map['\$createdAt'] ?? '';
    documentId = map['\$id'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'userId': userId,
      'name': name,
      'type': type,
      'breed': breed,
      'color': color,
      'image': image,
      'notes': notes,
      'weight': weight,
    };
  }
}
