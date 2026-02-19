import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugenix/services/chat_service.dart';
import 'package:sugenix/screens/chat_screen.dart';
import 'package:sugenix/models/doctor.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:sugenix/services/appointment_service.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/services/revenue_service.dart';
import 'package:sugenix/services/razorpay_service.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF0C4556)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDoctorProfile(context),
            _buildStatistics(context),
            _buildServiceInfo(context),
            _buildBookNowButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProfile(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.isMobile(context) ? 15 : 20,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: ResponsiveHelper.isMobile(context) ? 45 : 50,
            backgroundColor: const Color(0xFF0C4556),
            child: Text(
              doctor.name.split(' ').map((e) => e[0]).join(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 15),
          Text(
            doctor.name,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            doctor.specialization,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: ResponsiveHelper.isMobile(context) ? 18 : 20,
              ),
              const SizedBox(width: 5),
              Text(
                doctor.rating.toString(),
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 15 : 20,
      ),
      padding: EdgeInsets.all(
        ResponsiveHelper.isMobile(context) ? 15 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            "${doctor.totalBookings} Booking",
            Icons.calendar_today,
          ),
          _buildStatItem(
              context, "${doctor.totalPatients} Patient", Icons.people),
          _buildStatItem(context, "${doctor.likes} Likes", Icons.favorite),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String text, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF0C4556),
          size: ResponsiveHelper.isMobile(context) ? 25 : 30,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 14,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildServiceInfo(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(
        ResponsiveHelper.isMobile(context) ? 15 : 20,
      ),
      padding: EdgeInsets.all(
        ResponsiveHelper.isMobile(context) ? 15 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            "Service Info",
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 16,
                tablet: 17,
                desktop: 18,
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 15),
          _buildServiceItem("• Comprehensive diabetes management"),
          _buildServiceItem("• Blood sugar monitoring guidance"),
          _buildServiceItem("• Personalized diet plans"),
          _buildServiceItem("• Medication management"),
          _buildServiceItem("• Emergency consultation"),
          _buildServiceItem("• Follow-up care"),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildBookNowButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(
        ResponsiveHelper.isMobile(context) ? 15 : 20,
      ),
      width: double.infinity,
      height: ResponsiveHelper.isMobile(context) ? 50 : 55,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final auth = FirebaseAuth.instance;
                if (auth.currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login to chat')),
                  );
                  return;
                }

                final chatService = ChatService();
                final canChat = await chatService.canStartChat(
                  doctor.id,
                  auth.currentUser!.uid,
                );

                if (context.mounted) {
                  if (canChat) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          doctorId: doctor.id,
                          doctorName: doctor.name,
                          patientId: auth.currentUser!.uid,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'You can only chat with doctors you have an appointment with.'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.chat, color: Color(0xFF0C4556)),
              label: const Text(
                "Chat",
                style: TextStyle(
                  color: Color(0xFF0C4556),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0C4556), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AppointmentBookingScreen(doctor: doctor),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C4556),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "Book Now",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentBookingScreen extends StatefulWidget {
  final Doctor doctor;

  const AppointmentBookingScreen({super.key, required this.doctor});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();

  DateTime _selectedDate = DateTime.now();
  String _selectedTime = "15:00";
  final _patientNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedPatient = "My Self";
  bool _isLoading = false;
  List<String> _availableTimeSlots = [];
  String? _lastAppointmentId;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAvailableSlots();
    _setupRazorpayCallbacks();
  }

  void _setupRazorpayCallbacks() {
    RazorpayService.initialize(
      onSuccessCallback: (dynamic response) async {
        if (_lastAppointmentId != null) {
          try {
            await _appointmentService.processPayment(
              appointmentId: _lastAppointmentId!,
              paymentMethod: 'razorpay',
            );
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              Navigator.pop(context); // Close payment dialog if open
              _showSuccessDialog(context, _selectedDate);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment successful!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Payment recorded but failed to update: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      },
      onErrorCallback: (dynamic response) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    RazorpayService.dispose();
    _patientNameController.dispose();
    _mobileController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _patientNameController.text = profile?['name'] ?? '';
        _mobileController.text = profile?['phone'] ?? '';
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadAvailableSlots() async {
    try {
      final slots = await _appointmentService.getAvailableTimeSlots(
        widget.doctor.id,
        _selectedDate,
      );
      setState(() {
        _availableTimeSlots = slots;
        if (slots.isNotEmpty && !slots.contains(_selectedTime)) {
          _selectedTime = slots.first;
        }
      });
    } catch (e) {
      // Use default slots
      setState(() {
        _availableTimeSlots = [
          '09:00',
          '09:30',
          '10:00',
          '10:30',
          '11:00',
          '11:30',
          '12:00',
          '12:30',
          '13:00',
          '13:30',
          '14:00',
          '14:30',
          '15:00',
          '15:30',
          '16:00',
          '16:30',
          '17:00',
          '17:30',
          '18:00',
          '18:30',
          '19:00',
          '19:30',
          '20:00',
          '20:30'
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Recent Time",
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF0C4556)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorCard(),
            const SizedBox(height: 20),
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildTimeSlots(),
            const SizedBox(height: 20),
            _buildAppointmentFor(),
            const SizedBox(height: 20),
            _buildPatientSelection(),
            if (widget.doctor.consultationFee > 0) ...[
              const SizedBox(height: 20),
              _buildFeeBreakdown(),
            ],
            const SizedBox(height: 30),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF0C4556),
            child: Text(
              widget.doctor.name.split(' ').map((e) => e[0]).join(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.doctor.specialization,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.doctor.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final dates = [
      today.subtract(const Duration(days: 1)),
      today,
      today.add(const Duration(days: 1)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Date",
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
        const SizedBox(height: 15),
        Row(
          children: dates.asMap().entries.map((entry) {
            final date = entry.value;
            final isSelected = _selectedDate.year == date.year &&
                _selectedDate.month == date.month &&
                _selectedDate.day == date.day;
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isYesterday =
                date.day == today.subtract(const Duration(days: 1)).day;
            final isTomorrow =
                date.day == today.add(const Duration(days: 1)).day;

            String dateLabel;
            if (isToday) {
              dateLabel = 'Today, ${DateFormat('dd MMM').format(date)}';
            } else if (isYesterday) {
              dateLabel = 'Yesterday, ${DateFormat('dd MMM').format(date)}';
            } else if (isTomorrow) {
              dateLabel = 'Tomorrow, ${DateFormat('dd MMM').format(date)}';
            } else {
              dateLabel = DateFormat('EEE, dd MMM').format(date);
            }

            return Expanded(
              child: GestureDetector(
                onTap: () async {
                  setState(() {
                    _selectedDate = date;
                  });
                  await _loadAvailableSlots();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.isMobile(context) ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFF0C4556) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dateLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
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
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    if (_availableTimeSlots.isEmpty) {
      return const Center(
        child: Text('No time slots available',
            style: TextStyle(color: Colors.grey)),
      );
    }

    // Group slots by period
    final morningSlots = _availableTimeSlots.where((slot) {
      final hour = int.parse(slot.split(':')[0]);
      return hour >= 9 && hour < 12;
    }).toList();

    final afternoonSlots = _availableTimeSlots.where((slot) {
      final hour = int.parse(slot.split(':')[0]);
      return hour >= 12 && hour < 17;
    }).toList();

    final eveningSlots = _availableTimeSlots.where((slot) {
      final hour = int.parse(slot.split(':')[0]);
      return hour >= 17 && hour < 21;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Time",
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
        const SizedBox(height: 15),
        if (morningSlots.isNotEmpty)
          _buildTimeSlotSection("Morning", morningSlots),
        if (afternoonSlots.isNotEmpty) ...[
          if (morningSlots.isNotEmpty) const SizedBox(height: 15),
          _buildTimeSlotSection("Afternoon", afternoonSlots),
        ],
        if (eveningSlots.isNotEmpty) ...[
          if (afternoonSlots.isNotEmpty || morningSlots.isNotEmpty)
            const SizedBox(height: 15),
          _buildTimeSlotSection("Evening", eveningSlots),
        ],
      ],
    );
  }

  Widget _buildTimeSlotSection(String title, List<String> times) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title Slots",
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: ResponsiveHelper.isMobile(context) ? 8 : 10,
          runSpacing: ResponsiveHelper.isMobile(context) ? 8 : 10,
          children: times.map((time) {
            final isSelected = time == _selectedTime;
            final timeParts = time.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            final period = hour >= 12 ? 'PM' : 'AM';
            final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            final displayTime =
                '$displayHour:${minute.toString().padLeft(2, '0')} $period';

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = time;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.isMobile(context) ? 12 : 15,
                  vertical: ResponsiveHelper.isMobile(context) ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF0C4556) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayTime,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAppointmentFor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Appointment For",
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
        const SizedBox(height: 15),
        TextField(
          controller: _patientNameController,
          decoration: InputDecoration(
            hintText: "Patient Name",
            prefixIcon: const Icon(Icons.person, color: Color(0xFF0C4556)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.all(
              ResponsiveHelper.isMobile(context) ? 15 : 18,
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Mobile Number",
            prefixIcon: const Icon(Icons.phone, color: Color(0xFF0C4556)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.all(
              ResponsiveHelper.isMobile(context) ? 15 : 18,
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Additional Notes (Optional)",
            prefixIcon: const Icon(Icons.note, color: Color(0xFF0C4556)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.all(
              ResponsiveHelper.isMobile(context) ? 15 : 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Who is this patient?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C4556),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildPatientOption("My Self", "My Self"),
            const SizedBox(width: 15),
            _buildPatientOption("My Child", "My Child"),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () {
                // Handle add new patient
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0C4556)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "+ Add",
                  style: TextStyle(
                    color: Color(0xFF0C4556),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientOption(String text, String value) {
    final isSelected = _selectedPatient == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPatient = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0C4556) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFeeBreakdown() {
    final consultationFee = widget.doctor.consultationFee;
    final fees = RevenueService.calculateFees(consultationFee);
    // Total amount is consultation fee + platform fee (customer pays both)
    final totalFee =
        fees['totalFee'] ?? (consultationFee + (fees['platformFee'] ?? 0.0));
    final platformFee = fees['platformFee'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0C4556).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Breakdown',
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
          const SizedBox(height: 12),
          _buildFeeRow('Consultation Fee', consultationFee),
          _buildFeeRow('Platform Fee', platformFee, isSecondary: true),
          const Divider(),
          _buildFeeRow('Total Amount', totalFee, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, double amount,
      {bool isSecondary = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
              color: isSecondary
                  ? Colors.grey
                  : (isTotal ? const Color(0xFF0C4556) : Colors.black87),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
              color: isTotal ? const Color(0xFF0C4556) : Colors.black87,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, DateTime appointmentDateTime,
      String appointmentId) {
    final consultationFee = widget.doctor.consultationFee;
    final fees = RevenueService.calculateFees(consultationFee);
    final platformFee = fees['platformFee'] ?? 0.0;
    final totalFee = fees['totalFee'] ??
        (consultationFee +
            platformFee); // Fallback: consultationFee + platformFee

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Payment Required',
          style:
              TextStyle(color: Color(0xFF0C4556), fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₹${totalFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C4556),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Payment Method:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildPaymentOption(context, 'UPI / Wallet', 'razorpay',
                Icons.account_balance_wallet),
            _buildPaymentOption(
                context, 'Credit/Debit Card', 'razorpay', Icons.credit_card),
            _buildPaymentOption(
                context, 'Net Banking', 'razorpay', Icons.account_balance),
            const Divider(),
            _buildPaymentOption(context, 'Direct ', 'cod', Icons.money),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      BuildContext context, String label, String method, IconData icon) {
    return InkWell(
      onTap: () => _handlePaymentMethod(context, method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF0C4556).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0C4556), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0C4556),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF0C4556)),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentMethod(BuildContext context, String method) async {
    if (_lastAppointmentId == null) return;

    Navigator.pop(context); // Close dialog

    if (method == 'cod') {
      // Cash on Delivery - no Razorpay needed
      setState(() {
        _isLoading = true;
      });
      try {
        await _appointmentService.processPayment(
          appointmentId: _lastAppointmentId!,
          paymentMethod: 'cod',
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSuccessDialog(context, _selectedDate);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment booked! Pay on delivery.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Online payment - Open Razorpay Checkout
      final consultationFee = widget.doctor.consultationFee;
      final fees = RevenueService.calculateFees(consultationFee);
      final totalFee = fees['totalFee']!;

      setState(() {
        _isLoading = true;
      });

      try {
        await RazorpayService.openCheckout(
          amount: totalFee,
          name: _patientNameController.text.trim(),
          email: _userProfile?['email'] ?? 'patient@sugenix.com',
          phone: _mobileController.text.trim(),
          description: 'Appointment with ${widget.doctor.name}',
          notes: {
            'appointmentId': _lastAppointmentId,
            'doctorId': widget.doctor.id,
            'doctorName': widget.doctor.name,
          },
        );
        // Payment result will be handled by callbacks in _setupRazorpayCallbacks
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate payment: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildNextButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveHelper.isMobile(context) ? 50 : 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _bookAppointment(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C4556),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "Book Appointment",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _bookAppointment(BuildContext context) async {
    if (_patientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter patient name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse time
      final timeParts = _selectedTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );

      // Book appointment
      final appointmentId = await _appointmentService.bookAppointment(
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        dateTime: appointmentDateTime,
        patientName: _patientNameController.text.trim(),
        patientMobile: _mobileController.text.trim(),
        patientType: _selectedPatient,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        fee: widget.doctor.consultationFee > 0
            ? widget.doctor.consultationFee
            : null,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastAppointmentId = appointmentId;
        });
        if (widget.doctor.consultationFee > 0) {
          _showPaymentDialog(context, appointmentDateTime, appointmentId);
        } else {
          _showSuccessDialog(context, appointmentDateTime);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Extract the actual error message, stripping nested "Exception:" prefixes
        String errorMsg = e.toString();
        errorMsg = errorMsg.replaceAll(RegExp(r'^Exception:\s*'), '');
        errorMsg = errorMsg.replaceAll(
            RegExp(r'^Failed to book appointment:\s*(Exception:\s*)?'), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg.isNotEmpty
                ? errorMsg
                : 'Failed to book appointment. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context, DateTime appointmentDateTime) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(
              "Appointment booked slot successfully",
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              "Your appointment with ${widget.doctor.name} is on ${DateFormat('MMM dd, yyyy').format(appointmentDateTime)} at ${DateFormat('hh:mm a').format(appointmentDateTime)}",
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to doctor details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
