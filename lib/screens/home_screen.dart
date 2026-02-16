import 'package:flutter/material.dart';
import 'package:sugenix/models/doctor.dart';
import 'package:sugenix/screens/doctor_details_screen.dart';
import 'package:sugenix/screens/ai_assistant_screen.dart';
import 'package:sugenix/screens/wellness_screen.dart';
import 'package:sugenix/services/glucose_service.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:sugenix/services/doctor_service.dart';
import 'package:sugenix/services/favorites_service.dart';
import 'package:sugenix/services/language_service.dart';
import 'package:sugenix/widgets/translated_text.dart';
import 'package:sugenix/screens/emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlucoseService _glucoseService = GlucoseService();
  final AuthService _authService = AuthService();
  final DoctorService _doctorService = DoctorService();
  final FavoritesService _favoritesService = FavoritesService();

  List<Map<String, dynamic>> _recentReadings = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _glucoseStats;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Doctor> _allDoctors = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  Future<void> _loadData() async {
    try {
      // Load user profile
      _userProfile = await _authService.getUserProfile();

      // Load recent glucose readings
      _glucoseService.getGlucoseReadings().listen((readings) {
        if (mounted) {
          setState(() {
            _recentReadings = readings.take(3).toList();
            _isLoading = false;
          });
        }
      });

      // Load glucose statistics
      _glucoseStats = await _glucoseService.getGlucoseStatistics(days: 7);

      // Listen to doctors
      _doctorService.streamDoctors().listen((doctors) {
        if (mounted) {
          setState(() {
            _allDoctors = doctors;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TranslatedAppBarTitle('home', fallback: 'Home'),
      ),
      body: _isLoading ? _buildShimmerLoading() : _buildContent(),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildShimmerCard(height: 120),
          const SizedBox(height: 20),
          _buildShimmerCard(height: 200),
          const SizedBox(height: 20),
          _buildShimmerCard(height: 150),
        ],
      ),
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 30),
              _buildGlucoseOverview(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              const SizedBox(height: 30),
              _buildLiveDoctors(),
              const SizedBox(height: 30),
              _buildPopularDoctors(),
              const SizedBox(height: 30),
              _buildPediatricDoctors(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final userName = _userProfile?['name'] ?? 'User';
    final currentTime = DateFormat('EEEE, MMMM d').format(DateTime.now());

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.waving_hand, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'welcome_back_comma',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  fallback: 'Welcome back,',
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentTime,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Optional profile avatar placeholder (use user's photoUrl if available)
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.12),
            child: Icon(Icons.person, color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseOverview() {
    if (_recentReadings.isEmpty) {
      return _buildEmptyGlucoseCard();
    }

    return LanguageBuilder(
      builder: (context, languageCode) {
        final latestReading = _recentReadings.first;
        final glucoseValue = (latestReading['value'] as num?)?.toDouble() ?? 0.0;
        final status = _getGlucoseStatus(glucoseValue, languageCode);

        return AnimationConfiguration.staggeredList(
          position: 0,
          duration: const Duration(milliseconds: 600),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (status['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.monitor_heart,
                            color: status['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        TranslatedText(
                          'current_glucose_level',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C4556),
                          ),
                          fallback: 'Current Glucose Level',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          glucoseValue.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: status['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TranslatedText(
                              'mg_dl',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              fallback: 'mg/dL',
                            ),
                            Text(
                              status['message'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: status['color'] as Color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_glucoseStats != null) ...[
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyGlucoseCard() {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                TranslatedText(
                  'no_glucose_readings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C4556),
                  ),
                  fallback: 'No glucose readings yet',
                ),
                const SizedBox(height: 8),
                TranslatedText(
                  'start_monitoring',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  fallback: 'Start monitoring your glucose levels',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = _glucoseStats!;
    return LanguageBuilder(
      builder: (context, languageCode) {
        return Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'avg',
                '${stats['average'].toStringAsFixed(0)}',
                Icons.trending_up,
                Colors.blue,
                languageCode,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'normal',
                '${stats['normalReadings']}',
                Icons.check_circle,
                Colors.green,
                languageCode,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'high',
                '${stats['highReadings']}',
                Icons.warning,
                Colors.orange,
                languageCode,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'low',
                '${stats['lowReadings']}',
                Icons.error,
                Colors.red,
                languageCode,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
    String translationKey,
    String value,
    IconData icon,
    Color color,
    String languageCode,
  ) {
    final label = LanguageService.translate(translationKey, languageCode);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return AnimationConfiguration.staggeredList(
      position: 1,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: LanguageBuilder(
            builder: (context, languageCode) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'quick_actions',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C4556),
                    ),
                    fallback: 'Quick Actions',
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'add_reading',
                          Icons.add_circle,
                          const Color(0xFF4CAF50),
                          () {
                            Navigator.pushNamed(context, '/glucose-monitoring');
                          },
                          languageCode,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionCard(
                          'view_history',
                          Icons.history,
                          const Color(0xFF2196F3),
                          () {
                            Navigator.pushNamed(context, '/glucose-history');
                          },
                          languageCode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'ai_assistant',
                          Icons.psychology,
                          const Color(0xFF9C27B0),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AIAssistantScreen(),
                              ),
                            );
                          },
                          languageCode,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionCard(
                          'wellness',
                          Icons.favorite,
                          const Color(0xFFE91E63),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WellnessScreen(),
                              ),
                            );
                          },
                          languageCode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'emergency',
                          Icons.emergency,
                          const Color(0xFFF44336),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmergencyScreen(),
                              ),
                            );
                          },
                          languageCode,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionCard(
                          'medicine',
                          Icons.medication,
                          const Color(0xFF9C27B0),
                          () {
                            Navigator.pushNamed(context, '/medicine-orders');
                          },
                          languageCode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          'dashboard',
                          Icons.dashboard_customize,
                          const Color(0xFF3F51B5),
                          () {
                            Navigator.pushNamed(context, '/patient-dashboard');
                          },
                          languageCode,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionCard(
                          'records',
                          Icons.assignment,
                          const Color(0xFF4CAF50),
                          () {
                            Navigator.pushNamed(context, '/medical-records');
                          },
                          languageCode,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String translationKey,
    IconData icon,
    Color color,
    VoidCallback onTap,
    String languageCode,
  ) {
    final title = LanguageService.translate(translationKey, languageCode);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C4556),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDoctors() {
    final liveDoctors = _allDoctors.where((d) => d.isOnline).toList();
    return AnimationConfiguration.staggeredList(
      position: 2,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LanguageBuilder(
                builder: (context, languageCode) {
                  return Row(
                    children: [
                      TranslatedText(
                        'live_doctors',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C4556),
                        ),
                        fallback: 'Live Doctors',
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            TranslatedText(
                              'live',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              fallback: 'Live',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: liveDoctors.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildDoctorCard(liveDoctors[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularDoctors() {
    final popularDoctors = _allDoctors
        .where((d) => d.rating >= 4.5)
        .toList();
    return AnimationConfiguration.staggeredList(
      position: 3,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'popular_doctors',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C4556),
                ),
                fallback: 'Popular Doctors',
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularDoctors.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildDoctorCard(popularDoctors[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPediatricDoctors() {
    final pediatricDoctors = _allDoctors
        .where((d) => d.specialization.toLowerCase().contains('pediatric'))
        .toList();
    return AnimationConfiguration.staggeredList(
      position: 4,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'pediatric_specialists',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C4556),
                ),
                fallback: 'Pediatric Specialists',
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pediatricDoctors.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildDoctorCard(pediatricDoctors[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailsScreen(doctor: doctor),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
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
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0C4556).withOpacity(0.8),
                    const Color(0xFF1A6B7A).withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  if (doctor.isOnline)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: StreamBuilder<bool>(
                      stream: _favoritesService.isFavoriteStream(doctor.id),
                      builder: (context, snapshot) {
                        final isFav = snapshot.data ?? false;
                        return InkWell(
                          onTap: () async {
                            try {
                              await _favoritesService.toggleFavorite(doctor.id);
                              // Optionally show feedback
                            } catch (e) {
                              final languageCode = await LanguageService.getSelectedLanguage();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(LanguageService.translate('failed_to_update_favorite', languageCode)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.redAccent : Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C4556),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialization,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        doctor.rating.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0C4556),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getGlucoseStatus(double value, String languageCode) {
    if (value < 70) {
      return {'color': Colors.red, 'message': LanguageService.translate('low', languageCode)};
    } else if (value > 180) {
      return {'color': Colors.orange, 'message': LanguageService.translate('high', languageCode)};
    } else {
      return {'color': Colors.green, 'message': LanguageService.translate('normal', languageCode)};
    }
  }
}
