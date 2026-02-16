import 'package:flutter/material.dart';
import 'package:sugenix/services/medical_records_service.dart';
import 'package:sugenix/services/platform_image_service.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:sugenix/services/appointment_service.dart';
import 'package:sugenix/services/doctor_service.dart';
import 'package:sugenix/models/doctor.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final MedicalRecordsService _medicalRecordsService = MedicalRecordsService();
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _medicalRecordsService.getMedicalRecords().listen((records) {
      if (mounted) {
        setState(() {
          _records = records;
        });
      }
    });
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
            final title = LanguageService.translate('records', languageCode);
            return Text(
              title == 'records' ? 'Records' : title,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0C4556)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecordScreen(),
                ),
              ).then((_) => _loadRecords());
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _records.isEmpty ? _buildEmptyState() : _buildRecordsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveHelper.isMobile(context) ? 120 : 150,
              height: ResponsiveHelper.isMobile(context) ? 120 : 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment,
                size: ResponsiveHelper.isMobile(context) ? 60 : 80,
                color: const Color(0xFF0C4556),
              ),
            ),
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 20 : 30),
            Text(
              "Add a medical record",
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
            const SizedBox(height: 10),
            Text(
              "A document of your health history to assist in diagnosing your illness.",
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
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 30 : 40),
            SizedBox(
              width: ResponsiveHelper.isMobile(context) ? 200 : 250,
              height: ResponsiveHelper.isMobile(context) ? 50 : 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddRecordScreen(),
                    ),
                  ).then((_) => _loadRecords());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C4556),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Add a record",
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: ResponsiveHelper.getResponsivePadding(context),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              return _buildRecordCard(_records[index]);
            },
          ),
        ),
        Container(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: SizedBox(
            width: double.infinity,
            height: ResponsiveHelper.isMobile(context) ? 50 : 55,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddRecordScreen(),
                  ),
                ).then((_) => _loadRecords());
              },
              icon: const Icon(Icons.add),
              label: Text(
                "Add New Record",
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C4556),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final recordType = record['recordType'] as String? ?? 'report';
    final imageUrls = record['imageUrls'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 15 : 18),
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
                child: Icon(
                  recordType == 'report'
                      ? Icons.description
                      : recordType == 'prescription'
                          ? Icons.medication
                          : Icons.receipt,
                  color: const Color(0xFF0C4556),
                  size: ResponsiveHelper.isMobile(context) ? 25 : 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['title'] ?? 'Medical Record',
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
                    if (record['description'] != null &&
                        (record['description'] as String).isNotEmpty)
                      Text(
                        record['description'] as String,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C4556).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            recordType.toUpperCase(),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 10,
                                tablet: 11,
                                desktop: 12,
                              ),
                              color: const Color(0xFF0C4556),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (record['recordDate'] != null)
                          Text(
                            DateFormat('MMM dd, yyyy').format(
                              DateTime.parse(record['recordDate'] as String),
                            ),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 11,
                                tablet: 12,
                                desktop: 13,
                              ),
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 15),
            SizedBox(
              height: ResponsiveHelper.isMobile(context) ? 80 : 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = imageUrls[index] as String;
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: ResponsiveHelper.isMobile(context) ? 80 : 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF0C4556)),
                onPressed: () => _showShareDialog(record),
                tooltip: 'Share with Doctor',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showShareDialog(Map<String, dynamic> record) async {
    final appointmentService = AppointmentService();
    final doctorService = DoctorService();

    // Get user's appointments to find doctors
    final appointmentsStream = appointmentService.getUserAppointments();
    final appointments = await appointmentsStream.first;
    final doctors = await doctorService.getDoctors();

    if (appointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You need to have an appointment to share records. Please book an appointment first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to select doctor
    final selectedDoctor = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Share Record with Doctor',
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
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final doctorId = appointment['doctorId'] as String?;
              final doctor = doctors.firstWhere(
                (d) => d.id == doctorId,
                orElse: () => Doctor(
                  id: doctorId ?? '',
                  name: 'Unknown Doctor',
                  specialization: '',
                ),
              );

              return ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF0C4556)),
                title: Text(doctor.name),
                subtitle: Text(doctor.specialization),
                onTap: () {
                  Navigator.pop(context, {
                    'doctorId': doctorId,
                    'appointmentId': appointment['id'],
                    'doctorName': doctor.name,
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedDoctor != null) {
      try {
        await appointmentService.shareMedicalRecordsWithDoctor(
          doctorId: selectedDoctor['doctorId'] as String,
          appointmentId: selectedDoctor['appointmentId'] as String,
          recordIds: [record['id'] as String],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Record shared with ${selectedDoctor['doctorName']} successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share record: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  String _selectedRecordType = "Report";
  final _recordDateController = TextEditingController();

  final _addedByController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final MedicalRecordsService _medicalRecordsService = MedicalRecordsService();
  final AuthService _authService = AuthService();
  List<XFile> _selectedImages = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _recordDateController.text =
        DateFormat('dd MMM, yyyy').format(_selectedDate);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _authService.getUserProfile();
      setState(() {
        _addedByController.text = profile?['name'] ?? '';
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _recordDateController.dispose();
    _addedByController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Add Records",
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageUploadSection(),
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 20 : 30),
            _buildRecordDetails(),
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 20 : 30),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      height: ResponsiveHelper.isMobile(context) ? 180 : 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _selectedImages.isEmpty
          ? GestureDetector(
              onTap: _pickImages,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate,
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tap to add images",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(
                                      _selectedImages[index].path,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_selectedImages[index].path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add),
                        label: const Text("Add More"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await PlatformImageService.pickImages(
        maxImages: 5,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRecordDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("Title", _titleController, Icons.title),
        const SizedBox(height: 20),
        _buildTextField(
          "Description (Optional)",
          _descriptionController,
          Icons.description,
        ),
        const SizedBox(height: 20),
        _buildTextField("Records added by", _addedByController, Icons.edit),
        const SizedBox(height: 20),
        _buildRecordTypeSelector(),
        const SizedBox(height: 20),
        _buildDateField(),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0C4556),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label == "Records added by"
                ? "Name"
                : label, // <-- Use hintText instead of labelText
            suffixIcon: Icon(icon, color: const Color(0xFF0C4556)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordTypeSelector() {
    final recordTypes = [
      {"type": "Report", "icon": Icons.description},
      {"type": "Prescription", "icon": Icons.medication},
      {"type": "Invoice", "icon": Icons.receipt},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Type of record",
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 15,
              tablet: 16,
              desktop: 17,
            ),
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0C4556),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: recordTypes.map((record) {
            final isSelected = _selectedRecordType == record["type"];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRecordType = record["type"] as String;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.isMobile(context) ? 12 : 15,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFF0C4556) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        record["icon"] as IconData,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: ResponsiveHelper.isMobile(context) ? 25 : 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record["type"] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
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
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Record Date",
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 15,
              tablet: 16,
              desktop: 17,
            ),
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0C4556),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
                _recordDateController.text =
                    DateFormat('dd MMM, yyyy').format(pickedDate);
              });
            }
          },
          child: TextField(
            controller: _recordDateController,
            enabled: false,
            decoration: InputDecoration(
              hintText: "Select Date",
              prefixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF0C4556)),
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
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveHelper.isMobile(context) ? 50 : 55,
      child: ElevatedButton(
        onPressed: _handleUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C4556),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          "Upload record",
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

  Future<void> _handleUpload() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _medicalRecordsService.addMedicalRecord(
        recordType: _selectedRecordType.toLowerCase(),
        title: _titleController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : '',
        images: _selectedImages,
        recordDate: _selectedDate.toIso8601String(),
        addedBy: _addedByController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical record added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add medical record: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Upload complete
    }
  }
}

class AllRecordsScreen extends StatefulWidget {
  const AllRecordsScreen({super.key});

  @override
  State<AllRecordsScreen> createState() => _AllRecordsScreenState();
}

class _AllRecordsScreenState extends State<AllRecordsScreen> {
  final MedicalRecordsService _medicalRecordsService = MedicalRecordsService();
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _medicalRecordsService.getMedicalRecords().listen((records) {
      if (mounted) {
        setState(() {
          _records = records;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "All Records",
          style: TextStyle(
            color: Color(0xFF0C4556),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _records.isEmpty
                      ? const Center(
                          child: Text(
                            'No medical records found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
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
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0C4556,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      record["type"] == "report"
                                          ? Icons.description
                                          : Icons.medication,
                                      color: const Color(0xFF0C4556),
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record["title"] ?? "Medical Record",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0C4556),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          record["description"] ??
                                              "No description",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Type: ${record["type"]}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddRecordScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C4556),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Add a record",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
