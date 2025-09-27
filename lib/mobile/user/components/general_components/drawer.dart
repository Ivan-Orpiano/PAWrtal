import 'package:appwrite/models.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/user_home/user_home_controller.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> with SingleTickerProviderStateMixin {
  final UserHomeController controller =
      UserHomeController(Get.find<AuthRepository>());
  final AppWriteProvider appWriteProvider = AppWriteProvider();

  late User currentUser;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    appWriteProvider.getUser().then((value) {
      setState(() {
        currentUser = value!;
        isLoading = false;
      });
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to get responsive sizing
  double _getResponsiveSize(double screenHeight, double baseSize, {double minSize = 0.6, double maxSize = 1.2}) {
    double scale = (screenHeight / 800).clamp(minSize, maxSize); // 800 is reference height
    return baseSize * scale;
  }

  Widget _buildGradientContainer({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAFAFA),
            Color(0xFFF5F5F5),
            Color(0xFFEEEEEE),
            Color(0xFFE8E8E8),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }

  Widget _buildAnimatedListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = MediaQuery.of(context).size.height;
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(screenHeight, 8, minSize: 0.7, maxSize: 1.0),
                vertical: _getResponsiveSize(screenHeight, 4, minSize: 0.5, maxSize: 1.0),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_getResponsiveSize(screenHeight, 12, minSize: 0.8)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(_getResponsiveSize(screenHeight, 12, minSize: 0.8)),
                  onTap: onTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveSize(screenHeight, 16, minSize: 0.7),
                      vertical: _getResponsiveSize(screenHeight, 12, minSize: 0.6),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_getResponsiveSize(screenHeight, 12, minSize: 0.8)),
                      color: Colors.white.withOpacity(0.8),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: _getResponsiveSize(screenHeight, 8, minSize: 0.6),
                          offset: Offset(0, _getResponsiveSize(screenHeight, 2, minSize: 0.5)),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(_getResponsiveSize(screenHeight, 8, minSize: 0.6)),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(_getResponsiveSize(screenHeight, 8, minSize: 0.6)),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor ?? const Color(0xFF1976D2),
                            size: _getResponsiveSize(screenHeight, 20, minSize: 0.7, maxSize: 1.1),
                          ),
                        ),
                        SizedBox(width: _getResponsiveSize(screenHeight, 16, minSize: 0.6)),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: _getResponsiveSize(screenHeight, 16, minSize: 0.8, maxSize: 1.1),
                              fontWeight: FontWeight.w500,
                              color: textColor ?? const Color(0xFF2C2C2C),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: _getResponsiveSize(screenHeight, 14, minSize: 0.7, maxSize: 1.1),
                          color: Colors.grey.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserProfile() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = MediaQuery.of(context).size.height;
        bool isSmallScreen = screenHeight < 700;
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.all(_getResponsiveSize(screenHeight, 20, minSize: 0.6, maxSize: 1.0)),
            child: Column(
              children: [
                // Profile Avatar with gradient border
                Container(
                  padding: EdgeInsets.all(_getResponsiveSize(screenHeight, 4, minSize: 0.5)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                        blurRadius: _getResponsiveSize(screenHeight, 20, minSize: 0.5),
                        spreadRadius: _getResponsiveSize(screenHeight, 2, minSize: 0.5),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: EdgeInsets.all(_getResponsiveSize(screenHeight, 20, minSize: 0.6)),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: const Color(0xFF1976D2),
                      size: _getResponsiveSize(screenHeight, 50, minSize: 0.6, maxSize: 1.0),
                    ),
                  ),
                ),
                SizedBox(height: _getResponsiveSize(screenHeight, 20, minSize: 0.5, maxSize: 0.8)),
                
                // User Name
                Text(
                  currentUser.name,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(screenHeight, 24, minSize: 0.8, maxSize: 1.0),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isSmallScreen ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: _getResponsiveSize(screenHeight, 8, minSize: 0.5, maxSize: 0.8)),
                
                // User Email
                Text(
                  currentUser.email,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(screenHeight, 16, minSize: 0.7, maxSize: 1.0),
                    color: const Color(0xFF666666).withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isSmallScreen ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: _getResponsiveSize(screenHeight, 16, minSize: 0.5, maxSize: 0.8)),
                
                // Verification Status
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(screenHeight, 16, minSize: 0.7),
                    vertical: _getResponsiveSize(screenHeight, 8, minSize: 0.6),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_getResponsiveSize(screenHeight, 20, minSize: 0.8)),
                    color: currentUser.emailVerification
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFFFF5722).withOpacity(0.1),
                    border: Border.all(
                      color: currentUser.emailVerification
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5722),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentUser.emailVerification
                            ? Icons.verified_rounded
                            : Icons.warning_rounded,
                        color: currentUser.emailVerification
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF5722),
                        size: _getResponsiveSize(screenHeight, 16, minSize: 0.7, maxSize: 1.0),
                      ),
                      SizedBox(width: _getResponsiveSize(screenHeight, 8, minSize: 0.6)),
                      Text(
                        currentUser.emailVerification ? "Verified" : "Not Verified",
                        style: TextStyle(
                          fontSize: _getResponsiveSize(screenHeight, 14, minSize: 0.7, maxSize: 1.0),
                          fontWeight: FontWeight.w600,
                          color: currentUser.emailVerification
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF5722),
                        ),
                      ),
                      if (!currentUser.emailVerification) ...[
                        SizedBox(width: _getResponsiveSize(screenHeight, 8, minSize: 0.6)),
                        GestureDetector(
                          onTap: () {
                            appWriteProvider.sendVerificationEmail().then((value) {
                              if (value) {
                                CustomSnackBar.showSuccessSnackBar(
                                  context: Get.overlayContext,
                                  title: "Success",
                                  message: "Verification email sent successfully",
                                );
                              } else {
                                CustomSnackBar.showErrorSnackBar(
                                  context: Get.overlayContext,
                                  title: "Error",
                                  message: "Failed to send verification email",
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveSize(screenHeight, 8, minSize: 0.6),
                              vertical: _getResponsiveSize(screenHeight, 4, minSize: 0.5),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2),
                              borderRadius: BorderRadius.circular(_getResponsiveSize(screenHeight, 12, minSize: 0.7)),
                            ),
                            child: Text(
                              "Verify",
                              style: TextStyle(
                                fontSize: _getResponsiveSize(screenHeight, 12, minSize: 0.7, maxSize: 1.0),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _buildGradientContainer(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  double screenHeight = MediaQuery.of(context).size.height;
                  
                  return SafeArea(
                    child: Column(
                      children: [
                        // User Profile Section
                        _buildUserProfile(),
                        
                        // Divider
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSize(screenHeight, 20, minSize: 0.7),
                          ),
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: _getResponsiveSize(screenHeight, 20, minSize: 0.5, maxSize: 0.8)),
                        
                        // Navigation Items
                        Expanded(
                          child: Column(
                            children: [
                              _buildAnimatedListTile(
                                icon: Icons.person_rounded, 
                                title: "Profile", 
                                onTap: () {}
                              ),
                              _buildAnimatedListTile(
                                icon: Icons.settings_rounded,
                                title: "Settings",
                                onTap: () {},
                              ),
                              _buildAnimatedListTile(
                                icon: Icons.info_outline_rounded,
                                title: "About Us",
                                onTap: () {},
                              ),
                              _buildAnimatedListTile(
                                icon: Icons.help_outline_rounded,
                                title: "Help & Support",
                                onTap: () {},
                              ),
                              _buildAnimatedListTile(
                                icon: Icons.privacy_tip_outlined,
                                title: "Privacy Policy",
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        
                        // Bottom Section
                        Container(
                          margin: EdgeInsets.all(_getResponsiveSize(screenHeight, 16, minSize: 0.6)),
                          child: _buildAnimatedListTile(
                            icon: Icons.logout_rounded,
                            title: "Sign Out",
                            onTap: () {
                              controller.logout();
                            },
                            iconColor: const Color(0xFFE53935),
                            textColor: const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}