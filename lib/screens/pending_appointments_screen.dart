import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PendingAppointmentsScreen extends StatefulWidget {
  const PendingAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<PendingAppointmentsScreen> createState() => _PendingAppointmentsScreenState();
}

class _PendingAppointmentsScreenState extends State<PendingAppointmentsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? doctorName;
  String? doctorId;
  bool isLoading = true;
  List<DocumentSnapshot> pendingAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfoAndAppointments();
  }

  Future<void> _fetchDoctorInfoAndAppointments() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        doctorName = userDoc['username'];
        doctorId = userDoc['idNumber'] ?? user.uid;
        final query = await _firestore.collection('appointments')
            .where('doctor', isEqualTo: doctorName)
            .where('status', isEqualTo: 'Pending Confirmation')
            .get();
        pendingAppointments = query.docs;
      } else {
        // Handle missing user document
        doctorName = null;
        doctorId = null;
        pendingAppointments = [];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found. Please contact admin.')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _confirmAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({'status': 'Confirmed'});
    _fetchDoctorInfoAndAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Appointments')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingAppointments.isEmpty
              ? const Center(child: Text('No pending appointments.'))
              : ListView.builder(
                  itemCount: pendingAppointments.length,
                  itemBuilder: (context, idx) {
                    final appt = pendingAppointments[idx].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        title: Text('Patient: ${appt['patient']}'),
                        subtitle: Text('Date: ${appt['date']?.toDate()?.toString().split(' ')[0] ?? ''}\nSlot: ${appt['slot']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _confirmAppointment(pendingAppointments[idx].id),
                          child: const Text('Confirm'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
