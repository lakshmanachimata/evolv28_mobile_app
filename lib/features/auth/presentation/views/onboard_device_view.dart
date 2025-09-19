import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/app_router_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

class OnboardDeviceView extends StatefulWidget {
  const OnboardDeviceView({super.key});

  @override
  State<OnboardDeviceView> createState() => _OnboardDeviceViewState();
}

class _OnboardDeviceViewState extends State<OnboardDeviceView> {
  bool _showOtpScreen = false;
  bool _showDeviceActivatedDialog = false;
  bool _isVerifyingOtp = false;
  late TextEditingController _otpController;
  late FocusNode _otpFocusNode;
  late ScrollController _scrollController;
  final GlobalKey _textFieldKey = GlobalKey();
  late VerifyOtpUseCase _verifyOtpUseCase;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController(text: 'ABC1234567');
    _otpFocusNode = FocusNode();
    _scrollController = ScrollController();
    _verifyOtpUseCase = sl<VerifyOtpUseCase>();

    // Clear text when focused
    _otpFocusNode.addListener(() {
      if (_otpFocusNode.hasFocus && _otpController.text == 'ABC1234567') {
        _otpController.clear();
      }
    });

    // No automatic scrolling - let the user manually scroll if needed
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Validate if the OTP is exactly 10 characters and alphanumeric
  bool _isValidOtp(String otp) {
    if (otp.length != 10) return false;
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(otp);
  }

  // Get user email from SharedPreferences
  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email_id') ?? '';
  }

  // Verify OTP with the API
  Future<void> _verifyOtp() async {
    // Hide keyboard when button is clicked
    FocusScope.of(context).unfocus();
    
    final otp = _otpController.text.trim();
    
    // Validate OTP format
    if (!_isValidOtp(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-character alphanumeric code'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      // Get user email
      final email = await _getUserEmail();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user email found. Please login again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      print('🔐 OnboardDeviceView: Verifying OTP for email: $email');
      
      // Call the verify OTP API
      final result = await _verifyOtpUseCase(email, otp);
      
      result.fold(
        (error) {
          // Error occurred
          print('🔐 OnboardDeviceView: OTP verification failed: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid OTP. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        (success) {
          // Success
          print('🔐 OnboardDeviceView: OTP verification successful');
          
          // Show device activated success dialog
          _showDeviceActivatedSuccessDialog();
        },
      );
    } catch (e) {
      print('🔐 OnboardDeviceView: OTP verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isVerifyingOtp = false;
      });
    }
  }

  void _showDeviceActivatedSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'Device Activated',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      context.go(AppRoutes.devices); // Navigate to devices view
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFF17961,
                      ), // Coral/light orange
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent automatic scrolling when keyboard appears
      body: GestureDetector(
        onTap: () {
          // Hide keyboard when tapping outside input fields
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // Background Image
            Image.asset(
              'assets/images/term-background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // Header Section with evolv28 logo
            SafeArea(
              child: Column(children: [_buildHeader(context), const Spacer()]),
            ),

            // Main overlay with rounded top corners
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/modal-background.png'),
                    fit: BoxFit.cover,
                    opacity: 0.9,
                  ),
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height * 0.75 -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          48,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Conditional Content (Connect Device or OTP)
                        _showOtpScreen
                            ? _buildOtpVerificationContent(context)
                            : _buildConnectDeviceContent(context),

                        const SizedBox(height: 24),

                        // Add extra space for keyboard
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom + 50,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          // evolv28 Logo
          Expanded(
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.25,
                child: Image.asset(
                  'assets/images/evolv_text.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectDeviceContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        Text(
          'Connect Device',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 48),

        // Device Image
        SizedBox(
          width: 160,
          height: 160,
          child: Center(
            child: Image.asset(
              'assets/images/user_neck_device.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Action Buttons
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Connect Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Show OTP verification screen
              setState(() {
                _showOtpScreen = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF17961), // Coral/light orange
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Connect Evolv28',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Buy Now Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Handle buy now action
              print('Buy now tapped');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF547D81), // Teal/blue-green
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Buy now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Instruction Text
        Text(
          'Enter the 10 Digits code sent on your registered Email Id',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // OTP Input Field
        Container(
          key: _textFieldKey,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          // padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            maxLength: 10,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: _otpFocusNode.hasFocus ? '' : 'Enter alphanumeric code',
              hintStyle: const TextStyle(color: Colors.grey),
              counterText: '', // Hide character counter
            ),
            onChanged: (value) {
              // Handle OTP input changes
              print('OTP entered: $value');
            },
          ),
        ),

        const SizedBox(height: 16),

        // // Resend OTP Link
        // GestureDetector(
        //   onTap: () {
        //     print('Resend OTP tapped');
        //   },
        //   child: Text(
        //     'Resend OTP',
        //     style: TextStyle(
        //       fontSize: 14,
        //       color: Colors.white,
        //       fontWeight: FontWeight.bold,
        //     ),
        //   ),
        // ),

        // const SizedBox(height: 32),

        // Connect Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          height: 40,
          child: ElevatedButton(
            onPressed: _isVerifyingOtp ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isVerifyingOtp 
                  ? Colors.grey 
                  : const Color(0xFFF17961), // Coral/light orange
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isVerifyingOtp
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Validating code...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Connect Evolv28 First Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 32),

        // Contact Support
        GestureDetector(
          onTap: () {
            print('Contact Support tapped');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.headset_mic, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Contact Support Team',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
