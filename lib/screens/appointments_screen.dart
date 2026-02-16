import 'package:flutter/material.dart';
import 'package:sugenix/services/appointment_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sugenix/services/language_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, upcoming, past, cancelled

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    _appointmentService.getUserAppointments().listen((appointments) {
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_selectedFilter == 'all') return _appointments;
    
    final now = DateTime.now();
    return _appointments.where((appointment) {
      final appointmentDate = appointment['dateTime'] as DateTime? ?? DateTime.now();
      final status = appointment['status'] as String? ?? '';

      if (_selectedFilter == 'upcoming') {
        return appointmentDate.isAfter(now) && status != 'cancelled';
      } else if (_selectedFilter == 'past') {
        return appointmentDate.isBefore(now) && status != 'cancelled';
      } else if (_selectedFilter == 'cancelled') {
        return status == 'cancelled';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: StreamBuilder<String>(
          stream: LanguageService.currentLanguageStream,
          builder: (context, snapshot) {
            final languageCode = snapshot.data ?? 'en';
            final title = LanguageService.translate('my_appointments', languageCode);
            return Text(
              title == 'my_appointments' ? 'My Appointments' : title,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _filteredAppointments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: ResponsiveHelper.getResponsivePadding(context),
                        itemCount: _filteredAppointments.length,
                        itemBuilder: (context, index) {
                          return _buildAppointmentCard(_filteredAppointments[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'upcoming', 'label': 'Upcoming'},
      {'id': 'past', 'label': 'Past'},
      {'id': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.isMobile(context) ? 10 : 15,
        horizontal: ResponsiveHelper.isMobile(context) ? 15 : 20,
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['id'] as String;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.isMobile(context) ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0C4556) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: ResponsiveHelper.isMobile(context) ? 80 : 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No appointments found',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Book your first appointment with a doctor',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final appointmentDate = appointment['dateTime'] as DateTime? ?? DateTime.now();
    final status = appointment['status'] as String? ?? 'scheduled';
    final doctorName = appointment['doctorName'] as String? ?? 'Unknown Doctor';
    final isPast = appointmentDate.isBefore(DateTime.now());
    final isCancelled = status == 'cancelled';

    Color statusColor;
    String statusText;
    if (isCancelled) {
      statusColor = Colors.red;
      statusText = 'Cancelled';
    } else if (isPast) {
      statusColor = Colors.grey;
      statusText = 'Completed';
    } else {
      statusColor = Colors.green;
      statusText = 'Upcoming';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 15 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveHelper.isMobile(context) ? 50 : 60,
                height: ResponsiveHelper.isMobile(context) ? 50 : 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4556).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF0C4556),
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0C4556),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: ResponsiveHelper.isMobile(context) ? 14 : 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('MMM dd, yyyy').format(appointmentDate),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 13,
                              tablet: 14,
                              desktop: 15,
                            ),
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.access_time,
                          size: ResponsiveHelper.isMobile(context) ? 14 : 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('hh:mm a').format(appointmentDate),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 13,
                              tablet: 14,
                              desktop: 15,
                            ),
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.isMobile(context) ? 11 : 12,
                  ),
                ),
              ),
            ],
          ),
          if (appointment['notes'] != null && (appointment['notes'] as String).isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              'Notes: ${appointment['notes']}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
                color: Colors.grey[700],
              ),
            ),
          ],
          if (!isPast && !isCancelled) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelAppointment(appointment['id'] as String),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _shareRecordsWithDoctor(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C4556),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Share Records',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _appointmentService.cancelAppointment(appointmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel appointment: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareRecordsWithDoctor(Map<String, dynamic> appointment) async {
    // Navigate to medical records selection screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to medical records to share with doctor'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

