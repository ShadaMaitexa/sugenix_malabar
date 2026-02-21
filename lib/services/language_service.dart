import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  // Stream controller for language changes
  static final _languageController = StreamController<String>.broadcast();

  // Stream to listen for language changes
  static Stream<String> get languageStream => _languageController.stream;

  // Stream that emits current language immediately and on changes
  static Stream<String> get currentLanguageStream async* {
    // Emit current language immediately
    final current = await getSelectedLanguage();
    yield current;
    // Then listen for changes
    yield* _languageController.stream.asyncMap((_) async {
      return await getSelectedLanguage();
    });
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'Sugenix',
      'home': 'Home',
      'glucose': 'Glucose',
      'records': 'Records',
      'medicine': 'Medicine',
      'profile': 'Profile',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'welcome': 'Welcome',
      'logout': 'Logout',
      'settings': 'Settings',
      'language': 'Language',
      'sign_in': 'Sign in',
      'sign_in_title': 'Sign in',
      'welcome_back': 'Welcome back',
      'sign_in_to_continue': 'Sign in to continue',
      'signup_journey': 'Your journey to smarter diabetes care starts here',
      're_enter_password': 'Re-enter Password',
      'agree_terms': 'I agree to the terms and conditions',
      'have_account': 'Have an account? ',
      'dont_have_account': "Don't have an account? ",
      'forgot_password': 'Forgot password?',
      'continue_as': 'Continue as',
      'patient_user': 'Patient/User',
      'doctor_diabetologist': 'Doctor / Diabetologist',
      'pharmacy': 'Pharmacy',
      'fill_all_fields': 'Please fill in all fields',
      'passwords_no_match': 'Passwords do not match',
      'password_min_length': 'Password must be at least 6 characters',
      'signup_failed': 'Signup failed',
      'account_pending':
          'Your account is pending admin approval. Please wait for approval before logging in.',
      'agree_prefix': 'I agree to the ',
      'agree_suffix': '',
      'terms_and_conditions_title': 'Terms and Conditions',
      'terms_section_1_title': '1. Acceptance of Terms',
      'terms_section_1_content':
          'By accessing and using Sugenix, you agree to be bound by these Terms and Conditions and all applicable laws and regulations.',
      'terms_section_2_title': '2. Medical Disclaimer',
      'terms_section_2_content':
          'Sugenix is a tool for diabetes management and should not be used as a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
      'terms_section_3_title': '3. User Privacy',
      'terms_section_3_content':
          'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information. By using our service, you agree to the collection and use of information in accordance with our policy.',
      'terms_section_4_title': '4. Account Responsibilities',
      'terms_section_4_content':
          'You are responsible for maintaining the confidentiality of your account and password. You agree to notify us immediately of any unauthorized use of your account.',
      'terms_section_5_title': '5. Limitation of Liability',
      'terms_section_5_content':
          'Sugenix and its creators shall not be liable for any direct, indirect, incidental, special, or consequential damages resulting from the use or inability to use the service.',
      // Home Screen
      'welcome_back_comma': 'Welcome back,',
      'current_glucose_level': 'Current Glucose Level',
      'no_glucose_readings': 'No glucose readings yet',
      'start_monitoring': 'Start monitoring your glucose levels',
      'quick_actions': 'Quick Actions',
      'add_reading': 'Add Reading',
      'view_history': 'View History',
      'ai_assistant': 'AI Assistant',
      'wellness': 'Wellness',
      'emergency': 'Emergency',
      'dashboard': 'Dashboard',
      'live_doctors': 'Live Doctors',
      'live': 'Live',
      'popular_doctors': 'Popular Doctors',
      'pediatric_specialists': 'Pediatric Specialists',
      'top_doctors': 'Top Doctors',
      'my_appointments': 'My Appointments',
      // Patient dashboard
      'my_health_dashboard': 'My Health Dashboard',
      'seven_day_average': '7-Day Average',
      'in_range_readings': 'In Range',
      'high_alerts': 'High Alerts',
      'low_alerts': 'Low Alerts',
      'glucose_logs': 'Glucose Logs',
      'book_doctor': 'Book Doctor',
      'medical_records_section': 'Medical Records',
      'order_medicines': 'Order Medicines',
      'emergency_sos_action': 'Emergency SOS',
      'recent_glucose_readings': 'Recent Glucose Readings',
      'no_readings_message': 'No readings yet. Add your first reading.',
      'upcoming_appointments_section': 'Upcoming Appointments',
      'no_upcoming_appointments': 'No upcoming appointments.',
      'book_consultation_prompt': 'Book a consultation.',
      'recent_orders_section': 'Recent Medicine Orders',
      'no_recent_orders': 'No orders yet. Explore the e-pharmacy store.',
      'latest_medical_records': 'Latest Medical Records',
      'no_medical_records':
          'No records found. Upload prescriptions or reports.',
      'language_settings': 'Language Preferences',
      'view_all': 'View All',
      // Role specific quick actions
      'doctor_dashboard': 'Doctor Dashboard',
      'patient_records': 'Patient Records',
      'doctor_appointments': 'Doctor Appointments',
      'pharmacy_dashboard': 'Pharmacy Dashboard',
      'pharmacy_orders': 'Pharmacy Orders',
      'inventory_management': 'Inventory Manager',
      'normal': 'Normal',
      'high': 'High',
      'low': 'Low',
      'avg': 'Avg',
      'mg_dl': 'mg/dL',
      // Settings Screen
      'general': 'General',
      'enable_push_notifications': 'Enable push notifications',
      'notifications': 'Notifications',
      'biometric_login': 'Biometric Login',
      'use_fingerprint_faceid': 'Use fingerprint or face ID',
      'privacy_security': 'Privacy & Security',
      'change_password': 'Change Password',
      'update_account_password': 'Update your account password',
      'privacy_policy': 'Privacy Policy',
      'view_privacy_policy': 'View our privacy policy',
      'terms_conditions': 'Terms & Conditions',
      'read_terms_conditions': 'Read terms and conditions',
      'data_storage': 'Data & Storage',
      'backup_data': 'Backup Data',
      'backup_to_cloud': 'Backup your data to cloud',
      'clear_cache': 'Clear Cache',
      'clear_cache_temp': 'Clear app cache and temporary files',
      'account': 'Account',
      'sign_out_account': 'Sign out from your account',
      'are_you_sure_logout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'close': 'Close',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'update': 'Update',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      // Navigation
      'users': 'Users',
      'doctors': 'Doctors',
      'pharmacies': 'Pharmacies',
      'revenue': 'Revenue',
      'orders': 'Orders',
      'inventory': 'Inventory',
      'appointments': 'Appointments',
      // Common messages
      'failed_to_update_favorite': 'Failed to update favorite',
      'cache_cleared_successfully': 'Cache cleared successfully',
      'failed_to_clear_cache': 'Failed to clear cache',
      'data_backed_up_successfully': 'Data backed up successfully to cloud',
      'backup_failed': 'Backup failed',
      'please_login_to_backup': 'Please login to backup data',
      'biometric_login_enabled': 'Biometric login enabled',
      'biometric_login_disabled': 'Biometric login disabled',
      'password_changed_successfully': 'Password changed successfully',
      'failed_to_change_password': 'Failed to change password',
      'current_password_incorrect': 'Current password is incorrect',
      'new_password_too_weak':
          'New password is too weak. Please use a stronger password',
      'please_login_again': 'Please login again to change password',
      'please_enter_current_password': 'Please enter current password',
      'please_enter_new_password': 'Please enter new password',
      'new_passwords_no_match': 'New passwords do not match',
      'new_password_different':
          'New password must be different from current password',
      'are_you_sure_clear_cache':
          'Are you sure you want to clear all cached data? This will not delete your account data.',
      // Favorites
      'favourite_doctors': 'Favourite Doctors',
      'no_favourites_yet': 'No favourites yet',
      // Calendar
      'calendar': 'Calendar',
      'calendar_screen_coming_soon': 'Calendar Screen\nComing Soon!',
      'chats': 'Chats',
      'messages': 'Messages',
    },
    'ml': {
      'app_name': 'സുജെനിക്സ്',
      'home': 'ഹോം',
      'glucose': 'ഗ്ലൂക്കോസ്',
      'records': 'റെക്കോർഡുകൾ',
      'medicine': 'മരുന്ന്',
      'profile': 'പ്രൊഫൈൽ',
      'login': 'ലോഗിൻ',
      'signup': 'സൈൻ അപ്പ്',
      'email': 'ഇമെയിൽ',
      'password': 'പാസ്‌വേഡ്',
      'name': 'പേര്',
      'welcome': 'സ്വാഗതം',
      'logout': 'ലോഗ്‌ഔട്ട്',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'language': 'ഭാഷ',
      'sign_in': 'സൈൻ ഇൻ',
      'sign_in_title': 'സൈൻ ഇൻ',
      'welcome_back': 'വീണ്ടും സ്വാഗതം',
      'sign_in_to_continue': 'തുടരാൻ സൈൻ ഇൻ ചെയ്യുക',
      'signup_journey':
          'ബുദ്ധിപൂർവ്വമായ പ്രമേഹ പരിചരണത്തിലേക്കുള്ള നിങ്ങളുടെ യാത്ര ഇവിടെ ആരംഭിക്കുന്നു',
      're_enter_password': 'പാസ്‌വേഡ് വീണ്ടും നൽകുക',
      'agree_terms': 'ഞാൻ നിബന്ധനകളും വ്യവസ്ഥകളും അംഗീകരിക്കുന്നു',
      'have_account': 'അക്കൗണ്ട് ഉണ്ടോ? ',
      'dont_have_account': 'അക്കൗണ്ട് ഇല്ലേ? ',
      'forgot_password': 'പാസ്‌വേഡ് മറന്നോ?',
      'continue_as': 'ഇങ്ങനെ തുടരുക',
      'patient_user': 'രോഗി/ഉപയോക്താവ്',
      'doctor_diabetologist': 'ഡോക്ടർ / പ്രമേഹ വിദഗ്ദ്ധൻ',
      'pharmacy': 'ഫാർമസി',
      'fill_all_fields': 'ദയവായി എല്ലാ ഫീൽഡുകളും പൂരിപ്പിക്കുക',
      'passwords_no_match': 'പാസ്‌വേഡുകൾ പൊരുത്തപ്പെടുന്നില്ല',
      'password_min_length': 'പാസ്‌വേഡ് കുറഞ്ഞത് 6 പ്രതീകങ്ങൾ ആയിരിക്കണം',
      'signup_failed': 'സൈൻ അപ്പ് പരാജയപ്പെട്ടു',
      'account_pending':
          'നിങ്ങളുടെ അക്കൗണ്ട് അഡ്മിൻ അംഗീകാരത്തിനായി കാത്തിരിക്കുന്നു. ലോഗിൻ ചെയ്യുന്നതിന് മുമ്പ് അംഗീകാരത്തിനായി കാത്തിരിക്കുക.',
      'agree_prefix': 'ഞാൻ ',
      'agree_suffix': ' അംഗീകരിക്കുന്നു',
      'terms_and_conditions_title': 'നിബന്ധനകളും വ്യവസ്ഥകളും',
      'terms_section_1_title': '1. നിബന്ധനകളുടെ അംഗീകാരം',
      'terms_section_1_content':
          'സുജെനിക്സ് ആക്സസ് ചെയ്യുന്നതിലൂടെയും ഉപയോഗിക്കുന്നതിലൂടെയും, ഈ നിബന്ധനകളും വ്യവസ്ഥകളും ബാധകമായ എല്ലാ നിയമങ്ങളും ചട്ടങ്ങളും പാലിക്കുമെന്ന് നിങ്ങൾ സമ്മതിക്കുന്നു.',
      'terms_section_2_title': '2. മെഡിക്കൽ നിരാകരണം',
      'terms_section_2_content':
          'പ്രമേഹ നിയന്ത്രണത്തിനുള്ള ഒരു ഉപകരണമാണ് സുജെനിക്സ്, ഇത് പ്രൊഫഷണൽ മെഡിക്കൽ ഉപദേശത്തിനോ രോഗനിർണ്ണയത്തിനോ ചികിത്സയ്ക്കോ പകരമായി ഉപയോഗിക്കരുത്.',
      'terms_section_3_title': '3. ഉപയോക്തൃ സ്വകാര്യത',
      'terms_section_3_content':
          'നിങ്ങളുടെ സ്വകാര്യത ഞങ്ങൾക്ക് പ്രധാനമാണ്. ഞങ്ങളുടെ സേവനം ഉപയോഗിക്കുന്നതിലൂടെ, ഞങ്ങളുടെ നയത്തിന് അനുസൃതമായി വിവരങ്ങൾ ശേഖരിക്കുന്നതിനും ഉപയോഗിക്കുന്നതിനും നിങ്ങൾ സമ്മതിക്കുന്നു.',
      'terms_section_4_title': '4. അക്കൗണ്ട് ഉത്തരവാദിത്തങ്ങൾ',
      'terms_section_4_content':
          'നിങ്ങളുടെ അക്കൗണ്ടിന്റെയും പാസ്‌വേഡിന്റെയും രഹസ്യസ്വഭാവം കാത്തുസൂക്ഷിക്കുന്നതിന് നിങ്ങൾ ഉത്തരവാദിയാണ്.',
      'terms_section_5_title': '5. ബാധ്യതാ പരിമിതി',
      'terms_section_5_content':
          'സേവനം ഉപയോഗിക്കുന്നതിലൂടെയോ ഉപയോഗിക്കാനുള്ള കഴിവില്ലായ്മയിലൂടെയോ ഉണ്ടാകുന്ന നേരിട്ടുള്ളതോ അല്ലാത്തതോ ആയ നാശനഷ്ടങ്ങൾക്ക് സുജെനിക്സും അതിന്റെ സ്രഷ്‌ടാക്കളും ഉത്തരവാദികളായിരിക്കില്ല.',
      // Home Screen
      'welcome_back_comma': 'വീണ്ടും സ്വാഗതം,',
      'current_glucose_level': 'നിലവിലെ ഗ്ലൂക്കോസ് നില',
      'no_glucose_readings': 'ഇതുവരെ ഗ്ലൂക്കോസ് വായനകൾ ഇല്ല',
      'start_monitoring': 'നിങ്ങളുടെ ഗ്ലൂക്കോസ് നിലകൾ നിരീക്ഷിക്കാൻ ആരംഭിക്കുക',
      'quick_actions': 'ദ്രുത പ്രവർത്തനങ്ങൾ',
      'add_reading': 'വായന ചേർക്കുക',
      'view_history': 'ചരിത്രം കാണുക',
      'ai_assistant': 'AI അസിസ്റ്റന്റ്',
      'wellness': 'ആരോഗ്യം',
      'emergency': 'അടിയന്തിര',
      'dashboard': 'ഡാഷ്ബോർഡ്',
      'live_doctors': 'ലൈവ് ഡോക്ടർമാർ',
      'live': 'ലൈവ്',
      'popular_doctors': 'ജനപ്രിയ ഡോക്ടർമാർ',
      'pediatric_specialists': 'കുട്ടികളുടെ വിദഗ്ദ്ധർ',
      'top_doctors': 'മികച്ച ഡോക്ടർമാർ',
      'my_appointments': 'എന്റെ അപ്പോയിന്റ്മെന്റുകൾ',
      // Patient dashboard
      'my_health_dashboard': 'എന്റെ ആരോഗ്യ ഡാഷ്ബോർഡ്',
      'seven_day_average': '7 ദിവസത്തെ ശരാശരി',
      'in_range_readings': 'പരിധിക്കുള്ളിൽ',
      'high_alerts': 'ഉയർന്ന മുന്നറിയിപ്പുകൾ',
      'low_alerts': 'കുറഞ്ഞ മുന്നറിയിപ്പുകൾ',
      'glucose_logs': 'ഗ്ലൂക്കോസ് രേഖകൾ',
      'book_doctor': 'ഡോക്ടറെ ബുക്ക് ചെയ്യുക',
      'medical_records_section': 'മെഡിക്കൽ രേഖകൾ',
      'order_medicines': 'മരുന്നുകൾ ഓർഡർ ചെയ്യുക',
      'emergency_sos_action': 'അടിയന്തിര SOS',
      'recent_glucose_readings': 'അടുത്തകാല ഗ്ലൂക്കോസ് വായനകൾ',
      'no_readings_message': 'ഇതുവരെ വായനകളില്ല. നിങ്ങളുടെ ആദ്യ വായന ചേർക്കുക.',
      'upcoming_appointments_section': 'വരാനിരിക്കുന്ന അപ്പോയിന്റ്മെന്റുകൾ',
      'no_upcoming_appointments': 'വരാനിരിക്കുന്ന അപ്പോയിന്റ്മെന്റുകളില്ല.',
      'book_consultation_prompt': 'ഒരു കൗൺസൽട്ടേഷൻ ബുക്ക് ചെയ്യുക.',
      'recent_orders_section': 'അടുത്തകാല മരുന്ന് ഓർഡറുകൾ',
      'no_recent_orders': 'ഇനിയും ഓർഡറുകളില്ല. ഇ-ഫാർമസി സ്റ്റോർ അന്വേഷിക്കുക.',
      'latest_medical_records': 'പുതിയ മെഡിക്കൽ രേഖകൾ',
      'no_medical_records': 'ഇനിയും മെഡിക്കൽ രേഖകൾ കണ്ടെത്താനായില്ല.',
      'language_settings': 'ഭാഷാ മുൻഗണനകൾ',
      'view_all': 'എല്ലാം കാണുക',
      // Role specific quick actions
      'doctor_dashboard': 'ഡോക്ടർ ഡാഷ്ബോർഡ്',
      'patient_records': 'രോഗി രേഖകൾ',
      'doctor_appointments': 'ഡോക്ടർ അപ്പോയിന്റ്മെന്റുകൾ',
      'pharmacy_dashboard': 'ഫാർമസി ഡാഷ്ബോർഡ്',
      'pharmacy_orders': 'ഫാർമസി ഓർഡറുകൾ',
      'inventory_management': 'ഇൻവെന്ററി മാനേജർ',
      'normal': 'സാധാരണ',
      'high': 'ഉയർന്ന',
      'low': 'കുറഞ്ഞ',
      'avg': 'ശരാശരി',
      'mg_dl': 'mg/dL',
      // Settings Screen
      'general': 'പൊതുവായ',
      'enable_push_notifications': 'പുഷ് അറിയിപ്പുകൾ പ്രവർത്തനക്ഷമമാക്കുക',
      'notifications': 'അറിയിപ്പുകൾ',
      'biometric_login': 'ബയോമെട്രിക് ലോഗിൻ',
      'use_fingerprint_faceid': 'ഫിംഗർപ്രിന്റ് അല്ലെങ്കിൽ ഫേസ് ID ഉപയോഗിക്കുക',
      'privacy_security': 'സ്വകാര്യതയും സുരക്ഷയും',
      'change_password': 'പാസ്‌വേഡ് മാറ്റുക',
      'update_account_password':
          'നിങ്ങളുടെ അക്കൗണ്ട് പാസ്‌വേഡ് അപ്ഡേറ്റ് ചെയ്യുക',
      'privacy_policy': 'സ്വകാര്യതാ നയം',
      'view_privacy_policy': 'ഞങ്ങളുടെ സ്വകാര്യതാ നയം കാണുക',
      'terms_conditions': 'നിബന്ധനകളും വ്യവസ്ഥകളും',
      'read_terms_conditions': 'നിബന്ധനകളും വ്യവസ്ഥകളും വായിക്കുക',
      'data_storage': 'ഡാറ്റയും സംഭരണവും',
      'backup_data': 'ഡാറ്റ ബാക്കപ്പ്',
      'backup_to_cloud': 'നിങ്ങളുടെ ഡാറ്റ ക്ലൗഡിലേക്ക് ബാക്കപ്പ് ചെയ്യുക',
      'clear_cache': 'കാഷെ മായ്ക്കുക',
      'clear_cache_temp': 'ആപ്പ് കാഷെയും താൽക്കാലിക ഫയലുകളും മായ്ക്കുക',
      'account': 'അക്കൗണ്ട്',
      'sign_out_account': 'നിങ്ങളുടെ അക്കൗണ്ടിൽ നിന്ന് സൈൻ ഔട്ട് ചെയ്യുക',
      'are_you_sure_logout': 'നിങ്ങൾക്ക് ലോഗ്‌ഔട്ട് ചെയ്യണമെന്ന് ഉറപ്പാണോ?',
      'cancel': 'റദ്ദാക്കുക',
      'clear': 'മായ്ക്കുക',
      'close': 'അടയ്ക്കുക',
      'save': 'സേവ്',
      'delete': 'ഇല്ലാതാക്കുക',
      'edit': 'എഡിറ്റ്',
      'update': 'അപ്ഡേറ്റ്',
      'confirm': 'സ്ഥിരീകരിക്കുക',
      'yes': 'അതെ',
      'no': 'ഇല്ല',
      // Navigation
      'users': 'ഉപയോക്താക്കൾ',
      'doctors': 'ഡോക്ടർമാർ',
      'pharmacies': 'ഫാർമസികൾ',
      'revenue': 'വരുമാനം',
      'orders': 'ഓർഡറുകൾ',
      'inventory': 'ഇൻവെന്ററി',
      'appointments': 'അപ്പോയിന്റ്‌മെന്റുകൾ',
      // Common messages
      'failed_to_update_favorite':
          'പ്രിയങ്കരം അപ്ഡേറ്റ് ചെയ്യുന്നതിൽ പരാജയപ്പെട്ടു',
      'cache_cleared_successfully': 'കാഷെ വിജയകരമായി മായ്ച്ചു',
      'failed_to_clear_cache': 'കാഷെ മായ്ക്കുന്നതിൽ പരാജയപ്പെട്ടു',
      'data_backed_up_successfully':
          'ഡാറ്റ വിജയകരമായി ക്ലൗഡിലേക്ക് ബാക്കപ്പ് ചെയ്തു',
      'backup_failed': 'ബാക്കപ്പ് പരാജയപ്പെട്ടു',
      'please_login_to_backup': 'ഡാറ്റ ബാക്കപ്പ് ചെയ്യാൻ ദയവായി ലോഗിൻ ചെയ്യുക',
      'biometric_login_enabled': 'ബയോമെട്രിക് ലോഗിൻ പ്രവർത്തനക്ഷമമാക്കി',
      'biometric_login_disabled': 'ബയോമെട്രിക് ലോഗിൻ പ്രവർത്തനരഹിതമാക്കി',
      'password_changed_successfully': 'പാസ്‌വേഡ് വിജയകരമായി മാറ്റി',
      'failed_to_change_password': 'പാസ്‌വേഡ് മാറ്റുന്നതിൽ പരാജയപ്പെട്ടു',
      'current_password_incorrect': 'നിലവിലെ പാസ്‌വേഡ് തെറ്റാണ്',
      'new_password_too_weak':
          'പുതിയ പാസ്‌വേഡ് വളരെ ദുർബലമാണ്. ദയവായി ശക്തമായ പാസ്‌വേഡ് ഉപയോഗിക്കുക',
      'please_login_again': 'പാസ്‌വേഡ് മാറ്റാൻ ദയവായി വീണ്ടും ലോഗിൻ ചെയ്യുക',
      'please_enter_current_password': 'ദയവായി നിലവിലെ പാസ്‌വേഡ് നൽകുക',
      'please_enter_new_password': 'ദയവായി പുതിയ പാസ്‌വേഡ് നൽകുക',
      'new_passwords_no_match': 'പുതിയ പാസ്‌വേഡുകൾ പൊരുത്തപ്പെടുന്നില്ല',
      'new_password_different':
          'പുതിയ പാസ്‌വേഡ് നിലവിലെ പാസ്‌വേഡിൽ നിന്ന് വ്യത്യസ്തമായിരിക്കണം',
      'are_you_sure_clear_cache':
          'നിങ്ങൾക്ക് എല്ലാ കാഷ് ചെയ്ത ഡാറ്റയും മായ്ക്കണമെന്ന് ഉറപ്പാണോ? ഇത് നിങ്ങളുടെ അക്കൗണ്ട് ഡാറ്റ ഇല്ലാതാക്കില്ല.',
      // Favorites
      'favourite_doctors': 'പ്രിയങ്കര ഡോക്ടർമാർ',
      'no_favourites_yet': 'ഇതുവരെ പ്രിയങ്കരങ്ങൾ ഇല്ല',
      // Calendar
      'calendar': 'കലണ്ടർ',
      'calendar_screen_coming_soon': 'കലണ്ടർ സ്ക്രീൻ\nഉടൻ വരുന്നു!',
      'chats': 'ചാറ്റുകൾ',
      'messages': 'സന്ദേശങ്ങൾ',
    },
    'hi': {
      'app_name': 'सुजेनिक्स',
      'home': 'होम',
      'glucose': 'ग्लूकोज',
      'records': 'रिकॉर्ड्स',
      'medicine': 'दवा',
      'profile': 'प्रोफ़ाइल',
      'login': 'लॉगिन',
      'signup': 'साइन अप',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'name': 'नाम',
      'welcome': 'स्वागत है',
      'logout': 'लॉग आउट',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'sign_in': 'साइन इन',
      'sign_in_title': 'साइन इन',
      'welcome_back': 'वापसी पर स्वागत है',
      'sign_in_to_continue': 'जारी रखने के लिए साइन इन करें',
      'signup_journey':
          'स्मार्ट मधुमेह देखभाल की आपकी यात्रा यहाँ शुरू होती है',
      're_enter_password': 'पासवर्ड फिर से दर्ज करें',
      'agree_terms': 'मैं नियम और शर्तों से सहमत हूं',
      'have_account': 'क्या आपके पास खाता है? ',
      'dont_have_account': 'खाता नहीं है? ',
      'forgot_password': 'पासवर्ड भूल गए?',
      'continue_as': 'इस रूप में जारी रखें',
      'patient_user': 'रोगी/उपयोगकर्ता',
      'doctor_diabetologist': 'डॉक्टर / मधुमेह विशेषज्ञ',
      'pharmacy': 'फार्मेसी',
      'fill_all_fields': 'कृपया सभी फ़ील्ड भरें',
      'passwords_no_match': 'पासवर्ड मेल नहीं खाते',
      'password_min_length': 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए',
      'signup_failed': 'साइन अप विफल',
      'account_pending':
          'आपका खाता व्यवस्थापक अनुमोदन के लिए लंबित है। लॉगिन करने से पहले कृपया अनुमोदन की प्रतीक्षा करें।',
      'agree_prefix': 'मैं ',
      'agree_suffix': ' से सहमत हूं',
      'terms_and_conditions_title': 'नियम और शर्तें',
      'terms_section_1_title': '1. शर्तों की स्वीकृति',
      'terms_section_1_content':
          'सुजेनिक्स का उपयोग करके, आप इन नियमों और शर्तों और सभी लागू कानूनों और विनियमों से बाध्य होने के लिए सहमत हैं।',
      'terms_section_2_title': '2. चिकित्सा अस्वीकरण',
      'terms_section_2_content':
          'सुजेनिक्स मधुमेह प्रबंधन के लिए एक उपकरण है और इसे पेशेवर चिकित्सा सलाह के विकल्प के रूप में उपयोग नहीं किया जाना चाहिए।',
      'terms_section_3_title': '3. उपयोगकर्ता गोपनीयता',
      'terms_section_3_content':
          'आपकी गोपनीयता हमारे लिए महत्वपूर्ण है। हमारी सेवा का उपयोग करके, आप हमारी नीति के अनुसार जानकारी के संग्रह और उपयोग से सहमत हैं।',
      'terms_section_4_title': '4. खाता जिम्मेदारियां',
      'terms_section_4_content':
          'आप अपने खाते और पासवर्ड की गोपनीयता बनाए रखने के लिए जिम्मेदार हैं।',
      'terms_section_5_title': '5. देयता की सीमा',
      'terms_section_5_content':
          'सुजेनिक्स और इसके निर्माता सेवा के उपयोग से होने वाले किसी भी नुकसान के लिए उत्तरदायी नहीं होंगे।',
      // Home Screen
      'welcome_back_comma': 'वापसी पर स्वागत है,',
      'current_glucose_level': 'वर्तमान ग्लूकोज स्तर',
      'no_glucose_readings': 'अभी तक कोई ग्लूकोज रीडिंग नहीं',
      'start_monitoring': 'अपने ग्लूकोज स्तरों की निगरानी शुरू करें',
      'quick_actions': 'त्वरित कार्य',
      'add_reading': 'रीडिंग जोड़ें',
      'view_history': 'इतिहास देखें',
      'ai_assistant': 'AI सहायक',
      'wellness': 'कल्याण',
      'emergency': 'आपातकाल',
      'dashboard': 'डैशबोर्ड',
      'live_doctors': 'लाइव डॉक्टर',
      'live': 'लाइव',
      'popular_doctors': 'लोकप्रिय डॉक्टर',
      'pediatric_specialists': 'बाल रोग विशेषज्ञ',
      'top_doctors': 'शीर्ष डॉक्टर',
      'my_appointments': 'मेरी अपॉइंटमेंट',
      // Patient dashboard
      'my_health_dashboard': 'मेरा स्वास्थ्य डैशबोर्ड',
      'seven_day_average': '7-दिवसीय औसत',
      'in_range_readings': 'सीमा में',
      'high_alerts': 'उच्च अलर्ट',
      'low_alerts': 'कम अलर्ट',
      'glucose_logs': 'ग्लूकोज लॉग',
      'book_doctor': 'डॉक्टर बुक करें',
      'medical_records_section': 'चिकित्सा रिकॉर्ड',
      'order_medicines': 'दवाएँ ऑर्डर करें',
      'emergency_sos_action': 'आपातकालीन SOS',
      'recent_glucose_readings': 'हालिया ग्लूकोज रीडिंग',
      'no_readings_message': 'अभी तक कोई रीडिंग नहीं। अपनी पहली रीडिंग जोड़ें।',
      'upcoming_appointments_section': 'आगामी अपॉइंटमेंट',
      'no_upcoming_appointments': 'कोई आगामी अपॉइंटमेंट नहीं।',
      'book_consultation_prompt': 'एक परामर्श बुक करें।',
      'recent_orders_section': 'हालिया दवा ऑर्डर',
      'no_recent_orders': 'अभी तक कोई ऑर्डर नहीं। ई-फार्मेसी स्टोर देखें।',
      'latest_medical_records': 'ताज़ा चिकित्सा रिकॉर्ड',
      'no_medical_records': 'कोई चिकित्सा रिकॉर्ड नहीं मिला।',
      'language_settings': 'भाषा वरीयताएँ',
      'view_all': 'सभी देखें',
      // Role specific quick actions
      'doctor_dashboard': 'डॉक्टर डैशबोर्ड',
      'patient_records': 'रोगी रिकॉर्ड',
      'doctor_appointments': 'डॉक्टर अपॉइंटमेंट',
      'pharmacy_dashboard': 'फार्मेसी डैशबोर्ड',
      'pharmacy_orders': 'फार्मेसी ऑर्डर',
      'inventory_management': 'इन्वेंटरी प्रबंधन',
      'normal': 'सामान्य',
      'high': 'उच्च',
      'low': 'कम',
      'avg': 'औसत',
      'mg_dl': 'mg/dL',
      // Settings Screen
      'general': 'सामान्य',
      'enable_push_notifications': 'पुश अधिसूचनाएं सक्षम करें',
      'notifications': 'अधिसूचनाएं',
      'biometric_login': 'बायोमेट्रिक लॉगिन',
      'use_fingerprint_faceid': 'फिंगरप्रिंट या फेस ID का उपयोग करें',
      'privacy_security': 'गोपनीयता और सुरक्षा',
      'change_password': 'पासवर्ड बदलें',
      'update_account_password': 'अपना खाता पासवर्ड अपडेट करें',
      'privacy_policy': 'गोपनीयता नीति',
      'view_privacy_policy': 'हमारी गोपनीयता नीति देखें',
      'terms_conditions': 'नियम और शर्तें',
      'read_terms_conditions': 'नियम और शर्तें पढ़ें',
      'data_storage': 'डेटा और भंडारण',
      'backup_data': 'डेटा बैकअप',
      'backup_to_cloud': 'अपना डेटा क्लाउड में बैकअप करें',
      'clear_cache': 'कैश साफ़ करें',
      'clear_cache_temp': 'ऐप कैश और अस्थायी फ़ाइलें साफ़ करें',
      'account': 'खाता',
      'sign_out_account': 'अपने खाते से साइन आउट करें',
      'are_you_sure_logout': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'clear': 'साफ़ करें',
      'close': 'बंद करें',
      'save': 'सहेजें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'update': 'अपडेट',
      'confirm': 'पुष्टि करें',
      'yes': 'हाँ',
      'no': 'नहीं',
      // Navigation
      'users': 'उपयोगकर्ता',
      'doctors': 'डॉक्टर',
      'pharmacies': 'फार्मेसी',
      'revenue': 'राजस्व',
      'orders': 'ऑर्डर',
      'inventory': 'इन्वेंटरी',
      'appointments': 'अपॉइंटमेंट',
      // Common messages
      'failed_to_update_favorite': 'पसंदीदा अपडेट करने में विफल',
      'cache_cleared_successfully': 'कैश सफलतापूर्वक साफ़ हो गया',
      'failed_to_clear_cache': 'कैश साफ़ करने में विफल',
      'data_backed_up_successfully': 'डेटा सफलतापूर्वक क्लाउड में बैकअप हो गया',
      'backup_failed': 'बैकअप विफल',
      'please_login_to_backup': 'डेटा बैकअप करने के लिए कृपया लॉगिन करें',
      'biometric_login_enabled': 'बायोमेट्रिक लॉगिन सक्षम',
      'biometric_login_disabled': 'बायोमेट्रिक लॉगिन अक्षम',
      'password_changed_successfully': 'पासवर्ड सफलतापूर्वक बदल गया',
      'failed_to_change_password': 'पासवर्ड बदलने में विफल',
      'current_password_incorrect': 'वर्तमान पासवर्ड गलत है',
      'new_password_too_weak':
          'नया पासवर्ड बहुत कमजोर है। कृपया एक मजबूत पासवर्ड का उपयोग करें',
      'please_login_again': 'पासवर्ड बदलने के लिए कृपया फिर से लॉगिन करें',
      'please_enter_current_password': 'कृपया वर्तमान पासवर्ड दर्ज करें',
      'please_enter_new_password': 'कृपया नया पासवर्ड दर्ज करें',
      'new_passwords_no_match': 'नए पासवर्ड मेल नहीं खाते',
      'new_password_different': 'नया पासवर्ड वर्तमान पासवर्ड से अलग होना चाहिए',
      'are_you_sure_clear_cache':
          'क्या आप वाकई सभी कैश किए गए डेटा को साफ़ करना चाहते हैं? यह आपका खाता डेटा हटाएगा नहीं।',
      // Favorites
      'favourite_doctors': 'पसंदीदा डॉक्टर',
      'no_favourites_yet': 'अभी तक कोई पसंदीदा नहीं',
      // Calendar
      'calendar': 'कैलेंडर',
      'calendar_screen_coming_soon': 'कैलेंडर स्क्रीन\nजल्द ही आ रहा है!',
      'chats': 'चैट',
      'messages': 'संदेश',
    },
  };

  static final List<Map<String, String>> _supportedLanguages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ml', 'name': 'മലയാളം', 'flag': '🇮🇳'},
    {'code': 'hi', 'name': 'हिंदी', 'flag': '🇮🇳'},
  ];

  static List<Map<String, String>> getSupportedLanguages() {
    return _supportedLanguages;
  }

  static String getLanguageName(String code) {
    final lang = _supportedLanguages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'code': code, 'name': code, 'flag': ''},
    );
    return lang['name'] ?? code;
  }

  static Future<String> getSelectedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? _defaultLanguage;
    } catch (e) {
      return _defaultLanguage;
    }
  }

  static Future<void> setSelectedLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      // Update cached language
      _currentLanguage = languageCode;
      // Notify listeners about language change - this will trigger rebuilds
      _languageController.add(languageCode);
    } catch (e) {
      // Handle error
    }
  }

  // Get current language code synchronously (for initial load)
  static String? _currentLanguage;

  // Initialize current language
  static Future<void> initialize() async {
    _currentLanguage = await getSelectedLanguage();
  }

  // Get current language (cached)
  static String getCurrentLanguage() {
    return _currentLanguage ?? _defaultLanguage;
  }

  // Dispose stream controller (call this when app closes)
  static void dispose() {
    _languageController.close();
  }

  static String translate(String key, String languageCode) {
    return _translations[languageCode]?[key] ??
        _translations[_defaultLanguage]?[key] ??
        key;
  }

  static Future<String> getTranslated(String key) async {
    final languageCode = await getSelectedLanguage();
    return translate(key, languageCode);
  }

  // Get translated text stream that updates when language changes
  static Stream<String> getTranslatedStream(String key) {
    return languageStream.map((_) async {
      final lang = await getSelectedLanguage();
      return translate(key, lang);
    }).asyncMap((future) => future);
  }
}
