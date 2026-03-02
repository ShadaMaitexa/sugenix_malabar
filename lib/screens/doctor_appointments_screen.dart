import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sugenix/services/appointment_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  String _selectedFilter = 'upcoming';
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Doctor Appointments',
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _appointmentService.getDoctorAppointments(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = _filteredAppointments(snapshot.data!);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No appointments for this view.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildAppointmentCard(filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = [
      {'id': 'upcoming', 'label': 'Upcoming'},
      {'id': 'today', 'label': 'Today'},
      {'id': 'completed', 'label': 'Completed'},
      {'id': 'cancelled', 'label': 'Cancelled'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter['id'] as String;
                });
              },
              selectedColor: const Color(0xFF0C4556),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredAppointments(
      List<Map<String, dynamic>> appointments) {
    final now = DateTime.now();
    return appointments.where((appointment) {
      final status = (appointment['status'] as String? ?? 'scheduled').toLowerCase();
      final dateTime = appointment['dateTime'] as DateTime? ?? now;
      switch (_selectedFilter) {
        case 'today':
          return dateTime.day == now.day &&
              dateTime.month == now.month &&
              dateTime.year == now.year;
        case 'completed':
          return status == 'completed';
        case 'cancelled':
          return status == 'cancelled';
        default:
          return dateTime.isAfter(now) &&
              status != 'completed' &&
              status != 'cancelled';
      }
    }).toList();
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = (appointment['status'] as String? ?? 'scheduled').toLowerCase();
    final patient = appointment['patientName'] as String? ?? 'Patient';
    final patientType = appointment['patientType'] as String? ?? 'New';
    final patientPhone = appointment['patientMobile'] as String? ?? '';
    final notes = appointment['notes'] as String? ?? '';
    final scheduledAt = appointment['dateTime'] as DateTime? ?? DateTime.now();
    final fee = (appointment['fee'] as num?)?.toDouble();
    final consultationType = appointment['consultationType'] as String? ?? 'Offline';
    final isOnline = consultationType == 'Online';
    final now = DateTime.now();
    // Appointment is considered "active" for video call if it's within 15 mins before/after
    final isTimeForCall = isOnline && 
                          scheduledAt.isAfter(now.subtract(const Duration(minutes: 15))) &&
                          scheduledAt.isBefore(now.add(const Duration(minutes: 60)));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4556).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Color(0xFF0C4556)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C4556),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$patientType • ${DateFormat('EEE, MMM d • hh:mm a').format(scheduledAt)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
               _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.videocam : Icons.local_hospital,
                      size: 14,
                      color: isOnline ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      consultationType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOnline && isTimeForCall && status == 'scheduled') ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "● Time for Consultation",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                patientPhone.isEmpty ? 'Not shared' : patientPhone,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Notes: $notes',
              style: const TextStyle(color: Colors.black87),
            ),
          ],
          if (fee != null) ...[
            const SizedBox(height: 10),
            Text(
              'Consultation Fee: ₹${fee.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF0C4556),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (_isUpdating) const CircularProgressIndicator(strokeWidth: 2),
              if (isOnline && status != 'cancelled') ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isTimeForCall ? () => _startVideoCall(appointment) : null,
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('Start Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) => _updateStatus(
                  appointment['id'] as String,
                  value,
                ),
                itemBuilder: (context) {
                  return [
                    if (status != 'confirmed')
                      const PopupMenuItem(
                        value: 'confirmed',
                        child: Text('Mark as Confirmed'),
                      ),
                    if (status != 'completed')
                      const PopupMenuItem(
                        value: 'completed',
                        child: Text('Mark as Completed'),
                      ),
                    if (status != 'cancelled')
                      const PopupMenuItem(
                        value: 'cancelled',
                        child: Text('Cancel Appointment'),
                      ),
                  ];
                },
                child: Chip(
                  avatar: const Icon(Icons.more_horiz, size: 16),
                  label: const Text('Update Status'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'confirmed':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String appointmentId, String status) async {
    setState(() => _isUpdating = true);
    try {
      await _appointmentService.updateAppointmentStatus(appointmentId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment updated to ${status.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _startVideoCall(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videocam, color: Colors.green),
            SizedBox(width: 10),
            Text('Starting Video Call'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${appointment['patientName']}'),
            const SizedBox(height: 10),
            const Text('Connecting to secure video session...'),
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video call engine initialized. Waiting for patient...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Connect Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

