import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CrudeAdminAccount extends StatefulWidget {
  const CrudeAdminAccount({super.key});

  @override
  State<CrudeAdminAccount> createState() => _CrudeAdminAccountState();
}

class _CrudeAdminAccountState extends State<CrudeAdminAccount>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<AdminAccount> adminAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Management',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(81, 115, 153, 1)),
        ),
        backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromRGBO(81, 115, 153, 1),
          labelColor: Color.fromRGBO(81, 115, 153, 1),
          unselectedLabelColor: Color.fromRGBO(81, 115, 153, 1),
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Manage Admins'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          //_buildDashboardTab(),
          ManageAdminsTab(adminAccounts: adminAccounts),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  // Widget _buildDashboardTab() {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Welcome, Super Admin!',
  //           style: TextStyle(
  //             fontSize: 28,
  //             fontWeight: FontWeight.bold,
  //             color: Color.fromRGBO(81, 115, 153, 1.0),
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //         _buildStatsCards(),
  //         const SizedBox(height: 30),
  //         _buildQuickActions(),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildStatsCard(
            'Total Vet Clinics', '24', Icons.local_hospital, Colors.green),
        _buildStatsCard('Active Admins', '${adminAccounts.length}',
            Icons.person, Colors.blue),
        _buildStatsCard('Monthly Users', '1,245', Icons.people, Colors.orange),
        _buildStatsCard(
            'System Health', '98%', Icons.health_and_safety, Colors.purple),
      ],
    );
  }

  Widget _buildStatsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(81, 115, 153, 1.0),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Add New Admin',
                Icons.person_add,
                () => _tabController.animateTo(1),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton(
                'System Settings',
                Icons.settings,
                () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(81, 115, 153, 0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Container(
      color: const Color.fromRGBO(254, 255, 255, 1),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: Color.fromRGBO(81, 115, 153, 0.8),
            ),
            SizedBox(height: 20),
            Text(
              'Analytics Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(81, 115, 153, 1.0),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Coming Soon...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageAdminsTab extends StatefulWidget {
  final List<AdminAccount> adminAccounts;

  const ManageAdminsTab({super.key, required this.adminAccounts});

  @override
  State<ManageAdminsTab> createState() => _ManageAdminsTabState();
}

class _ManageAdminsTabState extends State<ManageAdminsTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(254, 255, 255, 1),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Admin Accounts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(81, 115, 153, 1.0),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateAdminDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Create Admin',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(81, 115, 153, 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAdminsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminsList() {
    if (widget.adminAccounts.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                'No admin accounts created yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Click "Create Admin" to add your first admin account',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.adminAccounts.length,
      itemBuilder: (context, index) {
        final admin = widget.adminAccounts[index];
        return _buildAdminCard(admin, index);
      },
    );
  }

  Widget _buildAdminCard(AdminAccount admin, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color.fromRGBO(81, 115, 153, 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(81, 115, 153, 0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color.fromRGBO(81, 115, 153, 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(81, 115, 153, 0.8),
                        Color.fromRGBO(81, 115, 153, 1.0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      admin.name
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(81, 115, 153, 1.0),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(admin.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getRoleColor(admin.role),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          admin.role,
                          style: TextStyle(
                            color: _getRoleColor(admin.role),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditAdminDialog(context, admin, index);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, index);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                      Icons.local_hospital, 'Clinic', admin.clinicName),
                ),
                Expanded(
                  child: _buildInfoItem(Icons.email, 'Email', admin.email),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child:
                      _buildInfoItem(Icons.phone, 'Phone', admin.phoneNumber),
                ),
                Expanded(
                  child: _buildInfoItem(
                      Icons.calendar_today, 'Created', admin.createdDate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color.fromRGBO(81, 115, 153, 0.8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(81, 115, 153, 1.0),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super admin':
        return Colors.red;
      case 'clinic admin':
        return Colors.blue;
      case 'veterinarian':
        return Colors.green;
      case 'staff':
        return Colors.orange;
      default:
        return const Color.fromRGBO(81, 115, 153, 1.0);
    }
  }

  void _showCreateAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateAdminDialog(
          onAdminCreated: (admin) {
            setState(() {
              widget.adminAccounts.add(admin);
            });
          },
        );
      },
    );
  }

  void _showEditAdminDialog(
      BuildContext context, AdminAccount admin, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateAdminDialog(
          existingAdmin: admin,
          onAdminCreated: (updatedAdmin) {
            setState(() {
              widget.adminAccounts[index] = updatedAdmin;
            });
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete ${widget.adminAccounts[index].name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.adminAccounts.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Admin account deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class CreateAdminDialog extends StatefulWidget {
  final Function(AdminAccount) onAdminCreated;
  final AdminAccount? existingAdmin;

  const CreateAdminDialog({
    super.key,
    required this.onAdminCreated,
    this.existingAdmin,
  });

  @override
  _CreateAdminDialogState createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedRole = 'Clinic Admin';
  bool _passwordVisible = false;

  final List<String> _roles = [
    'Super Admin',
    'Clinic Admin',
    'Veterinarian',
    'Staff',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingAdmin != null) {
      final admin = widget.existingAdmin!;
      _nameController.text = admin.name;
      _emailController.text = admin.email;
      _phoneController.text = admin.phoneNumber;
      _clinicNameController.text = admin.clinicName;
      _addressController.text = admin.address;
      _selectedRole = admin.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Colors.white,
              Color.fromARGB(255, 248, 253, 255),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(81, 115, 153, 0.8),
                    Color.fromRGBO(81, 115, 153, 1.0),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.white, size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      widget.existingAdmin != null
                          ? 'Edit Admin Account'
                          : 'Create New Admin Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Personal Information'),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value!)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Account Details'),
                      _buildRoleDropdown(),
                      const SizedBox(height: 15),
                      if (widget.existingAdmin == null) ...[
                        _buildPasswordField(),
                        const SizedBox(height: 20),
                      ],
                      _buildSectionTitle('Clinic Information'),
                      _buildTextField(
                        controller: _clinicNameController,
                        label: 'Vet Clinic Name',
                        icon: Icons.local_hospital,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Clinic name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Clinic Address',
                        icon: Icons.location_on,
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildActionButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            final admin = AdminAccount(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              role: _selectedRole,
              clinicName: _clinicNameController.text.trim(),
              address: _addressController.text.trim(),
              createdDate: widget.existingAdmin?.createdDate ??
                  DateTime.now().toString().split(' ').first,
            );
            widget.onAdminCreated(admin);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.existingAdmin != null
                    ? 'Admin account updated successfully'
                    : 'Admin account created successfully'),
                backgroundColor: const Color.fromRGBO(81, 115, 153, 1.0),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(81, 115, 153, 1.0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.existingAdmin != null
              ? 'Update Admin Account'
              : 'Create Admin Account',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromRGBO(81, 115, 153, 1.0),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon, color: const Color.fromRGBO(81, 115, 153, 0.8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Color.fromRGBO(81, 115, 153, 0.8)),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Password is required';
          if (value!.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon:
              const Icon(Icons.lock, color: Color.fromRGBO(81, 115, 153, 0.8)),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: const Color.fromRGBO(81, 115, 153, 0.8),
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Color.fromRGBO(81, 115, 153, 0.8)),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedRole = newValue;
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Role',
          prefixIcon: const Icon(Icons.admin_panel_settings,
              color: Color.fromRGBO(81, 115, 153, 0.8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Color.fromRGBO(81, 115, 153, 0.8)),
        ),
        items: _roles.map((role) {
          return DropdownMenuItem(
            value: role,
            child: Text(role),
          );
        }).toList(),
      ),
    );
  }
}

// Add the AdminAccount class definition
class AdminAccount {
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final String clinicName;
  final String address;
  final String createdDate;

  AdminAccount({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.clinicName,
    required this.address,
    required this.createdDate,
  });

  AdminAccount copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? clinicName,
    String? address,
    String? createdDate,
  }) {
    return AdminAccount(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      clinicName: clinicName ?? this.clinicName,
      address: address ?? this.address,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
