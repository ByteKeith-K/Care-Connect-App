class VitalSigns {
  final String diastolicBP;
  final String heartRate;
  final String height;
  final String oxygenSaturation;
  final String patientId;
  final DateTime recordedAt;
  final String respiratoryRate;
  final String systolicBP;
  final String temperature;
  final String? weight;

  VitalSigns({
    required this.diastolicBP,
    required this.heartRate,
    required this.height,
    required this.oxygenSaturation,
    required this.patientId,
    required this.recordedAt,
    required this.respiratoryRate,
    required this.systolicBP,
    required this.temperature,
    this.weight,
  });

  factory VitalSigns.fromMap(Map<String, dynamic> data) {
    return VitalSigns(
      diastolicBP: data['diastolicBP'],
      heartRate: data['heartRate'],
      height: data['height'],
      oxygenSaturation: data['oxygenSaturation'],
      patientId: data['patientId'],
      recordedAt: DateTime.parse(data['recordedAt']),
      respiratoryRate: data['respiratoryRate'],
      systolicBP: data['systolicBP'],
      temperature: data['temperature'],
      weight: data['weight'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'height': height,
      'oxygenSaturation': oxygenSaturation,
      'patientId': patientId,
      'recordedAt': recordedAt.toIso8601String(),
      'respiratoryRate': respiratoryRate,
      'systolicBP': systolicBP,
      'temperature': temperature,
      'weight': weight,
    };
  }
}
