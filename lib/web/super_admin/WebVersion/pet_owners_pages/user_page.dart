import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:intl/intl.dart';

/// ============================================
/// SUPER ADMIN USER MANAGEMENT SCREEN
/// ============================================
class SuperAdminUserManagementScreen extends StatefulWidget {
  const SuperAdminUserManagementScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminUserManagementScreen> createState() =>
      _SuperAdminUserManagementScreenState();
}

class _SuperAdminUserManagementScreenState
    extends State<SuperAdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  // Real-time subscription
  RealtimeSubscription? _userSubscription;
  RealtimeSubscription? _verificationSubscription;

  // User lists
  List<User> _allUsers = [];
  List<User> _verifiedUsers = [];
  List<User> _unverifiedUsers = [];

  bool _isLoading = true;
  String _searchQuery = '';

  // Colors
  static const Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  static const Color primaryBlue = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color lightBlue = Color(0xFF9FC5E8);
  static const Color deepBlue = Color(0xFF2F4F7F);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSubscription?.close();
    _verificationSubscription?.close();
    super.dispose();
  }

  /// Load all users from database
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      print('>>> Loading all users...');

      // Get all users from database
      final docs = await _authRepository.appWriteProvider.databases!.listDocuments(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        queries: [
          Query.equal('role', ['customer', 'user']), // Only get regular users
          Query.orderDesc('\$createdAt'),
          Query.limit(1000),
        ],
      );

      print('>>> Found ${docs.documents.length} users');

      // Convert to User models
      _allUsers = docs.documents.map((doc) => User.fromMap(doc.data)).toList();

      // Split into verified and unverified
      _categorizeUsers();

      setState(() => _isLoading = false);
    } catch (e) {
      print('>>> Error loading users: $e');
      setState(() => _isLoading = false);

      Get.snackbar(
        'Error',
        'Failed to load users: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Categorize users into verified and unverified
  void _categorizeUsers() {
    _verifiedUsers = _allUsers.where((user) => user.idVerified).toList();
    _unverifiedUsers = _allUsers.where((user) => !user.idVerified).toList();

    print('>>> Verified users: ${_verifiedUsers.length}');
    print('>>> Unverified users: ${_unverifiedUsers.length}');
  }

  /// Setup real-time subscriptions for users and verifications
  void _setupRealtimeSubscriptions() {
    try {
      final realtime = Realtime(_authRepository.appWriteProvider.client);

      // Subscribe to users collection changes
      _userSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.usersCollectionID}.documents'
      ]);

      _userSubscription!.stream.listen((response) {
        print('>>> Real-time user event: ${response.events}');

        if (response.events.contains('databases.*.collections.*.documents.*')) {
          // Reload users when any user document changes
          _loadUsers();
        }
      });

      // Subscribe to verification collection changes
      _verificationSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.idVerificationCollectionID}.documents'
      ]);

      _verificationSubscription!.stream.listen((response) {
        print('>>> Real-time verification event: ${response.events}');

        if (response.events.contains('databases.*.collections.*.documents.*')) {
          // Reload users when verification status changes
          _loadUsers();
        }
      });

      print('>>> Real-time subscriptions established');
    } catch (e) {
      print('>>> Error setting up real-time subscriptions: $e');
    }
  }

  /// Filter users based on search query
  List<User> _filterUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final nameLower = user.name.toLowerCase();
      final emailLower = user.email.toLowerCase();
      final phoneLower = (user.phone ?? '').toLowerCase();
      final queryLower = _searchQuery.toLowerCase();

      return nameLower.contains(queryLower) ||
          emailLower.contains(queryLower) ||
          phoneLower.contains(queryLower);
    }).toList();
  }

  /// Show user details dialog
  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(
        user: user,
        authRepository: _authRepository,
        onUserUpdated: _loadUsers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, accentTeal],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pet Owner Management',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryBlue),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or phone...',
                      prefixIcon: const Icon(Icons.search, color: primaryBlue),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: mediumGray),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: primaryBlue,
                indicatorWeight: 3,
                labelColor: primaryBlue,
                unselectedLabelColor: mediumGray,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user),
                        const SizedBox(width: 8),
                        Text('Verified (${_verifiedUsers.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pending),
                        const SizedBox(width: 8),
                        Text('Unverified (${_unverifiedUsers.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading users...',
                    style: TextStyle(color: mediumGray, fontSize: 16),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Verified users tab
                UserListView(
                  users: _filterUsers(_verifiedUsers),
                  isVerified: true,
                  onUserTap: _showUserDetails,
                ),
                // Unverified users tab
                UserListView(
                  users: _filterUsers(_unverifiedUsers),
                  isVerified: false,
                  onUserTap: _showUserDetails,
                ),
              ],
            ),
    );
  }
}

