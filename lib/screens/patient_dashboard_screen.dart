import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sugenix/screens/appointments_screen.dart';
import 'package:sugenix/screens/emergency_screen.dart';
import 'package:sugenix/screens/medical_records_screen.dart';
import 'package:sugenix/screens/medicine_orders_screen.dart';
import 'package:sugenix/services/appointment_service.dart';
import 'package:sugenix/services/glucose_service.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:sugenix/services/medical_records_service.dart';
import 'package:sugenix/services/medicine_orders_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final GlucoseService _glucoseService = GlucoseService();
  final AppointmentService _appointmentService = AppointmentService();
  final MedicalRecordsService _medicalRecordsService = MedicalRecordsService();
  final MedicineOrdersService _ordersService = MedicineOrdersService();

  Map<String, dynamic>? _glucoseStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _glucoseService.getGlucoseStatistics(days: 7);
      if (mounted) {
        setState(() {
          _glucoseStats = stats;
        });
      }
    } catch (_) {
      // ignore errors; stats remain null
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: LanguageService.currentLanguageStream,
      builder: (context, snapshot) {
        final languageCode =
            snapshot.data ?? LanguageService.getCurrentLanguage();
        return _buildDashboard(context, languageCode);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, String languageCode) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final title =
        _t('my_health_dashboard', languageCode, 'My Health Dashboard');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF5F6F8),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(context, languageCode),
            const SizedBox(height: 20),
            _buildQuickActions(context, languageCode),
            const SizedBox(height: 20),
            _buildRecentReadings(languageCode),
            const SizedBox(height: 20),
            _buildUpcomingAppointments(languageCode),
            const SizedBox(height: 20),
            _buildRecentOrders(languageCode),
            const SizedBox(height: 20),
            _buildMedicalRecords(languageCode),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String languageCode) {
    final isWide = ResponsiveHelper.isTablet(context) ||
        ResponsiveHelper.isDesktop(context);
    final avg = (_glucoseStats?['average'] as num?)?.toDouble();
    final normal = _glucoseStats?['normalReadings'] ?? 0;
    final high = _glucoseStats?['highReadings'] ?? 0;
    final low = _glucoseStats?['lowReadings'] ?? 0;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildSummaryCard(
          icon: Icons.monitor_heart,
          color: Colors.green,
          title: _t('seven_day_average', languageCode, '7-Day Average'),
          value: avg != null ? '${avg.toStringAsFixed(0)} mg/dL' : '--',
          width: isWide ? 220 : double.infinity,
        ),
        _buildSummaryCard(
          icon: Icons.thumb_up,
          color: Colors.blue,
          title: _t('in_range_readings', languageCode, 'In Range'),
          value: '$normal readings',
          width: isWide ? 220 : double.infinity,
        ),
        _buildSummaryCard(
          icon: Icons.warning,
          color: Colors.orange,
          title: _t('high_alerts', languageCode, 'High Alerts'),
          value: '$high readings',
          width: isWide ? 220 : double.infinity,
        ),
        _buildSummaryCard(
          icon: Icons.warning_amber,
          color: Colors.red,
          title: _t('low_alerts', languageCode, 'Low Alerts'),
          value: '$low readings',
          width: isWide ? 220 : double.infinity,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0C4556),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String languageCode) {
    final items = [
      {
        'title': _t('glucose_logs', languageCode, 'Glucose Logs'),
        'icon': Icons.bar_chart,
        'color': const Color(0xFF2196F3),
        'action': () => Navigator.pushNamed(context, '/glucose-history'),
      },
      {
        'title': _t('book_doctor', languageCode, 'Book Doctor'),
        'icon': Icons.medical_services,
        'color': const Color(0xFF9C27B0),
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            ),
      },
      {
        'title': _t('medical_records_section', languageCode, 'Medical Records'),
        'icon': Icons.assignment,
        'color': const Color(0xFF4CAF50),
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicalRecordsScreen()),
            ),
      },
      {
        'title': _t('order_medicines', languageCode, 'Order Medicines'),
        'icon': Icons.local_pharmacy,
        'color': const Color(0xFFFF9800),
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicineOrdersScreen()),
            ),
      },
      {
        'title': _t('emergency_sos_action', languageCode, 'Emergency SOS'),
        'icon': Icons.emergency_share,
        'color': const Color(0xFFF44336),
        'action': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyScreen()),
            ),
      },
    ];

    final columns = ResponsiveHelper.isDesktop(context)
        ? 5
        : (ResponsiveHelper.isTablet(context) ? 3 : 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: item['action'] as VoidCallback,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item['icon'] as IconData,
                      color: item['color'] as Color),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF0C4556),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentReadings(String languageCode) {
    return _buildSection(
      title: _t(
          'recent_glucose_readings', languageCode, 'Recent Glucose Readings'),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _glucoseService.getGlucoseReadings(),
        builder: (context, snapshot) {
          final readings = (snapshot.data ?? []).take(5).toList();
          if (readings.isEmpty) {
            return _buildEmptyState(_t('no_readings_message', languageCode,
                'No readings yet. Add your first reading.'));
          }
          return Column(
            children: readings.map((reading) {
              final value = (reading['value'] as num?)?.toDouble() ?? 0.0;
              final status = _glucoseService.classifyReading(value);
              final time = _toDate(reading['timestamp']);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (status['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.monitor_heart,
                      color: status['color'] as Color),
                ),
                title: Text(
                  '${value.toStringAsFixed(0)} mg/dL',
                  style: const TextStyle(
                    color: Color(0xFF0C4556),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  status['label'] as String,
                  style: TextStyle(color: status['color'] as Color),
                ),
                trailing: Text(
                  time != null
                      ? DateFormat('MMM dd • hh:mm a').format(time)
                      : '',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingAppointments(String languageCode) {
    return _buildSection(
      title: _t('upcoming_appointments_section', languageCode,
          'Upcoming Appointments'),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _appointmentService.getUserAppointments(),
        builder: (context, snapshot) {
          final appointments = (snapshot.data ?? []).where((a) {
            final dt = _toDate(a['dateTime']);
            final status = a['status'] as String? ?? '';
            return dt != null &&
                dt.isAfter(DateTime.now()) &&
                status != 'cancelled';
          }).toList()
            ..sort((a, b) {
              final da = a['dateTime'] as DateTime?;
              final db = b['dateTime'] as DateTime?;
              if (da == null || db == null) return 0;
              return da.compareTo(db);
            });
          final nextAppointments = appointments.take(3).toList();
          if (nextAppointments.isEmpty) {
            return _buildEmptyState(
              '${_t('no_upcoming_appointments', languageCode, 'No upcoming appointments.')} ${_t('book_consultation_prompt', languageCode, 'Book a consultation.')}',
            );
          }
          return Column(
            children: nextAppointments.map((appointment) {
              final doctor = appointment['doctorName'] as String? ?? 'Doctor';
              final dt = _toDate(appointment['dateTime']);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C4556).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month,
                      color: Color(0xFF0C4556)),
                ),
                title: Text(
                  doctor,
                  style: const TextStyle(
                    color: Color(0xFF0C4556),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  dt != null
                      ? DateFormat('EEE, MMM dd • hh:mm a').format(dt)
                      : '',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRecentOrders(String languageCode) {
    return _buildSection(
      title:
          _t('recent_orders_section', languageCode, 'Recent Medicine Orders'),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ordersService.getUserOrders(),
        builder: (context, snapshot) {
          final orders = (snapshot.data ?? []).take(5).toList();
          if (orders.isEmpty) {
            return _buildEmptyState(_t('no_recent_orders', languageCode,
                'No orders yet. Explore the e-pharmacy store.'));
          }
          return Column(
            children: orders.map((order) {
              final total = (order['total'] as num?)?.toDouble() ?? 0.0;
              final status = order['status'] as String? ?? 'pending';
              final created = _toDate(order['createdAt']);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_pharmacy,
                      color: Color(0xFF2196F3)),
                ),
                title: Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF0C4556),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  created != null ? DateFormat('MMM dd').format(created) : '',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMedicalRecords(String languageCode) {
    return _buildSection(
      title:
          _t('latest_medical_records', languageCode, 'Latest Medical Records'),
      action: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicalRecordsScreen()),
        ),
        child: Text(_t('view_all', languageCode, 'View All')),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _medicalRecordsService.getMedicalRecords(),
        builder: (context, snapshot) {
          final records = (snapshot.data ?? []).take(4).toList();
          if (records.isEmpty) {
            return _buildEmptyState(_t('no_medical_records', languageCode,
                'No records found. Upload prescriptions or reports.'));
          }
          return Column(
            children: records.map((record) {
              final title = record['title'] as String? ?? 'Record';
              final type = record['recordType'] as String? ??
                  (record['type'] as String? ?? 'general');
              final dateString = record['recordDate'] as String?;
              DateTime? parsedDate;
              if (dateString != null) {
                try {
                  parsedDate = DateTime.parse(dateString);
                } catch (_) {
                  parsedDate = null;
                }
              }
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment, color: Color(0xFF4CAF50)),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0C4556),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  type,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  parsedDate != null
                      ? DateFormat('MMM dd').format(parsedDate)
                      : '',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    Widget? action,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0C4556),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _t(String key, String languageCode, String fallback) {
    final translated = LanguageService.translate(key, languageCode);
    return translated == key ? fallback : translated;
  }

  DateTime? _toDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
