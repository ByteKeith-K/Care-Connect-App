import 'package:flutter/material.dart';
import '../services/ml_backend_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({Key? key}) : super(key: key);

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final MLBackendService mlService = MLBackendService();
  String? outcomePrediction;
  String? treatmentPrediction;
  bool isLoading = false;
  String? error;

  // Controllers for input fields
  final TextEditingController ageController = TextEditingController(text: '24');
  final TextEditingController hasMedicalAidController = TextEditingController(text: '0');
  final TextEditingController heartRateController = TextEditingController(text: '88');
  final TextEditingController systolicBPController = TextEditingController(text: '80');
  final TextEditingController diastolicBPController = TextEditingController(text: '60');
  final TextEditingController temperatureController = TextEditingController(text: '21.0');
  final TextEditingController respiratoryRateController = TextEditingController(text: '10');
  final TextEditingController oxygenSaturationController = TextEditingController(text: '21');
  final TextEditingController heightController = TextEditingController(text: '186');
  final TextEditingController weightController = TextEditingController(text: '70');

  // Dropdown options
  List<String> genderOptions = [];
  List<String> medicalHistoryOptions = [];
  List<String> diagnosisOptions = [];

  // Controllers for custom input
  final TextEditingController customGenderController = TextEditingController();
  final TextEditingController customMedicalHistoryController = TextEditingController();
  final TextEditingController customDiagnosisController = TextEditingController();

  // Add controllers for new fields
  String selectedGender = '';
  String selectedMedicalHistory = '';
  String selectedDiagnosis = '';
  double? outcomeProbability;
  double? treatmentProbability;

  // Patient selection
  String? selectedPatientId;
  List<Map<String, dynamic>> patientList = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownOptions();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    final docs = await FirebaseFirestore.instance.collection('patients').get();
    setState(() {
      patientList = docs.docs.map((d) => {
        'id': d.id,
        ...d.data()
      }).toList();
    });
  }

  Future<void> _fetchAndFillPatientData(String patientId) async {
    final doc = await FirebaseFirestore.instance.collection('patients').doc(patientId).get();
    if (doc.exists) {
      final data = doc.data()!;
      // Ensure genderOptions is unique and contains the selected gender
      String gender = data['gender']?.toString() ?? '';
      setState(() {
        ageController.text = data['age']?.toString() ?? ageController.text;
        selectedGender = gender;
        hasMedicalAidController.text = (data['hasMedicalAid'] == true) ? '1' : '0';
        selectedMedicalHistory = data['medicalHistory']?.toString() ?? selectedMedicalHistory;
        heightController.text = data['height']?.toString() ?? heightController.text;
        weightController.text = data['weight']?.toString() ?? weightController.text;
        // Add gender to genderOptions if missing
        if (gender.isNotEmpty && !genderOptions.contains(gender)) {
          genderOptions = [...genderOptions, gender];
        }
        // Remove duplicates
        genderOptions = genderOptions.toSet().toList();
      });
      // Fetch latest vital signs for this patient
      Query vitalsBase = FirebaseFirestore.instance.collection('vitalSigns')
        .where('patientId', isEqualTo: patientId);
      try {
        final vitalsQuery = await vitalsBase
          .orderBy('recordedAt', descending: true)
          .limit(1)
          .get();
        if (vitalsQuery.docs.isNotEmpty) {
          final vitals = vitalsQuery.docs.first.data() as Map<String, dynamic>;
          setState(() {
            heartRateController.text = vitals['heartRate']?.toString() ?? heartRateController.text;
            systolicBPController.text = vitals['systolicBP']?.toString() ?? systolicBPController.text;
            diastolicBPController.text = vitals['diastolicBP']?.toString() ?? diastolicBPController.text;
            temperatureController.text = vitals['temperature']?.toString() ?? temperatureController.text;
            respiratoryRateController.text = vitals['respiratoryRate']?.toString() ?? respiratoryRateController.text;
            oxygenSaturationController.text = vitals['oxygenSaturation']?.toString() ?? oxygenSaturationController.text;
          });
        }
      } catch (e) {
        // Fallback: try without orderBy if index/field is missing
        final vitalsQuery = await vitalsBase.limit(1).get();
        if (vitalsQuery.docs.isNotEmpty) {
          final vitals = vitalsQuery.docs.first.data() as Map<String, dynamic>;
          setState(() {
            heartRateController.text = vitals['heartRate']?.toString() ?? heartRateController.text;
            systolicBPController.text = vitals['systolicBP']?.toString() ?? systolicBPController.text;
            diastolicBPController.text = vitals['diastolicBP']?.toString() ?? diastolicBPController.text;
            temperatureController.text = vitals['temperature']?.toString() ?? temperatureController.text;
            respiratoryRateController.text = vitals['respiratoryRate']?.toString() ?? respiratoryRateController.text;
            oxygenSaturationController.text = vitals['oxygenSaturation']?.toString() ?? oxygenSaturationController.text;
          });
        }
      }
    }
  }

  Future<void> _fetchDropdownOptions() async {
    try {
      final options = await mlService.getCategoricalOptions();
      setState(() {
        // Ensure uniqueness
        genderOptions = List<String>.from(options['gender'] ?? []).toSet().toList();
        medicalHistoryOptions = List<String>.from(options['medicalHistory'] ?? []);
        diagnosisOptions = List<String>.from(options['diagnosis'] ?? []);
      });
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> getPredictions() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    final patientData = {
      "age": int.tryParse(ageController.text) ?? 0,
      "hasMedicalAid": int.tryParse(hasMedicalAidController.text) ?? 0,
      "heartRate": int.tryParse(heartRateController.text) ?? 0,
      "systolicBP": int.tryParse(systolicBPController.text) ?? 0,
      "diastolicBP": int.tryParse(diastolicBPController.text) ?? 0,
      "temperature": double.tryParse(temperatureController.text) ?? 0.0,
      "respiratoryRate": int.tryParse(respiratoryRateController.text) ?? 0,
      "oxygenSaturation": int.tryParse(oxygenSaturationController.text) ?? 0,
      "height": int.tryParse(heightController.text) ?? 0,
      "weight": int.tryParse(weightController.text) ?? 0,
      "gender": selectedGender,
      "medicalHistory": selectedMedicalHistory,
      "diagnosis": selectedDiagnosis,
    };
    try {
      final outcome = await mlService.predictPatientOutcome(patientData);
      final treatment = await mlService.predictTreatment(patientData);
      setState(() {
        outcomePrediction = outcome['prediction']?.toString();
        treatmentPrediction = treatment['prediction']?.toString();
        outcomeProbability = outcome['probability'] != null ? double.tryParse(outcome['probability'].toString()) : null;
        treatmentProbability = treatment['probability'] != null ? double.tryParse(treatment['probability'].toString()) : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ML Predictions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient selection dropdown
              DropdownButtonFormField<String>(
                value: selectedPatientId,
                decoration: const InputDecoration(labelText: 'Select Patient'),
                items: patientList.map((p) => DropdownMenuItem<String>(
                  value: p['id'],
                  child: Text('${p['name']} (${p['idNumber'] ?? p['id']})'),
                )).toList(),
                onChanged: (value) async {
                  setState(() => selectedPatientId = value);
                  if (value != null) {
                    await _fetchAndFillPatientData(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Input Data:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Flexible(child: TextField(controller: ageController, decoration: const InputDecoration(labelText: 'Age'))),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            // Ensure genderOptions is unique and contains selectedGender if not empty
                            final uniqueGenderOptions = Set<String>.from(genderOptions);
                            if (selectedGender.isNotEmpty && !uniqueGenderOptions.contains(selectedGender)) {
                              uniqueGenderOptions.add(selectedGender);
                            }
                            final genderDropdownOptions = uniqueGenderOptions.toList();
                            // If selectedGender is not in the options, set value to null
                            final dropdownValue = (selectedGender.isNotEmpty && genderDropdownOptions.contains(selectedGender)) ? selectedGender : null;
                            return DropdownButtonFormField<String>(
                              value: dropdownValue,
                              items: [
                                ...genderDropdownOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                const DropdownMenuItem<String>(
                                  value: '__add_new__',
                                  child: Text('Add new...'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == '__add_new__') {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Add Gender'),
                                      content: TextField(
                                        controller: customGenderController,
                                        decoration: const InputDecoration(labelText: 'New Gender'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            final newValue = customGenderController.text.trim();
                                            if (newValue.isNotEmpty && !genderOptions.contains(newValue)) {
                                              setState(() {
                                                genderOptions.add(newValue);
                                                selectedGender = newValue;
                                              });
                                            }
                                            customGenderController.clear();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  setState(() => selectedGender = v ?? '');
                                }
                              },
                              decoration: const InputDecoration(labelText: 'Gender'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(child: TextField(controller: heartRateController, decoration: const InputDecoration(labelText: 'Heart Rate'))),
                  const SizedBox(width: 8),
                  Flexible(child: TextField(controller: systolicBPController, decoration: const InputDecoration(labelText: 'Systolic BP'))),
                  const SizedBox(width: 8),
                  Flexible(child: TextField(controller: diastolicBPController, decoration: const InputDecoration(labelText: 'Diastolic BP'))),
                ],
              ),
              Row(
                children: [
                  Flexible(child: TextField(controller: temperatureController, decoration: const InputDecoration(labelText: 'Temperature'))),
                  const SizedBox(width: 8),
                  Flexible(child: TextField(controller: respiratoryRateController, decoration: const InputDecoration(labelText: 'Respiratory Rate'))),
                ],
              ),
              Row(
                children: [
                  Flexible(child: TextField(controller: oxygenSaturationController, decoration: const InputDecoration(labelText: 'Oxygen Saturation'))),
                  const SizedBox(width: 8),
                  Flexible(child: TextField(controller: heightController, decoration: const InputDecoration(labelText: 'Height'))),
                  const SizedBox(width: 8),
                  Flexible(child: TextField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight'))),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final uniqueMedicalHistoryOptions = Set<String>.from(medicalHistoryOptions);
                            if (selectedMedicalHistory.isNotEmpty && !uniqueMedicalHistoryOptions.contains(selectedMedicalHistory)) {
                              uniqueMedicalHistoryOptions.add(selectedMedicalHistory);
                            }
                            final medHistoryDropdownOptions = uniqueMedicalHistoryOptions.toList();
                            final dropdownValue = (selectedMedicalHistory.isNotEmpty && medHistoryDropdownOptions.contains(selectedMedicalHistory)) ? selectedMedicalHistory : null;
                            return DropdownButtonFormField<String>(
                              value: dropdownValue,
                              items: [
                                ...medHistoryDropdownOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                const DropdownMenuItem<String>(
                                  value: '__add_new__',
                                  child: Text('Add new...'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == '__add_new__') {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Add Medical History'),
                                      content: TextField(
                                        controller: customMedicalHistoryController,
                                        decoration: const InputDecoration(labelText: 'New Medical History'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            final newValue = customMedicalHistoryController.text.trim();
                                            if (newValue.isNotEmpty && !medicalHistoryOptions.contains(newValue)) {
                                              setState(() {
                                                medicalHistoryOptions.add(newValue);
                                                selectedMedicalHistory = newValue;
                                              });
                                            }
                                            customMedicalHistoryController.clear();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  setState(() => selectedMedicalHistory = v ?? '');
                                }
                              },
                              decoration: const InputDecoration(labelText: 'Medical History'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final uniqueDiagnosisOptions = Set<String>.from(diagnosisOptions);
                            if (selectedDiagnosis.isNotEmpty && !uniqueDiagnosisOptions.contains(selectedDiagnosis)) {
                              uniqueDiagnosisOptions.add(selectedDiagnosis);
                            }
                            final diagnosisDropdownOptions = uniqueDiagnosisOptions.toList();
                            final dropdownValue = (selectedDiagnosis.isNotEmpty && diagnosisDropdownOptions.contains(selectedDiagnosis)) ? selectedDiagnosis : null;
                            return DropdownButtonFormField<String>(
                              value: dropdownValue,
                              items: [
                                ...diagnosisDropdownOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                const DropdownMenuItem<String>(
                                  value: '__add_new__',
                                  child: Text('Add new...'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == '__add_new__') {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Add Diagnosis'),
                                      content: TextField(
                                        controller: customDiagnosisController,
                                        decoration: const InputDecoration(labelText: 'New Diagnosis'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            final newValue = customDiagnosisController.text.trim();
                                            if (newValue.isNotEmpty && !diagnosisOptions.contains(newValue)) {
                                              setState(() {
                                                diagnosisOptions.add(newValue);
                                                selectedDiagnosis = newValue;
                                              });
                                            }
                                            customDiagnosisController.clear();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  setState(() => selectedDiagnosis = v ?? '');
                                }
                              },
                              decoration: const InputDecoration(labelText: 'Diagnosis'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : getPredictions,
                child: isLoading ? const CircularProgressIndicator() : const Text('Get Predictions'),
              ),
              const SizedBox(height: 20),
              if (error != null) ...[
                Text('Error: $error', style: const TextStyle(color: Colors.red)),
              ] else ...[
                Text('Outcome Prediction: ${outcomePrediction ?? "-"}'),
                if (outcomeProbability != null) Text('Outcome Confidence: ${(outcomeProbability! * 100).toStringAsFixed(1)}%'),
                Text('Treatment Prediction: ${treatmentPrediction ?? "-"}'),
                if (treatmentProbability != null) Text('Treatment Confidence: ${(treatmentProbability! * 100).toStringAsFixed(1)}%'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
