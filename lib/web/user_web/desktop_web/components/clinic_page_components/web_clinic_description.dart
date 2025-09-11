import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class WebClinicDescriptionUpdated extends StatefulWidget {
  final Clinic clinic;
  
  const WebClinicDescriptionUpdated({super.key, required this.clinic});

  @override
  State<WebClinicDescriptionUpdated> createState() => _WebClinicDescriptionUpdatedState();
}

class _WebClinicDescriptionUpdatedState extends State<WebClinicDescriptionUpdated> {
  bool _showFullDescription = false;

  String get _truncatedDescription {
    const int maxLength = 300; // Show first 300 characters
    if (widget.clinic.description.length <= maxLength) {
      return widget.clinic.description;
    }
    return '${widget.clinic.description.substring(0, maxLength)}...';
  }

  bool get _hasLongDescription {
    return widget.clinic.description.length > 300;
  }

  @override
  Widget build(BuildContext context) {
    String description = widget.clinic.description.isNotEmpty 
        ? widget.clinic.description 
        : "This veterinary clinic provides comprehensive pet care services. "
          "We are committed to ensuring the health and well-being of your pets "
          "through professional veterinary care and compassionate service.";

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'About this veterinary clinic',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22
                ),
              ),
            ],
          ),
        ),
        
        // Contact Information Section
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.location_on_outlined, 'Address', widget.clinic.address),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone_outlined, 'Contact', widget.clinic.contact),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.email_outlined, 'Email', widget.clinic.email),
            ],
          ),
        ),

        // Description Section
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _showFullDescription || !_hasLongDescription 
                ? description 
                : _truncatedDescription,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        
        if (_hasLongDescription)
          InkWell(
            onTap: () {
              setState(() {
                _showFullDescription = !_showFullDescription;
              });
            },
            child: Row(
              children: [
                Text(
                  _showFullDescription ? "Show less" : "Show more",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline
                  ),
                ),
                Icon(
                  _showFullDescription 
                      ? Icons.keyboard_arrow_up_rounded 
                      : Icons.keyboard_arrow_right_rounded,
                  size: 24,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'Not provided',
                style: TextStyle(
                  fontSize: 15,
                  color: value.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}