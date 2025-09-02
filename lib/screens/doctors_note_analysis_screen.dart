import 'package:flutter/material.dart';
import '../gpt_note_analysis_service.dart';

const String backendUrl = 'http://192.168.27.178:5000'; // Set this to your backend server IP and port

class DoctorsNoteAnalysisScreen extends StatefulWidget {
  const DoctorsNoteAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<DoctorsNoteAnalysisScreen> createState() => _DoctorsNoteAnalysisScreenState();
}

class _DoctorsNoteAnalysisScreenState extends State<DoctorsNoteAnalysisScreen> {
  final TextEditingController _noteController = TextEditingController();
  String? _analysisResult;
  bool _loading = false;
  final GptNoteAnalysisService _service = GptNoteAnalysisService(backendUrl: backendUrl);

  Future<void> _analyzeNote() async {
    setState(() { _loading = true; _analysisResult = null; });
    final result = await _service.analyzeNote(_noteController.text);
    setState(() { _analysisResult = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctors Note Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste or type a clinical note:'),
            TextField(
              controller: _noteController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter doctor\'s note here...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _analyzeNote,
              child: _loading ? const CircularProgressIndicator() : const Text('Analyze'),
            ),
            const SizedBox(height: 24),
            if (_analysisResult != null) ...[
              const Text('Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_analysisResult!),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
