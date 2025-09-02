import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  final String baseUrl = 'http://192.168.27.104:5000'; // Use localhost for local dev

  Future<Map<String, dynamic>> getStatisticalAnalysis() async {
    final response = await http.get(Uri.parse('$baseUrl/statistics'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Error fetching statistics: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch statistical analysis');
    }
  }

  Future<Map<String, dynamic>> getPredictiveAnalytics(Map<String, dynamic> inputData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(inputData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch predictive analytics');
    }
  }

  Future<Map<String, dynamic>> getPersonalizedTreatment(Map<String, dynamic> inputData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/treatment'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(inputData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch personalized treatment');
    }
  }
}
