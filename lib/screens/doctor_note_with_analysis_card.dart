import 'package:flutter/material.dart';
import '../gpt_note_analysis_service.dart';

const String backendUrl = 'http://192.168.27.178:5000'; // Set this to your backend server IP and port

class DoctorNoteWithAnalysisCard extends StatefulWidget {
  final String noteText;
  final String createdAt;
  const DoctorNoteWithAnalysisCard({Key? key, required this.noteText, required this.createdAt}) : super(key: key);

  @override
  State<DoctorNoteWithAnalysisCard> createState() => _DoctorNoteWithAnalysisCardState();
}

class _DoctorNoteWithAnalysisCardState extends State<DoctorNoteWithAnalysisCard> {
  String? _analysis;
  bool _loading = false;
  bool _error = false;

  Future<void> _analyze() async {
    setState(() { _loading = true; _error = false; });
    try {
      final service = GptNoteAnalysisService(backendUrl: backendUrl);
      final result = await service.analyzeNote(widget.noteText);
      setState(() { _analysis = result; });
    } catch (e) {
      setState(() { _error = true; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                IconButton(
                  icon: const Icon(Icons.analytics, color: Colors.deepPurple),
                  tooltip: 'Analyze Note',
                  onPressed: _loading ? null : _analyze,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.noteText, style: const TextStyle(fontSize: 16)),
            if (_loading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (_analysis != null) ...[
              const Divider(),
              const Text('AI Analysis:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              Text(_analysis!, style: const TextStyle(fontSize: 15)),
            ],
            if (_error) ...[
              const SizedBox(height: 8),
              const Text('Error analyzing note. Please try again.', style: TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}
