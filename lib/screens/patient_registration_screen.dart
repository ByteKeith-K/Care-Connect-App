import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});
  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for text fields
  final _nameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalAidNameController = TextEditingController();
  final _medicalAidNumberController = TextEditingController();
  final _medicalAidSuffixController = TextEditingController();
  final _medicalAidMainMemberController = TextEditingController();
  final _nextOfKinNameController = TextEditingController();
  final _nextOfKinContactController = TextEditingController();

  String? _selectedGender;
  bool hasMedicalAid = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _medicalAidNameController.dispose();
    _medicalAidNumberController.dispose();
    _medicalAidSuffixController.dispose();
    _medicalAidMainMemberController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinContactController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final notificationsRef = _firestore.collection('adminNotifications');
    try {
      final docRef = await _firestore.collection('patients').add({
        'name': _nameController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'medicalHistory': _medicalHistoryController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'nextOfKin': {
          'name': _nextOfKinNameController.text.trim(),
          'contact': _nextOfKinContactController.text.trim(),
        },
        'hasMedicalAid': hasMedicalAid,
        'medicalAidName': hasMedicalAid ? _medicalAidNameController.text.trim() : null,
        'medicalAidNumber': hasMedicalAid ? _medicalAidNumberController.text.trim() : null,
        'medicalAidSuffix': hasMedicalAid ? _medicalAidSuffixController.text.trim() : null,
        'medicalAidMainMember': hasMedicalAid ? _medicalAidMainMemberController.text.trim() : null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Notify admin of new patient registration
      await notificationsRef.add({
        'type': 'patient_registered',
        'message': 'New patient registered: ${_nameController.text.trim()} (ID: ${_idNumberController.text.trim()})',
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient registered successfully!')),
      );
      Navigator.pop(context, docRef.id); // Return the new patient ID
      // Reset form
      _formKey.currentState?.reset();
      setState(() {
        _selectedGender = null;
        hasMedicalAid = false;
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firebase Error: \\${e.message}')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \\${e}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Registration'),
        backgroundColor: Colors.indigo.shade500,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Register a New Patient',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter full name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(
                      labelText: 'ID Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter ID number' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Please select gender' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter contact number' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter address' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _medicalHistoryController,
                    decoration: const InputDecoration(
                      labelText: 'Medical History (if any)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(
                      labelText: 'Allergies (if any)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Next of Kin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nextOfKinNameController,
                    decoration: const InputDecoration(
                      labelText: 'Next of Kin Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) => value!.isEmpty
                        ? 'Please enter next of kin name'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nextOfKinContactController,
                    decoration: const InputDecoration(
                      labelText: 'Next of Kin Contact',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_in_talk),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty
                        ? 'Please enter next of kin contact'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: hasMedicalAid,
                        onChanged: (value) {
                          setState(() {
                            hasMedicalAid = value!;
                          });
                        },
                      ),
                      const Text('Do you have Medical Aid?'),
                    ],
                  ),
                  if (hasMedicalAid) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _medicalAidNameController,
                      decoration: const InputDecoration(
                        labelText: 'Medical Aid Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_hospital),
                      ),
                      validator: (value) {
                        if (hasMedicalAid && value!.isEmpty) {
                          return 'Please enter Medical Aid Name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _medicalAidNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Medical Aid Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      validator: (value) {
                        if (hasMedicalAid && value!.isEmpty) {
                          return 'Please enter Medical Aid Number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _medicalAidSuffixController,
                      decoration: const InputDecoration(
                        labelText: 'Medical Aid Suffix',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _medicalAidMainMemberController,
                      decoration: const InputDecoration(
                        labelText: 'Medical Aid Main Member',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.indigo.shade500,
                      ),
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Register Patient',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}