import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../authentication/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'pending_appointments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isSidebarExpanded = true;
  bool isPatientExpanded = false;
  bool isAnalyticsExpanded = false;
  bool isAppointmentsExpanded = false;
  bool isClinicalNotesExpanded = false;

  final double expandedWidth = 250;
  final double collapsedWidth = 70;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<DocumentSnapshot>? _userDocFuture;

  int pendingCount = 0;
  bool isDoctor = false;

  // Add this field to the class:
  String? _sidebarUserType;

  Future<void> _fetchPendingCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      isDoctor = userDoc['userType'] == 'Doctor';
      if (isDoctor) {
        final doctorName = userDoc['username'];
        final query = await _firestore.collection('appointments')
            .where('doctor', isEqualTo: doctorName)
            .where('status', isEqualTo: 'Pending Confirmation')
            .get();
        if (mounted) {
          setState(() {
            pendingCount = query.docs.length;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Cache the Firestore user Future in initState to prevent loading flashes
      _userDocFuture = FirebaseFirestore.instance.collection('Users').doc(currentUser.uid).get();
      _fetchPendingCount();
    }
  }

  void toggleSidebar() {
    setState(() {
      isSidebarExpanded = !isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery
        .of(context)
        .size
        .width > 800;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.indigo.shade700,
        leading: isLargeScreen
            ? IconButton(
          icon: const Icon(Icons.menu),
          onPressed: toggleSidebar,
        )
            : Builder(
          builder: (context) =>
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: <Widget>[
          if (isDoctor)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.amber),
                  tooltip: 'Pending Appointments',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PendingAppointmentsScreen()),
                    ).then((_) => _fetchPendingCount());
                  },
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 11,
                    top: 11,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                Provider.of<AuthService>(context, listen: false).signOut(),
          ),
        ],
      ),
      drawer: isLargeScreen ? null : Drawer(child: _buildSidebarContent()),
      body: Row(
        children: [
          if (isLargeScreen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSidebarExpanded ? expandedWidth : collapsedWidth,
              color: Colors.indigo.shade700,
              child: _buildSidebarContent(),
            ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE3E9FF),
                    Color(0xFFEEF2FB),
                    Color(0xFFD1D9F6)
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overview Statistics',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quick glance at today\'s key metrics',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.indigo.shade400,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.indigo
                              .shade900),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Statistics refreshed')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.indigo.shade200, thickness: 1),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: isLargeScreen ? 2 : 1,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: isLargeScreen ? 2.2 : 1.5,
                        children: [
                          // ===== [START MODIFIED CODE] =====
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('patients')
                                .snapshots(),
                            builder: (context, snapshot) {
                              final count = snapshot.hasData ? snapshot.data!
                                  .docs.length : 0;
                              return _buildStatisticCard(
                                title: 'Total Patients',
                                value: count.toString(),
                                icon: Icons.people,
                                imagePath: 'assets/images/patient.jpg',
                                color: Colors.blueAccent,
                              );
                            },
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseAuth.instance.currentUser == null
                                ? null
                                : _firestore.collection('appointments')
                                    .where('doctor', isEqualTo: FirebaseAuth.instance.currentUser != null ? null : '') // fallback
                                    .where('date', isEqualTo: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                                    .snapshots(),
                            builder: (context, snapshot) {
                              int count = 0;
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null && snapshot.hasData) {
                                final userDoc = snapshot.data!.docs;
                                count = userDoc.length;
                              }
                              return _buildStatisticCard(
                                title: 'Appointments Today',
                                value: count.toString(),
                                icon: Icons.calendar_today,
                                imagePath: 'assets/images/appointments.jpg',
                                color: Colors.deepPurpleAccent,
                              );
                            },
                          ),
                          // ===== [END MODIFIED CODE] =====
                          // ===== [DYNAMIC CRITICAL CASES] =====
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseAuth.instance.currentUser == null
                                ? null
                                : _firestore.collection('criticalCases')
                                    .where('doctor', isEqualTo: FirebaseAuth.instance.currentUser?.displayName)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              int count = 0;
                              if (snapshot.hasData) {
                                count = snapshot.data!.docs.length;
                              }
                              return _buildStatisticCard(
                                title: 'Critical Cases',
                                value: count.toString(),
                                icon: Icons.warning,
                                imagePath: 'assets/images/critical.jpg',
                                color: Colors.redAccent,
                              );
                            },
                          ),
                          // ===== [DYNAMIC PENDING REPORTS] =====
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseAuth.instance.currentUser == null
                                ? null
                                : _firestore.collection('appointments')
                                    .where('doctor', isEqualTo: FirebaseAuth.instance.currentUser?.displayName)
                                    .where('status', isEqualTo: 'Pending Confirmation')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              int count = 0;
                              if (snapshot.hasData) {
                                count = snapshot.data!.docs.length;
                              }
                              return _buildStatisticCard(
                                title: 'Pending Reports',
                                value: count.toString(),
                                icon: Icons.file_copy,
                                imagePath: 'assets/images/reports.jpg',
                                color: Colors.orangeAccent,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== [EXISTING CODE - NO CHANGES] =====
  Widget _buildSidebarContent() {
    final user = FirebaseAuth.instance.currentUser;
    String fullName = user?.displayName ?? 'User';
    String email = user?.email ?? '';

    if (user != null) {
      // Use the cached _userDocFuture so the FutureBuilder does not re-run on every rebuild
      return FutureBuilder<DocumentSnapshot>(
        future: _userDocFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              color: Colors.indigo.shade800,
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 36, color: Colors.indigo),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Loading...', style: TextStyle(color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                        Text('Loading...', style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                        Text('Loading...', style: TextStyle(color: Colors
                            .white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final firestoreUserType = data?['userType'] ?? '';
            final firestoreFullName = data?['username'] ?? fullName;
            final firestoreEmail = data?['email'] ?? email;
            // Set the sidebarUserType here
            _sidebarUserType = firestoreUserType;
            return ListView(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 48, horizontal: 24),
                  color: Colors.indigo.shade800,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                            Icons.person, size: 36, color: Colors.indigo),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(firestoreUserType, style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                            Text(firestoreFullName, style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                            Text(firestoreEmail, style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Logout',
                        onPressed: () async {
                          await Provider
                              .of<AuthService>(context, listen: false)
                              .signOut();
                          Navigator.pushNamedAndRemoveUntil(context, '/', (
                              route) => false);
                        },
                      ),
                    ],
                  ),
                ),
                ..._buildSidebarMenu(),
              ],
            );
          }
          // Fallback if no Firestore data
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 48, horizontal: 24),
                color: Colors.indigo.shade800,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 36, color: Colors.indigo),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('', style: TextStyle(color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                          Text(fullName, style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                          Text(email, style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: () async {
                        await Provider
                            .of<AuthService>(context, listen: false)
                            .signOut();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (route) => false);
                      },
                    ),
                  ],
                ),
              ),
              ..._buildSidebarMenu(),
            ],
          );
        },
      );
    }
    // If not logged in
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          color: Colors.indigo.shade800,
          child: const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 36, color: Colors.indigo),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Not logged in', style: TextStyle(color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                    Text('', style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                    Text('',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ..._buildSidebarMenu(),
      ],
    );
  }

  List<Widget> _buildSidebarMenu() {
    // Get userType from Firestore user doc (already loaded in _buildSidebarContent)
    String userType = '';
    final user = FirebaseAuth.instance.currentUser;
    if (_userDocFuture != null) {
      // This is a hack: _userDocFuture is a Future<DocumentSnapshot>, but we can't await here.
      // Instead, we rely on _buildSidebarContent to pass userType as a parameter if needed.
      // For now, we will use a workaround: store userType in a field when _buildSidebarContent runs.
    }
    // Instead, let's use a field to cache userType
    // We'll set it in _buildSidebarContent and use it here
    // Add a field: String sidebarUserType = '';
    // In _buildSidebarContent, set sidebarUserType = firestoreUserType;
    // Use sidebarUserType here
    // For now, fallback to Doctor if not set
    final sidebarUserType = _sidebarUserType ?? 'Doctor';

    return [
      ExpansionTile(
        title: isSidebarExpanded
            ? const Text('Patient', style: TextStyle(fontWeight: FontWeight.bold))
            : const SizedBox.shrink(),
        leading: Icon(Icons.person, color: Colors.indigo.shade900),
        initiallyExpanded: isPatientExpanded,
        children: isSidebarExpanded
            ? [
          ListTile(
            title: const Text('Registration'),
            onTap: sidebarUserType == 'Doctor' ? null : () {
              Navigator.pushNamed(context, '/patient_registration');
            },
            enabled: sidebarUserType != 'Doctor',
          ),
          ListTile(
            title: const Text('View Records'),
            onTap: () {
              Navigator.pushNamed(context, '/patient_report');
            },
          ),
        ]
            : [],
        onExpansionChanged: (expanded) => setState(() => isPatientExpanded = expanded),
      ),
      ExpansionTile(
        title: isSidebarExpanded
            ? const Text('Clinical Notes', style: TextStyle(fontWeight: FontWeight.bold))
            : const SizedBox.shrink(),
        leading: Icon(Icons.person, color: Colors.indigo.shade900),
        initiallyExpanded: isClinicalNotesExpanded,
        children: isSidebarExpanded
            ? [
          ListTile(
            title: const Text('Vital Signs'),
            onTap: sidebarUserType == 'Doctor' ? null : () {
              Navigator.pushNamed(context, '/vital_signs');
            },
            enabled: sidebarUserType != 'Doctor',
          ),
        ]
            : [],
        onExpansionChanged: (expanded) => setState(() => isClinicalNotesExpanded = expanded),
      ),
      ExpansionTile(
        title: isSidebarExpanded
            ? const Text('Analytics Dashboard', style: TextStyle(fontWeight: FontWeight.bold))
            : const SizedBox.shrink(),
        leading: Icon(Icons.analytics, color: Colors.indigo.shade900),
        initiallyExpanded: isAnalyticsExpanded,
        children: isSidebarExpanded
            ? [
          ListTile(
            title: const Text('Open Analytics Dashboard'),
            onTap: () {
              Navigator.pushNamed(context, '/analytics_dashboard');
            },
          ),
        ]
            : [],
        onExpansionChanged: (expanded) => setState(() => isAnalyticsExpanded = expanded),
      ),
      ExpansionTile(
        title: isSidebarExpanded
            ? const Text('Appointments', style: TextStyle(fontWeight: FontWeight.bold))
            : const SizedBox.shrink(),
        leading: Icon(Icons.calendar_today, color: Colors.indigo.shade900),
        initiallyExpanded: isAppointmentsExpanded,
        children: isSidebarExpanded
            ? [
          ListTile(title: const Text('Add'), onTap: () {
            Navigator.pushNamed(context, '/appointments');
          }),
          ListTile(title: const Text('All'), onTap: () {}),
          ListTile(title: const Text('Reports'), onTap: () {
            Navigator.pushNamed(context, '/appointments_report');
          }),
          ListTile(title: const Text('Doctor Slots'), onTap: () {
            Navigator.pushNamed(context, '/doctor_slots');
          }),
          ListTile(title: const Text('Pending Appointments'), onTap: () {
            Navigator.pushNamed(context, '/pending_appointments');
          }),
        ]
            : [],
        onExpansionChanged: (expanded) => setState(() => isAppointmentsExpanded = expanded),
      ),
      ExpansionTile(
        title: isSidebarExpanded
            ? const Text('Doctors Note Analysis', style: TextStyle(fontWeight: FontWeight.bold))
            : const SizedBox.shrink(),
        leading: Icon(Icons.insights, color: Colors.indigo.shade900),
        initiallyExpanded: false,
        children: isSidebarExpanded
            ? [
          ListTile(
            title: const Text('Analyze Note'),
            onTap: sidebarUserType == 'Nurse' ? null : () {
              Navigator.pushNamed(context, '/bottesting');
            },
            enabled: sidebarUserType != 'Nurse',
          ),
        ]
            : [],
        onExpansionChanged: (_) {},
      ),
      ExpansionTile(
        title: isSidebarExpanded
            ? const Text('ML Predictions', style: TextStyle(fontWeight: FontWeight.bold))
            : const SizedBox.shrink(),
        leading: Icon(Icons.science, color: Colors.green.shade700),
        initiallyExpanded: false,
        children: isSidebarExpanded
            ? [
          ListTile(
            title: const Text('Open ML Predictions'),
            onTap: sidebarUserType == 'Nurse' ? null : () {
              Navigator.pushNamed(context, '/ml_predictions');
            },
            enabled: sidebarUserType != 'Nurse',
          ),
        ]
            : [],
        onExpansionChanged: (_) {},
      ),
      ExpansionTile(
        title: isSidebarExpanded
            ? const Text('Critical Cases', style: TextStyle(fontWeight: FontWeight.bold))
            : const SizedBox.shrink(),
        leading: Icon(Icons.warning, color: Colors.red.shade700),
        initiallyExpanded: false,
        children: isSidebarExpanded
            ? [
          ListTile(
            title: const Text('View Critical Cases'),
            onTap: sidebarUserType == 'Nurse' ? null : () {
              Navigator.pushNamed(context, '/critical_cases');
            },
            enabled: sidebarUserType != 'Nurse',
          ),
        ]
            : [],
        onExpansionChanged: (_) {},
      ),
    ];
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required String imagePath,
    Color? color,
    VoidCallback? onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title tapped')),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    (color ?? Colors.indigo.shade100).withOpacity(0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (color ?? Colors.indigo).withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Blurred background image
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                    // Card content
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: (color ?? Colors.white).withOpacity(0.18),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (color ?? Colors.indigo).withOpacity(
                                      0.10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Icon(icon, size: 40,
                                color: (color ?? Colors.indigo.shade700)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: (color ?? Colors.indigo.shade900),
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: (color ?? Colors.indigo.shade800)
                                  .withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ], // close children of Column
                      ), // close Column
                    ), // close Center
                  ], // close children of Stack
                ), // close Stack
              ), // close ClipRRect
            ), // close Container
          ), // close GestureDetector
        ); // close Transform.scale
      }, // close builder
    ); // close TweenAnimationBuilder
  }
}