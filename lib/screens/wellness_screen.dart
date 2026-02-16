import 'package:flutter/material.dart';
import 'package:sugenix/services/glucose_service.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/services/wellness_service.dart';
import 'package:sugenix/utils/responsive_layout.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sugenix/services/language_service.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  final GlucoseService _glucoseService = GlucoseService();
  final AuthService _authService = AuthService();
  final WellnessService _wellnessService = WellnessService();
  
  Map<String, dynamic>? _glucoseStats;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String _selectedCategory = 'diet';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _authService.getUserProfile(); // Load profile for context
      _glucoseStats = await _glucoseService.getGlucoseStatistics(days: 7);
      await _loadRecommendations();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendations = await _wellnessService.getRecommendations(
        category: _selectedCategory,
      );
      setState(() {
        _recommendations = recommendations;
      });
    } catch (e) {
      // Keep existing recommendations or use defaults
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
            final title = LanguageService.translate('home', languageCode);
            return Text(
              title == 'home' ? 'Wellness' : title,
              style: const TextStyle(
                color: Color(0xFF0C4556),
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C4556)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _isLoading
            ? _buildShimmerLoading()
            : SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPersonalizedBanner(),
                    const SizedBox(height: 30),
                    _buildCategoryTabs(),
                    const SizedBox(height: 20),
                    _buildRecommendations(),
                    // Add bottom padding for Android navigation buttons
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
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
              height: 150,
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
        ],
      ),
    );
  }

  Widget _buildPersonalizedBanner() {
    final avgGlucose = _glucoseStats?['average'] ?? 0.0;
    final status = _getGlucoseStatus(avgGlucose);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0C4556),
            const Color(0xFF1A6B7A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C4556).withOpacity(0.3),
            blurRadius: 15,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Personalized Wellness",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Based on your health data",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Avg Glucose (7 days)",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${avgGlucose.toStringAsFixed(0)} mg/dL",
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
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF0C4556),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGlucoseStatus(double value) {
    if (value < 70) return 'Low';
    if (value > 180) return 'High';
    return 'Normal';
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'id': 'diet', 'label': 'Diet', 'icon': Icons.restaurant},
      {'id': 'exercise', 'label': 'Exercise', 'icon': Icons.fitness_center},
      {'id': 'medication', 'label': 'Medication', 'icon': Icons.medication},
      {'id': 'lifestyle', 'label': 'Lifestyle', 'icon': Icons.wb_sunny},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () async {
                setState(() {
                  _selectedCategory = category['id'] as String;
                  _isLoading = true;
                });
                await _loadRecommendations();
                setState(() {
                  _isLoading = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0C4556) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0C4556)
                        : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : const Color(0xFF0C4556),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF0C4556),
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No recommendations available for this category.',
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
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recommendations",
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
        const SizedBox(height: 15),
        ..._recommendations.map((rec) => _buildRecommendationCard(rec)).toList(),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    // Parse color from string or use default
    Color cardColor;
    try {
      final colorString = recommendation['color'] as String? ?? '#0C4556';
      cardColor = Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      cardColor = const Color(0xFF0C4556);
    }

    // Get icon from string name or use default
    IconData iconData;
    final iconName = recommendation['icon'] as String? ?? 'info';
    switch (iconName) {
      case 'restaurant':
        iconData = Icons.restaurant;
        break;
      case 'directions_walk':
        iconData = Icons.directions_walk;
        break;
      case 'fitness_center':
        iconData = Icons.fitness_center;
        break;
      case 'alarm':
        iconData = Icons.alarm;
        break;
      case 'medical_services':
        iconData = Icons.medical_services;
        break;
      case 'bedtime':
        iconData = Icons.bedtime;
        break;
      case 'shopping_basket':
        iconData = Icons.shopping_basket;
        break;
      case 'no_food':
        iconData = Icons.no_food;
        break;
      case 'water_drop':
        iconData = Icons.water_drop;
        break;
      default:
        iconData = Icons.info;
    }

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 10 : 12),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: cardColor,
              size: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 24,
                tablet: 26,
                desktop: 28,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.isMobile(context) ? 12 : 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'] as String? ?? 'Recommendation',
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
                const SizedBox(height: 8),
                Text(
                  recommendation['description'] as String? ?? '',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 13,
                      tablet: 14,
                      desktop: 15,
                    ),
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

