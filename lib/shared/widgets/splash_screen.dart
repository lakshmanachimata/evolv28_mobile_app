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
import '../../core/services/session_service.dart';

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
              
              // Save music data to SharedPreferences and update session ID
              _handleMusicDataSuccess(data, userId);
              
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

  // Handle successful music data fetch
  void _handleMusicDataSuccess(List<dynamic> musicData, int userId) {
    // Save music data to SharedPreferences
    _saveMusicDataToPrefs(musicData);
    
    // Update session ID after successfully fetching music data
    _updateSessionId(userId);
  }

  // Save music data to SharedPreferences
  Future<void> _saveMusicDataToPrefs(List<dynamic> musicData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final musicDataString = jsonEncode(musicData);
      await prefs.setString('user_music_data', musicDataString);
      print('🚀 SplashScreen: Saved ${musicData.length} music items to SharedPreferences');
    } catch (e) {
      print('🚀 SplashScreen: Error saving music data to SharedPreferences: $e');
    }
  }

  // Update session ID after fetching music data
  Future<void> _updateSessionId(int userId) async {
    try {
      print('🚀 SplashScreen: Updating session ID for user: $userId');
      
      final sessionService = SessionService();
      final newSessionId = await sessionService.updateSessionId(userId);
      
      if (newSessionId != null) {
        print('🚀 SplashScreen: Session ID updated successfully: $newSessionId');
      } else {
        print('🚀 SplashScreen: Failed to update session ID');
      }
    } catch (e) {
      print('🚀 SplashScreen: Error updating session ID: $e');
    }
  }

  Future<void> _updateStoredUserData(dynamic userDetails) async {
    try {
      // Import SharedPreferences to update stored data
      final prefs = await SharedPreferences.getInstance();
      
      // Update user data with latest information from API
      if (userDetails.data != null) {
        final userData = userDetails.data;
        
        print('🚀 SplashScreen: Updating stored user data with latest information');
        print('🚀 SplashScreen: First Name: ${userData.fname}');
        print('🚀 SplashScreen: Last Name: ${userData.lname}');
        print('🚀 SplashScreen: Email: ${userData.emailId ?? userData.emailid}');
        print('🚀 SplashScreen: Token: ${userData.token ?? userData.tokenid}');
        print('🚀 SplashScreen: User ID: ${userData.userId ?? userData.id}');
        
        // Always save essential fields (username, email, token) consistently
        if (userData.fname != null && userData.fname!.isNotEmpty) {
          await prefs.setString('user_first_name', userData.fname!);
          print('🚀 SplashScreen: First name saved: ${userData.fname}');
        }
        
        if (userData.lname != null && userData.lname!.isNotEmpty) {
          await prefs.setString('user_last_name', userData.lname!);
          print('🚀 SplashScreen: Last name saved: ${userData.lname}');
        }
        
        // Handle different email field names
        final email = userData.emailId ?? userData.emailid;
        if (email != null && email.isNotEmpty) {
          await prefs.setString('user_email_id', email);
          print('🚀 SplashScreen: Email saved: $email');
        }
        
        // Handle different user ID field names
        final userId = userData.userId ?? userData.id;
        if (userId != null && userId.toString().isNotEmpty) {
          await prefs.setString('user_id', userId.toString());
          print('🚀 SplashScreen: User ID saved: $userId');
        }
        
        // Handle different token field names
        final token = userData.token ?? userData.tokenid;
        if (token != null && token.isNotEmpty) {
          await prefs.setString('user_token', token);
          print('🚀 SplashScreen: Token saved: $token');
        }
        
        // Update additional fields if available
        if (userData.logId != null && userData.logId!.isNotEmpty) {
          await prefs.setString('user_log_id', userData.logId!);
        }
        
        if (userData.gender != null && userData.gender!.isNotEmpty) {
          await prefs.setString('user_gender', userData.gender!);
        }
        
        if (userData.country != null && userData.country!.isNotEmpty) {
          await prefs.setString('user_country', userData.country!);
        }
        
        if (userData.age != null && userData.age!.isNotEmpty) {
          await prefs.setString('user_age', userData.age!);
        }
        
        if (userData.imagePath != null && userData.imagePath!.isNotEmpty) {
          await prefs.setString('user_image_path', userData.imagePath!);
        }
        
        if (userData.profilepicpath != null && userData.profilepicpath!.isNotEmpty) {
          await prefs.setString('user_profile_pic_path', userData.profilepicpath!);
        }
        
        // Update devices count
        final devicesCount = userData.devices?.length ?? 0;
        await prefs.setInt('user_devices_count', devicesCount);
        print('🚀 SplashScreen: Devices count saved: $devicesCount');
        
        // Update complete user data JSON
        await prefs.setString('user_data', jsonEncode(userDetails.toJson()));
        print('🚀 SplashScreen: Complete user data JSON saved');
        
        // Verify what was actually stored
        final storedToken = prefs.getString('user_token');
        final storedUserId = prefs.getString('user_id');
        final storedEmail = prefs.getString('user_email_id');
        final storedFirstName = prefs.getString('user_first_name');
        final storedLastName = prefs.getString('user_last_name');
        
        print('🚀 SplashScreen: User data updated successfully');
        print('🚀 SplashScreen: Verified stored token: "$storedToken"');
        print('🚀 SplashScreen: Verified stored userId: "$storedUserId"');
        print('🚀 SplashScreen: Verified stored email: "$storedEmail"');
        print('🚀 SplashScreen: Verified stored first name: "$storedFirstName"');
        print('🚀 SplashScreen: Verified stored last name: "$storedLastName"');
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
