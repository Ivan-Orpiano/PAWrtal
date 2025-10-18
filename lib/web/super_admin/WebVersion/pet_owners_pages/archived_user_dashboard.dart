import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/archived_user_model.dart';
import 'package:capstone_app/web/super_admin/WebVersion/services/archive_service.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';

/// Super Admin Dashboard for Archived Users
class ArchivedUsersDashboard extends StatefulWidget {
  const ArchivedUsersDashboard({Key? key}) : super(key: key);

  @override
  State<ArchivedUsersDashboard> createState() => _ArchivedUsersDashboardState();
}

class _ArchivedUsersDashboardState extends State<ArchivedUsersDashboard> {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ArchiveService _archiveService = Get.find<ArchiveService>();

  List<ArchivedUser> _archivedUsers = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'active'; // active, recovered, deleted, all
  String _selectedSort = 'newest'; // 'newest', 'oldest', 'alphabetical'

  // Real-time subscription
  RealtimeSubscription? _archiveSubscription;

  // Colors - UPDATED PALETTE
  static const Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  static const Color primaryColor = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color successGreen = Color(0xFF34D399);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color darkRed = Color(0xFFDC2626);
  static const Color darkBlue = Color.fromRGBO(51, 75, 103, 1);

  @override
  void initState() {
    super.initState();
    _loadArchivedUsers();
    _loadStats();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _archiveSubscription?.close();
    super.dispose();
  }

  Future<void> _loadArchivedUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await _authRepository.getAllArchivedUsers(
        includePermanentlyDeleted: _filterStatus == 'all' || _filterStatus == 'deleted',
        limit: 500,
      );

