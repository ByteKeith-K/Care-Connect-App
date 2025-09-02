import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorSlotsScreen extends StatefulWidget {
  final String? doctorId;
  const DoctorSlotsScreen({Key? key, this.doctorId}) : super(key: key);

  @override
  State<DoctorSlotsScreen> createState() => _DoctorSlotsScreenState();
}

class _DoctorSlotsScreenState extends State<DoctorSlotsScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> slots = [];
  final _slotController = TextEditingController();
  bool isLoading = false;
  String? _resolvedDoctorId;

  @override
  void initState() {
    super.initState();
    _resolveDoctorIdAndFetchSlots();
  }

  Future<void> _resolveDoctorIdAndFetchSlots() async {
    setState(() => isLoading = true);
    String? doctorId = widget.doctorId;
    final user = FirebaseAuth.instance.currentUser;
    if (doctorId == null) {
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        if (userDoc.exists) {
          doctorId = userDoc['idNumber'] ?? user.uid;
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile not found. Please contact admin.')),
          );
          return;
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logged-in user. Please sign in.')),
        );
        return;
      }
    }
    _resolvedDoctorId = doctorId;
    await _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    if (_resolvedDoctorId == null) {
      setState(() => isLoading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('doctorSlots').doc(_resolvedDoctorId).get();
    if (doc.exists && doc['slots'] != null) {
      slots = List<String>.from(doc['slots']);
    } else {
      slots = ["10:00 AM", "11:00 AM", "2:00 PM"];
    }
    setState(() => isLoading = false);
  }

  Future<void> _saveSlots() async {
    if (slots.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 6 slots allowed.')));
      return;
    }
    if (_resolvedDoctorId == null) return;
    await FirebaseFirestore.instance.collection('doctorSlots').doc(_resolvedDoctorId).set({'slots': slots});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slots saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Slots')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _slotController,
                            decoration: const InputDecoration(labelText: 'Add Slot (e.g. 3:00 PM)'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (_slotController.text.isNotEmpty && slots.length < 6) {
                              setState(() {
                                slots.add(_slotController.text);
                                _slotController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: slots.length,
                      itemBuilder: (context, idx) => ListTile(
                        title: Text(slots[idx]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              slots.removeAt(idx);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveSlots,
                    child: const Text('Save Slots'),
                  ),
                ],
              ),
            ),
    );
  }
}
