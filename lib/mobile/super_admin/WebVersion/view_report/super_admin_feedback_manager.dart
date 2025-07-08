import 'package:flutter/material.dart';

void main() {
  runApp(const VetClinicFeedbackApp());
}

class VetClinicFeedbackApp extends StatelessWidget {
  // const VetClinicFeedbackApp({Key? key}) : super(key: key);
  const VetClinicFeedbackApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vet Clinic Feedback Manager',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color.fromRGBO(248, 253, 255, 0.2),
      ),
      home: const VetClinicFeedbackManager(),
    );
  }
}

class VetClinicFeedbackManager extends StatefulWidget {
  const VetClinicFeedbackManager({super.key});

  @override
  State<VetClinicFeedbackManager> createState() =>
      _VetClinicFeedbackManagerState();
}

class _VetClinicFeedbackManagerState extends State<VetClinicFeedbackManager> {
  final List<Map<String, String>> allFeedback = [
    {
      'clinic': 'Happy Paws Vet Clinic',
      'user': 'Alice Johnson',
      'feedback': 'Amazing service and friendly staff!',
      'email': 'alice@example.com',
    },
    {
      'clinic': 'PetCare Animal Clinic',
      'user': 'Bob Smith',
      'feedback': 'Waiting time is too long.',
      'email': 'bob@example.com',
    },
  ];

  List<Map<String, String>> deleteRequests = [];

  String searchQuery = '';

  void _handleDeleteRequest(Map<String, String> feedback) {
    if (!deleteRequests.contains(feedback)) {
      setState(() {
        deleteRequests.add(feedback);
      });
    }
  }

  void _handleApprove(Map<String, String> feedback) {
    setState(() {
      allFeedback.remove(feedback);
      deleteRequests.remove(feedback);
    });
  }

  void _handleReject(Map<String, String> feedback) {
    setState(() {
      deleteRequests.remove(feedback);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filtered = allFeedback
        .where((f) =>
            f['clinic']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(248, 253, 255, 0.8),
        title: const Text('View Reports'),
      ),
      body: Row(
        children: [
          // Left: Feedback and Search
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search vet clinic...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final feedback = filtered[index];
                      return FeedbackCard(
                        feedback: feedback,
                        onRequestDelete: () => _handleDeleteRequest(feedback),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right: Notifications panel
          Expanded(
            flex: 1,
            child: NotificationPanel(
              requests: deleteRequests,
              onApprove: _handleApprove,
              onReject: _handleReject,
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackCard extends StatefulWidget {
  final Map<String, String> feedback;
  final VoidCallback onRequestDelete;

  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.onRequestDelete,
  });

  @override
  State<FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<FeedbackCard> {
  void _viewDetails() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Feedback from ${widget.feedback['user']}'),
        content: Text(
          'Clinic: ${widget.feedback['clinic']}\n'
          'Email: ${widget.feedback['email']}\n\n'
          'Feedback:\n${widget.feedback['feedback']}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 4,
      child: ListTile(
        title: Text(widget.feedback['clinic']!,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.feedback['feedback']!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'View',
              icon: const Icon(Icons.visibility, color: Colors.teal),
              onPressed: _viewDetails,
            ),
            IconButton(
              tooltip: 'Request Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: widget.onRequestDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationPanel extends StatelessWidget {
  final List<Map<String, String>> requests;
  final Function(Map<String, String>) onApprove;
  final Function(Map<String, String>) onReject;

  const NotificationPanel({
    super.key,
    required this.requests,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(248, 253, 255, 1),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delete Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: requests.isEmpty
                ? const Center(child: Text('No requests'))
                : ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return Card(
                        child: ListTile(
                          title: Text(request['clinic']!),
                          subtitle:
                              Text('Requested by: ${request['user'] ?? ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Approve',
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                onPressed: () => onApprove(request),
                              ),
                              IconButton(
                                tooltip: 'Reject',
                                icon: const Icon(Icons.cancel,
                                    color: Colors.redAccent),
                                onPressed: () => onReject(request),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
