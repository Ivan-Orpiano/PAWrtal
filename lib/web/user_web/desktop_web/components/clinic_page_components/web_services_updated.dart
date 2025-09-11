import 'package:flutter/material.dart';

class WebServicesUpdated extends StatelessWidget {
  final String serviceName;
  
  const WebServicesUpdated({super.key, required this.serviceName});

  IconData _getServiceIcon(String service) {
    String serviceLower = service.toLowerCase();
    
    if (serviceLower.contains('vaccination') || serviceLower.contains('vaccine') || serviceLower.contains('immunization')) {
      return Icons.vaccines_outlined;
    } else if (serviceLower.contains('surgery') || serviceLower.contains('operation') || serviceLower.contains('surgical')) {
      return Icons.local_hospital_outlined;
    } else if (serviceLower.contains('checkup') || serviceLower.contains('examination') || serviceLower.contains('consultation')) {
      return Icons.health_and_safety_outlined;
    } else if (serviceLower.contains('grooming') || serviceLower.contains('bath') || serviceLower.contains('cleaning')) {
      return Icons.pets_outlined;
    } else if (serviceLower.contains('dental') || serviceLower.contains('teeth') || serviceLower.contains('oral')) {
      return Icons.medication_liquid_outlined;
    } else if (serviceLower.contains('emergency') || serviceLower.contains('urgent') || serviceLower.contains('critical')) {
      return Icons.emergency_outlined;
    } else if (serviceLower.contains('laboratory') || serviceLower.contains('lab') || serviceLower.contains('test') || serviceLower.contains('diagnostic')) {
      return Icons.science_outlined;
    } else if (serviceLower.contains('microchip') || serviceLower.contains('chip') || serviceLower.contains('id')) {
      return Icons.memory_outlined;
    } else if (serviceLower.contains('boarding') || serviceLower.contains('hotel') || serviceLower.contains('stay')) {
      return Icons.hotel_outlined;
    } else if (serviceLower.contains('nutrition') || serviceLower.contains('diet') || serviceLower.contains('feeding')) {
      return Icons.restaurant_outlined;
    } else if (serviceLower.contains('x-ray') || serviceLower.contains('imaging') || serviceLower.contains('scan')) {
      return Icons.camera_outlined;
    } else if (serviceLower.contains('spay') || serviceLower.contains('neuter') || serviceLower.contains('sterilization')) {
      return Icons.healing_outlined;
    } else {
      return Icons.medical_services_outlined;
    }
  }

  Color _getServiceColor(String service) {
    String serviceLower = service.toLowerCase();
    
    if (serviceLower.contains('emergency') || serviceLower.contains('urgent')) {
      return Colors.red.shade600;
    } else if (serviceLower.contains('surgery') || serviceLower.contains('operation')) {
      return Colors.orange.shade600;
    } else if (serviceLower.contains('vaccination') || serviceLower.contains('vaccine')) {
      return Colors.green.shade600;
    } else {
      return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust padding and font size based on available width
        double horizontalPadding = constraints.maxWidth > 300 ? 12 : 8;
        double verticalPadding = constraints.maxWidth > 300 ? 8 : 6;
        double iconSize = constraints.maxWidth > 300 ? 22 : 18;
        double fontSize = constraints.maxWidth > 300 ? 16 : 14;
        double spacing = constraints.maxWidth > 300 ? 12 : 8;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, 
            vertical: verticalPadding
          ),
          decoration: BoxDecoration(
            color: _getServiceColor(serviceName).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getServiceColor(serviceName).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getServiceIcon(serviceName),
                size: iconSize,
                color: _getServiceColor(serviceName),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  serviceName,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}