import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_router_config.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );
  }

  void _startSplashSequence() async {
    _animationController.forward();

    // Wait for splash animation to complete
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      await _checkAuthenticationAndNavigate();
    }
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    try {
      // Get AuthRepository from context
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      
      // Check if user is logged in (has valid token and user ID)
      final isLoggedIn = await authRepository.isLoggedIn();
      print('🚀 SplashScreen: User logged in: $isLoggedIn');
      
      if (isLoggedIn) {
        // User is logged in, check profile state
        final hasCompleteProfile = await authRepository.hasCompleteProfile();
        final hasBasicProfileButNoDevices = await authRepository.hasBasicProfileButNoDevices();
        
        print('🚀 SplashScreen: Profile check - Complete: $hasCompleteProfile, Basic but no devices: $hasBasicProfileButNoDevices');
        
        if (hasCompleteProfile) {
          // User has complete profile (fname, lname, and devices), go to dashboard
          print('🚀 SplashScreen: Navigating to dashboard');
          context.go(AppRoutes.dashboard);
        } else if (hasBasicProfileButNoDevices) {
          // User has basic profile (fname, lname) but no devices, go to onboarding for device setup
          print('🚀 SplashScreen: Navigating to onboarding for device setup');
          context.go(AppRoutes.onboarding);
        } else {
          // User is logged in but profile incomplete, go to onboarding
          print('🚀 SplashScreen: Navigating to onboarding');
          context.go(AppRoutes.onboarding);
        }
      } else {
        // User not logged in, go to login screen
        print('🚀 SplashScreen: Navigating to login');
        context.go(AppRoutes.login);
      }
    } catch (e) {
      print('🚀 SplashScreen: Error checking authentication: $e');
      // On error, default to login screen
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash-background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Main content - Evolv28 logo in the center
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: Image.asset(
                        'assets/images/evolv_text.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
