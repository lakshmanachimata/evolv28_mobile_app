import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = OnboardingViewModel();
        // Refresh email data when view is created
        WidgetsBinding.instance.addPostFrameCallback((_) {
          viewModel.refreshEmailData();
          viewModel.addTextListeners();
        });
        return viewModel;
      },
      child: const _OnboardingViewBody(),
    );
  }
}

class _OnboardingViewBody extends StatelessWidget {
  const _OnboardingViewBody();

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
            // Background PNG
            Image.asset(
              'assets/images/login-background.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // Header Section with evolv28 logo
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildHeader(context),
              ),
            ),

            // Main form content - starts at 35% from top
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: 24,
              right: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileSetupForm(context),
                    const SizedBox(height: 24),
                    _buildContinueButton(context),
                  ],
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

  Widget _buildProfileSetupForm(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Perfect! Now let\'s set up your profile.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle
            Text(
              'What should we call you?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 24),

            // Email Field (uneditable)
            Text(
              'EMAIL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextFormField(
                enabled: false,
                controller: TextEditingController(text: viewModel.userEmail.isNotEmpty ? viewModel.userEmail : 'john@doe.com'),
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'john@doe.com',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // First Name Field
            Text(
              'FIRST NAME*',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextFormField(
                controller: viewModel.firstNameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Jane',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Last Name Field
            Text(
              'LAST NAME*',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextFormField(
                controller: viewModel.lastNameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Doe',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, viewModel, child) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: viewModel.isFormValid ? () async {
              // Save user profile data before navigating
              final success = await viewModel.saveUserProfile();
              if (success) {
                // Determine navigation route based on devices
                final navigationRoute = await viewModel.getNavigationRouteAfterProfileSave();
                
                if (navigationRoute == 'dashboard') {
                  print('🔐 OnboardingView: Navigating to dashboard');
                  context.go(AppRoutes.dashboard);
                } else {
                  print('🔐 OnboardingView: Navigating to onboard device');
                  context.go(AppRoutes.onboardDevice);
                }
              } else {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to save profile. Please try again.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: viewModel.isFormValid 
                  ? const Color(0xFFF17961) // Orange-red when enabled
                  : Colors.grey, // Gray when disabled
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white, // White text even when disabled
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyPolicyCard(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Shield icon with checkmark
        Center(
          child: SizedBox(
            width: 64,
            height: 64,
            child: SvgPicture.asset(
              'assets/images/terms_icon.svg',
              width: 40,
              height: 40,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Main title
        Text(
          'Lorem ipsum dolor sit amet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card content section
              Text(
                'Lorem ipsum dolor sit amet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),

              const SizedBox(height: 12),

              // Body text
              Text(
                'Lorem ipsum dolor sit amet consectetur. Ornare ullamcorper non orci cursus massa ante adipiscing.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Privacy Policy link
              GestureDetector(
                onTap: viewModel.handlePrivacyPolicyLinkTap,
                child: Text(
                  'Read our Privacy Policy',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Agree checkbox
              GestureDetector(
                onTap: viewModel.togglePrivacyPolicyAgreement,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF547D81), // Light orange/peach
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: viewModel.agreedToPrivacyPolicy
                              ? Colors.white
                              : Colors.transparent,
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: viewModel.agreedToPrivacyPolicy
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Color(0xFFF07A60),
                              )
                            : null,
                      ),

                      const SizedBox(width: 12),

                      // Text
                      Expanded(
                        child: Text(
                          'Agree to our Privacy Policy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Next Button
        _buildNextButton(context),
      ],
    );
  }

  Widget _buildProfileSetupCard(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Perfect! Now let\'s set up your profile.',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle
        Text(
          'What should we call you?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        // First Name Field
        Text(
          'FIRST NAME',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: TextFormField(
            controller: viewModel.firstNameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Jane',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Last Name Field
        Text(
          'LAST NAME',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: TextFormField(
            controller: viewModel.lastNameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Doe',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Next Button
        _buildNextButton(context),
      ],
    );
  }

  Widget _buildConnectBottom(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
      child: Column(
        children: [
          // Connect Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: viewModel.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF17961),
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
          const SizedBox(height: 32),
          // Buy Now Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: viewModel.handleBuyNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF547D81), // Teal/green
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
      ),
    );
  }

  Widget _buildConnectDeviceCard(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Top content
        Column(
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
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(color: Colors.transparent),
              child: Image.asset(
                'assets/images/user_neck_device.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpVerificationCard(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Instruction Text
        Center(
          child: Text(
            'Enter the 10 Digits code sent on your registered Email / Mobile number',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // OTP Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent),
          ),
          child: TextFormField(
            controller: viewModel.otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintStyle: TextStyle(color: Colors.black),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0.0,
              ),
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Resend OTP Link
        GestureDetector(
          onTap: viewModel.handleResendOtp,
          child: Text(
            'Resend OTP',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 72),

        // Connect Button
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: () {
              context.go(AppRoutes.devices);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF17961),
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
          onTap: viewModel.handleContactSupport,
          child: SizedBox(
            width: double.infinity,
            height: 24,
            child: SvgPicture.asset(
              'assets/images/support_text.svg',
              fit: BoxFit.fitHeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: viewModel.canProceedFromCurrentStep()
                  ? () async {
                      if (viewModel.currentStep == 1) {
                        // Save user profile data before navigating
                        final success = await viewModel.saveUserProfile();
                        if (success) {
                          // Determine navigation route based on devices
                          final navigationRoute = await viewModel.getNavigationRouteAfterProfileSave();
                          
                          if (navigationRoute == 'dashboard') {
                            print('🔐 OnboardingView: Navigating to dashboard');
                            context.go(AppRoutes.dashboard);
                          } else {
                            print('🔐 OnboardingView: Navigating to onboard device');
                            context.go(AppRoutes.onboardDevice);
                          }
                        } else {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save profile. Please try again.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } else if (viewModel.isLastStep) {
                        context.go('/home');
                      } else {
                        viewModel.nextStep();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF07A60), // Light orange/peach
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                viewModel.nextButtonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeviceActivatedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 280,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF07A60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 30),
                ),

                const SizedBox(height: 16),

                // Success Message
                const Text(
                  'Device Successfully Activated',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // OK Button
                SizedBox(
                  width: 120,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to home or next screen
                      context.go(AppRoutes.home);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF07A60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
}