/// ============================================
/// USER LIST VIEW
/// ============================================
class UserListView extends StatelessWidget {
  final List<User> users;
  final bool isVerified;
  final Function(User) onUserTap;

  const UserListView({
    Key? key,
    required this.users,
    required this.isVerified,
    required this.onUserTap,
  }) : super(key: key);

  static const Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  static const Color primaryBlue = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.pending,
              size: 80,
              color: primaryBlue.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              isVerified
                  ? 'No verified users found'
                  : 'No unverified users found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryBlue.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVerified
                  ? 'All users are pending verification'
                  : 'All users have been verified!',
              style: TextStyle(
                fontSize: 14,
                color: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Responsive grid layout
    int crossAxisCount = 1;
    if (isDesktop) {
      crossAxisCount = 3;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isDesktop ? 2.5 : 2.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return UserCard(
          user: users[index],
          onTap: () => onUserTap(users[index]),
        );
      },
    );
  }
}

/// ============================================
/// USER CARD (Grid Item)
/// ============================================
class UserCard extends StatefulWidget {
  final User user;
  final VoidCallback onTap;

  const UserCard({
    Key? key,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  static const Color primaryBlue = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color lightBlue = Color(0xFF9FC5E8);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          Colors.white,
                          lightBlue.withOpacity(0.2),
                          accentTeal.withOpacity(0.1),
                        ]
                      : [
                          Colors.white,
                          Colors.white.withOpacity(0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? primaryBlue.withOpacity(0.2)
                        : primaryBlue.withOpacity(0.1),
                    blurRadius: _isHovered ? 15 : 8,
                    offset: Offset(0, _isHovered ? 6 : 3),
                    spreadRadius: _isHovered ? 2 : 1,
                  ),
                ],
                border: Border.all(
                  color: _isHovered
                      ? primaryBlue.withOpacity(0.4)
                      : primaryBlue.withOpacity(0.2),
                  width: _isHovered ? 2 : 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [primaryBlue, accentTeal],
                        ),
                        border: Border.all(
                          color: _isHovered ? vetGreen : accentTeal,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.user.name.isNotEmpty
                              ? widget.user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Name
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Email
                          Row(
                            children: [
                              Icon(Icons.email, size: 14, color: mediumGray),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.user.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mediumGray,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Phone
                          if (widget.user.phone != null &&
                              widget.user.phone!.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: mediumGray),
                                const SizedBox(width: 4),
                                Text(
                                  widget.user.phone!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: mediumGray,
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 8),

                          // Verification badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.user.idVerified
                                    ? [vetGreen, vetGreen.withOpacity(0.7)]
                                    : [vetOrange, vetOrange.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.user.idVerified
                                      ? Icons.verified_user
                                      : Icons.pending,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.user.verificationStatusText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow icon
                    Icon(
                      Icons.arrow_forward_ios,
                      color: _isHovered ? primaryBlue : mediumGray,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================
/// USER DETAILS DIALOG
/// ============================================
class UserDetailsDialog extends StatefulWidget {
  final User user;
  final AuthRepository authRepository;
  final VoidCallback onUserUpdated;

  const UserDetailsDialog({
    Key? key,
    required this.user,
    required this.authRepository,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  State<UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<UserDetailsDialog> {
  bool _showDeleteConfirm = false;
  bool _isDeleting = false;

  static const Color backgroundColor = Color.fromRGBO(248, 253, 255, 1);
  static const Color primaryBlue = Color.fromRGBO(81, 115, 153, 1);
  static const Color accentTeal = Color(0xFF5B9BD5);
  static const Color lightBlue = Color(0xFF9FC5E8);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not available';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);

    try {
      print('>>> Deleting user: ${widget.user.userId}');

      // Delete user document from database
      if (widget.user.documentId != null) {
        await widget.authRepository.appWriteProvider.databases!.deleteDocument(
          databaseId: AppwriteConstants.dbID,
          collectionId: AppwriteConstants.usersCollectionID,
          documentId: widget.user.documentId!,
        );
      }

      Get.snackbar(
        'Success',
        '${widget.user.name} has been deleted successfully',
        backgroundColor: vetGreen,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      widget.onUserUpdated();
      Navigator.of(context).pop();
    } catch (e) {
      print('>>> Error deleting user: $e');

      Get.snackbar(
        'Error',
        'Failed to delete user: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 768;
    final dialogWidth = isDesktop ? 600.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          maxWidth: screenWidth * 0.95,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              backgroundColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 32 : 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBlue, accentTeal, lightBlue],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.user.role.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 32 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Status Section
                    _buildSectionHeader(
                      'Verification Status',
                      widget.user.idVerified
                          ? Icons.verified_user
                          : Icons.pending,
                      widget.user.idVerified ? vetGreen : vetOrange,
                    ),
                    const SizedBox(height: 16),
                    _buildVerificationStatusCard(),
                    const SizedBox(height: 24),

                    // Contact Information Section
                    _buildSectionHeader(
                      'Contact Information',
                      Icons.contact_mail_outlined,
                      primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildContactInfoCard(),
                    const SizedBox(height: 24),

                    // Account Information Section
                    _buildSectionHeader(
                      'Account Information',
                      Icons.account_circle_outlined,
                      accentTeal,
                    ),
                    const SizedBox(height: 16),
                    _buildAccountInfoCard(),

                    // Delete confirmation
                    if (_showDeleteConfirm) ...[
                      const SizedBox(height: 24),
                      _buildDeleteConfirmation(),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor,
                    lightBlue.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: _buildActionButtons(screenWidth > 500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.user.idVerified
              ? [
                  vetGreen.withOpacity(0.1),
                  vetGreen.withOpacity(0.05),
                ]
              : [
                  vetOrange.withOpacity(0.1),
                  vetOrange.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.user.idVerified
              ? vetGreen.withOpacity(0.3)
              : vetOrange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.user.idVerified ? vetGreen : vetOrange)
                .withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.user.idVerified
                        ? [vetGreen, vetGreen.withOpacity(0.7)]
                        : [vetOrange, vetOrange.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.user.idVerified ? vetGreen : vetOrange)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.user.idVerified
                      ? Icons.verified_user
                      : Icons.pending,
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
                      widget.user.verificationStatusText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.user.idVerified ? vetGreen : vetOrange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.idVerified
                          ? 'User identity has been verified'
                          : 'User identity verification pending',
                      style: TextStyle(
                        fontSize: 14,
                        color: mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.user.idVerified && widget.user.idVerifiedAt != null) ...[
            const SizedBox(height: 16),
            const Divider(color: mediumGray, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: mediumGray),
                const SizedBox(width: 8),
                Text(
                  'Verified on: ${_formatDate(widget.user.idVerifiedAt)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.email_outlined,
            'Email Address',
            widget.user.email,
            primaryBlue,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone Number',
            widget.user.phone ?? 'Not provided',
            accentTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentTeal.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.badge_outlined,
            'User ID',
            widget.user.userId,
            primaryBlue,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.assignment_ind_outlined,
            'Document ID',
            widget.user.documentId ?? 'N/A',
            accentTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.red[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Are you sure you want to delete ${widget.user.name}? This action cannot be undone and will permanently remove all user data.',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isWide) {
    if (_isDeleting) {
      return const Center(
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    if (_showDeleteConfirm) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => setState(() => _showDeleteConfirm = false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleDelete,
              icon: const Icon(Icons.delete_forever, size: 20),
              label: const Text('Confirm Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      );
    }

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () => setState(() => _showDeleteConfirm = true),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Delete User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showDeleteConfirm = true),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Delete User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      );
    }
  }
}