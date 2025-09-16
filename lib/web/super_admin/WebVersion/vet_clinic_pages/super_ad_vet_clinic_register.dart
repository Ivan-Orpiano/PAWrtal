import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get_storage/get_storage.dart';

class VetClinicRegister extends StatefulWidget {
  const VetClinicRegister({super.key});

  @override
  State<VetClinicRegister> createState() => _VetClinicRegisterState();
}

class _VetClinicRegisterState extends State<VetClinicRegister> {
  final GetStorage _getStorage = GetStorage();

  final GlobalKey<FormState> inputForm = GlobalKey<FormState>();

  final TextEditingController vetName = TextEditingController();
  final TextEditingController vetAddress = TextEditingController();
  final TextEditingController vetContact = TextEditingController();
  final TextEditingController vetEmail = TextEditingController();
  final TextEditingController vetPassword = TextEditingController();

  final int vetNameLimit = 69;
  final int vetAddressLimit = 39;
  final int vetContactLimit = 11;
  final int vetEmailLimit = 29;
  final int vetPasswordLimit = 19;

  Color vetNameBorderColor = Colors.grey;
  Color vetAddressBorderColor = Colors.grey;
  Color vetContactBorderColor = Colors.grey;
  Color vetEmailBorderColor = Colors.grey;
  Color vetPasswordBorderColor = Colors.grey;

  bool isLoading = false;
  bool isPasswordVisible = false;

  void _onVetNameChanged(String value) {
    setState(() {
      vetNameBorderColor =
          value.length > vetNameLimit ? Colors.orange : Colors.grey;
    });
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
          value.length > vetContactLimit ? Colors.orange : Colors.grey;
    });
  }

  void _onVetEmailChanged(String value) {
    setState(() {
      vetEmailBorderColor =
          value.length > vetEmailLimit ? Colors.orange : Colors.grey;
    });
  }

  void _onPasswordChanged(String value) {
    setState(() {
      vetPasswordBorderColor =
          value.length > vetPasswordLimit ? Colors.orange : Colors.grey;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 81, 115, 153),
          ),
          onPressed: () {
            // Navigate back to MenuPage
            Navigator.pop(context);
          },
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1,
        flexibleSpace: Container(
          margin: const EdgeInsets.only(top: 15.0),
          child: Center(
            child: Image.asset(
              "lib/images/PAWrtal_logo.png",
              height: screenHeight * 0.08,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Veterinary Registration",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Form(
                key: inputForm,
                child: Column(
                  children: [
                    TextFormField(
                      controller: vetName,
                      maxLength: vetNameLimit + 1,
                      obscureText: false,
                      onChanged: _onVetNameChanged,
                      decoration: InputDecoration(
                        labelText: "Veterinary Name: *",
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: vetNameBorderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: vetNameBorderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: vetNameBorderColor, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Veterinary Name is required.";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: vetAddress,
                      maxLength: vetAddressLimit + 1,
                      obscureText: false,
                      onChanged: _onVetAddressChanged,
                      decoration: InputDecoration(
                        labelText: "Address: *",
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: vetAddressBorderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: vetAddressBorderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: vetAddressBorderColor, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Address is required.";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: vetContact,
                      maxLength: vetContactLimit + 1,
                      obscureText: false,
                      keyboardType: TextInputType.number,
                      onChanged: _onVetContactChanged,
                      decoration: InputDecoration(
                        labelText: "Contact Number: *",
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: vetContactBorderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: vetContactBorderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: vetContactBorderColor, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contact Number is required';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'Contact Number must be numeric';
                        }
                        if (value.length != vetContactLimit) {
                          return 'Contact Number must be exactly $vetContactLimit digits';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: vetEmail,
                      maxLength: vetEmailLimit + 1,
                      obscureText: false,
                      onChanged: _onVetEmailChanged,
                      decoration: InputDecoration(
                        labelText: "Email: *",
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: vetEmailBorderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: vetEmailBorderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: vetEmailBorderColor, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Email is required";
                        }
                        if (!value.contains("@") || !value.contains(".")) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: vetPassword,
                      maxLength: vetPasswordLimit,
                      obscureText: !isPasswordVisible,
                      onChanged: _onPasswordChanged,
                      decoration: InputDecoration(
                        labelText: "Password: *",
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: vetPasswordBorderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: vetPasswordBorderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: vetPasswordBorderColor, width: 2)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
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
                  ],
                ),
              ), // buildTextField("Veterinary Name *" ),
              // buildTextField("Address *"),
              // buildTextField("Email *",
              //     keyboardType: TextInputType.emailAddress),
              // buildTextField("Password *", adminPassword: true),
              const SizedBox(height: 30),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 81, 115, 153),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _registerClinic,
                        child: const Text(
                          "Register",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerClinic() async {
    if (!inputForm.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      Client client = Client()
          .setEndpoint(AppwriteConstants.endPoint)
          .setProject(AppwriteConstants.projectID);
      final account = Account(client);
      final databases = Databases(client);

      final models.User newUser = await account.create(
        userId: ID.unique(),
        email: vetEmail.text.trim(),
        password: vetPassword.text.trim(),
        name: vetName.text.trim(),
      );

      await databases.createDocument(
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veterinary Admin created successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      String errorMessage = "Failed to register.";
      if (e is AppwriteException) {
        errorMessage = e.message ?? errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
