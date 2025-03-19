import 'package:capstone_app/mobile/admin/components/message_tile.dart';
import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MessagesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 75, bottom: 50),
            child: Text(
              "Messages",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 17),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                )),
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: Row(
                    children: [
                      Flexible(
                          child: TextField(
                        cursorColor: Colors.grey,
                        decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: BorderSide.none),
                            hintText: 'Search',
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            prefixIcon: Container(
                              width: 70,
                              height: 70,
                              padding: const EdgeInsets.all(15),
                              child: const Image(
                                image: AssetImage('lib/images/search_icon.jpg'),
                                color: Colors.grey,
                              ),
                            )),
                      )),
                    ],
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 30, right: 30, bottom: 240),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                          MessageTile(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
