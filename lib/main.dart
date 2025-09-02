import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/appointment_screen.dart';
import 'screens/appointments_report.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/patient_registration_screen.dart';
import 'screens/patient_report_screen.dart';
import 'screens/vital_signs_screen.dart';
import 'screens/doctors_notes_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/thank_you_screen.dart';
import 'authentication/auth_service.dart';
import 'screens/admin_dashboard.dart';
import 'screens/add_user.dart';
import 'screens/update_user.dart';
import 'screens/edit_patient.dart';
import 'screens/doctors_note_analysis_screen.dart';
import 'screens/analytics_dashboard.dart';
import 'screens/prediction_screen.dart';
import 'screens/bottesting screen.dart';
import 'screens/pending_appointments_screen.dart';
import 'screens/doctor_slots_screen.dart';
import 'screens/critical_cases_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
    runApp(const CareConnectApp());
  } catch (e) {
    print("Firebase initialization failed: $e");
    runApp(const FirebaseErrorApp());
  }
}

class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              const Text(
                'Initialization Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('Failed to connect to Firebase services.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CareConnectApp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/thankyou': (context) => const ThankYouScreen(),
          '/': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/admin_dashboard': (context) => const AdminDashboardScreen(),
          '/add_user': (context) => const AddUserScreen(),
          '/update_user': (context) => const UpdateUserScreen(),
          '/edit_patient': (context) => const EditPatientScreen(),
          '/patient_registration': (context) => const PatientRegistrationScreen(),
          '/appointments': (context) => const AppointmentScreen(),
          '/appointments_report': (context) => const AppointmentReportScreen(),
          '/patient_report': (context) => const PatientReportScreen(),
          '/vital_signs': (context) => const VitalSignsScreen(),
          '/doctors_notes': (context) => const DoctorsNotesScreen(),
          '/doctors_note_analysis': (context) => const DoctorsNoteAnalysisScreen(),
          '/analytics_dashboard': (context) => const AnalyticsDashboardScreen(),
          '/ml_predictions': (context) => const PredictionScreen(),
          '/bottesting': (context) => ChatScreen(),
          '/pending_appointments': (context) => const PendingAppointmentsScreen(),
          '/doctor_slots': (context) => DoctorSlotsScreen(doctorId: ''),
          '/critical_cases': (context) => const CriticalCasesScreen(),
        },
      ),
    );
  }
}