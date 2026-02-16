import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Razorpay Payment Service
/// 
/// This service handles all Razorpay payment operations including:
/// - Payment initialization
/// - Checkout opening
/// - Payment success/error handling
/// 
/// Current Configuration:
/// - Uses TEST MODE (dummy credentials)
/// - No real money is charged
/// - Suitable for development and testing
/// 
/// To use your own test keys:
/// 1. Sign up at https://razorpay.com/ (free, no KYC for test mode)
/// 2. Get test keys from https://dashboard.razorpay.com/app/keys
/// 3. Replace _keyId below with your test key
/// 
/// For production:
/// - Complete Razorpay KYC verification
/// - Generate live keys
/// - Replace test key with live key
/// - Implement server-side payment verification
class RazorpayService {
  static Razorpay? _razorpay;
  
  // Razorpay Test Key for testing (NO KYC REQUIRED)
  // 
  // ✅ IMPORTANT: Test keys DON'T require KYC verification!
  // You can get test keys immediately after signing up at Razorpay
  // 
  // Steps to get your test key (FREE, no KYC needed):
  // 1. Sign up at https://razorpay.com/ (FREE account, no credit card needed)
  // 2. Log in to dashboard: https://dashboard.razorpay.com/
  // 3. Go to Settings → API Keys
  // 4. Make sure you're in "Test Mode" (toggle at top right)
  // 5. Click "Generate Test Keys" if you don't have them
  // 6. Copy the "Key ID" (starts with rzp_test_)
  // 7. Replace the value below with your test key
  // 
  // Test Cards (for testing payments):
  // - Success: 4111 1111 1111 1111 (any CVV, any future expiry date)
  // - Failure: 4000 0000 0000 0002
  // - No real money is charged in test mode
  // 
  // Current value is a placeholder - replace with your test key from Razorpay dashboard
  // Format: rzp_test_XXXXXXXXXXXXXXXX
  // 
  // ⚠️ IMPORTANT: This is a dummy key for testing the UI flow only.
  // For actual payments to work, you need a real Razorpay test key.
  // 
  // HOW TO BYPASS KYC AND GET TEST KEYS:
  // 1. Sign up at https://razorpay.com/
  // 2. When it asks for KYC, look for a "Skip" or "Do it later" link (usually at bottom)
  // 3. OR go directly to: https://dashboard.razorpay.com/app/keys
  // 4. Look for "Test Mode" toggle (top right corner) - make sure it's ON
  // 5. Click "Generate Test Key" - this works WITHOUT KYC
  // 6. Copy the Key ID (starts with rzp_test_)
  // 
  // If KYC popup appears, try:
  // - Click outside the popup or "X" to close it
  // - Use browser back button
  // - Go directly to: https://dashboard.razorpay.com/app/keys (bypasses main dashboard)
  // 
  // This dummy key allows the app to run without crashing, but payments will fail.
  // Replace with your actual test key for payments to work.
  static const String _keyId = 'rzp_test_1DP5mmOlF5G5ag'; // Dummy test key - Replace with your actual key for payments to work
  
  // Callbacks for payment events
  static Function(PaymentSuccessResponse)? onSuccess;
  static Function(PaymentFailureResponse)? onError;
  static Function(ExternalWalletResponse)? onExternalWallet;

  /// Initialize Razorpay with callbacks
  static void initialize({
    Function(PaymentSuccessResponse)? onSuccessCallback,
    Function(PaymentFailureResponse)? onErrorCallback,
    Function(ExternalWalletResponse)? onExternalWalletCallback,
  }) {
    onSuccess = onSuccessCallback;
    onError = onErrorCallback;
    onExternalWallet = onExternalWalletCallback;
    
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Open Razorpay checkout
  static Future<void> openCheckout({
    required double amount,
    required String name,
    required String email,
    required String phone,
    String? description,
    Map<String, dynamic>? notes,
  }) async {
    if (_razorpay == null) {
      initialize();
    }

    // Validate Razorpay key exists
    if (_keyId.isEmpty) {
      throw Exception(
          'Payment service not configured. Please configure Razorpay API key.');
    }

    // Validate key format
    if (!_keyId.startsWith('rzp_test_') && !_keyId.startsWith('rzp_live_')) {
      throw Exception(
          'Invalid Razorpay key format. Key should start with "rzp_test_" or "rzp_live_"');
    }
    
    // Warn if using dummy key (but allow it to proceed for UI testing)
    if (_keyId == 'rzp_test_1DP5mmOlF5G5ag') {
      print('⚠️ Using dummy Razorpay test key - payments will fail. Replace with your actual test key for real payments.');
    }

    // Validate inputs
    if (amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      throw Exception('Name, email, and phone are required');
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Invalid email format');
    }

    // Validate phone (should be at least 10 digits for Indian numbers)
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 10) {
      throw Exception('Phone number must be at least 10 digits');
    }

    final options = {
      'key': _keyId,
      'amount': (amount * 100).toInt(), // Amount in paise (multiply by 100)
      'name': 'Sugenix',
      'description': description ?? 'Medicine Order Payment',
      'prefill': {
        'contact': cleanPhone,
        'email': email,
        'name': name,
      },
      'external': {
        'wallets': ['paytm'], // Optional: Enable specific wallets
      },
      'theme': {
        'color': '#0C4556', // Your app's primary color
      },
      'method': {
        'netbanking': true,
        'card': true,
        'upi': true,
        'wallet': true,
      },
      if (notes != null) 'notes': notes,
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      print('Razorpay Error: $e');
      rethrow; // Re-throw to let caller handle
    }
  }

  /// Handle payment success
  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Payment Success: ${response.paymentId}');
    if (onSuccess != null) {
      onSuccess!(response);
    }
  }

  /// Handle payment error
  static void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    print('Payment Error Details: ${response.error}');
    if (onError != null) {
      onError!(response);
    }
  }

  /// Handle external wallet
  static void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  /// Dispose Razorpay
  static void dispose() {
    if (_razorpay != null) {
      _razorpay!.clear();
      _razorpay = null;
    }
    onSuccess = null;
    onError = null;
    onExternalWallet = null;
  }
}
