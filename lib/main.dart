import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugenix/firebase_options.dart';
import 'package:sugenix/splash.dart';
import 'package:sugenix/Login.dart';
import 'package:sugenix/signin.dart';
import 'package:sugenix/screens/home_screen.dart';
import 'package:sugenix/screens/patient_home_screen.dart';
import 'package:sugenix/screens/medical_records_screen.dart';
import 'package:sugenix/screens/medicine_orders_screen.dart';
import 'package:sugenix/screens/profile_screen.dart';
import 'package:sugenix/screens/emergency_screen.dart';
import 'package:sugenix/screens/glucose_monitoring_screen.dart';
import 'package:sugenix/screens/ai_assistant_screen.dart';
import 'package:sugenix/screens/wellness_screen.dart';
import 'package:sugenix/screens/medicine_scanner_screen.dart';
import 'package:sugenix/screens/appointments_screen.dart';
import 'package:sugenix/screens/doctor_details_screen.dart';
import 'package:sugenix/screens/glucose_history_screen.dart';
import 'package:sugenix/screens/bluetooth_device_screen.dart';
import 'package:sugenix/screens/emergency_contacts_screen.dart';
import 'package:sugenix/services/favorites_service.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/models/doctor.dart';
import 'package:sugenix/screens/doctor_registration_screen.dart';
import 'package:sugenix/screens/pharmacy_registration_screen.dart';
import 'package:sugenix/screens/medicine_catalog_screen.dart';
import 'package:sugenix/screens/patient_dashboard_screen.dart';
import 'package:sugenix/screens/pharmacy_dashboard_screen.dart';
import 'package:sugenix/screens/pharmacy_orders_screen.dart';
import 'package:sugenix/screens/pharmacy_inventory_screen.dart';
import 'package:sugenix/screens/doctor_dashboard_screen.dart';
import 'package:sugenix/screens/admin_panel_screen.dart';
import 'package:sugenix/screens/prescription_upload_screen.dart';
import 'package:sugenix/services/app_localization_service.dart';
import 'package:sugenix/services/locale_notifier.dart';
import 'package:sugenix/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:sugenix/screens/web_landing_screen.dart';
import 'package:sugenix/screens/unsupported_role_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found - continue without it (optional)
    print('Note: .env file not found - using Firestore/constants for API keys');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firebase offline persistence
  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Set system UI overlay style to prevent system navigation buttons from overlapping
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize saved locale
  final savedLocale = await AppLocalizationService.getSavedLocale();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleNotifier()..setLocale(savedLocale),
      child: const SugenixApp(),
    ),
  );
}

class SugenixApp extends StatefulWidget {
  const SugenixApp({super.key});

  @override
  State<SugenixApp> createState() => _SugenixAppState();
}

class _SugenixAppState extends State<SugenixApp> {
  @override
  Widget build(BuildContext context) {
    // Use Consumer to rebuild MaterialApp when locale changes
    return Consumer<LocaleNotifier>(
      builder: (context, localeNotifier, child) {
        return MaterialApp(
          title: 'Sugenix - Diabetes Management',
          debugShowCheckedModeBanner: false,
          locale: localeNotifier.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            primaryColor: const Color(0xFF0C4556),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0C4556),
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C4556),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          home: kIsWeb ? const WebLandingScreen() : const SplashScreen(),
          routes: {
            '/login': (context) => const Login(),
            '/signup': (context) => const Signup(),
            '/home': (context) => const HomeScreen(),
            '/register-doctor': (context) => const DoctorRegistrationScreen(),
            '/register-pharmacy': (context) =>
                const PharmacyRegistrationScreen(),
            // Note: Doctor details requires a Doctor object; navigate via MaterialPageRoute
            '/medical-records': (context) => const MedicalRecordsScreen(),
            '/medicine-orders': (context) => const MedicineOrdersScreen(),
            '/medicine-catalog': (context) => const MedicineCatalogScreen(),
            '/patient-dashboard': (context) => const PatientDashboardScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/emergency': (context) => const EmergencyScreen(),
            '/glucose-monitoring': (context) => const GlucoseMonitoringScreen(),
            '/ai-assistant': (context) => const AIAssistantScreen(),
            '/wellness': (context) => const WellnessScreen(),
            '/medicine-scanner': (context) => const MedicineScannerScreen(),
            '/appointments': (context) => const AppointmentsScreen(),
            '/glucose-history': (context) => const GlucoseHistoryScreen(),
            '/bluetooth-devices': (context) => const BluetoothDeviceScreen(),
            '/emergency-contacts': (context) => const EmergencyContactsScreen(),
            '/pharmacy-dashboard': (context) => const PharmacyDashboardScreen(),
            '/prescription-upload': (context) =>
                const PrescriptionUploadScreen(),
          },
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final authService = AuthService();
      final profile = await authService.getUserProfile();
      setState(() {
        _userRole = profile?['role'] ?? 'user';
        _loadingRole = false;
      });
    } catch (e) {
      setState(() {
        _userRole = 'user';
        _loadingRole = false;
      });
    }
  }

