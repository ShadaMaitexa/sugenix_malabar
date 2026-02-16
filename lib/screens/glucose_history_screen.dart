import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugenix/services/glucose_service.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';

class GlucoseHistoryScreen extends StatefulWidget {
  const GlucoseHistoryScreen({super.key});

  @override
  State<GlucoseHistoryScreen> createState() => _GlucoseHistoryScreenState();
}

class _GlucoseHistoryScreenState extends State<GlucoseHistoryScreen> {
  final GlucoseService _glucoseService = GlucoseService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _loading = false;
  List<Map<String, dynamic>> _readings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      await _load();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      await _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _glucoseService.getGlucoseReadingsByDateRange(
        startDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
        endDate:
            DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      );
      setState(() => _readings = list);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportCSV() async {
    if (_readings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    final List<List<dynamic>> csvData = [
      [
        'Date',
        'Time',
        'Value (mg/dL)',
        'Type',
        'Notes',
        'AI Flagged',
        'AI Analysis'
      ]
    ];

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (final r in _readings) {
      final ts = (r['timestamp'] as Timestamp?)?.toDate();
      csvData.add([
        ts != null ? dateFormat.format(ts) : '',
        ts != null ? timeFormat.format(ts) : '',
        (r['value'] ?? '').toString(),
        (r['type'] ?? '').toString(),
        (r['notes'] ?? '').toString(),
        (r['isAIFlagged'] ?? false).toString(),
        (r['aiAnalysis'] ?? '').toString(),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final bytes = utf8.encode(csvString);
    final fileName =
        'glucose_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      (html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click());
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      try {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CSV exported to: $path'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to export CSV: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportPDF() async {
    if (_readings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Glucose History Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Date Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Date & Time', isHeader: true),
                      _buildTableCell('Value (mg/dL)', isHeader: true),
                      _buildTableCell('Type', isHeader: true),
                      _buildTableCell('Status', isHeader: true),
                      _buildTableCell('Notes', isHeader: true),
                    ],
                  ),
                  ..._readings.map((r) {
                    final ts = (r['timestamp'] as Timestamp?)?.toDate();
                    final value = ((r['value'] as num?)?.toDouble() ?? 0.0);
                    final type = (r['type'] as String?) ?? '';
                    final isFlagged = (r['isAIFlagged'] as bool?) ?? false;
                    final status = _getStatusText(value, isFlagged);

                    return pw.TableRow(
                      children: [
                        _buildTableCell(
                            ts != null ? dateFormat.format(ts) : '—'),
                        _buildTableCell(value.toStringAsFixed(0)),
                        _buildTableCell(type.toUpperCase()),
                        _buildTableCell(status),
                        _buildTableCell((r['notes'] ?? '').toString()),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Summary Statistics',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildSummaryStats(),
            ];
          },
        ),
      );

      final fileName =
          'glucose_history_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final bytes = await pdf.save();
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF exported to: $path'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _getStatusText(double value, bool isFlagged) {
    if (value < 70) return 'LOW';
    if (value > 180) return 'HIGH';
    return 'NORMAL';
  }

  pw.Widget _buildSummaryStats() {
    if (_readings.isEmpty) {
      return pw.Text('No statistics available');
    }

    final values = _readings
        .map((r) => ((r['value'] as num?)?.toDouble() ?? 0.0))
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) {
      return pw.Text('No statistics available');
    }

    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final normalCount = values.where((v) => v >= 70 && v <= 180).length;
    final highCount = values.where((v) => v > 180).length;
    final lowCount = values.where((v) => v < 70).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildStatRow('Total Readings', values.length.toString()),
        _buildStatRow('Average', average.toStringAsFixed(1)),
        _buildStatRow('Minimum', min.toStringAsFixed(0)),
        _buildStatRow('Maximum', max.toStringAsFixed(0)),
        _buildStatRow('Normal Range', normalCount.toString()),
        _buildStatRow('High Readings', highCount.toString()),
        _buildStatRow('Low Readings', lowCount.toString()),
      ],
    );
  }

  pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(double value) {
    if (value < 70) return Colors.red;
    if (value > 180) return Colors.orange;
    return Colors.green;
  }

  String _getStatusLabel(double value) {
    if (value < 70) return 'LOW';
    if (value > 180) return 'HIGH';
    return 'NORMAL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<String>(
          stream: LanguageService.currentLanguageStream,
          builder: (context, snapshot) {
            final languageCode = snapshot.data ?? 'en';
            final title =
                LanguageService.translate('glucose_history', languageCode);
            return Text(
              title == 'glucose_history' ? 'Glucose History' : title,
              style: TextStyle(
                color: const Color(0xFF0C4556),
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (value) {
              if (value == 'csv') {
                _exportCSV();
              } else if (value == 'pdf') {
                _exportPDF();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      'From: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.isMobile(context) ? 8 : 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      'To: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_readings.isNotEmpty && !_loading)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
              ),
              child: Container(
                padding: EdgeInsets.all(
                    ResponsiveHelper.isMobile(context) ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Total',
                      _readings.length.toString(),
                      Icons.assessment,
                    ),
                    _buildStatItem(
                      context,
                      'Avg',
                      _readings
                              .map((r) =>
                                  ((r['value'] as num?)?.toDouble() ?? 0.0))
                              .where((v) => v > 0)
                              .isEmpty
                          ? '0'
                          : (_readings
                                      .map((r) =>
                                          ((r['value'] as num?)?.toDouble() ??
                                              0.0))
                                      .where((v) => v > 0)
                                      .reduce((a, b) => a + b) /
                                  _readings
                                      .map((r) =>
                                          ((r['value'] as num?)?.toDouble() ??
                                              0.0))
                                      .where((v) => v > 0)
                                      .length)
                              .toStringAsFixed(0),
                      Icons.trending_up,
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 16),
          Expanded(
            child: _readings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: ResponsiveHelper.isMobile(context) ? 64 : 80,
                          color: Colors.grey,
                        ),
                        SizedBox(
                            height:
                                ResponsiveHelper.isMobile(context) ? 16 : 20),
                        Text(
                          'No readings in selected range',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: ResponsiveHelper.getResponsivePadding(context),
                    itemCount: _readings.length,
                    separatorBuilder: (_, __) => SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 8 : 12,
                    ),
                    itemBuilder: (context, index) {
                      final r = _readings[index];
                      final ts = (r['timestamp'] as Timestamp?)?.toDate();
                      final value = ((r['value'] as num?)?.toDouble() ?? 0.0);
                      final type = (r['type'] as String?) ?? '';
                      final notes = (r['notes'] as String?) ?? '';
                      final isFlagged = (r['isAIFlagged'] as bool?) ?? false;
                      final statusColor = _getStatusColor(value);
                      final statusLabel = _getStatusLabel(value);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isFlagged ? Colors.orange : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            ResponsiveHelper.isMobile(context) ? 12 : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.bloodtype,
                                      color: statusColor,
                                      size: ResponsiveHelper.isMobile(context)
                                          ? 20
                                          : 24,
                                    ),
                                  ),
                                  SizedBox(
                                    width: ResponsiveHelper.isMobile(context)
                                        ? 12
                                        : 16,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${value.toStringAsFixed(0)} mg/dL',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: ResponsiveHelper
                                                    .getResponsiveFontSize(
                                                  context,
                                                  mobile: 18,
                                                  tablet: 20,
                                                  desktop: 22,
                                                ),
                                                color: const Color(0xFF0C4556),
                                              ),
                                            ),
                                            SizedBox(
                                              width: ResponsiveHelper.isMobile(
                                                      context)
                                                  ? 8
                                                  : 12,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                statusLabel,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: ResponsiveHelper
                                                      .getResponsiveFontSize(
                                                    context,
                                                    mobile: 10,
                                                    tablet: 11,
                                                    desktop: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isFlagged) ...[
                                              SizedBox(
                                                width:
                                                    ResponsiveHelper.isMobile(
                                                            context)
                                                        ? 6
                                                        : 8,
                                              ),
                                              Icon(
                                                Icons.warning,
                                                color: Colors.orange,
                                                size: ResponsiveHelper.isMobile(
                                                        context)
                                                    ? 16
                                                    : 18,
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(
                                          height:
                                              ResponsiveHelper.isMobile(context)
                                                  ? 4
                                                  : 6,
                                        ),
                                        Text(
                                          '${type.toUpperCase()} • ${ts != null ? DateFormat('yyyy-MM-dd HH:mm').format(ts) : '—'}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: ResponsiveHelper
                                                .getResponsiveFontSize(
                                              context,
                                              mobile: 12,
                                              tablet: 13,
                                              desktop: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (notes.isNotEmpty) ...[
                                SizedBox(
                                  height: ResponsiveHelper.isMobile(context)
                                      ? 8
                                      : 12,
                                ),
                                Container(
                                  padding: EdgeInsets.all(
                                    ResponsiveHelper.isMobile(context) ? 8 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.note,
                                        size: ResponsiveHelper.isMobile(context)
                                            ? 16
                                            : 18,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(
                                        width:
                                            ResponsiveHelper.isMobile(context)
                                                ? 8
                                                : 12,
                                      ),
                                      Expanded(
                                        child: Text(
                                          notes,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: ResponsiveHelper
                                                .getResponsiveFontSize(
                                              context,
                                              mobile: 12,
                                              tablet: 13,
                                              desktop: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6F8),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0C4556), size: 24),
        SizedBox(height: ResponsiveHelper.isMobile(context) ? 4 : 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: const Color(0xFF0C4556),
          ),
        ),
        SizedBox(height: ResponsiveHelper.isMobile(context) ? 2 : 4),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
