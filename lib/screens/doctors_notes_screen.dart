import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_note_with_analysis_card.dart';
import '../gpt_note_analysis_service.dart';

class DoctorsNotesScreen extends StatefulWidget {
  const DoctorsNotesScreen({super.key});

  @override
  State<DoctorsNotesScreen> createState() => _DoctorsNotesScreenState();
}

class _DoctorsNotesScreenState extends State<DoctorsNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _analysis;
  bool _isAnalyzing = false;

  final String backendUrl = 'http://192.168.27.178:5000'; // Set this to your backend server IP and port
  GptNoteAnalysisService get _gptService => GptNoteAnalysisService(backendUrl: backendUrl);

  Future<void> _submitNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('doctorsNotes').add({
        'patientId': _patientIdController.text.trim(),
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor\'s note saved!')),
      );
      _notesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeNote() async {
    setState(() {
      _isAnalyzing = true;
    });
    try {
      final result = await _gptService.analyzeNote(_notesController.text);
      setState(() {
        _analysis = result;
      });
    } catch (e) {
      setState(() {
        _analysis = 'Error analyzing note.';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveAnalyzedNote() async {
    if (_formKey.currentState!.validate() && _analysis != null && _analysis!.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _firestore.collection('analysedNotes').add({
          'patientId': _patientIdController.text.trim(),
          'notes': _notesController.text.trim(),
          'analysis': _analysis,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyzed note saved!')),
        );
        _notesController.clear();
        setState(() { _analysis = null; });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor's Notes"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _patientIdController,
                          decoration: const InputDecoration(
                            labelText: 'Patient ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Enter patient ID' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: "Doctor's Notes / Treatments",
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          minLines: 6,
                          maxLines: 12,
                          validator: (value) => value == null || value.isEmpty ? 'Enter notes' : null,
                        ),
                        const SizedBox(height: 24),
                        // Enhance Save Note button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Save Note', style: TextStyle(fontSize: 18)),
                            onPressed: _isLoading ? null : _submitNote,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 6,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // --- Analysis and Save Buttons ---
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.analytics),
                                label: _isAnalyzing
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Analyze Note'),
                                onPressed: _isAnalyzing || _notesController.text.isEmpty ? null : _analyzeNote,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Save Analyzed Note'),
                                onPressed: _isLoading || _analysis == null || _analysis!.isEmpty ? null : _saveAnalyzedNote,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_analysis != null && _analysis!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.deepPurple.withOpacity(0.18), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.insights, color: Colors.deepPurple, size: 22),
                                    SizedBox(width: 8),
                                    Text('AI Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 17)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _analysis!,
                                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_patientIdController.text.isNotEmpty) ...[
                          FutureBuilder<QuerySnapshot>(
                            future: _firestore
                                .collection('patients')
                                .where('idNumber', isEqualTo: _patientIdController.text.trim())
                                .limit(1)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Text('Error: \\${snapshot.error}');
                              }
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const Text('No patient found with this ID.');
                              }
                              final data = docs.first.data() as Map<String, dynamic>;
                              final docId = docs.first.id;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Card(
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    color: Colors.indigo.shade50,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.indigo.shade200,
                                        child: const Icon(Icons.person, color: Colors.white),
                                      ),
                                      title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Age: \\${data['age'] ?? ''}', style: const TextStyle(fontSize: 16)),
                                            Text('ID Number: \\${data['idNumber'] ?? ''}', style: const TextStyle(fontSize: 16)),
                                            Text('Contact: \\${data['contact'] ?? ''}', style: const TextStyle(fontSize: 16)),
                                            Text('Patient Document ID: \\$docId', style: const TextStyle(fontSize: 14, color: Colors.indigo)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // For vital signs, only show the Card if data is available
                                  FutureBuilder<QuerySnapshot>(
                                    future: _firestore
                                        .collection('vitalSigns')
                                        .where('patientId', isEqualTo: docId)
                                        .limit(1)
                                        .get(),
                                    builder: (context, vitalSnapshot) {
                                      if (vitalSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (vitalSnapshot.hasError) {
                                        return Text('Error loading vital signs: \\${vitalSnapshot.error}');
                                      }
                                      final vitalDocs = vitalSnapshot.data?.docs ?? [];
                                      if (vitalDocs.isEmpty) {
                                        return const Text('No vital signs found for this patient.');
                                      }
                                      final vital = vitalDocs.first.data() as Map<String, dynamic>;
                                      return Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        color: Colors.green.shade50,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.monitor_heart, color: Colors.green, size: 28),
                                                  SizedBox(width: 8),
                                                  Text('Latest Vital Signs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                ],
                                              ),
                                              const Divider(),
                                              const SizedBox(height: 6),
                                              Text('Blood Pressure: \\${vital['systolicBP'] ?? '-'} / \\${vital['diastolicBP'] ?? '-'} mmHg'),
                                              Text('Heart Rate: \\${vital['heartRate'] ?? '-'} bpm'),
                                              Text('Temperature: \\${vital['temperature'] ?? '-'} °C'),
                                              Text('Oxygen Saturation: \\${vital['oxygenSaturation'] ?? '-'}%'),
                                              Text('Respiratory Rate: \\${vital['respiratoryRate'] ?? '-'}'),
                                              Text('Weight: \\${vital['weight'] ?? '-'} kg'),
                                              Text('Height: \\${vital['height'] ?? '-'} cm'),
                                              Text('Recorded At: \\${vital['recordedAt'] != null ? vital['recordedAt'].toDate().toString() : '-'}'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.note, color: Colors.indigo),
                                        SizedBox(width: 8),
                                        Text('Previous Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 250,
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: _firestore
                                          .collection('doctorsNotes')
                                          .where('patientId', isEqualTo: _patientIdController.text.trim())
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (snapshot.hasError) {
                                          return Text('Error: \\${snapshot.error}');
                                        }
                                        final notes = snapshot.data?.docs ?? [];
                                        if (notes.isEmpty) {
                                          return const Center(child: Text('No previous notes found for this patient.'));
                                        }
                                        return ListView.builder(
                                          physics: const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: notes.length,
                                          itemBuilder: (context, index) {
                                            final noteData = notes[index].data() as Map<String, dynamic>;
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8.0),
                                              child: DoctorNoteWithAnalysisCard(
                                                noteText: noteData['notes'] ?? '',
                                                createdAt: noteData['createdAt'] != null ? noteData['createdAt'].toDate().toString() : '',
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        // --- Analysed Notes Search and List ---
                        const SizedBox(height: 32),
                        const Text('Search Analysed Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _patientIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Search by Patient ID or Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 250,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _patientIdController.text.trim().isEmpty
                              ? _firestore.collection('analysedNotes').snapshots()
                              : _firestore.collection('analysedNotes')
                                  .where('patientId', isEqualTo: _patientIdController.text.trim())
                                  .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Text('Error: \\${snapshot.error}');
                              }
                              final notes = snapshot.data?.docs ?? [];
                              if (notes.isEmpty) {
                                return const Text('No analysed notes found.');
                              }
                              return ListView.builder(
                                itemCount: notes.length,
                                itemBuilder: (context, index) {
                                  final note = notes[index].data() as Map<String, dynamic>;
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: const Icon(Icons.analytics, color: Colors.deepPurple),
                                      title: Text(note['notes'] ?? ''),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Analysis: \\${note['analysis'] ?? ''}', style: const TextStyle(fontSize: 13, color: Colors.deepPurple)),
                                          Text(note['createdAt'] != null ? note['createdAt'].toDate().toString() : ''),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
