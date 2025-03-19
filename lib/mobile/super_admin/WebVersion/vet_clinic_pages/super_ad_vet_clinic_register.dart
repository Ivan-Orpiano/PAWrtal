import 'package:flutter/material.dart';

class VetClinicRegister extends StatefulWidget {
  const VetClinicRegister({super.key});

  @override
  State<VetClinicRegister> createState() => _VetClinicRegisterState();
}

class _VetClinicRegisterState extends State<VetClinicRegister> {

  final GlobalKey<FormState> inputForm = GlobalKey<FormState>();

  final TextEditingController vetName = TextEditingController();
  final TextEditingController vetLocation = TextEditingController();
  final TextEditingController vetEmail = TextEditingController();
  final TextEditingController vetPassword = TextEditingController();

  final int vetNameLimit = 59;
  final int vetLocationLimit = 19;
  final int vetEmailLimit = 29;
  final int vetPasswordLimit = 14;

  Color vetNameBorderColor = Colors.grey;
  Color vetLocationBorderColor = Colors.grey;
  Color vetEmailBorderColor = Colors.grey;
  Color vetPasswordBorderColor = Colors.grey;

  void _onVetNameChanged(String value) {
    setState(() {
      vetNameBorderColor = value.length > vetNameLimit ? Colors.orange : Colors.grey;
    });
  }
  void _onVetLocationChanged(String value) {
    setState(() {
      vetLocationBorderColor = value.length > vetLocationLimit ? Colors.orange : Colors.grey;
    });
  }
  void _onVetEmailChanged(String value) {
    setState(() {
      vetEmailBorderColor = value.length > vetEmailLimit ? Colors.orange : Colors.grey;
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
                    TextField(
                      controller: vetName,
                      maxLength: vetNameLimit + 1,
                      obscureText: true,
                      onChanged: _onVetNameChanged,
                      decoration: InputDecoration(
                        labelText: "Veterinay Name: *",
                        border: OutlineInputBorder(borderSide: BorderSide(color: vetNameBorderColor)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: vetNameBorderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: vetNameBorderColor, width: 2)),
                      ),
                    ),

                    TextField(
                      controller: vetLocation,
                      maxLength: vetLocationLimit + 1,
                      obscureText: true,
                      onChanged: _onVetLocationChanged,
                      decoration: InputDecoration(
                        labelText: "Location: *",
                        border: OutlineInputBorder(borderSide: BorderSide(color: vetLocationBorderColor)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: vetLocationBorderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: vetLocationBorderColor, width: 2)),
                      ),
                    ),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      controller: vetEmail,
                      maxLength: vetEmailLimit + 1,
                      obscureText: true,
                      onChanged: _onVetEmailChanged,
                      decoration: InputDecoration(
                        labelText: "Email: *",
                        border: OutlineInputBorder(borderSide: BorderSide(color: vetEmailBorderColor)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: vetEmailBorderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: vetEmailBorderColor, width: 2)),
                      ),
                    ),
                    
                    TextField(
                      controller: vetPassword,
                      maxLength: vetPasswordLimit + 1,
                      obscureText: true,
                      onChanged: _onPasswordChanged,
                      decoration: InputDecoration(
                        labelText: "Password: *",
                        border: OutlineInputBorder(borderSide: BorderSide(color: vetPasswordBorderColor)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: vetPasswordBorderColor)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: vetPasswordBorderColor, width: 2))                        
                      ),
                    ),
                    // buildTextField("Veterinary Name *" ),
                    // buildTextField("Location *"),
                    // buildTextField("Email *",
                    //     keyboardType: TextInputType.emailAddress),
                    // buildTextField("Password *", adminPassword: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (inputForm.currentState!.validate()) {
                      //connect ba database dito?

                    }
                  },
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

  Widget buildTextField(String label,
      { bool adminPassword = false,
      TextInputType keyboardType = TextInputType.text}) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        obscureText: adminPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }
}
