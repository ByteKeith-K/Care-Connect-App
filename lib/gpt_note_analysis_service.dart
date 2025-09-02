import 'dart:convert';
import 'package:http/http.dart' as http;

class GptNoteAnalysisService {
  final String backendUrl;
  GptNoteAnalysisService({required this.backendUrl});

  Future<String?> analyzeNote(String note) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.27.178:5000/analyze_note'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'note': note}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analysis'] as String?;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to analyze note');
      }
    } catch (e) {
      return 'Error: \\${e.toString()}';
    }
  }
}
