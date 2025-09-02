import 'package:flutter/material.dart';
import '../gpt_note_analysis_service.dart';

const String backendUrl = 'http://192.168.27.178:5000'; // Set this to your backend server IP and port

// Rename _CurrentNoteAnalysisWidget to CurrentNoteAnalysisWidget for public use
class CurrentNoteAnalysisWidget extends StatefulWidget {
  final String noteText;
  const CurrentNoteAnalysisWidget({Key? key, required this.noteText}) : super(key: key);

  @override
  State<CurrentNoteAnalysisWidget> createState() => _CurrentNoteAnalysisWidgetState();
}

class _CurrentNoteAnalysisWidgetState extends State<CurrentNoteAnalysisWidget> {
  String? _analysis;
  bool _loading = false;
  bool _error = false;
  String? _lastAnalyzedText;

  @override
  void didUpdateWidget(covariant CurrentNoteAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.noteText.trim().isNotEmpty && widget.noteText != _lastAnalyzedText) {
      _analyze();
    }
  }

  Future<void> _analyze() async {
    setState(() { _loading = true; _error = false; _analysis = null; });
    _lastAnalyzedText = widget.noteText;
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
    if (widget.noteText.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}
