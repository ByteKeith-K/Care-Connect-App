import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPatientScreen extends StatefulWidget {
  const EditPatientScreen({super.key});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicalAidNameController = TextEditingController();
  final TextEditingController _medicalAidNumberController = TextEditingController();
  final TextEditingController _medicalAidSuffixController = TextEditingController();
  final TextEditingController _medicalAidMainMemberController = TextEditingController();
  final TextEditingController _nextOfKinNameController = TextEditingController();
  final TextEditingController _nextOfKinContactController = TextEditingController();

  String? _selectedGender;
  bool hasMedicalAid = false;
  List<Map<String, dynamic>> mockPatients = [
    {
      'name': 'Victor',
      'idNumber': '123456789',
      'age': '45',
      'gender': 'Male',
      'contact': '0712345678',
      'address': '123 Main St',
      'medicalHistory': 'Diabetes',
      'allergies': 'None',
      'nextOfKinName': 'Jane',
      'nextOfKinContact': '0798765432',
      'hasMedicalAid': true,
      'medicalAidName': 'MedAid',
      'medicalAidNumber': 'MA123',
      'medicalAidSuffix': 'A',
      'medicalAidMainMember': 'Victor',
    },
    {
      'name': 'Jane Smith',
      'idNumber': '987654321',
      'age': '32',
      'gender': 'Female',
      'contact': '0723456789',
      'address': '456 Side St',
      'medicalHistory': 'Asthma',
      'allergies': 'Penicillin',
      'nextOfKinName': 'Victor',
      'nextOfKinContact': '0712345678',
      'hasMedicalAid': false,
      'medicalAidName': '',
      'medicalAidNumber': '',
      'medicalAidSuffix': '',
      'medicalAidMainMember': '',
    },
  ];
  List<Map<String, dynamic>> searchResults = [];
  Map<String, dynamic>? selectedPatient;

  void _searchPatients(String query) async {
    final firestore = FirebaseFirestore.instance;
    final results = <Map<String, dynamic>>[];
    if (query.isNotEmpty) {
      // Search by idNumber (exact match, case-insensitive)
      final idQuery = await firestore.collection('patients')
        .where('idNumber', isEqualTo: query)
        .get();
      results.addAll(idQuery.docs.map((doc) => doc.data()));
      // If not found, search by name (case-insensitive, partial match)
      if (results.isEmpty) {
        final allPatients = await firestore.collection('patients').get();
        final lowerQuery = query.toLowerCase();
        for (var doc in allPatients.docs) {
          final name = (doc.data()['name'] ?? '').toString();
          final id = (doc.data()['idNumber'] ?? '').toString();
          if (name.toLowerCase().contains(lowerQuery) || id.toLowerCase().contains(lowerQuery)) {
            results.add(doc.data());
          }
        }
      }
    }
    setState(() {
      searchResults = results;
    });
  }

  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      selectedPatient = patient;
      _nameController.text = patient['name'] ?? '';
      _idNumberController.text = patient['idNumber'] ?? '';
      _ageController.text = patient['age'] ?? '';
      _selectedGender = patient['gender'];
      _contactController.text = patient['contact'] ?? '';
      _addressController.text = patient['address'] ?? '';
      _medicalHistoryController.text = patient['medicalHistory'] ?? '';
      _allergiesController.text = patient['allergies'] ?? '';
      _nextOfKinNameController.text = patient['nextOfKinName'] ?? '';
      _nextOfKinContactController.text = patient['nextOfKinContact'] ?? '';
      hasMedicalAid = patient['hasMedicalAid'] ?? false;
      _medicalAidNameController.text = patient['medicalAidName'] ?? '';
      _medicalAidNumberController.text = patient['medicalAidNumber'] ?? '';
      _medicalAidSuffixController.text = patient['medicalAidSuffix'] ?? '';
      _medicalAidMainMemberController.text = patient['medicalAidMainMember'] ?? '';
    });
  }

  void _savePatient() async {
    if (_formKey.currentState!.validate() && selectedPatient != null) {
      final firestore = FirebaseFirestore.instance;
      final idNumber = _idNumberController.text.trim();
      final patientQuery = await firestore.collection('patients')
        .where('idNumber', isEqualTo: idNumber)
        .limit(1)
        .get();
      if (patientQuery.docs.isNotEmpty) {
        final docId = patientQuery.docs.first.id;
        await firestore.collection('patients').doc(docId).update({
          'name': _nameController.text.trim(),
          'idNumber': idNumber,
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
          'medicalAidName': _medicalAidNameController.text.trim(),
          'medicalAidNumber': _medicalAidNumberController.text.trim(),
          'medicalAidSuffix': _medicalAidSuffixController.text.trim(),
          'medicalAidMainMember': _medicalAidMainMemberController.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient details updated!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient not found in database.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search Patient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Enter Patient ID or Name',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchPatients(_searchController.text),
                    ),
                  ),
                  onChanged: _searchPatients,
                ),
                if (searchResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(
                        labelText: 'Select Patient',
                        border: OutlineInputBorder(),
                      ),
                      items: searchResults.map((patient) => DropdownMenuItem(
                        value: patient,
                        child: Text('${patient['name']} (${patient['idNumber']})'),
                      )).toList(),
                      onChanged: (patient) {
                        if (patient != null) _selectPatient(patient);
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter full name' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _idNumberController,
                        decoration: const InputDecoration(
                          labelText: 'ID Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter ID number' : null,
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
                        items: ['Male', 'Female']
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
                        validator: (value) => value == null ? 'Please select gender' : null,
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
                        validator: (value) => value!.isEmpty ? 'Please enter contact number' : null,
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
                        validator: (value) => value!.isEmpty ? 'Please enter address' : null,
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
                      const SizedBox(height: 10),
                      const Text('Next of Kin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nextOfKinNameController,
                        decoration: const InputDecoration(
                          labelText: 'Next of Kin Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter next of kin name' : null,
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
                        validator: (value) => value!.isEmpty ? 'Please enter next of kin contact' : null,
                      ),
                      const SizedBox(height: 10),
                      const Text('Medical Aid', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _medicalAidNameController,
                        decoration: const InputDecoration(
                          labelText: 'Medical Aid Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_hospital),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
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
                          if (value!.isEmpty) {
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
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save Patient Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _savePatient,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
