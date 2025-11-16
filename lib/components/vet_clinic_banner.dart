import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VetClinicBanner extends StatelessWidget {
  final bool isMobile;

  const VetClinicBanner({
    super.key,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF517399),
            Color(0xFF6B8EB3),
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF517399).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(Routes.vetClinicRegistration); //Get.toNamed(Routes.login)
          },
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),

        // Main Text
        const Text(
          'Join PAWrtal Today!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          'Register your veterinary clinic and connect with pet owners in San Jose del Monte',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // CTA Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Register Now',
                style: TextStyle(
                  color: Color(0xFF517399),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF517399),
                size: 20,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Benefits
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBenefit(Icons.check_circle, 'Free'),
            const SizedBox(width: 16),
            _buildBenefit(Icons.check_circle, 'Easy Setup'),
            const SizedBox(width: 16),
            _buildBenefit(Icons.check_circle, 'Instant'),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Side - Icon & Benefits
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildDesktopBenefit(Icons.verified_rounded, 'Verified Platform'),
              const SizedBox(height: 12),
              _buildDesktopBenefit(Icons.people_rounded, 'Reach More Clients'),
              const SizedBox(height: 12),
              _buildDesktopBenefit(Icons.calendar_today_rounded, 'Manage Appointments'),
            ],
          ),
        ),

        const SizedBox(width: 40),

        // Right Side - Main Content
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grow Your Veterinary Practice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Join PAWrtal - the leading pet care platform in San Jose del Monte, Bulacan. Connect with pet owners, manage appointments, and grow your business.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),

              // CTA Button
              ElevatedButton(
                onPressed: () {
                  Get.toNamed('/vet-clinic-registration');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF517399),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Register Your Clinic',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded, size: 22),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '✓ No setup fees  •  ✓ Quick approval  •  ✓ Free forever',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefit(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBenefit(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}