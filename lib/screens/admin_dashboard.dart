import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> notifications = [];

  bool isUserDropdownOpen = false;
  bool isPatientDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    FirebaseFirestore.instance
        .collection('adminNotifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        notifications = snapshot.docs.map((doc) => {
          'message': doc['message'] as String? ?? '',
          'timestamp': doc['timestamp']
        }).where((n) => (n['message'] as String).isNotEmpty).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade700,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.amber, size: 30),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Notifications'),
                      content: SizedBox(
                        width: 300,
                        child: ListView(
                          shrinkWrap: true,
                          children: notifications
                              .map((n) => ListTile(
                                    leading: const Icon(Icons.security, color: Colors.red),
                                    title: Text(n['message'] ?? ''),
                                    subtitle: n['timestamp'] != null && n['timestamp'] is Timestamp
                                        ? Text((n['timestamp'] as Timestamp).toDate().toString())
                                        : null,
                                  ))
                              .toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (notifications.isNotEmpty)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${notifications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.indigo.shade700,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                color: Colors.indigo.shade800,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 36, color: Colors.indigo),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Tsele', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('admin@careconnect.app', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 8),
                      ExpansionTile(
                        title: const Text('User Management', style: TextStyle(color: Colors.indigo)),
                        leading: const Icon(Icons.people, color: Colors.indigo),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_add, color: Colors.indigo),
                            title: const Text('Add User'),
                            onTap: () {
                              Navigator.pushNamed(context, '/add_user');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.edit, color: Colors.indigo),
                            title: const Text('Update User'),
                            onTap: () {
                              Navigator.pushNamed(context, '/update_user');
                            },
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: const Text('Patient Registration', style: TextStyle(color: Colors.indigo)),
                        leading: const Icon(Icons.person, color: Colors.indigo),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_document, color: Colors.indigo),
                            title: const Text('Edit Patient'),
                            onTap: () {
                              Navigator.pushNamed(context, '/edit_patient');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.red, size: 32),
                const SizedBox(width: 10),
                Text('Security Alerts', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) => Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.security, color: Colors.red, size: 28),
                    title: Text(
                      notifications[index]['message'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    subtitle: notifications[index]['timestamp'] != null && notifications[index]['timestamp'] is Timestamp
                        ? Text((notifications[index]['timestamp'] as Timestamp).toDate().toString())
                        : null,
                    tileColor: Colors.indigo.shade50,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
