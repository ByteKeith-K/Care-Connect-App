import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vital_signs.dart';
import '../models/doctors_notes.dart';
import '../models/patients.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<VitalSigns>> getVitalSigns() async {
    final snapshot = await _firestore.collection('vital_signs').get();
    return snapshot.docs.map((doc) => VitalSigns.fromMap(doc.data())).toList();
  }

  Future<List<DoctorsNotes>> getDoctorsNotes() async {
    final snapshot = await _firestore.collection('doctors_notes').get();
    return snapshot.docs.map((doc) => DoctorsNotes.fromMap(doc.data())).toList();
  }

  Future<List<Patient>> getPatients() async {
    final snapshot = await _firestore.collection('patients').get();
    return snapshot.docs.map((doc) => Patient.fromMap(doc.data())).toList();
  }
}
