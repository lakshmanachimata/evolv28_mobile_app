import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_router_config.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_user_details_usecase.dart';
import '../../features/auth/domain/usecases/get_all_music_usecase.dart';
import '../../core/di/injection_container.dart';

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
        // User is logged in, fetch latest user details first
        print('🚀 SplashScreen: Fetching latest user details...');
        final userDetails = await _fetchLatestUserDetails(authRepository);
        
        // Fetch all music for the user
        if (userDetails != null) {
          print('🚀 SplashScreen: Fetching all music for user...');
          await _fetchAllMusic(userDetails.data.userId ?? userDetails.data.id);
        }
        
        // Use the same navigation logic as LoginView
        final navigationRoute = await _getNavigationRoute(authRepository);
        print('🚀 SplashScreen: Navigation route determined: $navigationRoute');
        
        if (navigationRoute == 'dashboard') {
          print('🚀 SplashScreen: Navigating to dashboard');
          context.go(AppRoutes.dashboard);
        } else if (navigationRoute == 'onboardDevice') {
          print('🚀 SplashScreen: Navigating to onboard device');
          context.go(AppRoutes.onboardDevice);
        } else {
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

  // Get navigation route using the same logic as LoginViewModel
  Future<String> _getNavigationRoute(AuthRepository authRepository) async {
    try {
      final hasCompleteProfile = await authRepository.hasCompleteProfile();
      final hasBasicProfileButNoDevices = await authRepository.hasBasicProfileButNoDevices();
      
      print('🚀 SplashScreen: Profile check - Complete: $hasCompleteProfile, Basic but no devices: $hasBasicProfileButNoDevices');
      
      if (hasCompleteProfile) {
        print('🚀 SplashScreen: User has complete profile - navigating to dashboard');
        return 'dashboard';
      } else if (hasBasicProfileButNoDevices) {
        print('🚀 SplashScreen: User has basic profile but no devices - navigating to onboard device');
        return 'onboardDevice';
      } else {
        print('🚀 SplashScreen: User has incomplete profile - navigating to onboarding');
        return 'onboarding';
      }
    } catch (e) {
      print('🚀 SplashScreen: Error checking profile: $e');
      return 'onboarding'; // Default to onboarding if there's an error
    }
  }

  Future<dynamic> _fetchLatestUserDetails(AuthRepository authRepository) async {
    try {
      print('🚀 SplashScreen: Starting to fetch latest user details...');
      
      // Get stored user data to get user ID
      final storedUserData = await authRepository.getStoredUserData();
      print('🚀 SplashScreen: Stored user data: $storedUserData');
      
      final userIdString = storedUserData['userId'];
      print('🚀 SplashScreen: User ID string: $userIdString');
      
      if (userIdString != null && userIdString.isNotEmpty) {
        final userId = int.tryParse(userIdString);
        if (userId != null) {
          print('🚀 SplashScreen: Fetching latest user details for userId: $userId');
          
          // Get GetUserDetailsUseCase from dependency injection
          final getUserDetailsUseCase = sl<GetUserDetailsUseCase>();
          
          // Fetch latest user details
          final result = await getUserDetailsUseCase(userId);
          
          return result.fold(
            (error) {
              print('🚀 SplashScreen: Failed to fetch user details: $error');
              // Return null if fetch fails
              return null;
            },
            (userDetails) {
              print('🚀 SplashScreen: Successfully fetched latest user details');
              // Update stored user data with latest information
              _updateStoredUserData(userDetails);
              // Return the user details
              return userDetails;
            },
          );
        } else {
          print('🚀 SplashScreen: Invalid user ID format: $userIdString');
          return null;
        }
      } else {
        print('🚀 SplashScreen: No user ID found in stored data');
        return null;
      }
    } catch (e) {
      print('🚀 SplashScreen: Error fetching user details: $e');
      // Return null if fetch fails
      return null;
    }
  }

  Future<bool> _fetchAllMusic(String? userIdString) async {
    try {
      if (userIdString == null || userIdString.isEmpty) {
        print('🚀 SplashScreen: No user ID provided for fetching all music');
        return false;
      }

      final userId = int.tryParse(userIdString);
      if (userId == null) {
        print('🚀 SplashScreen: Invalid user ID format for fetching all music: $userIdString');
        return false;
      }

      print('🚀 SplashScreen: Fetching all music for userId: $userId');
      
      // Get GetAllMusicUseCase from dependency injection
      final getAllMusicUseCase = sl<GetAllMusicUseCase>();
      
      // Fetch all music
      final result = await getAllMusicUseCase(userId);
      
      return result.fold(
        (error) {
          print('🚀 SplashScreen: Failed to fetch all music: $error');
          return false;
        },
        (musicData) {
          print('🚀 SplashScreen: Successfully fetched all music');
          print('🚀 SplashScreen: All music response: $musicData');
          
          // Check if the data array is non-empty
          if (musicData is Map<String, dynamic> && musicData.containsKey('data')) {
            final data = musicData['data'];
            if (data is List && data.isNotEmpty) {
              print('🚀 SplashScreen: User has ${data.length} music items');
              return true;
            } else {
              print('🚀 SplashScreen: User has no music items (empty data array)');
              return false;
            }
          } else {
            print('🚀 SplashScreen: Invalid music data format');
            return false;
          }
        },
      );
    } catch (e) {
      print('🚀 SplashScreen: Error fetching all music: $e');
      return false;
    }
  }

  Future<void> _updateStoredUserData(dynamic userDetails) async {
    try {
      // Import SharedPreferences to update stored data
      final prefs = await SharedPreferences.getInstance();
      
      // Update user data with latest information from API
      if (userDetails.data != null) {
        final userData = userDetails.data;
        
        // Update individual fields
        if (userData.fname != null) {
          await prefs.setString('user_first_name', userData.fname!);
        }
        if (userData.lname != null) {
          await prefs.setString('user_last_name', userData.lname!);
        }
        if (userData.emailId != null) {
          await prefs.setString('user_email_id', userData.emailId!);
        }
        if (userData.userId != null) {
          await prefs.setString('user_id', userData.userId!);
        }
        if (userData.token != null) {
          await prefs.setString('user_token', userData.token!);
        }
        
        // Update additional fields from the API response
        if (userData.id != null) {
          await prefs.setString('user_id', userData.id!);
        }
        if (userData.tokenid != null) {
          await prefs.setString('user_token', userData.tokenid!);
        }
        if (userData.emailid != null) {
          await prefs.setString('user_email_id', userData.emailid!);
        }
        
        // Update devices count
        final devicesCount = userData.devices?.length ?? 0;
        await prefs.setInt('user_devices_count', devicesCount);
        
        // Update complete user data JSON
        await prefs.setString('user_data', jsonEncode(userDetails.toJson()));
        
        print('🚀 SplashScreen: Updated stored user data with latest information');
      }
    } catch (e) {
      print('🚀 SplashScreen: Error updating stored user data: $e');
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
