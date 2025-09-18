import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/validate_otp_usecase.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginViewModel(
        loginUseCase: context.read<LoginUseCase>(),
        sendOtpUseCase: context.read<SendOtpUseCase>(),
        validateOtpUseCase: context.read<ValidateOtpUseCase>(),
      ),
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
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;

  @override
  void initState() {
    super.initState();
    // Initialize OTP controllers and focus nodes
    _otpControllers = List.generate(4, (index) => TextEditingController());
    _otpFocusNodes = List.generate(4, (index) => FocusNode());
    
    // Hide keyboard when login screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background PNG
          Image.asset(
            'assets/images/login-background.png',
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),

          // Login content
          SafeArea(
            child: GestureDetector(
              onTap: () {
                // Hide keyboard when tapping outside input fields
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        48,
                  ),
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

                      const SizedBox(height: 40),

                      // Conditional Card (Login or OTP)
                      _showOtpCard
                          ? Column(
                              children: [
                                _buildOtpCard(),
                                const SizedBox(height: 24),
                                _buildTermsAndConditionsCheckbox(context),
                              ],
                            )
                          : _buildLoginCard(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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
        // Check if email field has been touched and has validation error
        final hasError = viewModel.email.isNotEmpty && !viewModel.isEmailValid;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextFormField(
            initialValue: 'lakshman.chimata@gmail.com',
            onChanged: viewModel.setEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'john@doe.com',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              errorText: hasError ? 'Please enter a valid email address' : null,
              errorStyle: const TextStyle(fontSize: 12),
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
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
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
        return Opacity(
          opacity: viewModel.isEmailValid ? 1.0 : 0.6,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
            onPressed: viewModel.isLoading
                ? null
                : () async {
                    // Validate email before proceeding
                    final emailError = viewModel.validateEmail();
                    if (emailError != null) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(emailError),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    // Show full-screen loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return _buildFullScreenLoader('Sending OTP...');
                      },
                    );

                    try {
                      // Call the OTP API
                      final otpResponse = await viewModel.sendOtp();
                      
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        
                        if (otpResponse != null) {
                          // Success - show OTP card
                          print('📧 LoginView: OTP sent successfully: ${otpResponse.data.otp}');
                          setState(() {
                            _showOtpCard = true;
                          });
                        } else {
                          // Error - show error message
                          final errorMessage = viewModel.errorMessage ?? 'Failed to send OTP';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('An error occurred: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF17961), // Always burnt orange color
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
                    'Continue with email id',
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

                  // // Password field
                  // _buildPasswordField(context),
                  // const SizedBox(height: 24),

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
                'Enter the OTP sent to your email id',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.normal,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 24),

              // Email field
              Consumer<LoginViewModel>(
                builder: (context, viewModel, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextFormField(
                      initialValue: viewModel.email.isNotEmpty ? viewModel.email : 'john@doe.com',
                      readOnly: true,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) =>
                      _buildOtpField(index, _otpControllers, _otpFocusNodes),
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
          if (value.isNotEmpty && index < 3) {
            focusNodes[index + 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildTermsAndConditionsCheckbox(BuildContext context) {
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
                    viewModel.setTermsAndConditions(
                      !viewModel.termsAndConditions,
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: viewModel.termsAndConditions
                          ? const Color(0xFFF17961)
                          : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFFF17961),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: viewModel.termsAndConditions
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I agree to the Terms and conditions & Privacy policy',
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

  void _handleOtpContinue(BuildContext context) async {
    // Get OTP from the input fields
    final otpControllers = _getOtpControllers();
    final otp = otpControllers.map((controller) => controller.text).join();
    
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a complete 4-digit OTP'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show full-screen loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildFullScreenLoader('Validating OTP...');
      },
    );

    try {
      // Call the OTP validation API
      final viewModel = Provider.of<LoginViewModel>(context, listen: false);
      final otpValidationResponse = await viewModel.validateOtp(otp);
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (otpValidationResponse != null) {
          // Success - OTP validated
          print('🔐 LoginView: OTP validated successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate to onboarding screen
          context.go(AppRoutes.onboarding);
        } else {
          // Error - show error message
          final errorMessage = viewModel.errorMessage ?? 'Failed to validate OTP';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper method to get OTP controllers
  List<TextEditingController> _getOtpControllers() {
    return _otpControllers;
  }

  // Full-screen loading overlay
  Widget _buildFullScreenLoader(String message) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF17961)),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
