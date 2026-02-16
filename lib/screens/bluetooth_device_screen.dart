import 'package:flutter/material.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BluetoothDeviceScreen extends StatefulWidget {
  const BluetoothDeviceScreen({super.key});

  @override
  State<BluetoothDeviceScreen> createState() => _BluetoothDeviceScreenState();
}

class _BluetoothDeviceScreenState extends State<BluetoothDeviceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isScanning = false;
  bool _isConnected = false;
  String? _connectedDeviceName;
  String? _connectedDeviceId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isScanning = false;
    });

    // Note: Actual Bluetooth scanning would require flutter_blue or similar package
    // This is a placeholder that shows the UI is ready for integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Bluetooth scanning requires additional setup. Please pair devices manually.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _connectToDevice(
      String deviceId, Map<String, dynamic> device) async {
    try {
      if (_auth.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please login to connect devices'),
              backgroundColor: Colors.red),
        );
        return;
      }

      // Update device connection status in Firebase
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('bluetooth_devices')
          .doc(deviceId)
          .update({
        'isConnected': true,
        'connectedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isConnected = true;
        _connectedDeviceName = device['name'];
        _connectedDeviceId = deviceId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device['name']}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      if (_auth.currentUser == null || _connectedDeviceId == null) return;

      // Update device connection status in Firebase
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('bluetooth_devices')
          .doc(_connectedDeviceId)
          .update({
        'isConnected': false,
        'disconnectedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isConnected = false;
        _connectedDeviceName = null;
        _connectedDeviceId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device disconnected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addDeviceManually() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bluetooth Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                hintText: 'e.g., Glucose Meter Pro',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Device Address (MAC)',
                hintText: 'e.g., 00:11:22:33:44:55',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        if (_auth.currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please login to add devices'),
                backgroundColor: Colors.red),
          );
          return;
        }

        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('bluetooth_devices')
            .add({
          'name': nameController.text.trim(),
          'address': addressController.text.trim(),
          'type': 'glucose_meter',
          'isPaired': true,
          'isConnected': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add device: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
            final title = LanguageService.translate('bluetooth_devices', languageCode);
            return Text(
              title == 'bluetooth_devices' ? 'Bluetooth Devices' : title,
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
          if (_isConnected)
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 15 : 20),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_connected, color: Colors.green),
                  SizedBox(width: ResponsiveHelper.isMobile(context) ? 10 : 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected to $_connectedDeviceName',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(
                            height: ResponsiveHelper.isMobile(context) ? 4 : 5),
                        Text(
                          'Device is ready to sync glucose readings',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 13,
                              desktop: 14,
                            ),
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: _disconnectDevice,
                  ),
                ],
              ),
            ),
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanForDevices,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bluetooth_searching),
                    label: Text(
                      _isScanning ? 'Scanning...' : 'Scan for Devices',
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
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.isMobile(context) ? 12 : 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addDeviceManually,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add',
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
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveHelper.isMobile(context) ? 12 : 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _auth.currentUser != null
                  ? _firestore
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .collection('bluetooth_devices')
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final devices = snapshot.data?.docs ?? [];
                if (devices.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final data = device.data() as Map<String, dynamic>;
                    return _buildDeviceCard(device.id, data);
                  },
                );
              },
            ),
          ),
        ],
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
              width: ResponsiveHelper.isMobile(context) ? 100 : 120,
              height: ResponsiveHelper.isMobile(context) ? 100 : 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0C4556).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth_disabled,
                size: ResponsiveHelper.isMobile(context) ? 50 : 60,
                color: const Color(0xFF0C4556),
              ),
            ),
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 20 : 30),
            Text(
              'No Devices Found',
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
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 10 : 15),
            Text(
              'Make sure your glucose meter is turned on and in pairing mode, then tap "Scan for Devices" to find it.',
              textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildDeviceCard(String deviceId, Map<String, dynamic> device) {
    final isPaired = device['isPaired'] as bool? ?? false;
    final isConnected = _isConnected && _connectedDeviceId == deviceId;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 15 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.transparent,
          width: 2,
        ),
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
            width: ResponsiveHelper.isMobile(context) ? 50 : 60,
            height: ResponsiveHelper.isMobile(context) ? 50 : 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0C4556).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.devices,
              size: ResponsiveHelper.isMobile(context) ? 25 : 30,
              color: const Color(0xFF0C4556),
            ),
          ),
          SizedBox(width: ResponsiveHelper.isMobile(context) ? 12 : 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device['name'] ?? 'Unknown Device',
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
                    if (isPaired) ...[
                      SizedBox(
                          width: ResponsiveHelper.isMobile(context) ? 8 : 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Paired',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobile: 10,
                              tablet: 11,
                              desktop: 12,
                            ),
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: ResponsiveHelper.isMobile(context) ? 4 : 5),
                Text(
                  device['address'] ?? '',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_connected, color: Colors.green),
              onPressed: _disconnectDevice,
            )
          else
            ElevatedButton(
              onPressed: () => _connectToDevice(deviceId, device),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C4556),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16,
                  vertical: ResponsiveHelper.isMobile(context) ? 8 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isPaired ? 'Connect' : 'Pair',
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
        ],
      ),
    );
  }
}
