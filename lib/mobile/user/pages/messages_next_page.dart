import 'package:flutter/material.dart';

class MessagesNextPage extends StatefulWidget {
  const MessagesNextPage({super.key});

  @override
  State<MessagesNextPage> createState() => _MessagesNextPageState();
}

class _MessagesNextPageState extends State<MessagesNextPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_left_rounded,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    "lib/images/pfp.jpg",
                    height: 45,
                    width: 45,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                const Text(
                  "Qualipaws"
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.call_rounded,
                  size: 30,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: 30,  
                ),
                onPressed: () {},
              )
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20 / 2
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.blue.shade200,
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Icon(
                    Icons.photo,
                    color: Colors.blue.shade200,
                  ),
                  const SizedBox( 
                    width: 20,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20 * 0.75
                      ),
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.grey.shade200,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Message",
                                border: InputBorder.none
                              ),
                            ),
                          ),
                          Icon(
                            Icons.sentiment_satisfied_alt_rounded,
                            color: Colors.blue.shade200,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.send_rounded,
                    color: Colors.blue.shade200,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}