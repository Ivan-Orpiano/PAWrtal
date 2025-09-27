import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_messages_page.dart';

class WebMobileMessagesPage extends StatefulWidget {
  const WebMobileMessagesPage({super.key});

  @override
  State<WebMobileMessagesPage> createState() => _WebMobileMessagesPageState();
}

class _WebMobileMessagesPageState extends State<WebMobileMessagesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeftPanel()
    );
  }
}

class LeftPanel extends StatefulWidget {
  const LeftPanel({super.key});

  @override
  State<LeftPanel> createState() => _LeftSidePanelState();
}

class _LeftSidePanelState extends State<LeftPanel> {

  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "Messages",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: WebMessagesSearchBar(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return MessageTile();
              },
            ),
          )
        ],
      ),
    );
  }
}

class MessageTile extends StatefulWidget {

  const MessageTile({super.key});

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MiddlePanel(),
          )
        );
      },
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset("lib/images/test_image.jpg", fit: BoxFit.fitHeight,),
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Name"
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Latest message"
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MiddlePanel extends StatefulWidget {
  const MiddlePanel({super.key});

  @override
  State<MiddlePanel> createState() => _MiddlePanelState();
}

class _MiddlePanelState extends State<MiddlePanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10)
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            height: 70,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  offset: const Offset(0, 0.5),
                  blurRadius: 1,
                )
              ]
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_left_rounded),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset("lib/images/pfp.jpg"),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Name ng fine shyt",
                  style: TextStyle(
                    fontSize: 14
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk_rounded),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.sidebar_right),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RightPanel(),
                          )
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          //dito yung messages, lagay bagong widget sa web_messages_page.dart para iisang code lang 
          Expanded(
            child: Container(
              height: 707,
            ),
          ),
          Container(
            height: 64,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded),
                  onPressed: () {},
                ),
                const Expanded(
                  child: TypeMessageHere()
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () {},
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RightPanel extends StatefulWidget {
  const RightPanel({super.key});

  @override
  State<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<RightPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10)
      ),
      child: IconButton(
        color: Colors.white,
        icon: const Icon(Icons.arrow_left_rounded),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}