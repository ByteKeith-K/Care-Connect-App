import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentReportScreen extends StatefulWidget {
  const AppointmentReportScreen({super.key});

  @override
  State<AppointmentReportScreen> createState() => _AppointmentReportScreenState();
}

class _AppointmentReportScreenState extends State<AppointmentReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== [NEW METHOD ADDED TO FIX ERROR] =====
  Widget _buildSummaryCards(List<QueryDocumentSnapshot> appointments) {
    final confirmedCount = appointments.where((doc) =>
    (doc.data() as Map<String, dynamic>)['status'] == 'Confirmed').length;
    final pendingCount = appointments.length - confirmedCount;
    final todayCount = appointments.where((doc) {
      final date = (doc.data() as Map<String, dynamic>)['date'] as Timestamp;
      return DateFormat('yyyy-MM-dd').format(date.toDate()) ==
          DateFormat('yyyy-MM-dd').format(DateTime.now());
    }).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard('Total', appointments.length, Colors.blue),
        _buildStatCard('Today', todayCount, Colors.purple),
        _buildStatCard('Confirmed', confirmedCount, Colors.green),
        _buildStatCard('Pending', pendingCount, Colors.orange),
      ],
    );
  }
  // ===== [END OF NEW METHOD] =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Reports")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDateFilterControls(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('appointments')
                    .where('date', isGreaterThanOrEqualTo: _startDate ?? DateTime(2000))
                    .where('date', isLessThanOrEqualTo: _endDate ?? DateTime(2100))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final appointments = snapshot.data!.docs;

                  return Column(
                    children: [
                      _buildSummaryCards(appointments), // This now works
                      const SizedBox(height: 16),
                      const Text(
                        'Appointments List',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointments[index].data() as Map<String, dynamic>;
                            return Card(
                              elevation: 2,
                              child: ListTile(
                                title: Text('${appointment['patient']} with ${appointment['doctor']}'),
                                subtitle: Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format((appointment['date'] as Timestamp).toDate())} at ${appointment['slot']}',
                                ),
                                trailing: Chip(
                                  label: Text(
                                    appointment['status'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: appointment['status'] == 'Confirmed'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: "Start Date",
                selectedDate: _startDate,
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDatePicker(
                label: "End Date",
                selectedDate: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Export PDF"),
          onPressed: () => _exportToPDF(),
        ),
      ],
    );
  }

  Future<void> _exportToPDF() async {
    final querySnapshot = await _firestore.collection('appointments')
        .where('date', isGreaterThanOrEqualTo: _startDate ?? DateTime(2000))
        .where('date', isLessThanOrEqualTo: _endDate ?? DateTime(2100))
        .get();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Appointment Report", style: const pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            ...querySnapshot.docs.map((doc) {
              final data = doc.data();
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  "${data['patient']} - ${data['doctor']} on ${DateFormat('yyyy-MM-dd').format((data['date'] as Timestamp).toDate())} at ${data['slot']} [${data['status']}]",
                  style: const pw.TextStyle(fontSize: 14),
                ),
              );
            }),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(selectedDate == null
            ? 'Select date'
            : DateFormat('yyyy-MM-dd').format(selectedDate)),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      elevation: 3,
      color: color.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}