import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UpdateUserScreen extends StatefulWidget {
  const UpdateUserScreen({super.key});

  @override
  State<UpdateUserScreen> createState() => _UpdateUserScreenState();
}

class _UpdateUserScreenState extends State<UpdateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTitle;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _verifyPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool? _isActive;
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  final TextEditingController _idNumberController = TextEditingController();
  String? _selectedUserRole;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final query = await FirebaseFirestore.instance.collection('Users').get();
    setState(() {
      _users = query.docs.map((doc) => {...doc.data(), 'docId': doc.id}).toList();
    });
  }

  void _onUserSelected(Map<String, dynamic>? user) {
    setState(() {
      _selectedUser = user;
      if (user != null) {
        _nameController.text = user['name'] ?? '';
        _emailController.text = user['email'] ?? '';
        _idNumberController.text = user['idNumber'] ?? '';
        _usernameController.text = user['username'] ?? '';
        _selectedUserRole = user['userType'];
        _isActive = user['isActive'] ?? true;
        _passwordController.clear();
        _verifyPasswordController.clear();
        _currentPasswordController.clear();
      } else {
        _nameController.clear();
        _emailController.clear();
        _idNumberController.clear();
        _usernameController.clear();
        _selectedUserRole = null;
        _isActive = true;
        _passwordController.clear();
        _verifyPasswordController.clear();
        _currentPasswordController.clear();
      }
    });
  }

  void _updateUser() async {
    if (_formKey.currentState!.validate() && _selectedUser != null) {
      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String idNumber = _idNumberController.text.trim();
      final String? userType = _selectedUserRole;
      final String username = _usernameController.text.trim();
      final bool isActive = _isActive ?? true;
      final String currentPassword = _currentPasswordController.text.trim();
      final String password = _passwordController.text.trim();
      final String verifyPassword = _verifyPasswordController.text.trim();

      if (userType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a user type.')),
        );
        return;
      }
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter full name.')),
        );
        return;
      }
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email.')),
        );
        return;
      }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address.')),
        );
        return;
      }
      if (idNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter User ID number.')),
        );
        return;
      }
      if (username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter username.')),
        );
        return;
      }
      if (password.isNotEmpty && password != verifyPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }
      try {
        // Update Firestore user details
        await FirebaseFirestore.instance.collection('Users').doc(_selectedUser!['docId']).update({
          'userType': userType,
          'name': name,
          'email': email,
          'idNumber': idNumber,
          'username': username,
          'isActive': isActive,
        });
        // If password is being changed, update in Firebase Auth
        if (password.isNotEmpty) {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null && user.email == email) {
            final cred = EmailAuthProvider.credential(email: email, password: currentPassword);
            await user.reauthenticateWithCredential(cred);
            await user.updatePassword(password);
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!')),
        );
        _fetchUsers();
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update User')),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedUser,
                      decoration: const InputDecoration(
                        labelText: 'Select User',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      items: _users.map((user) => DropdownMenuItem(
                        value: user,
                        child: Text('${user['name']} (${user['idNumber']})'),
                      )).toList(),
                      onChanged: _onUserSelected,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedUserRole,
                      decoration: const InputDecoration(
                        labelText: 'User Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      items: ['Doctor', 'Nurse', 'Admin']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUserRole = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a user type' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter full name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(
                        labelText: 'User ID Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter User ID number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_circle),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_open),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _verifyPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Verify Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _isActive ?? true,
                      onChanged: (val) {
                        setState(() {
                          _isActive = val;
                        });
                      },
                      secondary: const Icon(Icons.check_circle),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Update User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _updateUser,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
