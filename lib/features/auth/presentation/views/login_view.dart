import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../../domain/usecases/login_usecase.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          LoginViewModel(loginUseCase: context.read<LoginUseCase>()),
      child: const _LoginViewBody(),
    );
  }
}

class _LoginViewBody extends StatefulWidget {
  const _LoginViewBody();

  @override
  State<_LoginViewBody> createState() => _LoginViewBodyState();
}

class _LoginViewBodyState extends State<_LoginViewBody> {
  bool _showOtpCard = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background PNG
          Image.asset(
            'assets/images/bg_one.png',
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),

          // Login content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // Evolv28 Logo at top
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Image.asset(
                      'assets/images/evolv_text.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Conditional Card (Login or OTP)
                  Expanded(
                    child: _showOtpCard
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [_buildOtpCard()],
                          )
                        : Column(children: [const Spacer(), _buildLoginCard()]),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            onChanged: viewModel.setEmail,
            decoration: InputDecoration(
              hintText: 'john@doe.com',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            onChanged: viewModel.setPassword,
            obscureText: !viewModel.isPasswordVisible,
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  viewModel.isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey.shade600,
                ),
                onPressed: viewModel.togglePasswordVisibility,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: viewModel.isLoading
                ? null
                : () async {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      },
                    );

                    // Wait for 2 seconds then show OTP card
                    Future.delayed(const Duration(seconds: 1), () {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        setState(() {
                          _showOtpCard = true;
                        });
                      }
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF17961), // Burnt orange color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: viewModel.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildOrSeparator() {
    return Row(
      children: [
        Flexible(child: Container(height: 1, color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(child: Container(height: 1, color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildSocialLoginButtons(BuildContext context) {
    return Column(
      children: [
        // Facebook Login
        _buildSocialButton(
          text: 'Sign in with Facebook',
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
          svgAsset: 'assets/images/fb_login.svg',
          onPressed: () => _handleFacebookLogin(context),
        ),
        const SizedBox(height: 12),

        // Google Login (Android) or Apple Login (iOS)
        if (Platform.isAndroid)
          _buildSocialButton(
            text: 'Sign in with Google',
            backgroundColor: Colors.white,
            textColor: Colors.black,
            svgAsset: 'assets/images/google_login.svg',
            onPressed: () => _handleGoogleLogin(context),
            border: Border.all(color: Colors.grey.shade300),
          )
        else
          _buildSocialButton(
            text: 'Sign in with Apple',
            backgroundColor: Colors.black,
            textColor: Colors.white,
            svgAsset: 'assets/images/apple_login.svg',
            onPressed: () => _handleAppleLogin(context),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required String svgAsset,
    required VoidCallback onPressed,
    Border? border,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: border?.top,
        ),
        child: SvgPicture.asset(svgAsset, height: 40, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildTransactionalAlertsCheckbox(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    viewModel.setTransactionalAlerts(
                      !viewModel.transactionalAlerts,
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: viewModel.transactionalAlerts
                          ? const Color(0xFFF07A60)
                          : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFFF07A60),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: viewModel.transactionalAlerts
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receive transactional alerts via SMS, Email, WhatsApp',
                    style: TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleFacebookLogin(BuildContext context) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
    );

    // Simulate Facebook login process
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Simulate successful login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facebook login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen
        context.go(AppRoutes.home);
      }
    });
  }

  void _handleGoogleLogin(BuildContext context) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
    );

    // Simulate Google login process
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Simulate successful login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen
        context.go(AppRoutes.home);
      }
    });
  }

  void _handleAppleLogin(BuildContext context) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
    );

    // Simulate Apple login process
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Simulate successful login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen
        context.go(AppRoutes.home);
      }
    });
  }

  Widget _buildLoginCard() {
    return Column(
      children: [
        // Login Card
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.5),
                  ],
                  stops: const [0.4, 0.5],
                ),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Continue with',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.normal,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email field
                  _buildEmailField(context),
                  const SizedBox(height: 16),

                  // Password field
                  _buildPasswordField(context),
                  const SizedBox(height: 24),

                  // Continue button
                  _buildContinueButton(context),
                  const SizedBox(height: 24),

                  // OR separator
                  _buildOrSeparator(),
                  const SizedBox(height: 24),

                  // Social login buttons
                  _buildSocialLoginButtons(context),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Transactional alerts checkbox
        _buildTransactionalAlertsCheckbox(context),
      ],
    );
  }

  Widget _buildOtpCard() {
    final List<TextEditingController> _otpControllers = List.generate(
      6,
      (index) => TextEditingController(),
    );
    final List<FocusNode> _focusNodes = List.generate(
      6,
      (index) => FocusNode(),
    );

    // Pre-fill with sample OTP: 105948
    _otpControllers[0].text = '1';
    _otpControllers[1].text = '0';
    _otpControllers[2].text = '5';
    _otpControllers[3].text = '9';
    _otpControllers[4].text = '4';
    _otpControllers[5].text = '8';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.4),
                Colors.white.withValues(alpha: 0.5),
              ],
              stops: const [0.4, 0.5],
            ),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                offset: const Offset(0, 4),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Enter the OTP sent to your mobile\nnumber',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.normal,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 24),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) =>
                      _buildOtpField(index, _otpControllers, _focusNodes),
                ),
              ),
              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleOtpContinue(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF17961),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(
    int index,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          8,
        ), // Subtle rounded corners as in image
        border: Border.all(
          color: Color(0xFFE8E8E8),
          width: 1,
        ), // Thin border as shown
      ),
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          }
        },
      ),
    );
  }

  void _handleOtpContinue(BuildContext context) {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
    );

    // Simulate OTP verification process
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Simulate successful OTP verification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen
        context.go(AppRoutes.home);
      }
    });
  }
}
