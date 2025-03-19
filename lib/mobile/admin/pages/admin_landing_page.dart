import 'package:flutter/material.dart';

class AdminLandingPage extends StatefulWidget {
  const AdminLandingPage({super.key});

  @override
  State<AdminLandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<AdminLandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:
            Image.asset('lib/images/PAWrtal_logo.png', width: 200, height: 200),
        elevation: 0,
      ),
      drawer: const Drawer(
        backgroundColor: Color.fromARGB(255, 96, 139, 193),
        child: Column(
          children: [],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5),
        child: ListView(
          children: const [
            Image(
              image: AssetImage('lib/images/test_image.jpg'),
              width: 300,
              height: 300,
            ),
            Text(
              'Veterinary Clinic',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color.fromARGB(255, 81, 115, 153)),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
                'Lorem ipsum odor amet, consectetuer adipiscing elit. Consectetur aliquam natoque phasellus praesent sollicitudin mattis nulla.'),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Image(image: AssetImage('lib/images/dogimage.jpg')),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Text('Ratings and Reviews',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Text("don't know what to do"),
          ],
        ),
      ),
    );
  }
}
