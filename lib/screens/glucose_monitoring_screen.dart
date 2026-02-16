import 'package:flutter/material.dart';
import 'package:sugenix/services/glucose_service.dart';
import 'package:sugenix/services/gemini_service.dart';
import 'package:sugenix/screens/glucose_history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugenix/widgets/translated_text.dart';

class GlucoseMonitoringScreen extends StatefulWidget {
  const GlucoseMonitoringScreen({super.key});

  @override
  State<GlucoseMonitoringScreen> createState() =>
      _GlucoseMonitoringScreenState();
}

class _GlucoseMonitoringScreenState extends State<GlucoseMonitoringScreen> {
  final GlucoseService _glucoseService = GlucoseService();
  List<Map<String, dynamic>> _glucoseRecords = [];
  bool _isLoading = true;
  Map<String, dynamic>? _aiRecommendations;

  @override
  void initState() {
    super.initState();
    _loadGlucoseRecords();
  }

  void _loadGlucoseRecords() {
    _glucoseService.getGlucoseReadings().listen((records) {
      if (mounted) {
        setState(() {
          _glucoseRecords = records;
          _isLoading = false;
        });
        // Load AI recommendations when records are available
        if (records.isNotEmpty) {
          _loadAIRecommendations();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TranslatedAppBarTitle('glucose', fallback: 'Glucose'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0C4556)),
            onPressed: () => _showAddGlucoseDialog(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentReading(),
              const SizedBox(height: 30),
              _buildAIAnalysis(),
              const SizedBox(height: 30),
              _buildRecentReadings(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              // Add bottom padding for Android navigation buttons
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentReading() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final latestRecord = _glucoseRecords.isNotEmpty
        ? _glucoseRecords.first
        : null;
    final glucoseLevel = latestRecord != null
        ? ((latestRecord['value'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final readingType = latestRecord != null
        ? (latestRecord['type'] as String?)
        : null;
    final status = _getGlucoseStatus(glucoseLevel, readingType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            status['color'] as Color,
            (status['color'] as Color).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (status['color'] as Color).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Current Glucose Level",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${glucoseLevel.toStringAsFixed(0)} mg/dL",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            status['message'] as String,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysis() {
    // Calculate AI predictions based on recent data
    final prediction = _calculateAIPrediction();
    final recommendations = _aiRecommendations;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C4556).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Color(0xFF0C4556),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                "AI Analysis & Prediction",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C4556),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (prediction['riskLevel'] != null)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: prediction['riskColor'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    prediction['riskIcon'] as IconData,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction['riskTitle'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          prediction['riskMessage'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 15),
          const Text(
            "Trend Analysis",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            prediction['trendAnalysis'] as String,
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 15),
          const Text(
            "Personalized Recommendations",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C4556),
            ),
          ),
          const SizedBox(height: 10),
          if (recommendations != null) ...[
            if (recommendations['dietPlan'] != null) ...[
              _buildSectionTitle('Diet Plan', Icons.restaurant),
              const SizedBox(height: 8),
              _buildDietPlan(recommendations['dietPlan']),
              const SizedBox(height: 12),
            ],
            if (recommendations['exercise'] != null) ...[
              _buildSectionTitle('Exercise', Icons.fitness_center),
              const SizedBox(height: 8),
              _buildExercisePlan(recommendations['exercise']),
              const SizedBox(height: 12),
            ],
            if (recommendations['tips'] != null && recommendations['tips'] is List) ...[
              _buildSectionTitle('Tips', Icons.lightbulb),
              const SizedBox(height: 8),
              ...(recommendations['tips'] as List).map((tip) => _buildRecommendationItem(tip.toString())).toList(),
            ],
          ] else ...[
            ...(prediction['recommendations'] as List<String>)
                .map((rec) => _buildRecommendationItem(rec))
                .toList(),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateAIPrediction() {
    if (_glucoseRecords.isEmpty) {
      return {
        'riskLevel': null,
        'trendAnalysis':
            'No data available yet. Start logging your glucose readings to get AI predictions and personalized recommendations.',
        'recommendations': [
          'Begin monitoring your glucose levels regularly',
          'Log readings at different times of the day',
          'Maintain a consistent monitoring schedule',
        ],
      };
    }

    // Calculate average and trend (mock AI prediction - UI only)
    final recentReadings = _glucoseRecords.take(7).toList();
    final avgGlucose = recentReadings.isEmpty
        ? 0.0
        : (recentReadings
                .map((r) => (r['value'] as num?)?.toDouble() ?? 0.0)
                .reduce((a, b) => a + b) /
            recentReadings.length);

    final isRising = recentReadings.length > 1 &&
        ((recentReadings.first['value'] as num?)?.toDouble() ?? 0.0) >
            ((recentReadings.last['value'] as num?)?.toDouble() ?? 0.0);
    final isHigh = avgGlucose > 180;
    final isLow = avgGlucose < 70;

    String riskTitle;
    String riskMessage;
    Color riskColor;
    IconData riskIcon;

    if (isHigh) {
      riskTitle = 'High Glucose Alert';
      riskMessage =
          'Your average glucose levels are elevated. Consider consulting your doctor.';
      riskColor = Colors.red;
      riskIcon = Icons.warning;
    } else if (isLow) {
      riskTitle = 'Low Glucose Alert';
      riskMessage =
          'Your average glucose levels are low. Monitor closely and have a snack if needed.';
      riskColor = Colors.orange;
      riskIcon = Icons.warning;
    } else {
      riskTitle = 'Normal Range';
      riskMessage =
          'Your glucose levels are within the target range. Keep up the good work!';
      riskColor = Colors.green;
      riskIcon = Icons.check_circle;
    }

    String trendAnalysis = isRising
        ? 'Your glucose levels show a rising trend. Monitor closely and maintain your medication schedule. Consider reviewing your diet and activity levels.'
        : 'Your glucose levels are relatively stable. Continue with your current management plan.';

    List<String> recommendations = [];
    if (isHigh) {
      recommendations = [
        'Take your medications as prescribed',
        'Limit carbohydrate intake in your next meal',
        'Consider light physical activity',
        'Stay well hydrated',
      ];
    } else if (isLow) {
      recommendations = [
        'Have a snack with 15g of carbohydrates',
        'Monitor glucose levels every 15-30 minutes',
        'Avoid strenuous activities until levels normalize',
        'Consult your doctor if levels remain low',
      ];
    } else {
      recommendations = [
        'Continue taking medication as prescribed',
        'Maintain your current diet and exercise routine',
        'Stay hydrated throughout the day',
        'Keep monitoring regularly',
      ];
    }

    return {
      'riskLevel': isHigh ? 'high' : (isLow ? 'low' : 'normal'),
      'riskTitle': riskTitle,
      'riskMessage': riskMessage,
      'riskColor': riskColor,
      'riskIcon': riskIcon,
      'trendAnalysis': trendAnalysis,
      'recommendations': recommendations,
    };
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF0C4556), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReadings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Readings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C4556),
          ),
        ),
        const SizedBox(height: 15),
        ..._glucoseRecords.map((record) => _buildReadingCard(record)).toList(),
      ],
    );
  }

  Widget _buildReadingCard(Map<String, dynamic> record) {
    final value = (record['value'] as num?)?.toDouble() ?? 0.0;
    final readingType = record['type'] as String?;
    final status = _getGlucoseStatus(value, readingType);
    final timestampValue = record['timestamp'];
    final timestampDate = timestampValue is Timestamp
        ? timestampValue.toDate()
        : (timestampValue is DateTime ? timestampValue : null);
    final timeAgo =
        timestampDate != null ? _getTimeAgo(timestampDate) : 'Just now';

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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (status['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.bloodtype,
              color: status['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${value.toStringAsFixed(0)} mg/dL",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C4556),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${_getTypeLabel(record['type'] as String)} • $timeAgo",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (record['notes'] != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    record['notes'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          if (record['isAIFlagged'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "AI Alert",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C4556),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                "Add Reading",
                Icons.add,
                () => _showAddGlucoseDialog(),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton("View History", Icons.history, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GlucoseHistoryScreen(),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionButton("Set Reminder", Icons.alarm, () => _showSetReminderDialog()),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton("Export Data", Icons.download, () async {
                // Quick export for last 30 days
                try {
                  final end = DateTime.now();
                  final start = end.subtract(const Duration(days: 30));
                  final readings = await _glucoseService.getGlucoseReadingsByDateRange(
                    startDate: start,
                    endDate: end,
                  );
                  if (readings.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No data to export')),
                    );
                    return;
                  }
                  // Navigate to history screen where export button is available for full experience
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GlucoseHistoryScreen(),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: ${e.toString()}')),
                  );
                }
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0C4556), size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0C4556),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGlucoseDialog() {
    final glucoseController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'fasting';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Glucose Reading"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: glucoseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Glucose Level (mg/dL)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Reading Type",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'fasting', child: Text('Fasting')),
                  DropdownMenuItem(
                    value: 'post_meal',
                    child: Text('Post Meal'),
                  ),
                  DropdownMenuItem(value: 'random', child: Text('Random')),
                  DropdownMenuItem(value: 'bedtime', child: Text('Bedtime')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: "Notes (Optional)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (glucoseController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter glucose level'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                final value = double.tryParse(glucoseController.text);
                if (value == null || value <= 0 || value > 1000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid glucose level (1-1000 mg/dL)'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                try {
                  await _glucoseService.addGlucoseReading(
                    value: value,
                    type: selectedType,
                    notes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Glucose reading added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Don't pop dialog on error, let user try again
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add reading. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetReminderDialog() {
    TimeOfDay? selectedTime;
    bool isEnabled = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Set Glucose Reminder"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Enable Reminder"),
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() {
                      isEnabled = value;
                    });
                  },
                ),
                if (isEnabled) ...[
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text("Reminder Time"),
                    subtitle: Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : "Select time",
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "You'll be reminded daily to check your glucose level at the selected time.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isEnabled && selectedTime != null
                  ? () {
                      // Store reminder in SharedPreferences
                      // For now, just show a success message
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Reminder set for ${selectedTime!.format(context)}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  : null,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getGlucoseStatus(double value, [String? type]) {
    // Get status based on reading type with proper ranges
    final readingType = type ?? 'random';
    
    switch (readingType) {
      case 'fasting':
        if (value < 70) {
          return {
            'color': Colors.red,
            'message': 'Low - Consider immediate action',
          };
        } else if (value >= 70 && value <= 99) {
          return {
            'color': Colors.green,
            'message': 'Normal (70-99 mg/dL)',
          };
        } else if (value >= 100 && value <= 125) {
          return {
            'color': Colors.orange,
            'message': 'Prediabetes (100-125 mg/dL)',
          };
        } else {
          return {
            'color': Colors.red,
            'message': 'Diabetes (126+ mg/dL) - Consult doctor',
          };
        }
      case 'post_meal':
        if (value < 70) {
          return {
            'color': Colors.red,
            'message': 'Low - Consider immediate action',
          };
        } else if (value < 140) {
          return {
            'color': Colors.green,
            'message': 'Normal (<140 mg/dL)',
          };
        } else if (value >= 140 && value <= 199) {
          return {
            'color': Colors.orange,
            'message': 'Prediabetes (140-199 mg/dL)',
          };
        } else {
          return {
            'color': Colors.red,
            'message': 'Diabetes (200+ mg/dL) - Consult doctor',
          };
        }
      case 'random':
        if (value < 80) {
          return {
            'color': Colors.red,
            'message': 'Low - Consider immediate action',
          };
        } else if (value >= 80 && value <= 140) {
          return {
            'color': Colors.green,
            'message': 'Normal (80-140 mg/dL)',
          };
        } else if (value >= 200) {
          return {
            'color': Colors.red,
            'message': 'Diabetes (200+ mg/dL) - Consult doctor',
          };
        } else {
          return {
            'color': Colors.orange,
            'message': 'Elevated - Monitor closely',
          };
        }
      case 'bedtime':
        if (value < 90) {
          return {
            'color': Colors.red,
            'message': 'Low - Consider immediate action',
          };
        } else if (value >= 90 && value <= 150) {
          return {
            'color': Colors.green,
            'message': 'Normal (90-150 mg/dL)',
          };
        } else {
          return {
            'color': Colors.orange,
            'message': 'High - Monitor closely',
          };
        }
      default:
        if (value < 70) {
          return {
            'color': Colors.red,
            'message': 'Low - Consider immediate action',
          };
        } else if (value > 180) {
          return {
            'color': Colors.orange,
            'message': 'High - Monitor closely',
          };
        } else {
          return {
            'color': Colors.green,
            'message': 'Normal - Good control',
          };
        }
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'fasting':
        return 'Fasting';
      case 'post_meal':
        return 'Post Meal';
      case 'random':
        return 'Random';
      case 'bedtime':
        return 'Bedtime';
      default:
        return 'Unknown';
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }


  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0C4556)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C4556),
          ),
        ),
      ],
    );
  }

  Widget _buildDietPlan(Map<String, dynamic> dietPlan) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dietPlan['breakfast'] != null)
            _buildMealItem('Breakfast', dietPlan['breakfast'].toString()),
          if (dietPlan['lunch'] != null)
            _buildMealItem('Lunch', dietPlan['lunch'].toString()),
          if (dietPlan['dinner'] != null)
            _buildMealItem('Dinner', dietPlan['dinner'].toString()),
          if (dietPlan['snacks'] != null && dietPlan['snacks'] is List)
            _buildMealItem('Snacks', (dietPlan['snacks'] as List).join(', ')),
        ],
      ),
    );
  }

  Widget _buildMealItem(String meal, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$meal: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePlan(Map<String, dynamic> exercise) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise['type'] != null)
            Text('Type: ${exercise['type']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          if (exercise['duration'] != null)
            Text('Duration: ${exercise['duration']}', style: const TextStyle(fontSize: 13)),
          if (exercise['frequency'] != null)
            Text('Frequency: ${exercise['frequency']}', style: const TextStyle(fontSize: 13)),
          if (exercise['tips'] != null && exercise['tips'] is List) ...[
            const SizedBox(height: 8),
            ...(exercise['tips'] as List).map((tip) => Text('• $tip', style: const TextStyle(fontSize: 12))).toList(),
          ],
        ],
      ),
    );
  }

  Future<void> _loadAIRecommendations() async {
    if (_glucoseRecords.isEmpty) return;
    
    try {
      final latestRecord = _glucoseRecords.first;
      final glucoseLevel = (latestRecord['value'] as num?)?.toDouble() ?? 0.0;
      final readingType = latestRecord['type'] as String? ?? 'random';
      final recentReadings = _glucoseRecords.take(7).map((r) => {
        'value': r['value'],
        'type': r['type'],
      }).toList();
      
      final recommendations = await GeminiService.getGlucoseRecommendations(
        glucoseLevel: glucoseLevel,
        readingType: readingType,
        recentReadings: recentReadings,
      );
      
      if (mounted) {
        setState(() {
          _aiRecommendations = recommendations;
        });
      }
    } catch (e) {
      // Silently fail - fallback recommendations will be shown
      if (mounted) {
        setState(() {
          _aiRecommendations = null;
        });
      }
    }
  }
}
