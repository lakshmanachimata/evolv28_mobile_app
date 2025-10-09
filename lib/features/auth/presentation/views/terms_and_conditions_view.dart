import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/terms_and_conditions_viewmodel.dart';

class TermsAndConditionsView extends StatefulWidget {
  const TermsAndConditionsView({super.key});

  @override
  State<TermsAndConditionsView> createState() => _TermsAndConditionsViewState();
}

class _TermsAndConditionsViewState extends State<TermsAndConditionsView> {
  // Checkbox states
  bool _privacyPolicyAccepted = false;
  bool _termsAndConditionsAccepted = false;

  @override
  void initState() {
    super.initState();
    // Show bottom sheet automatically when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTermsBottomSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => sl<TermsAndConditionsViewModel>(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/term-background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header with logo and decorative elements
                _buildHeader(),

                // Main content area - just the shield icon and title
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Shield icon
                        _buildShieldIcon(),
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom sheet trigger
                _buildBottomSheetTrigger(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 120,
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

  Widget _buildShieldIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: SvgPicture.asset(
        'assets/images/terms_icon.svg',
        width: 60,
        height: 60,
        color: Colors.black, // Black by default
      ),
    );
  }

  Widget _buildBottomSheetTrigger(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {
          print('DEBUG: Button pressed - opening bottom sheet');
          _showTermsBottomSheet(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0E0E0), // Gray background
          foregroundColor: Colors.white, // White text
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'View Terms and Conditions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showTermsBottomSheet(BuildContext context) {
    print('DEBUG: Opening bottom sheet automatically');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent dismissing by swiping
      enableDrag: false, // Disable drag to dismiss
      builder: (context) {
        print('DEBUG: Building terms bottom sheet');
        return _buildTermsBottomSheet();
      },
    );
  }

  Widget _buildTermsBottomSheet() {
    print('DEBUG: Building bottom sheet widget');
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.66,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [


              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Shield icon with checkmark
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: SvgPicture.asset(
                        'assets/images/terms_icon.svg',
                        width: 60,
                        height: 60,
                        color: Colors.black, // Black outline
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  const Center(
                    child: Text(
                      'Terms and Conditions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Terms text
                  const Text(
                    'These terms govern the rights and responses to your use of the evolv28 device, the evolv28 website and application (current and / or future versions), and related content, material and / or services, including any support services received from evolv28 and create a legally binding agreement between both the parties.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Policy links
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _launchUrl(
                          'https://www.evolv28.com/privacy-policy/',
                        ),
                        child: const Text(
                          'Read our Privacy Policy',
                          style: TextStyle(
                            color: Color(0xFF20B2AA),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _launchUrl(
                          'https://www.evolv28.com/terms-conditions/',
                        ),
                        child: const Text(
                          'Read our Terms and Conditions',
                          style: TextStyle(
                            color: Color(0xFF20B2AA),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Checkboxes
                  Column(
                    children: [
                      _buildCheckboxRow(
                        'Agree to our Privacy Policy',
                        _privacyPolicyAccepted,
                        () {
                          setModalState(() {
                            _privacyPolicyAccepted = !_privacyPolicyAccepted;
                          });
                          print('Privacy Policy checkbox: $_privacyPolicyAccepted');
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildCheckboxRow(
                        'Agree to Terms and Conditions',
                        _termsAndConditionsAccepted,
                        () {
                          setModalState(() {
                            _termsAndConditionsAccepted = !_termsAndConditionsAccepted;
                          });
                          print('Terms and Conditions checkbox: $_termsAndConditionsAccepted');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Next button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_privacyPolicyAccepted && _termsAndConditionsAccepted)
                          ? () {
                              print('DEBUG: Next button pressed - both terms accepted');
                              Navigator.of(context).pop();
                              context.go(AppRoutes.onboarding);
                            }
                          : null, // Disabled when not both checked
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_privacyPolicyAccepted && _termsAndConditionsAccepted)
                            ? const Color(0xFFF17961) // Orange-red background when enabled
                            : const Color(0xFFE0E0E0), // Gray background when disabled
                        foregroundColor: Colors.white, // White text always
                        disabledForegroundColor: Colors.white, // Force white text when disabled
                        disabledBackgroundColor: const Color(0xFFE0E0E0), // Gray background when disabled
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // Force white text color
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildCheckboxRow(String text, bool isChecked, VoidCallback onTap) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFF4CAF50) : Colors.transparent,
              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  void _handleNext(BuildContext context) {
    // Handle navigation to next screen after accepting terms
    print('Terms and Conditions accepted, proceeding to next screen');

    // Close the bottom sheet first
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms and Conditions accepted successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to onboarding screen to complete user registration
    // This is the typical flow when a new user accepts terms
    context.go(AppRoutes.onboarding);
  }
}
