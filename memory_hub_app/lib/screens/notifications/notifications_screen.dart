import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              // Mark all as read
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  index % 3 == 0 ? Icons.favorite : 
                  index % 3 == 1 ? Icons.comment : Icons.person_add,
                ),
              ),
              title: Text(
                index % 3 == 0 ? 'John liked your memory' :
                index % 3 == 1 ? 'Sarah commented on your post' :
                'Alex started following you',
              ),
              subtitle: Text('${index + 1} hours ago'),
              trailing: index % 2 == 0 ? 
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ) : null,
              onTap: () {
                // Navigate to related content
              },
            ),
          );
        },
      ),
    );
  }
}
