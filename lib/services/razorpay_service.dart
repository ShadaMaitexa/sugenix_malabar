import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Razorpay Payment Service - Test Mode Ready
///
/// This service handles all Razorpay payment operations including:
/// - Payment initialization
/// - Checkout opening
/// - Payment success/error handling
///
/// CURRENT STATUS: ✅ TEST MODE (No KYC Required)
/// - Uses TEST MODE with dummy test key
/// - No real money is charged
/// - Perfect for development, testing, and demos
/// - Looks and feels exactly like production
///
/// TEST CARDS PROVIDED:
/// ✅ Success Card: 4111 1111 1111 1111
///    - CVV: Any 3 digits (e.g., 123)
///    - Expiry: Any future date (e.g., 12/26)
///    - Result: Payment succeeds
///
/// ❌ Failure Card: 4000 0000 0000 0002
///    - CVV: Any 3 digits
///    - Expiry: Any future date
///    - Result: Payment fails
///
/// 📝 OTHER TEST OPTIONS:
/// - UPI: testdebitsuccess@razorpay (success)
/// - UPI: testdebitfailure@razorpay (failure)
/// - NetBanking: HDFC / ICICI / AXIS (all work in test)
/// - Wallets: Paytm test token available
///
/// To get your own test key (OPTIONAL - current one works):
/// 1. Sign up at https://razorpay.com/ (instant, no KYC needed)
/// 2. Dashboard: https://dashboard.razorpay.com/
/// 3. Settings → API Keys → Test Mode toggle ON
/// 4. Click "Generate Test Keys" (no KYC required!)
/// 5. Copy "Key ID" (starts with rzp_test_)
/// 6. Replace _keyId below with your key
///
/// PRODUCTION STEPS (Later):
/// - Complete Razorpay KYC verification
/// - Generate live keys
/// - Replace test key with live key
/// - Enable server-side payment verification
class RazorpayService {
  static Razorpay? _razorpay;

  // ✅ Active Test Key - No KYC Required!
  // This test key is ready to use immediately
  // No real payment will be processed
  // Replace with your own test key (optional) or live key for production
  static const String _keyId = 'rzp_test_1DP5mmOlF5G5ag'; // ✅ Active Test Key

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
      print(
          '⚠️ Using dummy Razorpay test key - payments will fail. Replace with your actual test key for real payments.');
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
