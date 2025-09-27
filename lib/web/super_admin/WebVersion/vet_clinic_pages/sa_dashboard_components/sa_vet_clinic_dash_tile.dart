import 'package:flutter/material.dart';

class SuperAdminVetClinicTile extends StatelessWidget {
  const SuperAdminVetClinicTile({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InkWell(
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(227, 242, 253, 1),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 1,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.all(10),
            padding:
                const EdgeInsets.only(top: 15, left: 5, right: 5, bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    'lib/images/test_image.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: constraints.maxWidth > 400 ? 230 : 180,
                  ),
                )),
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 10, bottom: 5),
                  child: Text(
                    "Qualipaws",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: constraints.maxWidth > 400 ? 24 : 20,
                      color: const Color.fromARGB(255, 81, 115, 153),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 5),
                  child: Text(
                    "diyan lang sa gilid",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: constraints.maxWidth > 400 ? 16 : 14,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 3),
                      child: Icon(Icons.house_outlined,
                          size: constraints.maxWidth > 400 ? 24 : 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text("4 Rooms",
                          style: TextStyle(
                              fontSize: constraints.maxWidth > 400 ? 14 : 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(Icons.medical_services,
                          size: constraints.maxWidth > 400 ? 24 : 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text("1 Veterinarian",
                          style: TextStyle(
                              fontSize: constraints.maxWidth > 400 ? 14 : 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(Icons.star,
                          color: Colors.yellow,
                          size: constraints.maxWidth > 400 ? 24 : 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text("5.0",
                          style: TextStyle(
                              fontSize: constraints.maxWidth > 400 ? 14 : 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
