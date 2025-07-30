import 'package:capstone_app/web/user_web/desktop_web/pages/web_messages_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WebTabletMessagesPage extends StatefulWidget {
  const WebTabletMessagesPage({super.key});

  @override
  State<WebTabletMessagesPage> createState() => _WebTabletMessagesPageState();
}

class _WebTabletMessagesPageState extends State<WebTabletMessagesPage> {

  bool _showRightPanel = false;

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
          Expanded(
            child: _showRightPanel 
            ? Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
              child:  RightPanel(onToggleRightPanel: toggleRightPanel),
            ) 
            : Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
              child: MiddlePanel(onToggleRightPanel: toggleRightPanel),
            ),
          ) 
        ],
      ),
    );
  }
} 

class RightPanel extends StatefulWidget {
  final VoidCallback onToggleRightPanel;

  const RightPanel({
    super.key,
    required this.onToggleRightPanel
  });

  @override
  State<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<RightPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.sidebar_left),
                  onPressed: () {
                    widget.onToggleRightPanel();
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}