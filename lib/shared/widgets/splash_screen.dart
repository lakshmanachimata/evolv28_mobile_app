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
      
      if (isLoggedIn) {
        // User is logged in, fetch latest user details first
        final userDetails = await _fetchLatestUserDetails(authRepository);
        
        // Fetch all music for the user and check navigation based on music data
        if (userDetails != null) {
          final hasMusicData = await _fetchAllMusic(userDetails.data.userId ?? userDetails.data.id);
          
          // Always go to dashboard screen where permission dialogs are implemented
          context.go(AppRoutes.dashboard);
        } else {
          // If user details fetch fails, go to dashboard screen
          context.go(AppRoutes.dashboard);
        }
      } else {
        // User not logged in, go to login screen
        context.go(AppRoutes.login);
      }
    } catch (e) {
      // On error, default to login screen
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  Future<dynamic> _fetchLatestUserDetails(AuthRepository authRepository) async {
    try {
      
      // Get stored user data to get user ID
      final storedUserData = await authRepository.getStoredUserData();
      
      final userIdString = storedUserData['userId'];
      
      if (userIdString != null && userIdString.isNotEmpty) {
        final userId = int.tryParse(userIdString);
        if (userId != null) {
          
          // Get GetUserDetailsUseCase from dependency injection
          final getUserDetailsUseCase = sl<GetUserDetailsUseCase>();
          
          // Fetch latest user details
          final result = await getUserDetailsUseCase(userId);
          
          return result.fold(
            (error) {
              // Return null if fetch fails
              return null;
            },
            (userDetails) {
              // Update stored user data with latest information
              _updateStoredUserData(userDetails);
              // Return the user details
              return userDetails;
            },
          );
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      // Return null if fetch fails
      return null;
    }
  }

  Future<bool> _fetchAllMusic(String? userIdString) async {
    try {
      if (userIdString == null || userIdString.isEmpty) {
        return false;
      }

      final userId = int.tryParse(userIdString);
      if (userId == null) {
        return false;
      }

      
      // Get GetAllMusicUseCase from dependency injection
      final getAllMusicUseCase = sl<GetAllMusicUseCase>();
      
      // Fetch all music
      final result = await getAllMusicUseCase(userId);
      
      return result.fold(
        (error) {
          return false;
        },
        (musicData) {
          
          // Check if the data array is non-empty
          if (musicData is Map<String, dynamic> && musicData.containsKey('data')) {
            final data = musicData['data'];
            if (data is List && data.isNotEmpty) {
              return true;
            } else {
              return false;
            }
          } else {
            return false;
          }
        },
      );
    } catch (e) {
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
        
      }
    } catch (e) {
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
