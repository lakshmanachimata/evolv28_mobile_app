import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';

class OnboardDeviceView extends StatefulWidget {
  const OnboardDeviceView({super.key});

  @override
  State<OnboardDeviceView> createState() => _OnboardDeviceViewState();
}

class _OnboardDeviceViewState extends State<OnboardDeviceView> {
  bool _showOtpScreen = false;
  bool _showDeviceActivatedDialog = false;
  late TextEditingController _otpController;
  late FocusNode _otpFocusNode;
  late ScrollController _scrollController;
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController(text: 'ABC1234567');
    _otpFocusNode = FocusNode();
    _scrollController = ScrollController();
    
    // Listen to focus changes to scroll to text field
    _otpFocusNode.addListener(() {
      if (_otpFocusNode.hasFocus) {
        // Delay to ensure keyboard is shown
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_scrollController.hasClients) {
            // Scroll to the bottom to show the text field
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
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
                        _showOtpScreen ? _buildOtpVerificationContent(context) : _buildConnectDeviceContent(context),

                        const SizedBox(height: 24),
                        
                        // Add extra space for keyboard
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 50),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              hintText: 'Enter alphanumeric code',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onChanged: (value) {
              // Handle OTP input changes
              print('OTP entered: $value');
            },
          ),
        ),

        const SizedBox(height: 8),

        // Resend OTP Link
        GestureDetector(
          onTap: () {
            print('Resend OTP tapped');
          },
          child: Text(
            'Resend OTP',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Connect Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Show device activated success dialog
              _showDeviceActivatedSuccessDialog();
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
