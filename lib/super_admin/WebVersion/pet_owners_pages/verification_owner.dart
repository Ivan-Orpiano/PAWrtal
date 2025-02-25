import 'package:flutter/material.dart';

class PetOwner {
  final String name;
  final bool isActive;

  PetOwner(this.name, this.isActive);
}

class VerificationOwner extends StatefulWidget {
  const VerificationOwner({super.key});

  @override
  State<VerificationOwner> createState() => _VerificationOwner();
}

class _VerificationOwner extends State<VerificationOwner> {
  bool _showVerified = true;

  final List<String> _names = [
    'Kaptitan Pangkie',
    'Kaptitan Pongk',
    'Kaptitan Phew',
    'JKaptitan Pang',
    'Kaptitan Pogo',
    'GKaptitan kalb',
    'Kaptitan Bok',
    'Kaptitan Kal',
    'Kaptitan Bo',
    'Kaptitan Pogo',
  ];
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleButton('Verified', true),
                const SizedBox(width: 8),
                _buildToggleButton('Unverified', false),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _names.length,
                itemBuilder: (context, index) {
                  return _buildOwnerTile(_names[index], _showVerified);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isVerified) {
    bool isSelected = _showVerified == isVerified;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _showVerified = isVerified;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color.fromARGB(255, 81, 115, 153)
            : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildOwnerTile(String name, bool showVerified) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundImage: AssetImage(
            'lib/images/kapitankalbot.png'), // Replace with your image
      ),
      title: Text(name),
      trailing: showVerified
          ? const Icon(Icons.check_circle,
              color: Color.fromARGB(255, 0, 54, 155))
          : null,
    );
  }
}
