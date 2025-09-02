import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  String? _selectedPatientId;
  String? _selectedPatientName;
  List<Map<String, dynamic>> _patientSearchResults = [];
  String? _botReply;

  OverlayEntry? _patientDropdown;
  final LayerLink _dropdownLink = LayerLink();
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchBarKey = GlobalKey();

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showPatientDropdown(BuildContext context) {
    _removePatientDropdown(); // Always remove any existing overlay first
    if (_patientSearchResults.isEmpty) return;
    final overlay = Overlay.of(context);
    final renderBox = _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    _patientDropdown = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 4,
          child: SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: _patientSearchResults.length,
              itemBuilder: (context, idx) {
                final p = _patientSearchResults[idx];
                return ListTile(
                  title: Text(p['name'] ?? ''),
                  subtitle: Text('ID: \\${p['idNumber'] ?? p['id']}'),
                  onTap: () {
                    setState(() {
                      _selectedPatientId = p['idNumber'] ?? p['id'];
                      _selectedPatientName = p['name'] ?? '';
                      _searchController.text = p['name'] ?? '';
                      _patientSearchResults = [];
                    });
                    _removePatientDropdown();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    overlay.insert(_patientDropdown!);
  }

  void _removePatientDropdown() {
    _patientDropdown?.remove();
    _patientDropdown = null;
  }

  Future<void> _searchPatients(String query) async {
    final firestore = FirebaseFirestore.instance;
    final results = <Map<String, dynamic>>[];
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      final allPatients = await firestore.collection('patients').get();
      for (var doc in allPatients.docs) {
        final name = (doc.data()['name'] ?? '').toString();
        final id = (doc.data()['idNumber'] ?? '').toString();
        if (name.toLowerCase().contains(lowerQuery) || id.toLowerCase().contains(lowerQuery)) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }
    }
    setState(() {
      _patientSearchResults = results;
    });
  }

  Future<void> _sendMessageToBot(String text) async {
    setState(() { _botReply = null; });
    final response = await http.post(
      Uri.parse("https://api.aimlapi.com/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer 17e04b96d7a649a5940a95482fc5ede1",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "user", "content": text}
        ],
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = jsonDecode(response.body);
        final reply = data["choices"]?[0]?["message"]?["content"] ??
            data["choices"]?[0]?["text"] ??
            "No reply found.";
        setState(() { _botReply = reply; });
      } catch (e) {
        setState(() { _botReply = "Failed to parse reply."; });
      }
    } else {
      setState(() {
        _botReply = "Error: \\${response.statusCode}\\n\\${response.body}";
      });
    }
  }

  Future<void> _saveNote() async {
    if (_selectedPatientId == null || _controller.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    String? doctorName;
    if (user != null) {
      // Try to get displayName, fallback to email, fallback to UID
      doctorName = user.displayName ?? user.email ?? user.uid;
    }
    await FirebaseFirestore.instance.collection('doctorsNotes').add({
      'patientId': _selectedPatientId,
      'patientName': _selectedPatientName,
      'notes': _controller.text.trim(),
      'doctorName': doctorName ?? 'Unknown Doctor',
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved!')));
    setState(() { _controller.clear(); });
  }

  Future<void> _saveAnalysis() async {
    if (_selectedPatientId == null || _botReply == null || _botReply!.isEmpty) return;
    await FirebaseFirestore.instance.collection('analysedNotes').add({
      'patientId': _selectedPatientId,
      'patientName': _selectedPatientName,
      'notes': _controller.text.trim(),
      'analysis': _botReply,
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analysis saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Doctors Notes")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompositedTransformTarget(
                key: _searchBarKey,
                link: _dropdownLink,
                child: TextFormField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: "Search patient by name or ID",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) async {
                    await _searchPatients(query);
                    if (_patientSearchResults.isNotEmpty && _searchFocus.hasFocus) {
                      _showPatientDropdown(context);
                    } else {
                      _removePatientDropdown();
                    }
                  },
                  onTap: () {
                    if (_patientSearchResults.isNotEmpty) {
                      _showPatientDropdown(context);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16), // Add spacing between search and message box
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.note),
                      label: Text('View Previous Notes'),
                      onPressed: _selectedPatientId == null ? null : () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SizedBox(
                            height: 350,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('doctorsNotes')
                                  .where('patientId', isEqualTo: _selectedPatientId)
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return const Center(child: Text('No previous notes found.'));
                                }
                                return ListView.builder(
                                  itemCount: docs.length,
                                  itemBuilder: (context, idx) {
                                    final note = docs[idx].data() as Map<String, dynamic>;
                                    return ListTile(
                                      title: Text(note['notes'] ?? ''),
                                      subtitle: Text(note['createdAt'] != null ? note['createdAt'].toDate().toString() : ''),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.analytics),
                      label: Text('View Previous Analysis'),
                      onPressed: _selectedPatientId == null ? null : () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SizedBox(
                            height: 350,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('analysedNotes')
                                  .where('patientId', isEqualTo: _selectedPatientId)
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return const Center(child: Text('No previous analysis found.'));
                                }
                                return ListView.builder(
                                  itemCount: docs.length,
                                  itemBuilder: (context, idx) {
                                    final note = docs[idx].data() as Map<String, dynamic>;
                                    return ListTile(
                                      title: Text(note['analysis'] ?? ''),
                                      subtitle: Text(note['createdAt'] != null ? note['createdAt'].toDate().toString() : ''),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Add spacing between buttons and message box
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Enter health care issue...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        _sendMessageToBot(_controller.text.trim());
                      }
                    },
                  ),
                ],
              ),
              if (_botReply != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_botReply!, style: TextStyle(fontSize: 16)),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text('Save Note'),
                      onPressed: _saveNote,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.analytics),
                      label: Text('Save Analysis'),
                      onPressed: _saveAnalysis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}