  List<Widget> get _screens {
    if (_userRole == 'admin') {
      if (kIsWeb) {
        // Admin on web uses sidebar navigation, no bottom nav needed
        return [const AdminPanelScreen()];
      }
      return [const UnsupportedRoleScreen(role: 'Admin (Web Only)')];
    } else if (_userRole == 'pharmacy') {
      if (kIsWeb) {
        return [
          const PharmacyDashboardScreen(),
          const PharmacyOrdersScreen(),
          const PharmacyInventoryScreen(),
          const ProfileScreen(),
        ];
      }
      return [const UnsupportedRoleScreen(role: 'Pharmacy (Web Only)')];
    } else if (_userRole == 'doctor') {
      return [
        const DoctorDashboardScreen(),
        const ProfileScreen(),
      ];
    } else {
      // Patient/User
      return [
        const PatientHomeScreen(),
        const GlucoseMonitoringScreen(),
        const MedicalRecordsScreen(),
        const MedicineOrdersScreen(),
        const ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(AppLocalizations l10n) {
    if (_userRole == 'admin') {
      if (!kIsWeb) {
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.block, size: 24),
            activeIcon: Icon(Icons.block, size: 24),
            label: l10n.dashboard,
          ),
        ];
      }
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outlined, size: 24),
          activeIcon: Icon(Icons.people, size: 24),
          label: l10n.users,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services_outlined, size: 24),
          activeIcon: Icon(Icons.medical_services, size: 24),
          label: l10n.doctors,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_pharmacy_outlined, size: 24),
          activeIcon: Icon(Icons.local_pharmacy, size: 24),
          label: l10n.pharmacies,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined, size: 24),
          activeIcon: Icon(Icons.account_balance_wallet, size: 24),
          label: l10n.revenue,
        ),
      ];
    } else if (_userRole == 'pharmacy') {
      if (!kIsWeb) {
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.block, size: 24),
            activeIcon: Icon(Icons.block, size: 24),
            label: l10n.dashboard,
          ),
        ];
      }
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined, size: 24),
          activeIcon: Icon(Icons.dashboard, size: 24),
          label: l10n.dashboard,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined, size: 24),
          activeIcon: Icon(Icons.receipt_long, size: 24),
          label: l10n.orders,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined, size: 24),
          activeIcon: Icon(Icons.inventory_2, size: 24),
          label: l10n.inventory,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: 24),
          activeIcon: Icon(Icons.person, size: 24),
          label: l10n.profile,
        ),
      ];
    } else if (_userRole == 'doctor') {
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined, size: 24),
          activeIcon: Icon(Icons.dashboard, size: 24),
          label: l10n.dashboard,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: 24),
          activeIcon: Icon(Icons.person, size: 24),
          label: l10n.profile,
        ),
      ];
    } else {
      // Patient/User
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 24),
          activeIcon: Icon(Icons.home, size: 24),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart_outlined, size: 24),
          activeIcon: Icon(Icons.monitor_heart, size: 24),
          label: l10n.glucose,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined, size: 24),
          activeIcon: Icon(Icons.assignment, size: 24),
          label: l10n.records,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_outlined, size: 24),
          activeIcon: Icon(Icons.medication, size: 24),
          label: l10n.medicine,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: 24),
          activeIcon: Icon(Icons.person, size: 24),
          label: l10n.profile,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // For admin on web, show admin panel directly without bottom navigation
    if (_userRole == 'admin' && kIsWeb) {
      return _screens[0];
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                selectedItemColor: const Color(0xFF0C4556),
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedFontSize: isTablet ? 16 : 12,
                unselectedFontSize: isTablet ? 14 : 10,
                items: _getNavItems(l10n),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Placeholder screens for navigation
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendar),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
      ),
      body: Center(
        child: Text(
          l10n.calendarScreenComingSoon,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favoritesService = FavoritesService();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favouriteDoctors),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
      ),
      body: StreamBuilder<List<Doctor>>(
        stream: favoritesService.streamFavoriteDoctors(),
        builder: (context, snapshot) {
          final doctors = snapshot.data ?? [];
          if (doctors.isEmpty) {
            return Center(
              child: Text(
                l10n.noFavouritesYet,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final d = doctors[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.white,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0C4556),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  d.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0C4556),
                  ),
                ),
                subtitle: Text(
                  d.specialization,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorDetailsScreen(doctor: d),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF5F6F8),
    );
  }
}
