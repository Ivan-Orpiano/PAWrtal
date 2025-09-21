import 'dart:convert';

class ClinicSettings {
  String? documentId;
  late String clinicId;
  late bool isOpen;
  late Map<String, Map<String, dynamic>> operatingHours;
  late List<String> gallery;
  late Map<String, double>? location; // {lat: double, lng: double}
  late List<String> services;
  late int appointmentDuration;
  late int maxAdvanceBooking;
  late String emergencyContact;
  late String specialInstructions;
  late bool autoAcceptAppointments;
  late String createdAt;
  late String updatedAt;

  ClinicSettings({
    this.documentId,
    required this.clinicId,
    this.isOpen = true,
    Map<String, Map<String, dynamic>>? operatingHours,
    List<String>? gallery,
    this.location,
    List<String>? services,
    this.appointmentDuration = 30,
    this.maxAdvanceBooking = 30,
    this.emergencyContact = '',
    this.specialInstructions = '',
    this.autoAcceptAppointments = false,
    String? createdAt,
    String? updatedAt,
  })  : operatingHours = operatingHours ?? _getDefaultOperatingHours(),
        gallery = gallery ?? [],
        services = services ?? [],
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  static Map<String, Map<String, dynamic>> _getDefaultOperatingHours() {
    // Updated return type
    return {
      'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'},
      'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '15:00'},
      'sunday': {'isOpen': false, 'openTime': '09:00', 'closeTime': '17:00'},
    };
  }

  factory ClinicSettings.fromMap(Map<String, dynamic> map) {
    return ClinicSettings(
      documentId: map['\$id'],
      clinicId: map['clinicId'] ?? '',
      isOpen: map['isOpen'] ?? true,
      operatingHours: _parseOperatingHours(map['operatingHours']),
      gallery: List<String>.from(map['gallery'] ?? []),
      location: _parseLocation(map['location']),
      services: List<String>.from(map['services'] ?? []),
      appointmentDuration: map['appointmentDuration'] ?? 30,
      maxAdvanceBooking: map['maxAdvanceBooking'] ?? 30,
      emergencyContact: map['emergencyContact'] ?? '',
      specialInstructions: map['specialInstructions'] ?? '',
      autoAcceptAppointments: map['autoAcceptAppointments'] ?? false,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  static Map<String, Map<String, dynamic>> _parseOperatingHours(dynamic hours) {
    // Updated return type
    if (hours == null) return _getDefaultOperatingHours();
    if (hours is String) {
      try {
        Map<String, dynamic> decoded = json.decode(hours);
        Map<String, Map<String, dynamic>> converted = {};
        decoded.forEach((key, value) {
          if (value is Map) {
            converted[key] = Map<String, dynamic>.from(value);
          }
        });
        return converted;
      } catch (e) {
        return _getDefaultOperatingHours();
      }
    }
    if (hours is Map<String, Map<String, dynamic>>) return hours;
    return _getDefaultOperatingHours();
  }

  static Map<String, double>? _parseLocation(dynamic location) {
    if (location == null) return null;
    if (location is String) {
      try {
        final parsed = json.decode(location);
        return {
          'lat': (parsed['lat'] as num).toDouble(),
          'lng': (parsed['lng'] as num).toDouble(),
        };
      } catch (e) {
        return null;
      }
    }
    if (location is Map<String, dynamic>) {
      return {
        'lat': (location['lat'] as num).toDouble(),
        'lng': (location['lng'] as num).toDouble(),
      };
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'clinicId': clinicId,
      'isOpen': isOpen,
      'operatingHours': json.encode(operatingHours),
      'gallery': gallery,
      'location': location != null ? json.encode(location) : null,
      'services': services,
      'appointmentDuration': appointmentDuration,
      'maxAdvanceBooking': maxAdvanceBooking,
      'emergencyContact': emergencyContact,
      'specialInstructions': specialInstructions,
      'autoAcceptAppointments': autoAcceptAppointments,
      'createdAt': createdAt,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Helper methods
  bool isOpenToday() {
    final today = DateTime.now().weekday;
    final dayName = _getDayName(today);
    return operatingHours[dayName]?['isOpen'] ?? false;
  }

  String getTodayHours() {
    final today = DateTime.now().weekday;
    final dayName = _getDayName(today);
    final dayHours = operatingHours[dayName];

    if (dayHours?['isOpen'] == true) {
      return '${dayHours?['openTime']} - ${dayHours?['closeTime']}';
    }
    return 'Closed';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  List<String> getAvailableTimeSlots(DateTime date) {
    final dayName = _getDayName(date.weekday);
    final dayHours = operatingHours[dayName];

    if (dayHours?['isOpen'] != true) return [];

    final openTime = dayHours?['openTime'] as String;
    final closeTime = dayHours?['closeTime'] as String;

    final slots = <String>[];
    final openHour = int.parse(openTime.split(':')[0]);
    final openMinute = int.parse(openTime.split(':')[1]);
    final closeHour = int.parse(closeTime.split(':')[0]);
    final closeMinute = int.parse(closeTime.split(':')[1]);

    var currentTime =
        DateTime(date.year, date.month, date.day, openHour, openMinute);
    final endTime =
        DateTime(date.year, date.month, date.day, closeHour, closeMinute);

    while (currentTime.isBefore(endTime)) {
      slots.add(
          '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}');
      currentTime = currentTime.add(Duration(minutes: appointmentDuration));
    }

    return slots;
  }

  ClinicSettings copyWith({
    String? documentId,
    String? clinicId,
    bool? isOpen,
    Map<String, Map<String, dynamic>>? operatingHours,
    List<String>? gallery,
    Map<String, double>? location,
    List<String>? services,
    int? appointmentDuration,
    int? maxAdvanceBooking,
    String? emergencyContact,
    String? specialInstructions,
    bool? autoAcceptAppointments,
    String? createdAt,
    String? updatedAt,
  }) {
    return ClinicSettings(
      documentId: documentId ?? this.documentId,
      clinicId: clinicId ?? this.clinicId,
      isOpen: isOpen ?? this.isOpen,
      operatingHours: operatingHours ?? this.operatingHours,
      gallery: gallery ?? this.gallery,
      location: location ?? this.location,
      services: services ?? this.services,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      maxAdvanceBooking: maxAdvanceBooking ?? this.maxAdvanceBooking,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      autoAcceptAppointments:
          autoAcceptAppointments ?? this.autoAcceptAppointments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
