import 'package:flutter/material.dart';
import 'dart:ui';

class VetPopup extends StatelessWidget {
  final Map<String, dynamic> data;

  const VetPopup({super.key, required this.data});

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "open":
        return Colors.green;
      case "closed":
        return Colors.red;
      case "full":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = data["name"];
    final String description =
        data["description"] ?? "No description available.";
    final String image = data["image"] ?? "lib/images/default.jpg";
    final String status = data["status"] ?? "Unknown";

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: 250,
        child: Card(
          color: const Color.fromARGB(255, 39, 86, 139),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          elevation: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: SizedBox(
                  width: 250,
                  height: 150,
                  child: Image.asset(
                    image,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 75.0, sigmaY: 75.0),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 170,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(50, 71, 161, 196),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 250,
                      padding: const EdgeInsets.all(10),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatusColor(status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(description,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black),
                                maxLines: 2),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("More Info Clicked!")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 201, 221, 238),
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              child: const Text("More Info"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
