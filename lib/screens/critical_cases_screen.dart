import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/critical_case_reminder_service.dart';

class CriticalCasesScreen extends StatefulWidget {
  const CriticalCasesScreen({Key? key}) : super(key: key);

  @override
  State<CriticalCasesScreen> createState() => _CriticalCasesScreenState();
}

class _CriticalCasesScreenState extends State<CriticalCasesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _currentDoctorName;
  bool _loading = true;
  List<Map<String, dynamic>> _criticalCases = [];

  @override
  void initState() {
    super.initState();
    CriticalCaseReminderService().init(context);
    _fetchDoctorNameAndCases();
  }

  Future<void> _fetchDoctorNameAndCases() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      _currentDoctorName = userDoc['username'] ?? user.displayName;
      await _fetchCriticalCases();
    }
  }

  Future<void> _fetchCriticalCases() async {
    if (_currentDoctorName == null) return;
    final query = await _firestore
        .collection('criticalCases')
        .where('doctor', isEqualTo: _currentDoctorName)
        .get();
    setState(() {
      _criticalCases = query.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      _loading = false;
    });
  }

  Future<void> _addCriticalCase(String patientId, String patientName) async {
    if (_currentDoctorName == null) return;
    await _firestore.collection('criticalCases').add({
      'doctor': _currentDoctorName,
      'patientId': patientId,
      'patientName': patientName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _fetchCriticalCases();
  }

  Future<void> _deleteCriticalCase(String caseId) async {
    await _firestore.collection('criticalCases').doc(caseId).delete();
    await _fetchCriticalCases();
  }

  void _showAddDialog() async {
    String? selectedPatientId;
    String? selectedPatientName;
    final patients = await _firestore.collection('patients').get();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mark Patient as Critical'),
          content: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Select Patient'),
            items: patients.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text('${data['name'] ?? doc.id}'),
              );
            }).toList(),
            onChanged: (val) {
              selectedPatientId = val;
              selectedPatientName = patients.docs.firstWhere((d) => d.id == val).data()['name'];
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedPatientId != null && selectedPatientName != null) {
                  await _addCriticalCase(selectedPatientId!, selectedPatientName!);
                  Navigator.pop(context);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Critical Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Add Critical Case',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _criticalCases.isEmpty
              ? const Center(child: Text('No critical cases.'))
              : ListView.builder(
                  itemCount: _criticalCases.length,
                  itemBuilder: (context, idx) {
                    final c = _criticalCases[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(c['patientName'] ?? c['patientId'] ?? ''),
                        subtitle: Text('Patient ID: ${c['patientId']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCriticalCase(c['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
