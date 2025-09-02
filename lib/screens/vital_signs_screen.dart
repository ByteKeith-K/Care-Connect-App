import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_registration_screen.dart'; // Import the PatientRegistrationScreen

class VitalSignsScreen extends StatefulWidget {
  const VitalSignsScreen({super.key});

  @override
  State<VitalSignsScreen> createState() => _VitalSignsScreenState();
}

class _VitalSignsScreenState extends State<VitalSignsScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final heartRateController = TextEditingController();
  final systolicBPController = TextEditingController();
  final diastolicBPController = TextEditingController();
  final temperatureController = TextEditingController();
  final oxygenSaturationController = TextEditingController();
  final respiratoryRateController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  String? selectedPatientId;
  List<String> patientIds = ["101", "102", "103", "104"];

  void _handleNewPatientSelection() {
    setState(() {
      selectedPatientId = "New";
    });
    heartRateController.clear();
    systolicBPController.clear();
    diastolicBPController.clear();
    temperatureController.clear();
    oxygenSaturationController.clear();
    respiratoryRateController.clear();
    weightController.clear();
    heightController.clear();
  }
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && selectedPatientId != null) {
      try {
        await _firestore.collection('vitalSigns').add({
          'patientId': selectedPatientId,
          'systolicBP': systolicBPController.text,
          'diastolicBP': diastolicBPController.text,
          'heartRate': heartRateController.text,
          'temperature': temperatureController.text,
          'oxygenSaturation': oxygenSaturationController.text,
          'respiratoryRate': respiratoryRateController.text,
          'weight': weightController.text,
          'height': heightController.text,
          'recordedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vital signs recorded successfully')),
        );

        _formKey.currentState!.reset();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording vitals: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vital Signs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ===== [START MODIFIED CODE] =====
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('patients').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final patients = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: selectedPatientId,
                    decoration: const InputDecoration(labelText: 'Select Patient'),
                    items: [
                      ...patients.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text('${data['name']} (${doc.id})'),
                        );
                      }),
                      const DropdownMenuItem(
                        value: "New",
                        child: Text('New Patient'),
                      )
                    ],
                    onChanged: (value) async {
                      if (value == "New") {
                        // Navigate to patient registration, then refresh patients list
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientRegistrationScreen(),
                          ),
                        );
                        if (result == null) {
                          // After registration, refresh the patient list and let user select the new patient manually
                          setState(() {
                            selectedPatientId = null;
                          });
                        } else if (result is String) {
                          setState(() {
                            selectedPatientId = result;
                          });
                        }
                      } else {
                        setState(() => selectedPatientId = value);
                      }
                    },
                    validator: (value) =>
                    value == null ? 'Please select a patient' : null,
                  );
                },
              ),
              TextFormField(
                controller: systolicBPController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Systolic Blood Pressure (mmHg)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter systolic blood pressure';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: diastolicBPController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Diastolic Blood Pressure (mmHg)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter diastolic blood pressure';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: heartRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Heart Rate (bpm)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter heart rate';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: temperatureController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Temperature (°C)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter temperature';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: oxygenSaturationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Oxygen Saturation (%)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter oxygen saturation';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: respiratoryRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Respiratory Rate (breaths/min)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter respiratory rate';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (Kg)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height (Cm)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter height';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}