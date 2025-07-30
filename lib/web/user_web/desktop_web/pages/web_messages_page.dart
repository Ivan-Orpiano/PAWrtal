import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WebMessagesPage extends StatefulWidget {
  const WebMessagesPage({super.key});

  @override
  State<WebMessagesPage> createState() => _MessagesWebPageState();
}

class _MessagesWebPageState extends State<WebMessagesPage> {
  bool _showRightPanel = true;

  void toggleRightPanel (){
    setState(() {
      _showRightPanel = !_showRightPanel;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: Row(
        children: [
          //put condition if dekstopBody width 350, if tablet body be expanded with flex of 3? or 2?
          const SizedBox(
            width: 350,
            child: LeftPanel()
          ),
          Flexible(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, right: 8, bottom: 16),
              child: MiddlePanel(
                onToggleRightPanel: toggleRightPanel,
              ),
            )
          ),
          if (_showRightPanel)
          const Flexible(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(left: 8, top: 16, right: 16, bottom: 16),
              child: RightPanel(),
            )
          )
        ],
      ),
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
                return MessageTile(
                  isSelected: selectedIndex == index,
                  onTap: () {
                    setState(() {
                    if (selectedIndex == index) {
                      selectedIndex = null;
                    } else {
                      selectedIndex = index;
                    }
                    });
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class MessageTile extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const MessageTile({
    super.key, 
    required this.isSelected,
    required this.onTap
  });

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {

  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    Color currentColor;

    if (widget.isSelected) {
      currentColor = Colors.blue.shade200; // color when tapped
    } else if (isHovered) {
      currentColor = Colors.grey.shade200; // color when hovered
    } else {
      currentColor = Colors.white; // default color
    }

    return InkWell(
      onTap: widget.onTap,
      onHover: (hovering){
        setState(() {
          isHovered = hovering;
        });
      },
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset("lib/images/pfp.jpg"),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Name ng fyne shyt"
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Last message ng fine shyt"
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

class WebMessagesSearchBar extends StatefulWidget {
  const WebMessagesSearchBar({super.key});

  @override
  State<WebMessagesSearchBar> createState() => _WebMessagesSearchBarState();
}

class _WebMessagesSearchBarState extends State<WebMessagesSearchBar> {

  final TextEditingController _controller = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _showClear = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        onTap: () {
          setState(() {
            _showClear = _controller.text.isNotEmpty;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: const TextStyle(
            fontSize: 14
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1.5
            )
          ),
          suffixIcon: _showClear 
          ? IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _controller.clear();
              setState(() {
                _showClear = false;
              });
            },
          )
          : const Icon(Icons.search_rounded)
        )
      ),
    );
  }
}

class MiddlePanel extends StatefulWidget {
  final VoidCallback onToggleRightPanel;

  const MiddlePanel({
    super.key, 
    required this.onToggleRightPanel
  });

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset("lib/images/pfp.jpg"),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Name ng fine shyt",
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
                        widget.onToggleRightPanel();
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          //dito yung messages
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

class TypeMessageHere extends StatefulWidget {
  const TypeMessageHere({super.key});

  @override
  State<TypeMessageHere> createState() => _TypeMessageHereState();
}

class _TypeMessageHereState extends State<TypeMessageHere> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Aa',
            hintStyle: const TextStyle(
              fontSize: 14
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1.5
              )
            ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.emoji_emotions_rounded),
            onPressed: () {},
          )
          )
        ),
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
    );
  }
}
