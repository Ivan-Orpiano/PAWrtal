import 'package:capstone_app/web/user_web/desktop_web/components/clinic_page_components/web_services_updated.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class WebClinicServicesUpdated extends StatefulWidget {
  final Clinic clinic;

  const WebClinicServicesUpdated({super.key, required this.clinic});

  @override
  State<WebClinicServicesUpdated> createState() =>
      _WebClinicServicesUpdatedState();
}

class _WebClinicServicesUpdatedState extends State<WebClinicServicesUpdated> {
  List<String> _parseServices() {
    // First try to get services from clinic settings if available
    // For now, fall back to existing logic until settings are integrated
    if (widget.clinic.services.isNotEmpty) {
      return widget.clinic.services
          .split(RegExp(r'[,;|\n•]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Default services
    return [
      'General Checkup',
      'Vaccination',
      'Surgery',
      'Dental Care',
      'Emergency Care',
      'Laboratory Tests',
      'Pet Grooming',
      'Microchipping'
    ];
  }

  int _getColumnCount(double width) {
    if (width >= 800) {
      return 2; // Desktop: 2 columns
    } else if (width >= 600) {
      return 2; // Tablet: 2 columns
    } else {
      return 1; // Mobile: 1 column
    }
  }

  double _getChildAspectRatio(double width) {
    if (width >= 800) {
      return 10; // Desktop: keep original ratio
    } else if (width >= 600) {
      return 8; // Tablet: slightly shorter
    } else {
      return 6; // Mobile: even shorter for better fit
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _parseServices();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getColumnCount(width),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: _getChildAspectRatio(width),
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return WebServicesUpdated(serviceName: services[index]);
          },
        );
      },
    );
  }
}
