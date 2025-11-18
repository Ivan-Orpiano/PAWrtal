import 'package:capstone_app/data/models/vet_clinic_registration_request_model.dart';
import 'package:capstone_app/utils/vet_clinic_email_service.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/super_ad_pin_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class VetClinicRegister extends StatefulWidget {
  final VetClinicRegistrationRequest? preFilledRequest;

  const VetClinicRegister({super.key, this.preFilledRequest});

  @override
  State<VetClinicRegister> createState() => _VetClinicRegisterState();
}

class _VetClinicRegisterState extends State<VetClinicRegister>
    with TickerProviderStateMixin {
  final GetStorage _getStorage = GetStorage();
  final VetClinicEmailService _emailService = VetClinicEmailService();

  final GlobalKey<FormState> inputForm = GlobalKey<FormState>();

  final TextEditingController vetName = TextEditingController();
  final TextEditingController vetAddress = TextEditingController();
  final TextEditingController vetContact = TextEditingController();
  final TextEditingController vetEmail = TextEditingController();
  final TextEditingController vetPassword = TextEditingController();
  final TextEditingController vetConfirmPassword = TextEditingController();

  final int vetNameLimit = 69;
  final int vetAddressLimit = 69;
  final int vetContactLimit = 11;
  final int vetEmailLimit = 39;
  final int vetPasswordLimit = 29;

  Color vetNameBorderColor = Colors.grey;
  Color vetAddressBorderColor = Colors.grey;
  Color vetContactBorderColor = Colors.grey;
  Color vetEmailBorderColor = Colors.grey;
  Color vetPasswordBorderColor = Colors.grey;
  Color vetConfirmPasswordBorderColor = Colors.grey;

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  // Password generation toggle
  bool autoGeneratePassword = true;
  String? generatedPassword;

  // ============ ADD THIS VARIABLE ============
  Map<String, double>? selectedClinicLocation;
  // ===========================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();

    // Pre-fill data if provided
    if (widget.preFilledRequest != null) {
      vetName.text = widget.preFilledRequest!.clinicName;
      vetAddress.text = widget.preFilledRequest!.fullAddress;
      vetContact.text = widget.preFilledRequest!.contactNumber;
      vetEmail.text = widget.preFilledRequest!.email;

      // Generate password immediately if auto-generate is enabled
      if (autoGeneratePassword) {
        _generatePassword();
      }
    } else {
      // Only set default contact if no pre-filled data
      vetContact.text = "09";
      vetContact.selection = TextSelection.fromPosition(
        TextPosition(offset: vetContact.text.length),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    vetConfirmPassword.dispose();
    super.dispose();
  }

  // Generate secure password
  void _generatePassword() {
    if (vetName.text.trim().isNotEmpty && vetEmail.text.trim().isNotEmpty) {
      setState(() {
        generatedPassword = VetClinicEmailService.generateSecurePassword(
          clinicName: vetName.text.trim(),
          email: vetEmail.text.trim(),
        );
      });
    }
  }

  void _onLocationSelected(Map<String, double> location) {
    setState(() {
      if (location.isEmpty) {
        selectedClinicLocation = null;
      } else {
        selectedClinicLocation = location;
      }
    });
  }

  void _onVetNameChanged(String value) {
    setState(() {
      vetNameBorderColor =
          value.length > vetNameLimit ? Colors.orange : Colors.grey;
    });

    // Regenerate password if auto-generate is enabled
    if (autoGeneratePassword && vetEmail.text.trim().isNotEmpty) {
      _generatePassword();
    }
  }

  void _onVetAddressChanged(String value) {
    setState(() {
      vetAddressBorderColor =
          value.length > vetAddressLimit ? Colors.orange : Colors.grey;
    });
  }

  void _onVetContactChanged(String value) {
    setState(() {
      vetContactBorderColor =
          value.length == vetContactLimit ? Colors.grey : Colors.orange;
    });
  }

  void _onVetEmailChanged(String value) {
    setState(() {
      vetEmailBorderColor =
          value.length > vetEmailLimit ? Colors.orange : Colors.grey;
    });

    // Regenerate password if auto-generate is enabled
    if (autoGeneratePassword && vetName.text.trim().isNotEmpty) {
      _generatePassword();
    }
  }

  void _onPasswordChanged(String value) {
    setState(() {
      vetPasswordBorderColor =
          value.length > vetPasswordLimit ? Colors.orange : Colors.grey;
    });
  }

  void _onConfirmPasswordChanged(String value) {
    setState(() {
      vetConfirmPasswordBorderColor =
          value.length > vetPasswordLimit ? Colors.orange : Colors.grey;
    });
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String labelText,
    required int maxLength,
    required Color borderColor,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    IconData? prefixIcon,
    int animationDelay = 0,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength + 1,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: borderColor == Colors.orange
                ? Colors.orange
                : const Color.fromARGB(255, 81, 115, 153),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: prefixIcon != null
              ? Container(
                  margin: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    prefixIcon,
                    color: const Color.fromARGB(255, 81, 115, 153),
                    size: 22,
                  ),
                )
              : null,
          suffixIcon: suffixIcon,
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 81, 115, 153),
              width: 2.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: validator,
      ),
    );
  }

  // NEW: Build password generation toggle
  Widget _buildPasswordToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.vpn_key_rounded,
                color: const Color.fromARGB(255, 81, 115, 153),
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                'Password Generation Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Auto-generate option
          InkWell(
            onTap: () {
              setState(() {
                autoGeneratePassword = true;
                _generatePassword();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: autoGeneratePassword
                    ? const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: autoGeneratePassword
                      ? const Color.fromARGB(255, 81, 115, 153)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    autoGeneratePassword
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: autoGeneratePassword
                        ? const Color.fromARGB(255, 81, 115, 153)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto-generate secure password',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Password will be generated based on clinic details',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Manual entry option
          InkWell(
            onTap: () {
              setState(() {
                autoGeneratePassword = false;
                generatedPassword = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !autoGeneratePassword
                    ? const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !autoGeneratePassword
                      ? const Color.fromARGB(255, 81, 115, 153)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    !autoGeneratePassword
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: !autoGeneratePassword
                        ? const Color.fromARGB(255, 81, 115, 153)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter password manually',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You will enter the password for this clinic',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Show generated password if auto-generate is enabled
          if (autoGeneratePassword && generatedPassword != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle,
                          color: Color(0xFF4CAF50), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Generated Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            generatedPassword!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier New',
                              color: Color.fromARGB(255, 81, 115, 153),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: generatedPassword!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: 'Copy password',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This password will be sent to the clinic\'s email address',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            surfaceTintColor: Colors.transparent,
            expandedHeight: screenHeight * 0.15,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 81, 115, 153)
                        .withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color.fromARGB(255, 81, 115, 153),
                  size: 20,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 81, 115, 153)
                            .withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "lib/images/PAWrtal_logo.png",
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Header Section with gradient background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromARGB(255, 81, 115, 153),
                              const Color.fromARGB(255, 101, 133, 170)
                                  .withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 81, 115, 153)
                                  .withOpacity(0.3),
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
                                    Icons.local_hospital_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    "Veterinary Registration",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Form Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 81, 115, 153)
                                  .withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: inputForm,
                          child: Column(
                            children: [
                              _buildAnimatedTextField(
                                controller: vetName,
                                labelText: "Veterinary Name ",
                                maxLength: vetNameLimit,
                                borderColor: vetNameBorderColor,
                                onChanged: _onVetNameChanged,
                                prefixIcon: Icons.business_rounded,
                                animationDelay: 0,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Veterinary Name is required.";
                                  }
                                  return null;
                                },
                              ),
                              _buildAnimatedTextField(
                                controller: vetAddress,
                                labelText: "Address ",
                                maxLength: vetAddressLimit,
                                borderColor: vetAddressBorderColor,
                                onChanged: _onVetAddressChanged,
                                prefixIcon: Icons.location_on_rounded,
                                animationDelay: 100,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Address is required.";
                                  }
                                  return null;
                                },
                              ),
                              _buildAnimatedTextField(
                                controller: vetContact,
                                labelText: "Contact Number",
                                maxLength: vetContactLimit,
                                borderColor: vetContactBorderColor,
                                onChanged: _onVetContactChanged,
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.phone_rounded,
                                animationDelay: 200,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  TextInputFormatter.withFunction(
                                      (oldValue, newValue) {
                                    String text = newValue.text;
                                    if (text.length < 2) {
                                      return const TextEditingValue(
                                        text: '09',
                                        selection:
                                            TextSelection.collapsed(offset: 2),
                                      );
                                    }
                                    if (!text.startsWith('09')) {
                                      text = '09' +
                                          text.replaceAll(RegExp(r'^0*9*'), '');
                                    }

                                    if (text.length > vetContactLimit) {
                                      text = text.substring(0, vetContactLimit);
                                    }
                                    int offset = newValue.selection.baseOffset;
                                    if (offset < 2) {
                                      offset = 2;
                                    }
                                    return TextEditingValue(
                                      text: text,
                                      selection: TextSelection.collapsed(
                                          offset: offset),
                                    );
                                  }),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Contact Number is required';
                                  }
                                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                                    return 'Contact Number must be numeric';
                                  }
                                  if (!value.startsWith('09')) {
                                    return 'Contact Number must start with 09';
                                  }
                                  if (value.length != vetContactLimit) {
                                    return 'Contact Number must be exactly $vetContactLimit digits';
                                  }
                                  return null;
                                },
                              ),
                              _buildAnimatedTextField(
                                controller: vetEmail,
                                labelText: "Email ",
                                maxLength: vetEmailLimit,
                                borderColor: vetEmailBorderColor,
                                onChanged: _onVetEmailChanged,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_rounded,
                                animationDelay: 300,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Email is required";
                                  }
                                  if (!value.contains("@") ||
                                      !value.contains(".")) {
                                    return "Enter a valid email address";
                                  }
                                  return null;
                                },
                              ),

                              // Password generation toggle
                              _buildPasswordToggle(),

                              // Show password fields only if manual entry is selected
                              if (!autoGeneratePassword) ...[
                                _buildAnimatedTextField(
                                  controller: vetPassword,
                                  labelText: "Password ",
                                  maxLength: vetPasswordLimit,
                                  borderColor: vetPasswordBorderColor,
                                  onChanged: _onPasswordChanged,
                                  obscureText: !isPasswordVisible,
                                  prefixIcon: Icons.lock_rounded,
                                  animationDelay: 400,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isPasswordVisible
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: const Color.fromARGB(
                                          255, 81, 115, 153),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Password is required";
                                    }
                                    if (value.length < 6) {
                                      return "Password must be at least 6 characters";
                                    }
                                    return null;
                                  },
                                ),
                                _buildAnimatedTextField(
                                  controller: vetConfirmPassword,
                                  labelText: "Confirm Password",
                                  maxLength: vetPasswordLimit,
                                  borderColor: vetConfirmPasswordBorderColor,
                                  onChanged: _onConfirmPasswordChanged,
                                  obscureText: !isConfirmPasswordVisible,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  animationDelay: 450,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isConfirmPasswordVisible
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: const Color.fromARGB(
                                          255, 81, 115, 153),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isConfirmPasswordVisible =
                                            !isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Confirm Password is required";
                                    }
                                    if (value != vetPassword.text) {
                                      return "Passwords do not match";
                                    }
                                    if (value.length < 6) {
                                      return "Password must be at least 6 characters";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ============ MAP SECTION - ADD HERE ============
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 81, 115, 153)
                                  .withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SuperAdPinMaps(
                          onLocationSelected: _onLocationSelected,
                          currentLocation: selectedClinicLocation,
                        ),
                      ),
                      // ============ END MAP SECTION ============

                      const SizedBox(height: 30),

                      // Register Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 81, 115, 153)
                                  .withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: isLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(255, 81, 115, 153),
                                      const Color.fromARGB(255, 81, 115, 153)
                                          .withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _registerClinic,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color.fromARGB(255, 81, 115, 153),
                                        const Color.fromARGB(255, 81, 115, 153)
                                            .withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.app_registration_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Register Clinic",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 40),
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

  Future<void> _registerClinic() async {
    if (!inputForm.currentState!.validate()) return;

    // Additional validation for auto-generated password
    if (autoGeneratePassword && generatedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while password is being generated'),
          backgroundColor: Colors.orange,
        ),
      );
      _generatePassword();
      return;
    }

    // NEW: Validate location selection
    if (selectedClinicLocation == null || selectedClinicLocation!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please pin the clinic location on the map before registering',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      Client client = Client()
          .setEndpoint(AppwriteConstants.endPoint)
          .setProject(AppwriteConstants.projectID);
      final account = Account(client);
      final databases = Databases(client);

      // Use generated password or manual password
      final passwordToUse =
          autoGeneratePassword ? generatedPassword! : vetPassword.text.trim();

      // Create user account
      final models.User newUser = await account.create(
        userId: ID.unique(),
        email: vetEmail.text.trim(),
        password: passwordToUse,
        name: vetName.text.trim(),
      );

      // Create clinic document
      final clinicDoc = await databases.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicsCollectionID,
        documentId: ID.unique(),
        data: {
          'clinicName': vetName.text.trim(),
          'address': vetAddress.text.trim(),
          'contact': vetContact.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
          'adminId': newUser.$id,
          'createdBy': _getStorage.read("userId") ?? "",
          'role': "admin",
          'email': vetEmail.text.trim(),
          'services': "",
          'description': "",
          'image': "",
        },
      );

      // Create default clinic settings WITH LOCATION
      final defaultSettings = ClinicSettings(
        clinicId: clinicDoc.$id,
        location: selectedClinicLocation, // NEW: Include the selected location
      );

      await databases.createDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.clinicSettingsCollectionID,
        documentId: ID.unique(),
        data: defaultSettings.toMap(),
      );

      // Send welcome email with credentials
      final emailResult = await _emailService.sendWelcomeEmail(
        clinicName: vetName.text.trim(),
        email: vetEmail.text.trim(),
        password: passwordToUse,
        adminName: vetName.text.trim(),
      );

      if (emailResult['success'] == true) {
        // Show success dialog with email notification
        Get.dialog(
          Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Clinic Registered Successfully!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The veterinary clinic has been registered with location coordinates and a welcome email with account credentials has been sent to ${vetEmail.text.trim()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 81, 115, 153),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Get.back(); // Close dialog
                        Navigator.pop(context,
                            true); // Return to previous page with success
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );
      } else {
        // Show success but email failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Clinic registered with location but failed to send email: ${emailResult['message']}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      String errorMessage = "Failed to register.";
      if (e is AppwriteException) {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
