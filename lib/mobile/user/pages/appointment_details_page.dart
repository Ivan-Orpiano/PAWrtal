import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsPage extends StatelessWidget {
  final Appointment appointment;
  final Clinic? clinic;
  final Pet? pet;

  const AppointmentDetailsPage({
    super.key,
    required this.appointment,
    this.clinic,
    this.pet,
  });

  Color _getStatusColor() {
    switch (appointment.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (appointment.status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM dd, yyyy').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 81, 115, 153),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appointment Details',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              appointment.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Appointment details
                  _buildDetailRow(
                    Icons.local_hospital,
                    'Clinic',
                    clinic?.clinicName ?? 'Unknown Clinic',
                  ),
                  
                  _buildDetailRow(
                    Icons.location_on,
                    'Address',
                    clinic?.address ?? 'Address not available',
                  ),
                  
                  _buildDetailRow(
                    Icons.medical_services,
                    'Service',
                    appointment.service,
                  ),
                  
                  _buildDetailRow(
                    Icons.pets,
                    'Pet',
                    pet?.name ?? appointment.petId, // Fallback to stored petId
                  ),
                  
                  if (pet != null) ...[
                    _buildDetailRow(
                      Icons.category,
                      'Pet Type',
                      '${pet!.type} • ${pet!.breed}',
                    ),
                    if (pet!.color != null && pet!.color!.isNotEmpty)
                      _buildDetailRow(
                        Icons.palette,
                        'Pet Color',
                        pet!.color!,
                      ),
                  ],
                  
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    _formatDate(appointment.dateTime),
                  ),
                  
                  _buildDetailRow(
                    Icons.access_time,
                    'Time',
                    _formatTime(appointment.dateTime),
                  ),
                  
                  if (appointment.notes != null && appointment.notes!.isNotEmpty)
                    _buildDetailRow(
                      Icons.note,
                      'Notes',
                      appointment.notes!,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Additional info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Information',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Booked on: ${DateFormat('MMM dd, yyyy • h:mm a').format(appointment.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (appointment.updatedAt != appointment.createdAt)
                          Text(
                            'Last updated: ${DateFormat('MMM dd, yyyy • h:mm a').format(appointment.updatedAt)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  if (appointment.status.toLowerCase() == 'pending')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement cancel appointment
                              _showCancelDialog(context);
                            },
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.red[200]!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement contact clinic
                        _showContactOptions(context);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact Clinic'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement cancel appointment logic
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact ${clinic?.clinicName ?? 'Clinic'}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Color.fromARGB(255, 81, 115, 153)),
              title: const Text('Call'),
              subtitle: Text(clinic?.contact ?? 'Phone not available'),
              onTap: () {
                // TODO: Implement phone call
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color.fromARGB(255, 81, 115, 153)),
              title: const Text('Email'),
              subtitle: Text(clinic?.email ?? 'Email not available'),
              onTap: () {
                // TODO: Implement email
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}