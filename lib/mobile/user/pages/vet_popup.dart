import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_clinic_page_handler.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';

class VetPopup extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? clinicSettings;

  const VetPopup({
    super.key,
    required this.clinic,
    this.clinicSettings,
  });

  @override
  State<VetPopup> createState() => _VetPopupState();
}

class _VetPopupState extends State<VetPopup> {
  ClinicRatingStats? _ratingStats;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _loadRatingStats();
  }

  Future<void> _loadRatingStats() async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final stats = await authRepository
          .getClinicRatingStats(widget.clinic.documentId ?? '');
      if (mounted) {
        setState(() {
          _ratingStats = stats;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      print("Error loading rating stats for popup: $e");
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  Color getStatusColor() {
    final settings = widget.clinicSettings;
    if (settings == null) return Colors.grey;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isTodayClosedDate = settings.closedDates.contains(todayStr);

    if (isTodayClosedDate) {
      return Colors.red;
    } else if (!settings.isOpen) {
      return Colors.red;
    } else if (settings.isOpenNow()) {
      return Colors.green;
    } else if (settings.isOpenToday()) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String getStatusText() {
    final settings = widget.clinicSettings;
    if (settings == null) return "Unknown";

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isTodayClosedDate = settings.closedDates.contains(todayStr);

    if (isTodayClosedDate) {
      return "CLOSED TODAY";
    } else if (!settings.isOpen) {
      return "CLOSED";
    } else if (settings.isOpenNow()) {
      return "OPEN";
    } else if (settings.isOpenToday()) {
      return "CLOSED NOW";
    } else {
      return "CLOSED";
    }
  }

  String _getImageUrl() {
    if (widget.clinicSettings != null &&
        widget.clinicSettings!.dashboardPic.isNotEmpty) {
      return widget.clinicSettings!.dashboardPic;
    }
    if (widget.clinicSettings != null &&
        widget.clinicSettings!.gallery.isNotEmpty) {
      return widget.clinicSettings!.gallery.first;
    }
    return widget.clinic.image;
  }

  Widget _buildRatingDisplay() {
    if (_isLoadingRating) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final rating = _ratingStats?.averageRating ?? 0.0;
    final reviewCount = _ratingStats?.totalReviews ?? 0;

    if (reviewCount == 0) {
      return const Text(
        "No reviews",
        style: TextStyle(
          fontSize: 11,
          color: Colors.white70,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          " ($reviewCount)",
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final description = widget.clinic.description.isNotEmpty
        ? widget.clinic.description
        : "No description available.";

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: 250,
        child: Card(
          color: const Color.fromARGB(255, 39, 86, 139),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          elevation: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: SizedBox(
                  width: 250,
                  height: 150,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'lib/images/placeholder.png',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'lib/images/placeholder.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 75.0, sigmaY: 75.0),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(50, 71, 161, 196),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 250,
                      padding: const EdgeInsets.all(10),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.clinic.clinicName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatusColor(),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                getStatusText(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildRatingDisplay(),
                            const SizedBox(height: 5),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WebClinicPageHandlerUpdated(
                                      clinic: widget.clinic,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 201, 221, 238),
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              child: const Text("More Info"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
