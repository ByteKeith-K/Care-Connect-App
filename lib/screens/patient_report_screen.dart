import 'dart:typed_data';
import 'package:flutter/material.dart';
// ===== [START NEW IMPORTS] =====
import 'package:cloud_firestore/cloud_firestore.dart';
// ===== [END NEW IMPORTS] =====
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PatientReportScreen extends StatefulWidget {
  const PatientReportScreen({super.key});

  @override
  State<PatientReportScreen> createState() => _PatientReportScreenState();
}

class _PatientReportScreenState extends State<PatientReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _selectedPatient;
  bool _isLoadingPdf = false; // Enhancement: loading state for PDF/share

  // Dropdown search state
  List<DocumentSnapshot> _searchResults = [];
  bool _showDropdown = false;

  // Overlay-based dropdown for patient search
  OverlayEntry? _patientDropdown;
  final LayerLink _dropdownLink = LayerLink();
  final FocusNode _searchFocus = FocusNode();
  final GlobalKey _searchBarKey = GlobalKey();
  List<Map<String, dynamic>> _patientSearchResults = [];
  String? _selectedPatientId;
  String? _selectedPatientName;

  // Enhanced search: by name or ID, with dropdown suggestions
  Future<void> _searchPatients(String query) async {
    final firestore = FirebaseFirestore.instance;
    final results = <Map<String, dynamic>>[];
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      final allPatients = await firestore.collection('patients').get();
      for (var doc in allPatients.docs) {
        final name = (doc.data()['name'] ?? '').toString();
        final id = (doc.data()['idNumber'] ?? '').toString();
        if (name.toLowerCase().contains(lowerQuery) || id.toLowerCase().contains(lowerQuery)) {
          results.add({'id': doc.id, ...doc.data(), 'docRef': doc});
        }
      }
    }
    setState(() {
      _patientSearchResults = results;
    });
    if (_searchFocus.hasFocus && results.isNotEmpty) {
      _showPatientDropdown(context);
    } else {
      _removePatientDropdown();
    }
  }

  void _showPatientDropdown(BuildContext context) {
    _removePatientDropdown();
    if (_patientSearchResults.isEmpty) return;
    final overlay = Overlay.of(context);
    final renderBox = _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    _patientDropdown = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 4,
          child: SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: _patientSearchResults.length,
              itemBuilder: (context, idx) {
                final p = _patientSearchResults[idx];
                return ListTile(
                  title: Text(p['name'] ?? ''),
                  subtitle: Text('ID: ${p['idNumber'] ?? p['id']}'),
                  onTap: () {
                    setState(() {
                      _selectedPatientId = p['idNumber'] ?? p['id'];
                      _selectedPatientName = p['name'] ?? '';
                      _searchController.text = p['name'] ?? '';
                      _patientSearchResults = [];
                      // Also set _selectedPatient for report display
                      _selectedPatient = p['docRef'] as DocumentSnapshot?;
                    });
                    _removePatientDropdown();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    overlay.insert(_patientDropdown!);
  }

  void _removePatientDropdown() {
    _patientDropdown?.remove();
    _patientDropdown = null;
  }

  // ===== [START MODIFIED CODE] =====
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final data = _selectedPatient!.data() as Map<String, dynamic>;

    final List<pw.Widget> pdfWidgets = [
      pw.Text('Patient Summary', style: const pw.TextStyle(fontSize: 24)),
      pw.SizedBox(height: 20),
      pw.Text('Patient ID: ${data['idNumber'] ?? ''}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.Text('Name: ${data['name'] ?? ''}', style: const pw.TextStyle(fontSize: 18)),
      pw.Text('Age: ${data['age'] ?? ''}'),
      pw.Text('Gender: ${data['gender'] ?? ''}'),
      pw.Text('Contact: ${data['contact'] ?? ''}'),
      pw.Text('Address: ${data['address'] ?? ''}'),
      pw.Text('Allergies: ${data['allergies'] ?? ''}'),
      pw.Text('Medical History: ${data['medicalHistory'] ?? ''}'),
      pw.Text('Created At: ${data['createdAt'] != null ? data['createdAt'].toDate().toString() : ''}'),
      pw.SizedBox(height: 10),
      pw.Text('Medical Aid:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ];
    if (data['hasMedicalAid'] == true) {
      pdfWidgets.addAll([
        pw.Text('Medical Aid Name: ${data['medicalAidName'] ?? ''}'),
        pw.Text('Medical Aid Number: ${data['medicalAidNumber'] ?? ''}'),
        pw.Text('Medical Aid Suffix: ${data['medicalAidSuffix'] ?? ''}'),
        pw.Text('Main Member: ${data['medicalAidMainMember'] ?? ''}'),
      ]);
    } else {
      pdfWidgets.add(pw.Text('No Medical Aid'));
    }
    pdfWidgets.add(pw.SizedBox(height: 10));
    pdfWidgets.add(pw.Text('Next of Kin:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
    pdfWidgets.add(pw.Text('Name: ${data['nextOfKin'] != null && data['nextOfKin']['name'] != null ? data['nextOfKin']['name'] : ''}'));
    pdfWidgets.add(pw.Text('Contact: ${data['nextOfKin'] != null && data['nextOfKin']['contact'] != null ? data['nextOfKin']['contact'] : ''}'));

    // Fetch doctor's notes for the patient and add to PDF
    final notesQuery = await _firestore
        .collection('doctorsNotes')
        .where('patientId', isEqualTo: data['idNumber'])
        .orderBy('createdAt', descending: true)
        .get();
    final notes = notesQuery.docs;
    pdfWidgets.add(pw.SizedBox(height: 20));
    pdfWidgets.add(pw.Text('Reports Timeline', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)));
    if (notes.isEmpty) {
      pdfWidgets.add(pw.Text("No doctor's notes found for this patient.", style: const pw.TextStyle(color: PdfColor.fromInt(0xFF888888))));
    } else {
      for (final doc in notes) {
        final note = doc.data();
        final doctorName = note['doctorName'] ?? 'Unknown Doctor';
        final createdAt = note['createdAt'] != null ? (note['createdAt'] as Timestamp).toDate().toString() : '';
        pdfWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFCCCCCC)),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(note['notes'] ?? 'No Note', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: $createdAt', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Doctor: $doctorName', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      }
    }

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: pdfWidgets,
        ),
      ),
    );
    return pdf.save();
  }
  // ===== [END MODIFIED CODE] =====

  // ===== [START NEW CODE] =====
  // Enhanced timeline for doctor's notes
  Widget _buildTimeline(List<QueryDocumentSnapshot> notes) {
    if (notes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 48),
            SizedBox(height: 8),
            Text("No doctor's notes found for this patient.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    // Sort notes by createdAt descending
    notes.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    // Define urgent keywords
    final urgentKeywords = ['urgent', 'critical', 'chest pain', 'shortness of breath', 'severe'];
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, idx) {
        final note = notes[idx].data() as Map<String, dynamic>;
        final doctorName = note['doctorName'] ?? 'Unknown Doctor';
        final createdAt = note['createdAt'] != null ? (note['createdAt'] as Timestamp).toDate().toString() : '';
        final noteText = note['notes'] ?? 'No Note';
        // Check for urgent keywords
        final isUrgent = urgentKeywords.any((kw) => noteText.toLowerCase().contains(kw));
        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isFirst: idx == 0,
          isLast: idx == notes.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: isUrgent ? Colors.red : Colors.indigo,
          ),
          endChild: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Row(
                children: [
                  Expanded(child: Text(noteText)),
                  if (isUrgent) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.warning, color: Colors.red, size: 18),
                  ]
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: $createdAt'),
                  Text('Doctor: $doctorName'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // ===== [END NEW CODE] =====

  @override
  void initState() {
    super.initState();
    // _searchController.addListener(_onSearchChanged); // Remove this line
  }

  @override
  void dispose() {
    _removePatientDropdown();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Report'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  CompositedTransformTarget(
                    link: _dropdownLink,
                    child: TextField(
                      key: _searchBarKey,
                      focusNode: _searchFocus,
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by Name or Patient ID',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (val) async {
                        await _searchPatients(val);
                      },
                      onTap: () async {
                        if (_searchController.text.isNotEmpty) {
                          await _searchPatients(_searchController.text);
                        }
                      },
                      onSubmitted: (val) {
                        _removePatientDropdown();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedPatient != null) ...[
                _buildPatientCard(_selectedPatient!),
                const SizedBox(height: 20),
                const Text('Reports Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                SizedBox(
                  height: 300,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('doctorsNotes')
                        .where('patientId', isEqualTo: (_selectedPatient!.data() as Map<String, dynamic>)['idNumber'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Text('Error: \\${snapshot.error}');
                      }
                      final notes = snapshot.data?.docs ?? [];
                      return _buildTimeline(notes);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===== [START NEW CODE] =====
  Widget _buildPatientCard(DocumentSnapshot patient) {
    final data = patient.data() as Map<String, dynamic>;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty)
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(data['photoUrl']),
                ),
              ),
            if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty)
              const SizedBox(height: 10),
            Text('Patient ID: ${data['idNumber'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Name: ${data['name'] ?? ''}', style: const TextStyle(fontSize: 18)),
            Text('Age: ${data['age'] ?? ''}'),
            Text('Gender: ${data['gender'] ?? ''}'),
            Text('Contact: ${data['contact'] ?? ''}'),
            Text('Address: ${data['address'] ?? ''}'),
            Text('Allergies: ${data['allergies'] ?? ''}'),
            Text('Medical History: ${data['medicalHistory'] ?? ''}'),
            Text('Created At: ${data['createdAt'] != null ? data['createdAt'].toDate().toString() : ''}'),
            const SizedBox(height: 10),
            const Text('Medical Aid:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (data['hasMedicalAid'] == true) ...[
              Text('Medical Aid Name: ${data['medicalAidName'] ?? ''}'),
              Text('Medical Aid Number: ${data['medicalAidNumber'] ?? ''}'),
              Text('Medical Aid Suffix: ${data['medicalAidSuffix'] ?? ''}'),
              Text('Main Member: ${data['medicalAidMainMember'] ?? ''}'),
            ] else ...[
              const Text('No Medical Aid'),
            ],
            const SizedBox(height: 10),
            const Text('Next of Kin:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Name: ${data['nextOfKin']?['name'] ?? ''}'),
            Text('Contact: ${data['nextOfKin']?['contact'] ?? ''}'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: _isLoadingPdf ? const Text('Generating...') : const Text('Generate PDF'),
              onPressed: _isLoadingPdf ? null : () async {
                if (!mounted) return;
                setState(() => _isLoadingPdf = true);
                try {
                  final pdfData = await _generatePdf();
                  final tempDir = await getTemporaryDirectory();
                  final fileName = '${data['name'] ?? 'patient'}_${data['idNumber'] ?? 'id'}.pdf';
                  final file = File('${tempDir.path}/$fileName');
                  await file.writeAsBytes(pdfData);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF generated successfully!\nSaved at: ${file.path}')),
                  );
                  // Immediately open the print dialog
                  await Printing.layoutPdf(onLayout: (_) async => pdfData);
                } finally {
                  if (mounted) setState(() => _isLoadingPdf = false);
                }
              },
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5), // Light blue
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigoAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('Share Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: () async {
                  setState(() => _isLoadingPdf = true);
                  try {
                    final data = patient.data() as Map<String, dynamic>;
                    final String patientName = data['name'] ?? 'patient';
                    final String patientId = data['idNumber'] ?? 'id';
                    final pdfData = await _generatePdf();
                    if (pdfData.lengthInBytes > 5 * 1024 * 1024) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Warning: PDF is very large and may not share properly.')),
                      );
                    }
                    final tempDir = await getTemporaryDirectory();
                    final fileName = '${patientName}_$patientId.pdf';
                    final file = File('${tempDir.path}/$fileName');
                    await file.writeAsBytes(pdfData);
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: 'Patient Report: $patientName ($patientId)',
                      subject: 'Patient Report for $patientName',
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report shared successfully!')),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to share report: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoadingPdf = false);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            // Prediction button and ML prediction removed
          ],
        ),
      ),
    );
  }
  // ===== [END NEW CODE] =====
}