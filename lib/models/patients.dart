import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String address;
  final String age;
  final String allergies;
  final String contact;
  final DateTime createdAt;
  final String gender;
  final bool hasMedicalAid;
  final String idNumber;
  final String? medicalAidMainMember;
  final String? medicalAidName;
  final String? medicalAidNumber;
  final String? medicalAidSuffix;
  final String medicalHistory;
  final String name;
  final Map<String, String> nextOfKin;

  Patient({
    required this.address,
    required this.age,
    required this.allergies,
    required this.contact,
    required this.createdAt,
    required this.gender,
    required this.hasMedicalAid,
    required this.idNumber,
    this.medicalAidMainMember,
    this.medicalAidName,
    this.medicalAidNumber,
    this.medicalAidSuffix,
    required this.medicalHistory,
    required this.name,
    required this.nextOfKin,
  });

  factory Patient.fromMap(Map<String, dynamic> data) {
    return Patient(
      address: data['address'],
      age: data['age'],
      allergies: data['allergies'],
      contact: data['contact'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      gender: data['gender'],
      hasMedicalAid: data['hasMedicalAid'],
      idNumber: data['idNumber'],
      medicalAidMainMember: data['medicalAidMainMember'],
      medicalAidName: data['medicalAidName'],
      medicalAidNumber: data['medicalAidNumber'],
      medicalAidSuffix: data['medicalAidSuffix'],
      medicalHistory: data['medicalHistory'],
      name: data['name'],
      nextOfKin: Map<String, String>.from(data['nextOfKin']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'age': age,
      'allergies': allergies,
      'contact': contact,
      'createdAt': createdAt.toIso8601String(),
      'gender': gender,
      'hasMedicalAid': hasMedicalAid,
      'idNumber': idNumber,
      'medicalAidMainMember': medicalAidMainMember,
      'medicalAidName': medicalAidName,
      'medicalAidNumber': medicalAidNumber,
      'medicalAidSuffix': medicalAidSuffix,
      'medicalHistory': medicalHistory,
      'name': name,
      'nextOfKin': nextOfKin,
    };
  }

  @override
  String toString() {
    return 'Patient(name: $name, age: $age, gender: $gender, contact: $contact, medicalHistory: $medicalHistory)';
  }
}
