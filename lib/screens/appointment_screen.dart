import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_slots_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedPatient;
  String? selectedDoctor;
  String? selectedDoctorId;
  String? visitDescription;
  DateTime? selectedDate;
  String? selectedSlot;
  String appointmentStatus = "Pending Confirmation";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> slots = ["10:00 AM", "11:00 AM", "2:00 PM"];
  bool isLoadingSlots = false;

  Future<void> _fetchSlotsForDoctor(String doctorId) async {
    setState(() => isLoadingSlots = true);
    final doc = await _firestore.collection('doctorSlots').doc(doctorId).get();
    if (doc.exists && doc['slots'] != null) {
      slots = List<String>.from(doc['slots']);
    } else {
      slots = ["10:00 AM", "11:00 AM", "2:00 PM"];
    }
    setState(() => isLoadingSlots = false);
  }

  List<Map<String, dynamic>> patientList = [];
  List<Map<String, dynamic>> doctorList = [];
  String? userType;
  String? currentDoctorName;
  String? currentDoctorId;

  @override
  void initState() {
    super.initState();
    _fetchUserTypeAndDoctors();
    _fetchPatients();
  }

  Future<void> _fetchUserTypeAndDoctors() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      userType = userDoc['userType'];
      if (userType == 'Doctor') {
        currentDoctorName = userDoc['username'] ?? user.displayName;
        currentDoctorId = userDoc['idNumber'] ?? user.uid;
        selectedDoctor = currentDoctorName;
        selectedDoctorId = currentDoctorId;
      }
    }
    // Fetch all doctors for dropdown if not doctor
    final docs = await _firestore.collection('Users').where('userType', isEqualTo: 'Doctor').get();
    doctorList = docs.docs.map((d) => {
      'name': d['username'],
      'id': d['idNumber'] ?? d.id
    }).toList();
    setState(() {});
  }

  Future<void> _fetchPatients() async {
    final docs = await _firestore.collection('patients').get();
    patientList = docs.docs.map((d) => {
      'name': d['name'],
      'id': d['idNumber'] ?? d.id
    }).toList();
    setState(() {});
  }

  Future<void> _submitAppointment() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _firestore.collection('appointments').add({
          'patient': selectedPatient,
          'doctor': selectedDoctor,
          'description': visitDescription,
          'date': selectedDate,
          'slot': selectedSlot,
          'status': appointmentStatus,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment Added Successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Add Appointment',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPatient,
                          decoration: const InputDecoration(labelText: 'Patient *'),
                          items: [
                            ...patientList.map((p) => DropdownMenuItem<String>(
                              value: p['name'],
                              child: Text('${p['name']} (${p['id']})'),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPatient = value;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a patient' : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        tooltip: 'Add New Patient',
                        onPressed: _navigateToAddPatientScreen,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: userType == 'Doctor'
                      ? TextFormField(
                          initialValue: currentDoctorName != null && currentDoctorId != null ? '$currentDoctorName ($currentDoctorId)' : '',
                          decoration: const InputDecoration(labelText: 'Doctor'),
                          enabled: false,
                        )
                      : DropdownButtonFormField<String>(
                          value: selectedDoctor,
                          decoration: const InputDecoration(labelText: 'Doctor *'),
                          items: doctorList.map<DropdownMenuItem<String>>((d) => DropdownMenuItem<String>(
                            value: d['name'],
                            child: Text('${d['name']} (${d['id']})'),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDoctor = value;
                              selectedDoctorId = doctorList.firstWhere((d) => d['name'] == value)['id'];
                            });
                            if (selectedDoctorId != null) {
                              _fetchSlotsForDoctor(selectedDoctorId!);
                            }
                          },
                          validator: (value) => value == null ? 'Please select a doctor' : null,
                        ),
                ),
              ),
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    decoration:
                    const InputDecoration(labelText: 'Visit Description'),
                    onChanged: (value) {
                      setState(() {
                        visitDescription = value;
                      });
                    },
                  ),
                ),
              ),
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date *',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    controller: TextEditingController(
                      text: selectedDate == null
                          ? ''
                          : DateFormat('yyyy-MM-dd').format(selectedDate!),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a date' : null,
                  ),
                ),
              ),
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedSlot,
                        decoration: const InputDecoration(labelText: 'Available Slots'),
                        items: slots.map((slot) {
                          return DropdownMenuItem(
                            value: slot,
                            child: Text(slot),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSlot = value;
                          });
                        },
                      ),
                      if (userType == 'Doctor')
                        Align(
                          alignment: Alignment.centerRight,
                          child: isLoadingSlots
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Manage Slots'),
                                  onPressed: isLoadingSlots
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DoctorSlotsScreen(doctorId: currentDoctorId!),
                                            ),
                                          ).then((_) => _fetchSlotsForDoctor(currentDoctorId!));
                                        },
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    value: appointmentStatus,
                    decoration: const InputDecoration(
                        labelText: 'Appointment Patient Status'),
                    items: [
                      "Pending Confirmation",
                      "Confirmed",
                    ].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        appointmentStatus = value!;
                      });
                    },
                  ),
                ),
              ),
              const Divider(),
              ElevatedButton(
                onPressed: _submitAppointment,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddPatientScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPatientScreen(
          onPatientAdded: (newPatient) {
            setState(() {
              patientList.insert(0, {'name': newPatient, 'id': ''});
              selectedPatient = newPatient;
            });
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }
}

class AddPatientScreen extends StatefulWidget {
  final Function(String) onPatientAdded;

  const AddPatientScreen({super.key, required this.onPatientAdded});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Patient Name'),
                onChanged: (value) {
                  name = value;
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Patient ID'),
                onChanged: (value) {
                  id = value;
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter an ID' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onPatientAdded(name!);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Patient'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}