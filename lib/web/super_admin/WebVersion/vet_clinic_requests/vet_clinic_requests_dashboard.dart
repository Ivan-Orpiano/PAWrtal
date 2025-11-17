import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_requests/vet_clinic_requests_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_requests/vet_clinic_request_detail_page.dart';
import 'package:capstone_app/data/models/vet_clinic_registration_request_model.dart';
import 'package:intl/intl.dart';

class VetClinicRequestsDashboard extends StatelessWidget {
  const VetClinicRequestsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VetClinicRequestsController());
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF517399)),
          onPressed: () => Get.back(),
        ),
        title: Image.asset(
          'lib/images/PAWrtal_logo.png',
          height: 35,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(controller, isMobile),
          _buildFilters(controller, isMobile),
          _buildSearchBar(controller, isMobile),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingState();
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return _buildErrorState(controller);
              }

              final requests = controller.filteredRequests;

              if (requests.isEmpty) {
                return _buildEmptyState(controller);
              }

              return RefreshIndicator(
                onRefresh: controller.refreshRequests,
                color: const Color(0xFF517399),
                child: ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(
                      context,
                      requests[index],
                      isMobile,
                      controller,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(VetClinicRequestsController controller, bool isMobile) {
    return Obx(() {
      final stats = controller.requestStats;
      return Container(
        margin: EdgeInsets.all(isMobile ? 16 : 24),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF517399), Color(0xFF6B8EB3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF517399).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage clinic registration applications',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isMobile)
              _buildMobileStats(stats)
            else
              _buildDesktopStats(stats),
          ],
        ),
      );
    });
  }

  Widget _buildMobileStats(Map<String, int> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total', stats['total']!, Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Pending', stats['pending']!, Colors.orange)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCard('Approved', stats['approved']!, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Rejected', stats['rejected']!, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total', stats['total']!, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Pending', stats['pending']!, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Approved', stats['approved']!, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Rejected', stats['rejected']!, Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(VetClinicRequestsController controller, bool isMobile) {
    return Obx(() => Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(controller, 'all', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip(controller, 'pending', 'Pending'),
            const SizedBox(width: 8),
            _buildFilterChip(controller, 'approved', 'Approved'),
            const SizedBox(width: 8),
            _buildFilterChip(controller, 'rejected', 'Rejected'),
          ],
        ),
      ),
    ));
  }

  Widget _buildFilterChip(
    VetClinicRequestsController controller,
    String value,
    String label,
  ) {
    final isSelected = controller.selectedFilter.value == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => controller.updateFilter(value),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF517399),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF517399),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF517399) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildSearchBar(VetClinicRequestsController controller, bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search by clinic name, email, or location...',
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF517399)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    VetClinicRegistrationRequest request,
    bool isMobile,
    VetClinicRequestsController controller,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await Get.to(() => VetClinicRequestDetailPage(request: request));
        if (result == true) {
          controller.refreshRequests();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.clinicName,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF517399),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.fullAddress,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: request.statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(request.statusIcon, size: 16, color: request.statusColor),
                      const SizedBox(width: 4),
                      Text(
                        request.status.toUpperCase(),
                        style: TextStyle(
                          color: request.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.email_rounded, request.email, isMobile),
                _buildInfoChip(Icons.phone_rounded, request.contactNumber, isMobile),
                _buildInfoChip(
                  Icons.calendar_today_rounded,
                  DateFormat('MMM dd, yyyy').format(request.submittedAt),
                  isMobile,
                ),
                _buildInfoChip(
                  Icons.attach_file_rounded,
                  '${request.documentFileIds.length} documents',
                  isMobile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 14 : 16, color: const Color(0xFF517399)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF517399),
      ),
    );
  }

  Widget _buildErrorState(VetClinicRequestsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Requests',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: controller.refreshRequests,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF517399),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(VetClinicRequestsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF517399).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 64,
                color: Color(0xFF517399),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.selectedFilter.value == 'all'
                  ? 'No Requests Yet'
                  : 'No ${controller.selectedFilter.value} requests',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF517399),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.searchQuery.value.isEmpty
                  ? 'Registration requests will appear here'
                  : 'No requests match your search',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}