// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:provider/provider.dart';
// import '../authentication/auth_service.dart';
// import 'forgot_password_screen.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   String _userType = 'doctor';
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//
//   // Future<void> _login() async {
//   //   // 1. Validate form
//   //   if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
//   //     return;
//   //   }
//   //
//   //   if (!mounted) return;
//   //   setState(() => _isLoading = true);
//   //
//   //   try {
//   //     debugPrint('Attempting login for username: ${_usernameController.text}');
//   //
//   //     // 2. Find user document
//   //     final querySnapshot = await FirebaseFirestore.instance
//   //         .collection('careConnectApp')
//   //         .where('username', isEqualTo: _usernameController.text.trim())
//   //         .limit(1)
//   //         .get();
//   //
//   //     if (querySnapshot.docs.isEmpty) {
//   //       throw 'User not found. Please check username or register.';
//   //     }
//   //
//   //     final userDoc = querySnapshot.docs.first;
//   //     final userData = userDoc.data() as Map<String, dynamic>? ?? {};
//   //
//   //     debugPrint('Found user document: ${userDoc.id}');
//   //     debugPrint('User data: $userData');
//   //
//   //     // 3. Get email from document
//   //     final userEmail = userData['email'] as String?;
//   //     if (userEmail == null || userEmail.isEmpty) {
//   //       throw 'No email associated with this account. Contact support.';
//   //     }
//   //
//   //     // 4. Verify user type
//   //     final storedUserType = userData['userType'] as String?;
//   //     if (storedUserType == null || storedUserType != _userType) {
//   //       throw 'Access denied. Your account type is $storedUserType';
//   //     }
//   //
//   //     // 5. Authenticate with Firebase Auth
//   //     debugPrint('Attempting authentication with email: $userEmail');
//   //     await Provider.of<AuthService>(context, listen: false)
//   //         .signInWithEmailAndPassword(
//   //       email: userEmail,
//   //       password: _passwordController.text.trim(),
//   //       userType: _userType,
//   //     );
//   //
//   //     debugPrint('Authentication successful!');
//   //
//   //   } on FirebaseAuthException catch (e) {
//   //     _showError(e.code.replaceAll('-', ' ').capitalize());
//   //   } catch (e) {
//   //     _showError(e.toString().replaceAll('AuthException: ', ''));
//   //   } finally {
//   //     if (mounted) {
//   //       setState(() => _isLoading = false);
//   //     }
//   //   }
//   // }
//   Future<void> _login() async {
//     if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
//       return;
//     }
//     setState(() => _isLoading = true);
//     final notificationsRef = FirebaseFirestore.instance.collection('adminNotifications');
//     try {
//       final email = _emailController.text.trim();
//       debugPrint('Attempting login for email: $email');
//       // 1. Find user document in 'Users' collection by email
//       final userSnapshot = await FirebaseFirestore.instance
//           .collection('Users')
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();
//       if (userSnapshot.docs.isEmpty) {
//         // Notify admin of failed login
//         await notificationsRef.add({
//           'type': 'login_failed',
//           'message': 'Failed login attempt for email: $email',
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//         throw 'User not found';
//       }
//       final userData = userSnapshot.docs.first.data();
//       final userType = userData['userType'] as String? ?? '';
//       // 2. Authenticate
//       debugPrint('Attempting auth with email: $email');
//       final auth = Provider.of<AuthService>(context, listen: false);
//       try {
//         final user = await auth.signInWithEmailAndPassword(
//           email: email,
//           password: _passwordController.text.trim(),
//           userType: userType,
//         );
//         if (user != null) {
//           // Notify admin of successful login
//           await notificationsRef.add({
//             'type': 'login_success',
//             'message': 'User ${userData['username'] ?? email} logged in successfully.',
//             'timestamp': FieldValue.serverTimestamp(),
//           });
//           debugPrint('Login success!');
//           if (userType.toLowerCase() == 'admin') {
//             Navigator.pushReplacementNamed(context, '/admin_dashboard');
//           } else {
//             Navigator.pushReplacementNamed(context, '/dashboard');
//           }
//         }
//       } on AuthException catch (e) {
//         // Notify admin of failed login
//         await notificationsRef.add({
//           'type': 'login_failed',
//           'message': 'Failed login attempt for user: ${userData['username'] ?? email}',
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//         _showError(e.message);
//       }
//     } catch (e) {
//       _showError('Login failed. Please try again.');
//       debugPrint('Login error: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   void _showError(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//     debugPrint('Error: $message');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blue.shade300, Colors.blue.shade900],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Card(
//                 elevation: 8,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: Colors.blue.shade100,
//                           child: Icon(
//                             Icons.account_box_outlined,
//                             size: 50,
//                             color: Colors.blue.shade900,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         Text(
//                           'Care Connect',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue.shade900,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'Login to your account',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _usernameController,
//                           decoration: const InputDecoration(
//                             labelText: 'Username',
//                             border: OutlineInputBorder(),
//                             prefixIcon: Icon(Icons.person),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter username';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 10),
//                         TextFormField(
//                           controller: _passwordController,
//                           obscureText: _obscurePassword,
//                           decoration: const InputDecoration(
//                             labelText: 'Password',
//                             border: OutlineInputBorder(),
//                             prefixIcon: Icon(Icons.lock),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter password';
//                             }
//                             if (value.length < 6) {
//                               return 'Password too short';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 10),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => const ForgotPasswordScreen(),
//                                 ),
//                               );
//                             },
//                             child: Text(
//                               'Forgot Password?',
//                               style: TextStyle(color: Colors.blue.shade900),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 40, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                             backgroundColor: Colors.blue.shade600,
//                           ),
//                           onPressed: _isLoading ? null : _login,
//                           child: _isLoading
//                               ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                             ),
//                           )
//                               : const Text(
//                             'Login',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// extension StringExtension on String {
//   String capitalize() {
//     return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../authentication/auth_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    final notificationsRef = FirebaseFirestore.instance.collection('adminNotifications');
    try {
      final email = _emailController.text.trim();
      debugPrint('Attempting login for email: $email');
      // 1. Find user document in 'Users' collection by email
      final userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (userSnapshot.docs.isEmpty) {
        // Notify admin of failed login
        await notificationsRef.add({
          'type': 'login_failed',
          'message': 'Failed login attempt for email: $email',
          'timestamp': FieldValue.serverTimestamp(),
        });
        throw 'User not found';
      }
      final userData = userSnapshot.docs.first.data();
      final userType = userData['userType'] as String? ?? '';
      // 2. Authenticate
      debugPrint('Attempting auth with email: $email');
      final auth = Provider.of<AuthService>(context, listen: false);
      try {
        final user = await auth.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
          userType: userType,
        );
        if (user != null) {
          // Notify admin of successful login
          await notificationsRef.add({
            'type': 'login_success',
            'message': 'User ${userData['username'] ?? email} logged in successfully.',
            'timestamp': FieldValue.serverTimestamp(),
          });
          debugPrint('Login success!');
          if (userType.toLowerCase() == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } on AuthException catch (e) {
        // Notify admin of failed login
        await notificationsRef.add({
          'type': 'login_failed',
          'message': 'Failed login attempt for user: ${userData['username'] ?? email}',
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showError(e.message);
      }
    } catch (e) {
      _showError('Login failed. Please try again.');
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo (same as splash screen)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.health_and_safety, color: Color(0xFF42A5F5), size: 80),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Care Connect',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF42A5F5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Login to your account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(() =>
                              _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.length < 6) {
                              return 'Password too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            backgroundColor: Colors.blue.shade600,
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}