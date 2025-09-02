class DoctorsNotes {
  final DateTime createdAt;
  final String notes;
  final String patientId;

  DoctorsNotes({
    required this.createdAt,
    required this.notes,
    required this.patientId,
  });

  factory DoctorsNotes.fromMap(Map<String, dynamic> data) {
    return DoctorsNotes(
      createdAt: DateTime.parse(data['createdAt']),
      notes: data['notes'],
      patientId: data['patientId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'patientId': patientId,
    };
  }
}
