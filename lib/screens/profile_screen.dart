import 'package:flutter/material.dart';
import 'package:sugenix/screens/medical_records_screen.dart';
import 'package:sugenix/screens/medicine_orders_screen.dart';
import 'package:sugenix/screens/appointments_screen.dart';
import 'package:sugenix/screens/emergency_screen.dart';
import 'package:sugenix/screens/emergency_contacts_screen.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sugenix/widgets/translated_text.dart';
import 'package:sugenix/services/role_service.dart';
import 'package:sugenix/screens/admin_panel_screen.dart';
import 'package:sugenix/screens/doctor_dashboard_screen.dart';
import 'package:sugenix/screens/doctor_appointments_screen.dart';
import 'package:sugenix/screens/pharmacy_dashboard_screen.dart';
import 'package:sugenix/screens/pharmacy_orders_screen.dart';
import 'package:sugenix/screens/settings_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _userRole;

  // Common controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  // Patient-specific controllers
  final _diabetesTypeController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  // Doctor-specific controllers
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  List<String> _selectedLanguages = [];

  // Pharmacy-specific controllers
  final _addressController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _userRole = profile['role'] ?? 'user';

          // Common fields
          _nameController.text = profile['name'] ?? '';
          _mobileController.text = profile['phone'] ?? '';
          _emailController.text = profile['email'] ?? '';

          // Patient-specific fields
          if (_userRole == 'user' || _userRole == null) {
            _diabetesTypeController.text = profile['diabetesType'] ?? '';
            _selectedGender = profile['gender'] ?? 'Male';

            // Load date of birth
            if (profile['dateOfBirth'] != null) {
              if (profile['dateOfBirth'] is Timestamp) {
                _selectedDateOfBirth =
                    (profile['dateOfBirth'] as Timestamp).toDate();
              } else if (profile['dateOfBirth'] is DateTime) {
                _selectedDateOfBirth = profile['dateOfBirth'] as DateTime;
              }
            }

            // Load height and weight
            _heightController.text = profile['height']?.toString() ?? '';
            _weightController.text = profile['weight']?.toString() ?? '';
          }

          // Doctor-specific fields
          if (_userRole == 'doctor') {
            _specializationController.text = profile['specialization'] ?? '';
            _hospitalController.text = profile['hospital'] ?? '';
            _bioController.text = profile['bio'] ?? '';
            _experienceController.text = profile['experience'] ?? '';
            _educationController.text = profile['education'] ?? '';
            _consultationFeeController.text =
                profile['consultationFee']?.toString() ?? '';
            if (profile['languages'] != null) {
              _selectedLanguages = List<String>.from(profile['languages']);
            }
          }

          // Pharmacy-specific fields
          if (_userRole == 'pharmacy') {
            _addressController.text = profile['address'] ?? '';
            _licenseNumberController.text = profile['licenseNumber'] ?? '';
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (_userRole == 'user' || _userRole == null) {
        // Patient profile update
        double? height;
        double? weight;

        if (_heightController.text.isNotEmpty) {
          height = double.tryParse(_heightController.text);
          if (height == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a valid height'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        if (_weightController.text.isNotEmpty) {
          weight = double.tryParse(_weightController.text);
          if (weight == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a valid weight'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        // Validate required fields
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name is required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_mobileController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobile number is required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await _authService.updateUserProfile(
          name: _nameController.text,
          phone: _mobileController.text,
          diabetesType: _diabetesTypeController.text,
          gender: _selectedGender,
          dateOfBirth: _selectedDateOfBirth,
          height: height,
          weight: weight,
        );
      } else if (_userRole == 'doctor') {
        // Doctor profile update
        double? consultationFee;
        if (_consultationFeeController.text.isNotEmpty) {
          consultationFee = double.tryParse(_consultationFeeController.text);
          if (consultationFee == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a valid consultation fee'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        // Validate required fields
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name is required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_mobileController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobile number is required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await _authService.updateUserProfile(
          name: _nameController.text,
          phone: _mobileController.text,
          specialization: _specializationController.text,
          hospital: _hospitalController.text,
          bio: _bioController.text,
          experience: _experienceController.text,
          education: _educationController.text,
          consultationFee: consultationFee,
          languages: _selectedLanguages.isNotEmpty ? _selectedLanguages : null,
        );
      } else if (_userRole == 'pharmacy') {
        // Pharmacy profile update
        // Validate required fields
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name is required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_mobileController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobile number is required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await _authService.updateUserProfile(
          name: _nameController.text,
          phone: _mobileController.text,
          address: _addressController.text,
          licenseNumber: _licenseNumberController.text,
        );
      }

      setState(() {
        _isEditing = false;
      });

      // Reload profile to reflect changes
      await _loadUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _diabetesTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _consultationFeeController.dispose();
    _addressController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0C4556),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0C4556),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TranslatedAppBarTitle('profile', fallback: 'Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<String>(
            stream: RoleService().roleStream(),
            builder: (context, snapshot) {
              final role = snapshot.data ?? 'user';
              if (role == 'admin') {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings,
                      color: Color(0xFF0C4556)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminPanelScreen()),
                    );
                  },
                );
              }
              if (role == 'doctor') {
                return IconButton(
                  icon: const Icon(Icons.medical_information,
                      color: Color(0xFF0C4556)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DoctorDashboardScreen()),
                    );
                  },
                );
              }
              if (role == 'pharmacy') {
                return IconButton(
                  icon: const Icon(Icons.local_pharmacy,
                      color: Color(0xFF0C4556)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PharmacyDashboardScreen()),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Language button only for patients (user role)
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF0C4556)),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _isLoading
            ? _buildShimmerLoading()
            : ResponsiveLayout(
                mobile: _buildMobileLayout(),
                tablet: _buildTabletLayout(),
                desktop: _buildDesktopLayout(),
              ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildProfileForm(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _buildProfileForm()),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
          const SizedBox(width: 30),
          Expanded(flex: 2, child: _buildProfileForm()),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C4556), Color(0xFF1A6B7A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C4556).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: ResponsiveHelper.isMobile(context) ? 40 : 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: ResponsiveHelper.isMobile(context) ? 40 : 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _userProfile?['name'] ?? 'User',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _userProfile?['email'] ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_userRole == 'doctor')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userProfile?['specialization'] ?? 'Doctor',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (_userRole == 'pharmacy')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pharmacy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userProfile?['diabetesType'] ?? 'Type 1',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userRole == 'doctor'
                ? 'Professional Information'
                : _userRole == 'pharmacy'
                    ? 'Pharmacy Information'
                    : 'Personal Information',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            'Full Name',
            _nameController,
            Icons.person,
            enabled: _isEditing,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            'Email',
            _emailController,
            Icons.email,
            enabled: false, // Email cannot be changed
          ),
          const SizedBox(height: 15),
          _buildTextField(
            'Mobile Number',
            _mobileController,
            Icons.phone,
            enabled: _isEditing,
          ),
          // Patient-specific fields
          if (_userRole == 'user' || _userRole == null) ...[
            const SizedBox(height: 15),
            _buildGenderDropdown(),
            const SizedBox(height: 15),
            _buildDateOfBirthField(),
            const SizedBox(height: 15),
            _buildTextField(
              'Diabetes Type',
              _diabetesTypeController,
              Icons.medical_services,
              enabled: _isEditing,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Height (cm)',
                    _heightController,
                    Icons.height,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTextField(
                    'Weight (kg)',
                    _weightController,
                    Icons.monitor_weight,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
          // Doctor-specific fields
          if (_userRole == 'doctor') ...[
            const SizedBox(height: 15),
            _buildTextField(
              'Specialization',
              _specializationController,
              Icons.medical_services,
              enabled: _isEditing,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              'Hospital/Clinic',
              _hospitalController,
              Icons.local_hospital,
              enabled: _isEditing,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              'Experience',
              _experienceController,
              Icons.work,
              enabled: _isEditing,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              'Education',
              _educationController,
              Icons.school,
              enabled: _isEditing,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              'Consultation Fee (₹)',
              _consultationFeeController,
              Icons.currency_rupee,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              'Bio',
              _bioController,
              Icons.description,
              enabled: _isEditing,
              maxLines: 3,
            ),
          ],
          // Pharmacy-specific fields
          if (_userRole == 'pharmacy') ...[
            const SizedBox(height: 15),
            _buildTextField(
              'Address',
              _addressController,
              Icons.location_on,
              enabled: _isEditing,
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              'License Number',
              _licenseNumberController,
              Icons.verified,
              enabled: _isEditing,
            ),
          ],
          if (_isEditing) ...[
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C4556),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // Reload profile to reset form fields to original values
                      if (mounted) {
                        await _loadUserProfile();
                        if (mounted) {
                          setState(() {
                            _isEditing = false;
                          });
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Color(0xFF0C4556)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF0C4556),
                        fontWeight: FontWeight.w600,
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

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Gender',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _isEditing ? Colors.grey[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            items: ['Male', 'Female', 'Other'].map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(
                  gender,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    color: _isEditing ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              );
            }).toList(),
            onChanged: _isEditing
                ? (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    }
                  }
                : null,
            icon: Icon(
              Icons.arrow_drop_down,
              color: _isEditing ? const Color(0xFF0C4556) : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    final age = _calculateAge(_selectedDateOfBirth);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Date of Birth',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (age != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4556).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Age: $age years',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    color: const Color(0xFF0C4556),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isEditing ? _selectDateOfBirth : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: _isEditing ? Colors.grey[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateOfBirth != null
                        ? DateFormat('dd MMM yyyy')
                            .format(_selectedDateOfBirth!)
                        : 'Select Date of Birth',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                      color: _selectedDateOfBirth != null
                          ? (_isEditing ? Colors.black87 : Colors.grey[600])
                          : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color:
                      _isEditing ? const Color(0xFF0C4556) : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0C4556)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0C4556)),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }

  Widget _buildActionButtons() {
    final quickActions = _quickActionsForRole(context);
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < quickActions.length; i++) ...[
            _buildActionButton(quickActions[i]),
            if (i != quickActions.length - 1) const SizedBox(height: 15),
          ],
        ],
      ),
    );
  }

  List<_ProfileQuickAction> _quickActionsForRole(BuildContext context) {
    final role = _userRole ?? 'user';
    final List<_ProfileQuickAction> actions = [];

    switch (role) {
      case 'doctor':
        actions.addAll([
          _ProfileQuickAction(
            title: 'Doctor Dashboard',
            icon: Icons.dashboard_customize,
            color: const Color(0xFF2196F3),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()),
            ),
          ),
          _ProfileQuickAction(
            title: 'Doctor Appointments',
            icon: Icons.event,
            color: const Color(0xFF9C27B0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DoctorAppointmentsScreen()),
            ),
          ),
        ]);
        break;
      case 'pharmacy':
        actions.addAll([
          _ProfileQuickAction(
            title: 'Pharmacy Dashboard',
            icon: Icons.store_mall_directory,
            color: const Color(0xFF009688),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PharmacyDashboardScreen()),
            ),
          ),
          _ProfileQuickAction(
            title: 'Pharmacy Orders',
            icon: Icons.local_shipping,
            color: const Color(0xFFFFA726),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PharmacyOrdersScreen()),
            ),
          ),
        ]);
        break;
      default:
        actions.addAll([
          _ProfileQuickAction(
            title: 'Medical Records',
            icon: Icons.folder_open,
            color: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicalRecordsScreen()),
            ),
          ),
          _ProfileQuickAction(
            title: 'Medicine Orders',
            icon: Icons.medication,
            color: const Color(0xFF2196F3),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicineOrdersScreen()),
            ),
          ),
          _ProfileQuickAction(
            title: 'My Appointments',
            icon: Icons.calendar_today,
            color: const Color(0xFF9C27B0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            ),
          ),
          _ProfileQuickAction(
            title: 'Emergency Contacts',
            icon: Icons.emergency,
            color: const Color(0xFFF44336),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EmergencyContactsScreen()),
            ),
          ),
          _ProfileQuickAction(
            title: 'Emergency SOS',
            icon: Icons.sos,
            color: const Color(0xFFF44336),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyScreen()),
            ),
          ),
        ]);
    }

    actions.addAll([
      _ProfileQuickAction(
        title: 'Settings',
        icon: Icons.settings,
        color: const Color(0xFF673AB7),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      ),
      _ProfileQuickAction(
        title: 'Help & Support',
        icon: Icons.help_outline,
        color: const Color(0xFFE91E63),
        onTap: () => _showHelpSupportDialog(context),
      ),
    ]);

    return actions;
  }

  Widget _buildActionButton(_ProfileQuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                action.title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0C4556),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: action.color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help? We\'re here for you!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSupportOption(
                context,
                Icons.phone,
                'Call Support',
                '+91 123 456 7890',
                () async {
                  final Uri telUri = Uri(scheme: 'tel', path: '+911234567890');
                  if (await canLaunchUrl(telUri)) {
                    await launchUrl(telUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch phone dialer')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildSupportOption(
                context,
                Icons.email,
                'Email Support',
                'support@sugenix.com',
                () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@sugenix.com',
                    queryParameters: {'subject': 'Support Request - Sugenix'},
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch email client')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildSupportOption(
                context,
                Icons.help_outline,
                'FAQs',
                'Frequently Asked Questions',
                () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening FAQs...')),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0C4556)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0C4556),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ProfileQuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProfileQuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
