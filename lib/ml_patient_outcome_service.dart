import 'dart:convert';
import 'package:http/http.dart' as http;

class MlPatientOutcomeService {
  final String backendUrl;
  MlPatientOutcomeService({required this.backendUrl});

  Future<Map<String, dynamic>?> predictOutcome({
    required int age,
    required String gender,
    required int systolicBP,
    required int diastolicBP,
    required int heartRate,
    required double temperature,
    required int oxygenSaturation,
    required int respiratoryRate,
    required double weight,
    required double height,
    required String medicalHistory,
    required String doctorNote,
  }) async {
    final body = jsonEncode({
      'age': age,
      'gender': gender,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'temperature': temperature,
      'oxygenSaturation': oxygenSaturation,
      'respiratoryRate': respiratoryRate,
      'weight': weight,
      'height': height,
      'medicalHistory': medicalHistory,
      'doctorNote': doctorNote,
    });
    final response = await http.post(
      Uri.parse('$backendUrl/predict_outcome'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }
}