      setState(() {
        _archivedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading archived users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _archiveService.getArchiveStats();
      setState(() => _stats = stats);
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  void _setupRealtimeSubscription() {
    try {
      final subscription = _authRepository.subscribeToArchivedUsers();

      _archiveSubscription = subscription as RealtimeSubscription?;

      subscription.listen((event) {
        print('>>> Archive real-time event received');
        _loadArchivedUsers();
        _loadStats();
      });
    } catch (e) {
      print('Error setting up real-time subscription: $e');
    }
  }

  List<ArchivedUser> get _filteredUsers {
    var filtered = _archivedUsers.where((user) {
      // Filter by status
      switch (_filterStatus) {
        case 'active':
          if (user.isPermanentlyDeleted || user.isRecovered) return false;
          break;
        case 'recovered':
          if (!user.isRecovered) return false;
          break;
        case 'deleted':
          if (!user.isPermanentlyDeleted) return false;
          break;
        case 'all':
          break;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.phone?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_selectedSort) {
      case 'alphabetical':
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.scheduledDeletionAt.compareTo(b.scheduledDeletionAt));
        break;
      case 'newest':
      default:
        filtered.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));
        break;
    }

    return filtered;
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, backgroundColor],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sort Archived Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSortOption(
              'Newest First',
              'Recently archived users',
              Icons.arrow_downward_rounded,
              'newest',
              [successGreen, accentTeal],
            ),
            const SizedBox(height: 12),
            _buildSortOption(
              'Oldest First',
              'Users due for deletion soon',
              Icons.arrow_upward_rounded,
              'oldest',
              [warningOrange, primaryColor],
            ),
            const SizedBox(height: 12),
            _buildSortOption(
              'Alphabetical (A-Z)',
              'Sort by user name',
              Icons.sort_by_alpha_rounded,
              'alphabetical',
              [primaryColor, darkBlue],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    String title,
    String subtitle,
    IconData icon,
    String sortValue,
    List<Color> colors,
  ) {
    final isSelected = _selectedSort == sortValue;

    return InkWell(
      onTap: () {
        setState(() => _selectedSort = sortValue);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [colors[0].withOpacity(0.15), colors[1].withOpacity(0.1)])
              : null,
          color: isSelected ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors[0] : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colors[0] : darkBlue,
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
            if (isSelected)
              Icon(Icons.check_circle, color: colors[0], size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _recoverUser(ArchivedUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recover User'),
        content: Text('Are you sure you want to recover ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: successGreen),
            child: const Text('Recover'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentUser = await _authRepository.getUser();
      final result = await _authRepository.recoverArchivedUser(
        userId: user.userId,
        recoveredBy: currentUser?.name ?? 'Super Admin',
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          '${user.name} has been recovered successfully',
          backgroundColor: successGreen,
          colorText: Colors.white,
        );
        _loadArchivedUsers();
        _loadStats();
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to recover user: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _processScheduledDeletionsNow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Scheduled Deletions'),
        content: const Text(
          'This will permanently delete all users whose 30-day period has expired. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: darkRed),
            child: const Text('Process'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing deletions...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final result = await _archiveService.processNow();

      Get.back(); // Close loading dialog

      Get.dialog(
        AlertDialog(
          title: const Text('Processing Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Users processed: ${result['processed']}'),
              if (result['errors'] != null && (result['errors'] as List).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Errors: ${(result['errors'] as List).length}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      _loadArchivedUsers();
      _loadStats();
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to process deletions: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, accentTeal],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.archive, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Archived Users',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryColor),
            onPressed: () {
              _loadArchivedUsers();
              _loadStats();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: darkRed),
            onPressed: _processScheduledDeletionsNow,
            tooltip: 'Process Deletions Now',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats Section - UPDATED DESIGN
          _buildStatsSection(),

          // Search and Filter - UPDATED WITH SORT BUTTON
          _buildSearchAndFilter(),

          // User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUserList(),
          ),
        ],
      ),
    );
  }

  // UPDATED: Stats Section with new color scheme
  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(0.1), accentTeal.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Archived',
                _stats['total']?.toString() ?? '0',
                Icons.archive,
                primaryColor,
              ),
              _buildStatItem(
                'Active',
                _stats['activeArchives']?.toString() ?? '0',
                Icons.hourglass_empty,
                warningOrange,
              ),
              _buildStatItem(
                'Due Soon',
                _stats['dueSoon']?.toString() ?? '0',
                Icons.warning,
                darkRed,
              ),
              _buildStatItem(
                'Recovered',
                _stats['recovered']?.toString() ?? '0',
                Icons.restore,
                successGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final serviceStatus = _archiveService.getServiceStatus();
            final isRunning = serviceStatus['isRunning'] as bool;
            final lastRun = serviceStatus['lastRunTime'] as String;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRunning
                      ? [warningOrange.withOpacity(0.1), primaryColor.withOpacity(0.05)]
                      : [successGreen.withOpacity(0.1), accentTeal.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isRunning ? warningOrange.withOpacity(0.3) : successGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isRunning ? Icons.sync : Icons.check_circle,
                    color: isRunning ? warningOrange : successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRunning
                          ? 'Auto-deletion service is running...'
                          : 'Auto-deletion service active. Last run: ${lastRun.isNotEmpty ? _formatDateTime(lastRun) : "Never"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isRunning ? warningOrange : successGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // UPDATED: Stat Item with gradient
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // UPDATED: Search and Filter with Sort button
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search Bar with Sort Button
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, backgroundColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or phone...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, color: primaryColor, size: 20),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: primaryColor),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, accentTeal],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showSortMenu,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Icon(Icons.filter_list, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Chips and Sort Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Active', 'active'),
                    _buildFilterChip('Recovered', 'recovered'),
                    _buildFilterChip('Deleted', 'deleted'),
                    _buildFilterChip('All', 'all'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.15), accentTeal.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedSort == 'alphabetical'
                          ? Icons.sort_by_alpha
                          : _selectedSort == 'oldest'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                      size: 14,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedSort == 'alphabetical'
                          ? 'A-Z'
                          : _selectedSort == 'oldest'
                              ? 'Oldest'
                              : 'Newest',
                      style: const TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _filterStatus = value);
            _loadArchivedUsers();
          }
        },
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withOpacity(0.2),
        checkmarkColor: primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 80,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No archived users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Archived users will appear here',
            style: TextStyle(
              fontSize: 14,
              color: primaryColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_filteredUsers[index]);
      },
    );
  }

  // UPDATED: User Card with improved colors
  Widget _buildUserCard(ArchivedUser user) {
    final daysLeft = user.daysUntilDeletion;
    final isDueSoon = daysLeft <= 7 && daysLeft > 0;
    final isDueNow = user.isDeletionDue;

    Color statusColor;
    if (user.isPermanentlyDeleted) {
      statusColor = Colors.grey;
    } else if (user.isRecovered) {
      statusColor = successGreen;
    } else if (isDueNow) {
      statusColor = darkRed;
    } else if (isDueSoon) {
      statusColor = warningOrange;
    } else {
      statusColor = primaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, backgroundColor.withOpacity(0.5)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      user.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Details Section - UPDATED WITH NEW DESIGN
              _buildDetailRow(Icons.person, 'Archived by', user.archivedBy),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.calendar_today,
                'Archived on',
                _formatDateTime(user.archivedAt.toIso8601String()),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.delete_forever,
                'Scheduled deletion',
                _formatDateTime(user.scheduledDeletionAt.toIso8601String()),
              ),
              if (user.archiveReason.isNotEmpty && user.archiveReason != 'No reason provided') ...[
                const SizedBox(height: 8),
                _buildDetailRow(Icons.info_outline, 'Reason', user.archiveReason),
              ],

              // Warning Banner
              if (isDueSoon || isDueNow) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDueNow
                          ? [darkRed.withOpacity(0.15), darkRed.withOpacity(0.05)]
                          : [warningOrange.withOpacity(0.15), warningOrange.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDueNow ? darkRed.withOpacity(0.3) : warningOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDueNow ? Icons.error : Icons.warning,
                        color: isDueNow ? darkRed : warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isDueNow
                              ? 'This user is due for permanent deletion'
                              : 'Will be permanently deleted in $daysLeft days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDueNow ? darkRed : warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Actions
              if (!user.isPermanentlyDeleted && !user.isRecovered) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [successGreen, accentTeal],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: successGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _recoverUser(user),
                      icon: const Icon(Icons.restore, size: 18, color: Colors.white),
                      label: const Text(
                        'Recover User',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Detail Row with new gradient design
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.05), accentTeal.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.2), accentTeal.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: primaryColor),
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}