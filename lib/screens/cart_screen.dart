import 'package:flutter/material.dart';
import 'package:sugenix/services/medicine_cart_service.dart';
import 'package:sugenix/services/razorpay_service.dart';
import 'package:sugenix/services/auth_service.dart';
import 'package:sugenix/services/platform_settings_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _showSuccessAnimation = false;

  final MedicineCartService _cartService = MedicineCartService();
  final AuthService _authService = AuthService();
  final PlatformSettingsService _platformSettings = PlatformSettingsService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedPaymentMethod = 'COD'; // 'COD' or 'Razorpay'
  bool _processingPayment = false;
  Map<String, dynamic>? _userProfile;
  double _cartSubtotal = 0.0;
  double _platformFee = 0.0;
  double _cartTotal = 0.0;
  bool _isGuest = false;
  int _refreshKey = 0;
  double _lastCalculatedSubtotal =
      -1.0; // Track last calculated subtotal to avoid unnecessary recalculations

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _initializeRazorpay();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    RazorpayService.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      // User is logged in
      setState(() {
        _isGuest = false;
      });
      await _loadUserProfile();
    } else {
      // Guest user
      setState(() {
        _isGuest = true;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();
    setState(() {
      _userProfile = profile;
      if (profile != null) {
        _nameController.text = profile['name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
      }
    });
  }

  void _initializeRazorpay() {
    RazorpayService.initialize(
      onSuccessCallback: _handlePaymentSuccess,
      onErrorCallback: _handlePaymentError,
      onExternalWalletCallback: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(dynamic response) {
    setState(() {
      _processingPayment = false;
    });

    // Complete the order with payment details
    _completeOrder(
      paymentMethod: 'Razorpay',
      paymentId: response.paymentId,
      orderId: response.orderId,
    );
  }

  void _handlePaymentError(dynamic response) {
    setState(() {
      _processingPayment = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(dynamic response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
        ),
      );
    }
  }

  Future<void> _completeOrder({
    required String paymentMethod,
    String? paymentId,
    String? orderId,
  }) async {
    try {
      final address = _addressController.text.trim();

      // For COD, only check address if it's empty
      if (paymentMethod == 'COD' && address.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter delivery address')),
          );
        }
        return;
      }

      // Get customer details
      final name = _isGuest
          ? _nameController.text.trim()
          : (_userProfile?['name'] ?? 'User');
      final email = _isGuest
          ? _emailController.text.trim()
          : (_userProfile?['email'] ?? _authService.currentUser?.email ?? '');
      final phone = _isGuest
          ? _phoneController.text.trim()
          : (_userProfile?['phone'] ?? '');

      // For COD, if user is logged in, use profile data (don't require form filling)
      // Only validate if guest or if fields are actually empty
      if (paymentMethod == 'COD') {
        // For COD, use defaults if empty and user is logged in
        final finalName =
            name.isNotEmpty ? name : (_userProfile?['name'] ?? 'User');
        final finalEmail = email.isNotEmpty
            ? email
            : (_userProfile?['email'] ??
                _authService.currentUser?.email ??
                'user@sugenix.com');
        final finalPhone =
            phone.isNotEmpty ? phone : (_userProfile?['phone'] ?? '0000000000');

        await _cartService.checkout(
          address: address.isNotEmpty
              ? address
              : (_userProfile?['address'] ?? 'Address not specified'),
          customerName: finalName,
          customerEmail: finalEmail,
          customerPhone: finalPhone,
          paymentMethod: paymentMethod,
          paymentId: paymentId,
          razorpayOrderId: orderId,
        );

        if (!mounted) return;

        // Show success animation for COD
        setState(() {
          _showSuccessAnimation = true;
        });

        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        setState(() {
          _showSuccessAnimation = false;
        });

        Navigator.pop(context);
        return;
      }

      // For online payment, validate all fields
      if (name.isEmpty || email.isEmpty || phone.isEmpty || address.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please fill in all required details')),
          );
        }
        return;
      }

      final finalOrderId = await _cartService.checkout(
        address: address,
        customerName: name,
        customerEmail: email,
        customerPhone: phone,
        paymentMethod: paymentMethod,
        paymentId: paymentId,
        razorpayOrderId: orderId,
      );

      if (!mounted) return;

      // For COD, show success animation
      if (paymentMethod == 'COD') {
        setState(() {
          _showSuccessAnimation = true;
        });

        // Wait for animation
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        setState(() {
          _showSuccessAnimation = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Order placed successfully! Order ID: #$finalOrderId'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _showSuccessAnimation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateCartTotals(double subtotal) async {
    // Only recalculate if subtotal has changed
    if (subtotal == _lastCalculatedSubtotal && _cartTotal > 0) {
      return;
    }

    _lastCalculatedSubtotal = subtotal;

    try {
      final feeCalc = await _platformSettings.calculatePlatformFee(subtotal);
      if (mounted) {
        setState(() {
          _cartSubtotal = subtotal;
          _platformFee = feeCalc['platformFee'] ?? 0.0;
          _cartTotal = feeCalc['totalAmount'] ?? subtotal;
        });
      }
    } catch (e) {
      // Fallback if calculation fails
      if (mounted) {
        setState(() {
          _cartSubtotal = subtotal;
          _platformFee = 0.0;
          _cartTotal = subtotal;
        });
      }
    }
  }

  Future<void> _processPayment(double amount) async {
    // Get customer details (from profile if logged in, or from form if guest)
    final name = _isGuest
        ? _nameController.text.trim()
        : (_userProfile?['name'] ?? 'User');
    final email = _isGuest
        ? _emailController.text.trim()
        : (_userProfile?['email'] ??
            _authService.currentUser?.email ??
            'user@sugenix.com');
    final phone = _isGuest
        ? _phoneController.text.trim()
        : (_userProfile?['phone'] ?? '0000000000');

    // Validate details before opening checkout
    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all details before payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _processingPayment = true;
    });

    try {
      await RazorpayService.openCheckout(
        amount: amount,
        name: name,
        email: email,
        phone: phone,
        description: 'Medicine Order Payment - Sugenix',
        notes: {
          'isGuest': _isGuest,
          'customerName': name,
        },
      );
      // Success/Error handled by callbacks
    } catch (e) {
      setState(() {
        _processingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C4556),
        actions: [
          TextButton(
            onPressed: () async {
              await _cartService.clearCart();
              setState(() {
                _refreshKey++;
                _lastCalculatedSubtotal = -1.0;
              });
            },
            child:
                const Text('Clear', style: TextStyle(color: Color(0xFF0C4556))),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey(_refreshKey),
                  future: _cartService.getCartItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      // Reset totals when cart is empty
                      if (_cartTotal != 0.0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _cartSubtotal = 0.0;
                              _platformFee = 0.0;
                              _cartTotal = 0.0;
                              _lastCalculatedSubtotal = -1.0;
                            });
                          }
                        });
                      }
                      return const Center(
                        child: Text('Your cart is empty',
                            style: TextStyle(color: Colors.grey)),
                      );
                    }
                    double subtotal = 0.0;
                    for (final i in items) {
                      final price = (i['price'] as num?)?.toDouble() ?? 0.0;
                      final qty = (i['quantity'] as int?) ?? 1;
                      subtotal += price * qty;
                    }

                    // Calculate platform fee and total (only if subtotal changed)
                    if (subtotal != _lastCalculatedSubtotal) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _calculateCartTotals(subtotal);
                      });
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isGuest) ...[
                                  const Text('Customer Details',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'Full Name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      hintText: 'Email Address',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.email),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      hintText: 'Phone Number',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.phone),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                const Text('Delivery Address',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter delivery address',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_on),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                const Text('Payment Method',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Cash on Delivery'),
                                        value: 'COD',
                                        groupValue: _selectedPaymentMethod,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedPaymentMethod = value!;
                                          });
                                        },
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Online Payment'),
                                        value: 'Razorpay',
                                        groupValue: _selectedPaymentMethod,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedPaymentMethod = value!;
                                          });
                                        },
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 12),
                                // Price breakdown
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey)),
                                    Text(
                                      '₹${_cartSubtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Platform Fee',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey)),
                                    Text(
                                      '₹${_platformFee.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Amount',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text('₹${_cartTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0C4556))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        final item = items[index];
                        final name = (item['name'] as String?) ?? '';
                        final manufacturer =
                            (item['manufacturer'] as String?) ?? '';
                        final price =
                            (item['price'] as num?)?.toDouble() ?? 0.0;
                        final qty = (item['quantity'] as int?) ?? 1;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.medication,
                                color: Color(0xFF0C4556)),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0C4556))),
                            subtitle: Text(
                              (manufacturer.isNotEmpty
                                      ? manufacturer
                                      : 'Medicine') +
                                  ' • ₹' +
                                  price.toStringAsFixed(2),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: SizedBox(
                              width: 140,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    onPressed: () async {
                                      await _cartService.updateQuantity(
                                          item['id'] as String, qty - 1);
                                      setState(() {
                                        _refreshKey++;
                                        _lastCalculatedSubtotal = -1.0;
                                      });
                                    },
                                  ),
                                  Text(qty.toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () async {
                                      await _cartService.updateQuantity(
                                          item['id'] as String, qty + 1);
                                      setState(() {
                                        _refreshKey++;
                                        _lastCalculatedSubtotal = -1.0;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            dense: true,
                            minVerticalPadding: 8,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            subtitleTextStyle:
                                const TextStyle(color: Colors.grey),
                            onTap: () {},
                            isThreeLine: false,
                            // Show price under the title line
                            // Using trailing area for qty; include price in subtitle
                            // Already referenced via 'price' variable
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C4556),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _processingPayment || _showSuccessAnimation
                          ? null
                          : () async {
                              // Check if form is already filled
                              final address = _addressController.text.trim();
                              final name = _isGuest
                                  ? _nameController.text.trim()
                                  : (_userProfile?['name'] ?? 'User');
                              final email = _isGuest
                                  ? _emailController.text.trim()
                                  : (_userProfile?['email'] ??
                                      _authService.currentUser?.email ??
                                      '');
                              final phone = _isGuest
                                  ? _phoneController.text.trim()
                                  : (_userProfile?['phone'] ?? '');

                              // For COD, if form is already filled, proceed directly
                              if (_selectedPaymentMethod == 'COD') {
                                if (address.isNotEmpty &&
                                    name.isNotEmpty &&
                                    email.isNotEmpty &&
                                    phone.isNotEmpty) {
                                  // Form is already filled, proceed with order
                                  await _completeOrder(paymentMethod: 'COD');
                                } else {
                                  // Show error to fill form
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please fill in all details before placing order'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                // Process Razorpay payment
                                await _processPayment(_cartTotal);
                              }
                            },
                      child: _processingPayment
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _selectedPaymentMethod == 'Razorpay'
                                  ? 'Pay Now'
                                  : 'Place Order (COD)',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Success animation overlay
          if (_showSuccessAnimation)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Order placed successfully',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C4556),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your order has been placed successfully.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6F8),
    );
  }
}
