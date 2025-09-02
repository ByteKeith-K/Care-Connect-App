import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  Map<String, dynamic>? _statsData;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _patients = [];
  String? _selectedPatientId;
  String _patientSearch = '';

  Future<void> _fetchPatients() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.27.104/patients'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _patients = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      // Ignore patient fetch errors for now
    }
  }

  Future<void> _fetchStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      String url = 'http://192.168.27.104/statistics';
      if (_selectedPatientId != null) {
        url += '?patient_id=$_selectedPatientId';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _statsData = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch statistics: \\${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: \\${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _fetchStats();
  }

  Widget _buildTable(Map<String, dynamic> data) {
    final keys = data.keys.toList();
    final firstRow = data[keys.first];
    final columns = firstRow is Map ? firstRow.keys.toList() : <String>[];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
          ...columns.map((c) => DataColumn(label: Text(c)))
        ],
        rows: keys.map((k) {
          final row = data[k];
          return DataRow(cells: [
            DataCell(Text(k)),
            ...columns.map((c) => DataCell(Text(row[c]?.toString() ?? '-')))
          ]);
        }).toList(),
      ),
    );
  }

  // Chart for BP time series
  Widget _buildLineChart(List<dynamic> data) {
    if (data.isEmpty) return const Text('No time series data.');
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      final x = i.toDouble();
      final y = (entry['systolicBP'] ?? entry['systolicbp'] ?? entry['value'] ?? 0).toDouble();
      spots.add(FlSpot(x, y));
    }
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.indigo,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // Chart for histograms and group bar charts
  Widget _buildBarChart(List<String> labels, List<num> values) {
    if (values.isEmpty) return const Text('No data.');
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: [
            for (int i = 0; i < values.length; i++)
              BarChartGroupData(x: i, barRods: [BarChartRodData(toY: values[i].toDouble(), color: Colors.indigo)])
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final idx = value.toInt();
                  return idx >= 0 && idx < labels.length
                      ? Text(labels[idx], style: const TextStyle(fontSize: 10))
                      : const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // Fix correlation table to not use toStringAsFixed on dynamic
  Widget _buildCorrelationTable(Map<String, dynamic> data) {
    final rows = data.keys.toList();
    final cols = rows;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [DataColumn(label: Text(''))] + cols.map((c) => DataColumn(label: Text(c))).toList(),
        rows: rows.map((r) => DataRow(cells: [
          DataCell(Text(r)),
          ...cols.map((c) {
            final val = data[r]?[c];
            return DataCell(Text(val is num ? val.toStringAsFixed(2) : (val?.toString() ?? '-')));
          })
        ])).toList(),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final stats = _statsData;
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Patient Analytics Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          if (_selectedPatientId != null)
            pw.Text('Patient ID: ${_selectedPatientId}', style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 8),
          if (stats != null) ...[
            pw.Text('Summary Statistics', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(stats['summary']?.toString() ?? 'No summary data.'),
            pw.SizedBox(height: 8),
            pw.Text('Correlation Matrix', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(stats['correlation_matrix']?.toString() ?? 'No correlation data.'),
            pw.SizedBox(height: 8),
            pw.Text('Summary by Gender', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(stats['summary_by_gender']?.toString() ?? 'No gender breakdown.'),
            pw.SizedBox(height: 8),
            pw.Text('Summary by Age Group', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(stats['summary_by_age_group']?.toString() ?? 'No age group breakdown.'),
            pw.SizedBox(height: 8),
            pw.Text('Summary by Medical History', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(stats['summary_by_medical_history']?.toString() ?? 'No medical history breakdown.'),
            pw.SizedBox(height: 8),
            pw.Text('Regression: Systolic BP vs Age', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(stats['systolicBP_vs_age']?['summary']?.toString() ?? 'No regression data.'),
          ]
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildPatientDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Patient:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search by name',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (val) {
            setState(() { _patientSearch = val.trim().toLowerCase(); });
          },
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          value: _selectedPatientId,
          hint: const Text('All Patients'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('All Patients')),
            ..._patients.where((p) =>
              _patientSearch.isEmpty || (p['name']?.toLowerCase().contains(_patientSearch) ?? false)
            ).map((p) => DropdownMenuItem<String>(
              value: p['id'],
              child: Text(p['name'] != null && p['name'].toString().isNotEmpty ? '${p['name']} (${p['id']})' : p['id']),
            ))
          ],
          onChanged: (val) {
            setState(() { _selectedPatientId = val; });
            _fetchStats();
          },
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: _fetchStats,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Export JSON'),
                onPressed: _statsData == null ? null : () {
                  final jsonStr = const JsonEncoder.withIndent('  ').convert(_statsData);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Export Analytics JSON'),
                      content: SingleChildScrollView(child: SelectableText(jsonStr)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                onPressed: _statsData == null ? null : _exportPdf,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView() {
    if (_statsData == null) return const Text('No analytics data available.');
    final summary = _statsData!['summary'] as Map<String, dynamic>?;
    final regression = _statsData!['systolicBP_vs_age'] as Map<String, dynamic>?;
    final corr = _statsData!['correlation_matrix'] as Map<String, dynamic>?;
    final byGender = _statsData!['summary_by_gender'] as Map<String, dynamic>?;
    final byAgeGroup = _statsData!['summary_by_age_group'] as Map<String, dynamic>?;
    final byMedHist = _statsData!['summary_by_medical_history'] as Map<String, dynamic>?;
    final bpTimeSeries = _statsData!['bp_time_series'] as List<dynamic>?;
    final ageHist = _statsData!['age_histogram'] as Map<String, dynamic>?;
    return ListView(
      children: [
        _buildPatientDropdown(),
        const SizedBox(height: 16),
        const Text('Patient Analytics Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Summary Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                summary != null ? _buildTable(summary) : const Text('No summary data.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Correlation Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                corr != null ? _buildCorrelationTable(corr) : const Text('No correlation data.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Summary by Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                byGender != null && byGender.isNotEmpty
                  ? _buildTable(byGender)
                  : const Text('No gender breakdown available.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (byAgeGroup != null && byAgeGroup.isNotEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary by Age Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildTable(byAgeGroup),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (byMedHist != null && byMedHist.isNotEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary by Medical History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildTable(byMedHist),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (bpTimeSeries != null && bpTimeSeries.isNotEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Systolic BP Over Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildLineChart(bpTimeSeries),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (ageHist != null && ageHist['counts'] != null && ageHist['bins'] != null) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Age Distribution Histogram', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildBarChart(
                    List<String>.generate(ageHist['bins'].length - 1, (i) =>
                      '${ageHist['bins'][i]}-${ageHist['bins'][i + 1] - 1}'),
                    List<num>.from(ageHist['counts']),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Regression: Systolic BP vs Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (regression != null) ...[
                  Text('R²: 	${regression['rsquared'] ?? '-'}'),
                  Text('P-values: ${regression['pvalues'] ?? '-'}'),
                  Text('Coefficients: ${regression['params'] ?? '-'}'),
                  ExpansionTile(
                    title: const Text('Full Regression Summary'),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(regression['summary'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text('No regression analysis available.'),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('About this app'),
                  content: const Text('Patient Analytics Dashboard v1.0\n\n'
                      'This app provides analytics and reporting features for patient data.\n'
                      'Developed by Your Name.'),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text('Error: $_error'))
          : _buildStatsView(),
    );
  }
}
