import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';

class VetClinicFeedbackApp extends StatefulWidget {
  const VetClinicFeedbackApp({super.key});
  @override
  State<VetClinicFeedbackApp> createState() => _VetClinicFeedbackAppState();
}

class _VetClinicFeedbackAppState extends State<VetClinicFeedbackApp> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedStatus = 'All';
  List<FeedbackItem> _allFeedbacks = [];
  List<FeedbackItem> _filteredFeedbacks = [];
  final bool _isLoading = false;
  final int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
    _filteredFeedbacks = _allFeedbacks;
  }

  void _loadSampleData() {
    _allFeedbacks = [
      FeedbackItem(
        id: '001',
        vetClinicName: 'Paws & Claws Veterinary Clinic',
        customerName: 'John Smith',
        feedback:
            'Excellent service! Dr. Martinez was very professional and caring.',
        rating: 5,
        status: 'Pending',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        hasDeleteRequest: true,
        adminRequestedBy: 'Admin Sarah',
      ),
      FeedbackItem(
        id: '002',
        vetClinicName: 'City Pet Hospital',
        customerName: 'Emily Johnson',
        feedback: 'Long wait time, but good treatment for my cat.',
        rating: 3,
        status: 'Approved',
        date: DateTime.now().subtract(const Duration(days: 1)),
        hasDeleteRequest: false,
      ),
      FeedbackItem(
        id: '003',
        vetClinicName: 'Animal Care Center',
        customerName: 'Michael Brown',
        feedback: 'Poor service. Staff was rude and unprofessional.',
        rating: 1,
        status: 'Pending',
        date: DateTime.now().subtract(const Duration(days: 2)),
        hasDeleteRequest: true,
        adminRequestedBy: 'Admin Mike',
      ),
      FeedbackItem(
        id: '004',
        vetClinicName: 'Happy Tails Veterinary',
        customerName: 'Sarah Wilson',
        feedback:
            'Great facilities and friendly staff. My dog loves coming here!',
        rating: 5,
        status: 'Approved',
        date: DateTime.now().subtract(const Duration(days: 3)),
        hasDeleteRequest: false,
      ),
      FeedbackItem(
        id: '005',
        vetClinicName: 'Pet Wellness Center',
        customerName: 'David Lee',
        feedback: 'Average experience. Could improve appointment scheduling.',
        rating: 3,
        status: 'Under Review',
        date: DateTime.now().subtract(const Duration(days: 4)),
        hasDeleteRequest: true,
        adminRequestedBy: 'Admin Lisa',
      ),
    ];
    _filteredFeedbacks = _allFeedbacks;
  }

  void _filterFeedbacks() {
    setState(() {
      _filteredFeedbacks = _allFeedbacks.where((feedback) {
        bool matchesSearch = _searchController.text.isEmpty ||
            feedback.vetClinicName
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            feedback.customerName
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'With Delete Request' &&
                feedback.hasDeleteRequest) ||
            (_selectedFilter == 'No Delete Request' &&
                !feedback.hasDeleteRequest);

        bool matchesStatus =
            _selectedStatus == 'All' || feedback.status == _selectedStatus;

        return matchesSearch && matchesFilter && matchesStatus;
      }).toList();
    });
  }

  void _showFeedbackDetails(FeedbackItem feedback) {
    showDialog(
      context: context,
      builder: (context) => FeedbackDetailDialog(feedback: feedback),
    );
  }

  void _handleDeleteRequest(FeedbackItem feedback) {
    showDialog(
      context: context,
      builder: (context) => DeleteRequestDialog(
        feedback: feedback,
        onApprove: () => _approveDeletion(feedback),
        onDeny: () => _denyDeletion(feedback),
      ),
    );
  }

  void _approveDeletion(FeedbackItem feedback) {
    setState(() {
      _allFeedbacks.removeWhere((item) => item.id == feedback.id);
      _filterFeedbacks();
    });
    _showSnackBar('Deletion approved and feedback removed', Colors.green);
  }

  void _denyDeletion(FeedbackItem feedback) {
    setState(() {
      feedback.hasDeleteRequest = false;
      feedback.adminRequestedBy = null;
    });
    _showSnackBar('Deletion request denied', Colors.orange);
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
    int totalFeedbacks = _allFeedbacks.length;
    int pendingRequests = _allFeedbacks.where((f) => f.hasDeleteRequest).length;
    int approvedFeedbacks =
        _allFeedbacks.where((f) => f.status == 'Approved').length;
    double avgRating = _allFeedbacks.isEmpty
        ? 0
        : _allFeedbacks.map((f) => f.rating).reduce((a, b) => a + b) /
            _allFeedbacks.length;

    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      margin: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isMobile ? 1.2 : 1.5,
            children: [
              _buildStatCard('Total Feedbacks', totalFeedbacks.toString(),
                  Icons.feedback, const Color(0xFF4A90E2)),
              _buildStatCard('Delete Requests', pendingRequests.toString(),
                  Icons.delete_outline, const Color(0xFFE74C3C)),
              _buildStatCard('Approved', approvedFeedbacks.toString(),
                  Icons.check_circle, const Color(0xFF2ECC71)),
              _buildStatCard('Avg Rating', avgRating.toStringAsFixed(1),
                  Icons.star, const Color(0xFFF39C12)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(248, 253, 255, 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatusDropdown()),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: _buildSearchBar()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildFilterDropdown()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildStatusDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => _filterFeedbacks(),
      decoration: InputDecoration(
        hintText: 'Search vet clinics or customers...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF517399)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF517399)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
      value: _selectedFilter,
      decoration: InputDecoration(
        labelText: 'Filter Requests',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
        ),
      ),
      items: ['All', 'With Delete Request', 'No Delete Request']
          .map((filter) => DropdownMenuItem(value: filter, child: Text(filter)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!;
          _filterFeedbacks();
        });
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      dropdownColor: const Color.fromRGBO(248, 253, 255, 1),
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF517399), width: 2),
        ),
      ),
      items: ['All', 'Pending', 'Approved', 'Under Review']
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
          _filterFeedbacks();
        });
      },
    );
  }

  Widget _buildFeedbackList() {
    if (_filteredFeedbacks.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(248, 253, 255, 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 64, color: Color(0xFF95A5A6)),
              SizedBox(height: 16),
              Text(
                'No feedback found',
                style: TextStyle(fontSize: 18, color: Color(0xFF7F8C8D)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(248, 253, 255, 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredFeedbacks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _buildMobileFeedbackCard(_filteredFeedbacks[index]),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(
                    label: Text('Vet Clinic',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Customer',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Rating',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Status',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Date',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Delete Request',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Actions',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filteredFeedbacks
                  .map((feedback) => _buildDataRow(feedback))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileFeedbackCard(FeedbackItem feedback) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback.vetClinicName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _buildStatusChip(feedback.status),
            ],
          ),
          const SizedBox(height: 8),
          Text('Customer: ${feedback.customerName}',
              style: const TextStyle(color: Color(0xFF7F8C8D))),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRatingStars(feedback.rating),
              const SizedBox(width: 16),
              Text(
                '${feedback.date.day}/${feedback.date.month}/${feedback.date.year}',
                style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12),
              ),
            ],
          ),
          if (feedback.hasDeleteRequest) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFF6B6B)),
              ),
              child: Text(
                'Delete requested by ${feedback.adminRequestedBy}',
                style: const TextStyle(color: Color(0xFFD63031), fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showFeedbackDetails(feedback),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF517399)),
              ),
              if (feedback.hasDeleteRequest)
                TextButton.icon(
                  onPressed: () => _handleDeleteRequest(feedback),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Handle'),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE74C3C)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(FeedbackItem feedback) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              feedback.vetClinicName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(feedback.customerName)),
        DataCell(_buildRatingStars(feedback.rating)),
        DataCell(_buildStatusChip(feedback.status)),
        DataCell(Text(
            '${feedback.date.day}/${feedback.date.month}/${feedback.date.year}')),
        DataCell(
          feedback.hasDeleteRequest
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFF6B6B)),
                  ),
                  child: Text(
                    feedback.adminRequestedBy!,
                    style:
                        const TextStyle(color: Color(0xFFD63031), fontSize: 12),
                  ),
                )
              : const Text('No', style: TextStyle(color: Color(0xFF7F8C8D))),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showFeedbackDetails(feedback),
                icon: const Icon(Icons.visibility, color: Color.fromRGBO(81, 115, 153, 1)),
                tooltip: 'View Details',
              ),
              if (feedback.hasDeleteRequest)
                IconButton(
                  onPressed: () => _handleDeleteRequest(feedback),
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFE74C3C)),
                  tooltip: 'Handle Delete Request',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: const Color(0xFFF39C12),
          size: 16,
        );
      }),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Approved':
        chipColor = const Color(0xFF2ECC71);
        break;
      case 'Pending':
        chipColor = const Color(0xFFF39C12);
        break;
      case 'Under Review':
        chipColor = const Color(0xFF3498DB);
        break;
      default:
        chipColor = const Color(0xFF95A5A6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings,
                color: Color.fromARGB(255, 81, 115, 153)),
            SizedBox(width: 8),
            Text(
              'Feedback Manager',
              style: TextStyle(
                  color: Color.fromARGB(255, 81, 115, 153),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Export functionality
              _showSnackBar(
                  'Export functionality coming soon!', const Color(0xFF3498DB));
            },
            icon: const Icon(Icons.file_download,
                color: Color.fromARGB(255, 81, 115, 153)),
            tooltip: 'Export CSV',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _loadSampleData();
                _filterFeedbacks();
              });
            },
            icon: const Icon(Icons.refresh,
                color: Color.fromARGB(255, 81, 115, 153)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardStats(),
            const SizedBox(height: 16),
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            _buildFeedbackList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApplicationReport()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        child: const Icon(Icons.mobile_friendly,
            color: Color.fromARGB(255, 81, 115, 153)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class FeedbackItem {
  final String id;
  final String vetClinicName;
  final String customerName;
  final String feedback;
  final int rating;
  String status;
  final DateTime date;
  bool hasDeleteRequest;
  String? adminRequestedBy;

  FeedbackItem({
    required this.id,
    required this.vetClinicName,
    required this.customerName,
    required this.feedback,
    required this.rating,
    required this.status,
    required this.date,
    required this.hasDeleteRequest,
    this.adminRequestedBy,
  });
}

class FeedbackDetailDialog extends StatelessWidget {
  final FeedbackItem feedback;

  const FeedbackDetailDialog({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        color: const Color.fromRGBO(248, 253, 255, 1),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.feedback, color: Color(0xFF517399), size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Feedback Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            _buildDetailRow('Vet Clinic:', feedback.vetClinicName),
            _buildDetailRow('Customer:', feedback.customerName),
            _buildDetailRow('Rating:', '${feedback.rating}/5 stars'),
            _buildDetailRow('Status:', feedback.status),
            _buildDetailRow('Date:',
                '${feedback.date.day}/${feedback.date.month}/${feedback.date.year}'),
            if (feedback.hasDeleteRequest)
              _buildDetailRow(
                  'Delete Requested By:', feedback.adminRequestedBy!),
            const SizedBox(height: 16),
            const Text(
              'Feedback:',
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
                feedback.feedback,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context), //dito
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF517399),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Respond functionality
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Respond functionality coming soon!'),
                        backgroundColor: Color(0xFF3498DB),
                      ),
                    );
                  },
                  icon: const Icon(Icons.reply, color: Colors.white),
                  label: const Text('Respond'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF517399),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
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
            width: 120,
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

class DeleteRequestDialog extends StatelessWidget {
  final FeedbackItem feedback;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const DeleteRequestDialog({
    super.key,
    required this.feedback,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning, color: Color(0xFFF39C12)),
          SizedBox(width: 8),
          Text('Delete Request'),
        ],
      ),
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin "${feedback.adminRequestedBy}" has requested to delete this feedback:',
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
                Text('Vet Clinic: ${feedback.vetClinicName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Customer: ${feedback.customerName}'),
                Text('Rating: ${feedback.rating}/5'),
                const SizedBox(height: 8),
                Text(feedback.feedback,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'What would you like to do?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDeny();
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF95A5A6)),
          child: Text('Deny Request'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onApprove();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74C3C),
            foregroundColor: Colors.white,
          ),
          child: Text('Approve Deletion'),
        ),
      ],
    );
  }
}
