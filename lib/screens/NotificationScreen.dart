import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text('Notifications', style: TextStyle(fontSize: 22, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {
                // Help button action
              },
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFF1C1C1E),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('notifications').where('status', isEqualTo: 'sent').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent, // Matches the given color reference
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications available.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          var notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(10.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index].data() as Map<String, dynamic>;
              String title = notification['title'] ?? 'No Title';
              String body = notification['body'] ?? 'No Content';
              DateTime? timestamp = (notification['timestamp'] as Timestamp?)?.toDate();

              return Card(
                color: Color(0xFF2C2C2E), // Dark card color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.0),
                      Text(
                        body,
                        style: TextStyle(color: Colors.white70),
                      ),
                      if (timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Received: ${DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)}",
                            style: TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onTap: () {
                    // Add action for notification tap if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
