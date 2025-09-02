import 'dart:convert';
import 'package:http/http.dart' as http;

class MLBackendService {
  // Set your backend URL here
  final String baseUrl = 'http://1192.168.27.104:5000';

  MLBackendService();

  Future<Map<String, dynamic>> getCategoricalOptions() async {
    final response = await http.get(Uri.parse('$baseUrl/categorical_options'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch categorical options');
    }
  }

  Future<Map<String, dynamic>> predictPatientOutcome(Map<String, dynamic> patientData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict_outcome'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patientData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get prediction');
    }
  }

  Future<Map<String, dynamic>> predictTreatment(Map<String, dynamic> patientData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict_treatment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patientData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get prediction');
    }
  }
}
