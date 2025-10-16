import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/super_admin/mobile/super_admin_mobile_home_page.dart';
import 'package:capstone_app/web/super_admin/tablet/super_admin_tablet_home_page.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';


class VeterinaryReport extends StatefulWidget {
  const VeterinaryReport({super.key});
  @override
  State<VeterinaryReport> createState() => _VeterinaryReportState();
}

class _VeterinaryReportState extends State<VeterinaryReport> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedReason = 'All';
  List<DeletionRequestItem> _allRequests = [];
  List<DeletionRequestItem> _filteredRequests = [];
  final bool _isLoading = false;
  final int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isVetReportsHovered = false;
  bool _isSystemReportsHovered = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
    _filteredRequests = _allRequests;
  }

  void _loadSampleData() {
    _allRequests = [
      DeletionRequestItem(
        id: '001',
        vetClinicName: 'Paws & Claws Veterinary Clinic',
        requestedBy: 'Dr. Sarah Martinez',
        reason: 'Business Closure',
        description:
            'The veterinary clinic is permanently closing due to retirement. All patient records have been transferred to partner clinics.',
        status: 'Pending',
        dateRequested: DateTime.now().subtract(const Duration(hours: 2)),
        businessLicense: 'VET-2023-001',
        contactEmail: 'sarah.martinez@pawsclaws.com',
        contactPhone: '+1 (555) 123-4567',
      ),
      DeletionRequestItem(
        id: '002',
        vetClinicName: 'City Pet Hospital',
        requestedBy: 'Admin Emily Johnson',
        reason: 'Policy Violation',
        description:
            'Multiple reports of unprofessional conduct and violation of platform terms of service.',
        status: 'Under Review',
        dateRequested: DateTime.now().subtract(const Duration(days: 1)),
        businessLicense: 'VET-2023-002',
        contactEmail: 'admin@citypethospital.com',
        contactPhone: '+1 (555) 234-5678',
      ),
      DeletionRequestItem(
        id: '003',
        vetClinicName: 'Animal Care Center',
        requestedBy: 'Dr. Michael Brown',
        reason: 'Relocation',
        description:
            'Moving to a different service area outside our platform coverage. Will continue operations under new management.',
        status: 'Approved',
        dateRequested: DateTime.now().subtract(const Duration(days: 2)),
        businessLicense: 'VET-2023-003',
        contactEmail: 'm.brown@animalcare.com',
        contactPhone: '+1 (555) 345-6789',
        dateProcessed: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      DeletionRequestItem(
        id: '004',
        vetClinicName: 'Happy Tails Veterinary',
        requestedBy: 'Dr. Sarah Wilson',
        reason: 'Business Closure',
        description:
            'Economic difficulties due to recent market changes. Unable to maintain operations.',
        status: 'Denied',
        dateRequested: DateTime.now().subtract(const Duration(days: 3)),
        businessLicense: 'VET-2023-004',
        contactEmail: 'info@happytails.vet',
        contactPhone: '+1 (555) 456-7890',
        dateProcessed: DateTime.now().subtract(const Duration(days: 1)),
        denialReason: 'Insufficient documentation provided',
      ),
      DeletionRequestItem(
        id: '005',
        vetClinicName: 'Pet Wellness Center',
        requestedBy: 'Admin David Lee',
        reason: 'Data Privacy Request',
        description:
            'GDPR compliance request for complete data removal from all systems.',
        status: 'Pending',
        dateRequested: DateTime.now().subtract(const Duration(days: 4)),
        businessLicense: 'VET-2023-005',
        contactEmail: 'privacy@petwellness.com',
        contactPhone: '+1 (555) 567-8901',
      ),
    ];
    _filteredRequests = _allRequests;
  }

  void _filterRequests() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        bool matchesSearch = _searchController.text.isEmpty ||
            request.vetClinicName
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            request.requestedBy
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        bool matchesStatus =
            _selectedStatus == 'All' || request.status == _selectedStatus;

        bool matchesReason =
            _selectedReason == 'All' || request.reason == _selectedReason;

        return matchesSearch && matchesStatus && matchesReason;
      }).toList();
    });
  }

  void _showRequestDetails(DeletionRequestItem request) {
    showDialog(
      context: context,
      builder: (context) => RequestDetailDialog(request: request),
    );
  }

  void _handleDeletionRequest(DeletionRequestItem request) {
    showDialog(
      context: context,
      builder: (context) => DeleteRequestActionDialog(
        request: request,
        onApprove: () => _approveDeletion(request),
        onDeny: (reason) => _denyDeletion(request, reason),
      ),
    );
  }

  void _approveDeletion(DeletionRequestItem request) {
    setState(() {
      request.status = 'Approved';
      request.dateProcessed = DateTime.now();
      _filterRequests();
    });
    _showSnackBar('Deletion request approved successfully', Colors.green);
  }

  void _denyDeletion(DeletionRequestItem request, String reason) {
    setState(() {
      request.status = 'Denied';
      request.dateProcessed = DateTime.now();
      request.denialReason = reason;
      _filterRequests();
    });
    _showSnackBar('Deletion request denied', Colors.orange);
  }

  void _deleteRequest(DeletionRequestItem request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color(0xFFE74C3C)),
            SizedBox(width: 8),
            Text('Confirm Deletion'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the ${request.status.toLowerCase()} request from "${request.vetClinicName}"?\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF95A5A6),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allRequests.removeWhere((item) => item.id == request.id);
                _filterRequests();
              });
              Navigator.pop(context);
              _showSnackBar(
                'Request deleted successfully',
                const Color(0xFFE74C3C),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  Widget _buildDashboardStats() {
    int totalRequests = _allRequests.length;
    int pendingRequests =
        _allRequests.where((r) => r.status == 'Pending').length;
    int approvedRequests =
        _allRequests.where((r) => r.status == 'Approved').length;
    int underReviewRequests =
        _allRequests.where((r) => r.status == 'Under Review').length;

    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Total Requests', totalRequests.toString(),
              Icons.delete_forever, const Color(0xFF4A90E2)),
          const SizedBox(width: 12),
          _buildStatCard('Pending', pendingRequests.toString(), Icons.pending,
              const Color(0xFFF39C12)),
          const SizedBox(width: 12),
          _buildStatCard('Approved', approvedRequests.toString(),
              Icons.check_circle, const Color(0xFF2ECC71)),
          const SizedBox(width: 12),
          _buildStatCard('Under Review', underReviewRequests.toString(),
              Icons.reviews, const Color(0xFF9B59B6)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Focus(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterRequests(),
              decoration: InputDecoration(
                hintText: 'Search vet clinics or requesters...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterRequests();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color.fromRGBO(81, 115, 153, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color.fromRGBO(81, 115, 153, 1), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatusDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildReasonDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: const TextStyle(color: Colors.black),
        floatingLabelStyle: const TextStyle(color: Color(0xFF517399)),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF517399)),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['All', 'Pending', 'Approved', 'Denied', 'Under Review']
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
          _filterRequests();
        });
      },
    );
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
      value: _selectedReason,
      decoration: InputDecoration(
        labelText: 'Reason',
        labelStyle: const TextStyle(color: Colors.black),
        floatingLabelStyle: const TextStyle(color: Color(0xFF517399)),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF517399)),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        'All',
        'Business Closure',
        'Policy Violation',
        'Relocation',
        'Data Privacy Request',
        'Other'
      ]
          .map((reason) => DropdownMenuItem(value: reason, child: Text(reason)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedReason = value!;
          _filterRequests();
        });
      },
    );
  }

  Widget _buildRequestList() {
    if (_filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No deletion requests found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        final request = _filteredRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(DeletionRequestItem request) {
    return Card(
      color: const Color.fromRGBO(242, 250, 252, 1),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRequestDetails(request),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.business, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Request ID: ${request.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(request.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.vetClinicName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    request.requestedBy,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${request.dateRequested.day}/${request.dateRequested.month}/${request.dateRequested.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFF39C12)),
                  const SizedBox(width: 4),
                  Text(
                    request.reason,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Business License and Contact Info
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF517399), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business,
                            size: 16, color: Color(0xFF517399)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'License: ${request.businessLicense}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email,
                            size: 16, color: Color(0xFF517399)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.contactEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 16, color: Color(0xFF517399)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.contactPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Show denial reason if denied
              if (request.status == 'Denied' &&
                  request.denialReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 16, color: Colors.red[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Denial Reason',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.denialReason!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (request.status == 'Pending' ||
                          request.status == 'Under Review')
                        ElevatedButton.icon(
                          onPressed: () => _handleDeletionRequest(request),
                          icon: const Icon(
                            Icons.gavel,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text('Process'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 81, 115, 153),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      if (request.status == 'Approved' ||
                          request.status == 'Denied') ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _deleteRequest(request),
                          icon: const Icon(
                            Icons.delete_forever,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = const Color(0xFF2ECC71);
        break;
      case 'Pending':
        color = const Color(0xFFF39C12);
        break;
      case 'Under Review':
        color = const Color(0xFF9B59B6);
        break;
      case 'Denied':
        color = const Color(0xFFE74C3C);
        break;
      default:
        color = const Color(0xFF95A5A6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded,
              color: Color.fromRGBO(81, 115, 153, 1)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Menu',
        ),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.delete_forever,
                color: Color.fromARGB(255, 81, 115, 153)),
            SizedBox(width: 8),
            Text(
              'Vet Reports',
              style: TextStyle(
                  color: Color.fromARGB(255, 81, 115, 153),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        elevation: 0,
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: Row(
        children: [
        
          Expanded(
            child: Column(
              children: [
                _buildDashboardStats(),
                _buildSearchAndFilters(),
                Expanded(child: _buildRequestList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
    child: Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(81, 115, 153, 1),
                Color.fromRGBO(81, 115, 153, 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Developer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Management Panel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildDrawerItem(
                context,
                icon: Icons.local_hospital_rounded,
                title: 'Veterinary Clinics',
                subtitle: 'Manage vet clinics',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuperAdminVetClinicDashboard(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.people_rounded,
                title: 'Pet Owner Management',
                subtitle: 'Manage user accounts',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuperAdminUserManagementScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.feedback_rounded,
                title: 'System Reports',
                subtitle: 'User feedback & reports',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminFeedbackManagement(),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(),
              ),
            ],
          ),
        ),

        // Logout Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: _isLoggingOut
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(81, 115, 153, 0.7),
                          Color.fromRGBO(81, 115, 153, 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Logging Out...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : InkWell(
                    onTap: () async {
                      setState(() => _isLoggingOut = true);
                      try {
                        await LogoutHelper.logout();
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoggingOut = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logout failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(220, 53, 69, 1),
                            Color.fromRGBO(200, 35, 51, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromRGBO(81, 115, 153, 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(81, 115, 153, 0.2),
                    Color.fromRGBO(81, 115, 153, 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color.fromRGBO(81, 115, 153, 1),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(81, 115, 153, 1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color.fromRGBO(81, 115, 153, 0.5),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class DeletionRequestItem {
  final String id;
  final String vetClinicName;
  final String requestedBy;
  final String reason;
  final String description;
  String status;
  final DateTime dateRequested;
  final String businessLicense;
  final String contactEmail;
  final String contactPhone;
  DateTime? dateProcessed;
  String? denialReason;

  DeletionRequestItem({
    required this.id,
    required this.vetClinicName,
    required this.requestedBy,
    required this.reason,
    required this.description,
    required this.status,
    required this.dateRequested,
    required this.businessLicense,
    required this.contactEmail,
    required this.contactPhone,
    this.dateProcessed,
    this.denialReason,
  });
}

class RequestDetailDialog extends StatelessWidget {
  final DeletionRequestItem request;

  const RequestDetailDialog({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.delete_forever,
                      color: Color(0xFF517399), size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Deletion Request Details',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Vet Clinic:', request.vetClinicName),
              _buildDetailRow('Requested By:', request.requestedBy),
              _buildDetailRow('Reason:', request.reason),
              _buildDetailRow('Status:', request.status),
              _buildDetailRow('Business License:', request.businessLicense),
              _buildDetailRow('Contact Email:', request.contactEmail),
              _buildDetailRow('Contact Phone:', request.contactPhone),
              _buildDetailRow('Date Requested:',
                  '${request.dateRequested.day}/${request.dateRequested.month}/${request.dateRequested.year}'),
              if (request.dateProcessed != null)
                _buildDetailRow('Date Processed:',
                    '${request.dateProcessed!.day}/${request.dateProcessed!.month}/${request.dateProcessed!.year}'),
              if (request.denialReason != null)
                _buildDetailRow('Denial Reason:', request.denialReason!),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FDFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: Text(
                  request.description,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF517399),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Color(0xFF7F8C8D)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteRequestActionDialog extends StatefulWidget {
  final DeletionRequestItem request;
  final VoidCallback onApprove;
  final Function(String) onDeny;

  const DeleteRequestActionDialog({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  State<DeleteRequestActionDialog> createState() =>
      _DeleteRequestActionDialogState();
}

class _DeleteRequestActionDialogState extends State<DeleteRequestActionDialog> {
  final TextEditingController _denialReasonController = TextEditingController();
  bool _showDenialForm = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(
            Icons.gavel,
            color: Color(0xFF517399),
          ),
          SizedBox(width: 8),
          Text('Process Deletion Request'),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review the deletion request for "${widget.request.vetClinicName}":',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FDFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E6ED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Requested By: ${widget.request.requestedBy}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Reason: ${widget.request.reason}'),
                  Text('Business License: ${widget.request.businessLicense}'),
                  const SizedBox(height: 8),
                  const Text('Description:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(widget.request.description,
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_showDenialForm) ...[
              const Text(
                'What would you like to do with this request?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ] else ...[
              const Text(
                'Please provide a reason for denial:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _denialReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter denial reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF517399), width: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_showDenialForm) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF95A5A6)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _showDenialForm = true;
              });
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFE74C3C)),
            child: const Text('Deny Request'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onApprove();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve Deletion'),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              setState(() {
                _showDenialForm = false;
                _denialReasonController.clear();
              });
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF95A5A6)),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_denialReasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                widget.onDeny(_denialReasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Denial'),
          ),
        ],
      ],
    );
  }
  @override
  void dispose() {
    _denialReasonController.dispose();
    super.dispose();
  }
}
