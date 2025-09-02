// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Stream<User?> get authStateChanges => _auth.authStateChanges();
//
//   // Future<User?> signInWithEmailAndPassword({
//   //   required String email,
//   //   required String password,
//   //   String? userType,
//   // }) async {
//   //   try {
//   //     // Enhanced input validation
//   //     if (email.isEmpty || !email.contains('@')) {
//   //       throw AuthException('Please enter a valid email address');
//   //     }
//   //     if (password.isEmpty) {
//   //       throw AuthException('Password is required');
//   //     }
//   //
//   //     // Authenticate with Firebase Auth
//   //     final credential = await _auth.signInWithEmailAndPassword(
//   //       email: email.trim(),
//   //       password: password.trim(),
//   //     );
//   //
//   //     // Get user document with additional validation
//   //     final userDoc = await _firestore.collection('careConnectApp')
//   //         .where('email', isEqualTo: email.trim())
//   //         .limit(1)
//   //         .get();
//   //
//   //     if (userDoc.docs.isEmpty) {
//   //       await _auth.signOut();
//   //       throw AuthException('Account not properly configured');
//   //     }
//   //
//   //     final userData = userDoc.docs.first.data();
//   //     debugPrint('User document: ${userDoc.docs.first.id} - $userData');
//   //
//   //     // Comprehensive validation
//   //     if (userData['email'] == null || userData['email']!.isEmpty) {
//   //       await _auth.signOut();
//   //       throw AuthException('Account missing email configuration');
//   //     }
//   //
//   //     if (userData['isActive'] != true) {
//   //       await _auth.signOut();
//   //       throw AuthException('Account deactivated. Contact admin.');
//   //     }
//   //
//   //     if (userType != null) {
//   //       final storedUserType = userData['userType']?.toString();
//   //       if (storedUserType == null) {
//   //         await _auth.signOut();
//   //         throw AuthException('Account missing user type');
//   //       }
//   //       if (storedUserType != userType) {
//   //         await _auth.signOut();
//   //         throw AuthException('Access denied for $userType');
//   //       }
//   //     }
//   //
//   //     await _updateLastLogin(userDoc.docs.first.reference);
//   //     return credential.user;
//   //   } on FirebaseAuthException catch (e) {
//   //     throw AuthException(_mapAuthError(e.code));
//   //   } catch (e) {
//   //     debugPrint('Auth error: $e');
//   //     throw AuthException('Login failed. Please try again.');
//   //   }
//   // }
//   // auth_service.dart
//   Future<User?> signInWithEmailAndPassword({
//     required String email,
//     required String password,
//     String? userType,
//   }) async {
//     try {
//       // Input validation
//       if (email.isEmpty || password.isEmpty) {
//         throw AuthException('Email and password are required');
//       }
//
//       // Authenticate with Firebase Auth
//       final credential = await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );
//
//       // Get user document
//       final userDoc = await _firestore.collection('careConnectApp')
//           .where('email', isEqualTo: email.trim())
//           .limit(1)
//           .get();
//
//       if (userDoc.docs.isEmpty) {
//         await _auth.signOut();
//         throw AuthException('Account not properly configured');
//       }
//
//       final userData = userDoc.docs.first.data();
//
//       // Validate account status
//       if (userData['isActive'] != true) {
//         await _auth.signOut();
//         throw AuthException('Account deactivated');
//       }
//
//       if (userType != null && userData['userType'] != userType) {
//         await _auth.signOut();
//         throw AuthException('Access denied for $userType');
//       }
//
//       return credential.user;
//     } on FirebaseAuthException catch (e) {
//       throw AuthException(_mapAuthError(e.code));
//     } catch (e) {
//       debugPrint('Auth error: $e');
//       throw AuthException('Login failed. Please try again.');
//     }
//   }
//
//   Future<void> sendPasswordResetEmail(String email) async {
//     try {
//       if (!email.contains('@')) {
//         throw AuthException('Please enter a valid email address');
//       }
//
//       await _auth.sendPasswordResetEmail(email: email.trim());
//     } on FirebaseAuthException catch (e) {
//       throw AuthException(_mapAuthError(e.code));
//     }
//   }
//
//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//     } catch (e) {
//       debugPrint('Sign out error: $e');
//       throw AuthException('Failed to sign out. Please try again.');
//     }
//   }
//
//   Future<void> _updateLastLogin(DocumentReference userRef) async {
//     try {
//       await userRef.update({
//         'lastLogin': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       debugPrint('Failed to update last login: $e');
//     }
//   }
//
//   String _mapAuthError(String code) {
//     switch (code) {
//       case 'user-not-found':
//       case 'wrong-password':
//         return 'Invalid credentials';
//       case 'too-many-requests':
//         return 'Too many attempts. Try again later.';
//       case 'user-disabled':
//         return 'Account disabled. Contact admin.';
//       case 'invalid-email':
//         return 'Please enter a valid email';
//       default:
//         return 'Authentication failed';
//     }
//   }
// }
//
// class AuthException implements Exception {
//   final String message;
//   AuthException(this.message);
//
//   @override
//   String toString() => message;
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
    String? userType,
  }) async {
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }

      // Authenticate with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Get user document from Firestore
      final userDoc = await _firestore.collection('Users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        await _auth.signOut();
        throw AuthException('User not registered');
      }

      final userData = userDoc.docs.first.data();
      debugPrint('User Data: $userData');

      // Validate account status
      if (userData['isActive'] != true) {
        await _auth.signOut();
        throw AuthException('Account deactivated. Contact admin.');
      }

      if (userType != null && userData['userType'] != userType) {
        await _auth.signOut();
        throw AuthException('You do not have $userType access');
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    } catch (e, stackTrace) {
      debugPrint('Auth error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw AuthException('Login failed. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (!email.contains('@')) {
        throw AuthException('Please enter a valid email address');
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw AuthException('Failed to sign out. Please try again.');
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid credentials';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'user-disabled':
        return 'Account disabled. Contact admin.';
      case 'invalid-email':
        return 'Please enter a valid email';
      default:
        return 'Authentication failed';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}