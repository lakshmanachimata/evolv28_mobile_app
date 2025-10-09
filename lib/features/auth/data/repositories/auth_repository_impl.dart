import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/create_profile_request.dart';
import '../../domain/entities/create_profile_response.dart';
import '../../domain/entities/otp_response.dart';
import '../../domain/entities/otp_validation_response.dart';
import '../../domain/entities/social_login_request.dart';
import '../../domain/entities/social_login_response.dart';
import '../../domain/entities/terms_required_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SharedPreferences sharedPreferences;
  final Dio _dio = Dio();

  AuthRepositoryImpl({required this.sharedPreferences});

  @override
  Future<Either<String, AuthResult>> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock login logic - in real app, this would be an API call
      if (email == 'test@example.com' && password == 'password') {
        final user = User(id: '1', email: email, name: 'Test User');

        final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

        // Always save user data consistently (username, email, token)
        await _saveUserDataConsistently(
          token: token,
          userId: '1',
          firstName: 'Test',
          lastName: 'User',
          email: email,
          userName: 'Test User',
        );

        // Also save legacy fields if remember me is checked
        if (rememberMe) {
          await sharedPreferences.setString('auth_token', token);
          await sharedPreferences.setString('user_email_id', email);
        }

        return Right(AuthResult(user: user, token: token));
      } else {
        return const Left('Invalid email or password');
      }
    } catch (e) {
      return Left('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, OtpResponse>> sendOtp(String email) async {
    try {
      print('📧 AuthRepository: Sending OTP request for email: $email');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.sendOtp}',
        data: {'email_id': email},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('📧 AuthRepository: OTP API response: ${response.data}');

      if (response.statusCode == 200) {
        final otpResponse = OtpResponse.fromJson(response.data);

        if (!otpResponse.error) {
          print(
            '📧 AuthRepository: OTP sent successfully: ${otpResponse.data.otp}',
          );
          return Right(otpResponse);
        } else {
          print(
            '📧 AuthRepository: OTP API returned error: ${otpResponse.message}',
          );
          return Left(otpResponse.message);
        }
      } else {
        print(
          '📧 AuthRepository: OTP API failed with status: ${response.statusCode}',
        );
        return Left('Failed to send OTP. Please try again.');
      }
    } catch (e) {
      print('📧 AuthRepository: OTP API error: $e');
      if (e is DioException) {
        if (e.response != null) {
          // Server responded with error status
          final errorMessage =
              e.response?.data?['message'] ??
              'Failed to send OTP. Please try again.';
          return Left(errorMessage);
        } else {
          // Network error
          return Left(
            'Network error. Please check your connection and try again.',
          );
        }
      }
      return Left('Failed to send OTP. Please try again.');
    }
  }

  @override
  Future<Either<String, bool>> verifyOtp(String email, String otp) async {
    try {
      print('🔐 AuthRepository: Verifying OTP for email: $email');

      // Get stored token for authorization
      final token = sharedPreferences.getString('user_token') ?? '';

      if (token.isEmpty) {
        print('🔐 AuthRepository: No token found for OTP verification');
        return const Left('No authentication token found. Please login again.');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.verifyOtp}',
        data: {'email': email, 'otp': otp.toUpperCase()},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': token,
          },
        ),
      );

      print(
        '🔐 AuthRepository: Verify OTP API response: ${response.statusCode}',
      );
      print('🔐 AuthRepository: Verify OTP API data: ${response.data}');

      if (response.statusCode == 200) {
        // Check if the response indicates success
        final responseData = response.data;
        print(
          '🔐 AuthRepository: Response data type: ${responseData.runtimeType}',
        );
        print('🔐 AuthRepository: Response data: $responseData');

        if (responseData is Map<String, dynamic>) {
          // Check the 'error' field - if error is false, it's success
          final hasError =
              responseData['error'] ??
              true; // Default to true (error) if field is missing
          print('🔐 AuthRepository: Has error: $hasError');

          if (!hasError) {
            print('🔐 AuthRepository: OTP verification successful');
            return const Right(true);
          } else {
            final errorMessage =
                responseData['message'] ?? 'OTP verification failed';
            print('🔐 AuthRepository: OTP verification failed: $errorMessage');
            return Left(errorMessage);
          }
        } else if (responseData is String) {
          // Try to parse JSON string
          try {
            final Map<String, dynamic> parsedData = jsonDecode(responseData);
            final hasError = parsedData['error'] ?? true;

            if (!hasError) {
              print('🔐 AuthRepository: OTP verification successful');
              return const Right(true);
            } else {
              final errorMessage =
                  parsedData['message'] ?? 'OTP verification failed';
              print(
                '🔐 AuthRepository: OTP verification failed: $errorMessage',
              );
              return Left(errorMessage);
            }
          } catch (e) {
            print('🔐 AuthRepository: Failed to parse JSON string: $e');
            return const Left('Invalid response format from server');
          }
        } else {
          // If response is not a map or string, assume error for safety
          print(
            '🔐 AuthRepository: OTP verification failed - invalid response format',
          );
          return const Left('Invalid response format from server');
        }
      } else {
        print(
          '🔐 AuthRepository: Verify OTP API failed with status: ${response.statusCode}',
        );
        return Left('Failed to verify OTP. Please try again.');
      }
    } catch (e) {
      print('🔐 AuthRepository: Verify OTP API error: $e');
      if (e is DioException) {
        if (e.response != null) {
          // Server responded with error status
          final errorMessage =
              e.response?.data?['message'] ??
              'Failed to verify OTP. Please try again.';
          return Left(errorMessage);
        } else {
          // Network error
          return Left(
            'Network error. Please check your connection and try again.',
          );
        }
      }
      return Left('Failed to verify OTP. Please try again.');
    }
  }

  @override
  Future<Either<String, OtpValidationResponse>> getUserDetails(
    int userId,
  ) async {
    try {
      print('🔐 AuthRepository: Getting user details for userId: $userId');

      // Get stored token for authorization
      final token = sharedPreferences.getString('user_token') ?? '';

      if (token.isEmpty) {
        print('🔐 AuthRepository: No token found for user details request');
        return const Left('No authentication token found. Please login again.');
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.userDetails}/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': token,
          },
        ),
      );

      print(
        '🔐 AuthRepository: Get user details API response: ${response.statusCode}',
      );
      print('🔐 AuthRepository: Get user details API data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print(
          '🔐 AuthRepository: Response data type: ${responseData.runtimeType}',
        );
        print('🔐 AuthRepository: Response data: $responseData');

        if (responseData is Map<String, dynamic>) {
          // Check the 'error' field - if error is false, it's success
          final hasError =
              responseData['error'] ??
              true; // Default to true (error) if field is missing
          print('🔐 AuthRepository: Has error: $hasError');

          if (!hasError) {
            print('🔐 AuthRepository: User details retrieved successfully');
            final otpValidationResponse = OtpValidationResponse.fromJson(
              responseData,
            );
            return Right(otpValidationResponse);
          } else {
            final errorMessage =
                responseData['message'] ?? 'Failed to get user details';
            print('🔐 AuthRepository: Get user details failed: $errorMessage');
            return Left(errorMessage);
          }
        } else if (responseData is String) {
          // Try to parse JSON string
          try {
            final Map<String, dynamic> parsedData = jsonDecode(responseData);
            final hasError = parsedData['error'] ?? true;

            if (!hasError) {
              print('🔐 AuthRepository: User details retrieved successfully');
              final otpValidationResponse = OtpValidationResponse.fromJson(
                parsedData,
              );
              return Right(otpValidationResponse);
            } else {
              final errorMessage =
                  parsedData['message'] ?? 'Failed to get user details';
              print(
                '🔐 AuthRepository: Get user details failed: $errorMessage',
              );
              return Left(errorMessage);
            }
          } catch (e) {
            print('🔐 AuthRepository: Failed to parse JSON string: $e');
            return const Left('Invalid response format from server');
          }
        } else {
          // If response is not a map or string, assume error for safety
          print(
            '🔐 AuthRepository: Get user details failed - invalid response format',
          );
          return const Left('Invalid response format from server');
        }
      } else {
        print(
          '🔐 AuthRepository: Get user details API failed with status: ${response.statusCode}',
        );
        return Left('Failed to get user details. Please try again.');
      }
    } catch (e) {
      print('🔐 AuthRepository: Get user details API error: $e');
      if (e is DioException) {
        if (e.response != null) {
          // Server responded with error status
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('message')) {
            return Left(errorData['message']);
          }
          return Left('Server error: ${e.response!.statusCode}');
        }
        return const Left(
          'Network error. Please check your internet connection.',
        );
      }
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, dynamic>> getAllMusic(int userId) async {
    try {
      print('🔐 AuthRepository: Getting all music for userId: $userId');

      // Get stored token for authorization
      final token = sharedPreferences.getString('user_token') ?? '';

      if (token.isEmpty) {
        print('🔐 AuthRepository: No token found for all music request');
        return const Left('No authentication token found. Please login again.');
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.allMusic}/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'authorization': token,
          },
        ),
      );

      print(
        '🔐 AuthRepository: Get all music API response: ${response.statusCode}',
      );
      print('🔐 AuthRepository: Get all music API data: ${response.data}');
      print(
        '🔐 AuthRepository: Response data type: ${response.data.runtimeType}',
      );

      if (response.statusCode == 200) {
        print('🔐 AuthRepository: All music retrieved successfully');
        return Right(response.data);
      } else {
        print(
          '🔐 AuthRepository: Get all music API failed with status: ${response.statusCode}',
        );
        return Left('Failed to retrieve music. Please try again.');
      }
    } catch (e) {
      print('🔐 AuthRepository: Get all music API error: $e');
      if (e is DioException) {
        if (e.response != null) {
          // Server responded with error status
          final errorData = e.response!.data;
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('message')) {
            return Left(errorData['message']);
          }
          return Left('Server error: ${e.response!.statusCode}');
        }
        return const Left(
          'Network error. Please check your internet connection.',
        );
      }
      return Left('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Either<String, dynamic>> validateOtp(
    String email,
    String otp,
  ) async {
    try {
      print('🔐 AuthRepository: Validating OTP for email: $email');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.validateOtp}',
        data: {'email_id': email, 'otp': otp},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print('🔐 AuthRepository: OTP validation API response: ${response.data}');
      print('🔐 AuthRepository: Response type: ${response.data.runtimeType}');
      print(
        '🔐 AuthRepository: Response keys: ${response.data is Map ? (response.data as Map).keys.toList() : 'Not a Map'}',
      );

      // Debug the data structure more deeply
      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        print('🔐 AuthRepository: Full response map: $responseMap');

        if (responseMap.containsKey('data') && responseMap['data'] is Map) {
          final dataMap = responseMap['data'] as Map<String, dynamic>;
          print(
            '🔐 AuthRepository: Data section keys: ${dataMap.keys.toList()}',
          );
          print('🔐 AuthRepository: Data section values: $dataMap');
          print('🔐 AuthRepository: Token in data: ${dataMap['token']}');
          print('🔐 AuthRepository: UserId in data: ${dataMap['UserId']}');
        }
      }

      if (response.statusCode == 200) {
        final otpValidationResponse = OtpValidationResponse.fromJson(
          response.data,
        );

        if (!otpValidationResponse.error) {
          print('🔐 AuthRepository: OTP validated successfully');

          // Check if userId and token are null (user doesn't exist)
          if (otpValidationResponse.data.userId == null ||
              otpValidationResponse.data.token == null) {
            print(
              '🔐 AuthRepository: User does not exist - userId and token are null, showing Terms and Conditions',
            );
            return Right(TermsRequiredResponse.termsRequired());
          }

          // Store user data in SharedPreferences
          await _storeUserData(otpValidationResponse.data);

          return Right(otpValidationResponse);
        } else {
          print(
            '🔐 AuthRepository: OTP validation failed: ${otpValidationResponse.message}',
          );
          return Left(otpValidationResponse.message);
        }
      } else {
        print(
          '🔐 AuthRepository: OTP validation API failed with status: ${response.statusCode}',
        );
        return Left('Failed to validate OTP. Please try again.');
      }
    } catch (e) {
      print('🔐 AuthRepository: OTP validation API error: $e');
      if (e is DioException) {
        if (e.response != null) {
          // Server responded with error status
          final errorMessage =
              e.response?.data?['message'] ??
              'Failed to validate OTP. Please try again.';
          return Left(errorMessage);
        } else {
          // Network error
          return Left(
            'Network error. Please check your connection and try again.',
          );
        }
      }
      return Left('Failed to validate OTP. Please try again.');
    }
  }

  // Centralized method to save user data (username, email, token) consistently
  Future<void> _saveUserDataConsistently({
    String? token,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? userName,
    String? logId,
    String? gender,
    String? country,
    String? age,
    String? imagePath,
    String? profilePicPath,
    List<dynamic>? devices,
    Map<String, dynamic>? fullUserData,
  }) async {
    try {
      print('🔐 AuthRepository: Saving user data consistently');
      print('🔐 AuthRepository: Token: $token');
      print('🔐 AuthRepository: User ID: $userId');
      print('🔐 AuthRepository: First Name: $firstName');
      print('🔐 AuthRepository: Last Name: $lastName');
      print('🔐 AuthRepository: Email: $email');
      print('🔐 AuthRepository: User Name: $userName');

      // Always save the essential fields (username, email, token)
      if (token != null && token.isNotEmpty) {
        await sharedPreferences.setString('user_token', token);
        print('🔐 AuthRepository: Token saved: $token');
      }

      if (userId != null && userId.isNotEmpty) {
        await sharedPreferences.setString('user_id', userId);
        print('🔐 AuthRepository: User ID saved: $userId');
      }

      if (firstName != null && firstName.isNotEmpty) {
        await sharedPreferences.setString('user_first_name', firstName);
        print('🔐 AuthRepository: First name saved: $firstName');
      }

      if (lastName != null && lastName.isNotEmpty) {
        await sharedPreferences.setString('user_last_name', lastName);
        print('🔐 AuthRepository: Last name saved: $lastName');
      }

      if (email != null && email.isNotEmpty) {
        await sharedPreferences.setString('user_email_id', email);
        print('🔐 AuthRepository: Email saved: $email');
      }

      // Save additional fields if provided
      if (userName != null && userName.isNotEmpty) {
        await sharedPreferences.setString('user_name', userName);
      }

      if (logId != null && logId.isNotEmpty) {
        await sharedPreferences.setString('user_log_id', logId);
      }

      if (gender != null && gender.isNotEmpty) {
        await sharedPreferences.setString('user_gender', gender);
      }

      if (country != null && country.isNotEmpty) {
        await sharedPreferences.setString('user_country', country);
      }

      if (age != null && age.isNotEmpty) {
        await sharedPreferences.setString('user_age', age);
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        await sharedPreferences.setString('user_image_path', imagePath);
      }

      if (profilePicPath != null && profilePicPath.isNotEmpty) {
        await sharedPreferences.setString(
          'user_profile_pic_path',
          profilePicPath,
        );
      }

      // Save devices count if provided
      if (devices != null) {
        await sharedPreferences.setInt('user_devices_count', devices.length);
        print('🔐 AuthRepository: Devices count saved: ${devices.length}');
      }

      // Save complete user data as JSON if provided
      if (fullUserData != null) {
        await sharedPreferences.setString(
          'user_data_json',
          jsonEncode(fullUserData),
        );
        print('🔐 AuthRepository: Full user data JSON saved');
      }

      // Verify what was actually stored
      final storedToken = sharedPreferences.getString('user_token');
      final storedUserId = sharedPreferences.getString('user_id');
      final storedEmail = sharedPreferences.getString('user_email_id');
      final storedFirstName = sharedPreferences.getString('user_first_name');
      final storedLastName = sharedPreferences.getString('user_last_name');

      print('🔐 AuthRepository: User data saved successfully');
      print('🔐 AuthRepository: Verified stored token: "$storedToken"');
      print('🔐 AuthRepository: Verified stored userId: "$storedUserId"');
      print('🔐 AuthRepository: Verified stored email: "$storedEmail"');
      print(
        '🔐 AuthRepository: Verified stored first name: "$storedFirstName"',
      );
      print('🔐 AuthRepository: Verified stored last name: "$storedLastName"');
    } catch (e) {
      print('🔐 AuthRepository: Error saving user data consistently: $e');
    }
  }

  // Store user data in SharedPreferences (legacy method for OTP validation)
  Future<void> _storeUserData(OtpValidationData userData) async {
    try {
      print('🔐 AuthRepository: Storing user data in SharedPreferences');
      print('🔐 AuthRepository: Raw userData.token: ${userData.token}');
      print('🔐 AuthRepository: Raw userData.userId: ${userData.userId}');
      print('🔐 AuthRepository: Raw userData.logId: ${userData.logId}');
      print('🔐 AuthRepository: Raw userData.fname: ${userData.fname}');
      print('🔐 AuthRepository: Raw userData.lname: ${userData.lname}');

      // Use centralized method to save user data
      await _saveUserDataConsistently(
        token: userData.token,
        userId: userData.userId,
        firstName: userData.fname,
        lastName: userData.lname,
        email: userData.emailId,
        userName: userData.userName,
        logId: userData.logId,
        gender: userData.gender,
        country: userData.country,
        age: userData.age,
        imagePath: userData.imagePath,
        profilePicPath: userData.profilepicpath,
        devices: userData.devices,
        fullUserData: userData.toJson(),
      );
    } catch (e) {
      print('🔐 AuthRepository: Error storing user data: $e');
    }
  }

  @override
  Future<void> logout() async {
    print('🔐 AuthRepository: Logging out - clearing all user data');

    // Clear all user data fields
    await sharedPreferences.remove('auth_token');
    await sharedPreferences.remove('user_email_id');
    await sharedPreferences.remove('user_data_json');
    await sharedPreferences.remove('user_data'); // Also clear this field
    await sharedPreferences.remove('user_token');
    await sharedPreferences.remove('user_id');
    await sharedPreferences.remove('user_log_id');
    await sharedPreferences.remove('user_first_name');
    await sharedPreferences.remove('user_last_name');
    await sharedPreferences.remove('user_email_id');
    await sharedPreferences.remove('user_name');
    await sharedPreferences.remove('user_gender');
    await sharedPreferences.remove('user_country');
    await sharedPreferences.remove('user_age');
    await sharedPreferences.remove('user_image_path');
    await sharedPreferences.remove('user_profile_pic_path');
    await sharedPreferences.remove('user_devices_count');

    print('🔐 AuthRepository: All user data cleared successfully');
  }

  @override
  Future<Either<String, bool>> deleteUserAccount() async {
    try {
      // Get stored user data
      print('🔐 AuthRepository: Getting user data from SharedPreferences...');

      // Debug: List all stored keys
      final allKeys = sharedPreferences.getKeys();
      print('🔐 AuthRepository: All stored keys: $allKeys');

      // Debug: Check what type of data is stored
      final userIdValue = sharedPreferences.get('user_id');
      final tokenValue = sharedPreferences.get('user_token');

      print(
        '🔐 AuthRepository: Raw userId type: ${userIdValue.runtimeType}, value: $userIdValue',
      );
      print(
        '🔐 AuthRepository: Raw token type: ${tokenValue.runtimeType}, value: $tokenValue',
      );

      // Convert to string safely
      final userId = userIdValue?.toString() ?? '';
      final token = tokenValue?.toString() ?? '';

      print('🔐 AuthRepository: Converted userId: $userId');
      print(
        '🔐 AuthRepository: Converted token: ${token.isNotEmpty ? 'present' : 'empty'}',
      );

      if (userId.isEmpty || token.isEmpty) {
        print('🔐 AuthRepository: No user ID or token found for deletion');
        print('🔐 AuthRepository: Proceeding with local data cleanup only');

        // Clear any remaining local data
        await logout();

        return Right(true); // Return success since local cleanup is done
      }

      print('🔐 AuthRepository: Deleting user account for ID: $userId');

      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.deleteUser}/$userId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': token,
          },
        ),
      );

      print(
        '🔐 AuthRepository: Delete user API response: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('🔐 AuthRepository: User account deleted successfully');

        // Clear all user data from SharedPreferences
        await logout();

        return Right(true);
      } else {
        print(
          '🔐 AuthRepository: Delete user API failed with status: ${response.statusCode}',
        );
        return Left('Failed to delete account. Please try again.');
      }
    } catch (e) {
      print('🔐 AuthRepository: Delete user API error: $e');
      if (e is DioException) {
        if (e.response != null) {
          // Server responded with error status
          final errorMessage =
              e.response?.data?['message'] ??
              'Failed to delete account. Please try again.';
          return Left(errorMessage);
        } else {
          // Network error
          return Left(
            'Network error. Please check your connection and try again.',
          );
        }
      }
      return Left('Failed to delete account. Please try again.');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = sharedPreferences.getString('user_token');
    return token != null && token.isNotEmpty;
  }

  // Check if user has complete profile (firstname, lastname, and devices)
  @override
  Future<bool> hasCompleteProfile() async {
    final firstName =
        sharedPreferences.getString('user_first_name')?.trim() ?? '';
    final lastName =
        sharedPreferences.getString('user_last_name')?.trim() ?? '';
    final devicesCount = sharedPreferences.getInt('user_devices_count') ?? 0;

    print(
      '🔐 AuthRepository: Profile check - FirstName: "$firstName", LastName: "$lastName", Devices: $devicesCount',
    );

    // User has complete profile if they have both first and last name AND have devices
    final hasCompleteProfile =
        (firstName.isNotEmpty && lastName.isNotEmpty) || devicesCount > 0;

    print('🔐 AuthRepository: Has complete profile: $hasCompleteProfile');
    return hasCompleteProfile;
  }

  // Check if user has basic profile (firstname and lastname) but no devices
  Future<bool> hasBasicProfileButNoDevices() async {
    final firstName =
        sharedPreferences.getString('user_first_name')?.trim() ?? '';
    final lastName =
        sharedPreferences.getString('user_last_name')?.trim() ?? '';
    final devicesCount = sharedPreferences.getInt('user_devices_count') ?? 0;

    print(
      '🔐 AuthRepository: Basic profile check - FirstName: "$firstName", LastName: "$lastName", Devices: $devicesCount',
    );

    // User has basic profile but no devices if they have both first and last name BUT no devices
    final hasBasicProfileButNoDevices =
        firstName.isNotEmpty && lastName.isNotEmpty && devicesCount == 0;

    print(
      '🔐 AuthRepository: Has basic profile but no devices: $hasBasicProfileButNoDevices',
    );
    return hasBasicProfileButNoDevices;
  }

  // Get stored user data
  @override
  Future<Map<String, String>> getStoredUserData() async {
    return {
      'token': sharedPreferences.getString('user_token') ?? '',
      'userId': sharedPreferences.getString('user_id') ?? '',
      'firstName': sharedPreferences.getString('user_first_name') ?? '',
      'lastName': sharedPreferences.getString('user_last_name') ?? '',
      'emailId': sharedPreferences.getString('user_email_id') ?? '',
      'userName': sharedPreferences.getString('user_name') ?? '',
      'gender': sharedPreferences.getString('user_gender') ?? '',
      'country': sharedPreferences.getString('user_country') ?? '',
      'age': sharedPreferences.getString('user_age') ?? '',
      'imagePath': sharedPreferences.getString('user_image_path') ?? '',
      'profilePicPath':
          sharedPreferences.getString('user_profile_pic_path') ?? '',
      'devicesCount': sharedPreferences.getInt('user_devices_count').toString(),
    };
  }

  @override
  Future<Either<String, SocialLoginResponse>> socialLogin(
    SocialLoginRequest request,
  ) async {
    try {
      print(
        '🔐 AuthRepository: Social login request for email: ${request.emailId}',
      );

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.socialLogin}',
        data: request.toJson(),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
        '🔐 AuthRepository: Social login API response: ${response.statusCode}',
      );
      print('🔐 AuthRepository: Social login API data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print(
          '🔐 AuthRepository: Response data type: ${responseData.runtimeType}',
        );

        final socialLoginResponse = SocialLoginResponse.fromJson(responseData);
        print('🔐 AuthRepository: Has error: ${socialLoginResponse.error}');

        if (!socialLoginResponse.error && socialLoginResponse.data != null) {
          // Store user data in SharedPreferences using centralized method
          final userData = socialLoginResponse.data!;
          await _saveUserDataConsistently(
            token: userData.tokenid,
            userId: userData.id,
            firstName: userData.fname,
            lastName: userData.lname,
            email: userData.emailid,
            logId: userData.logId,
            fullUserData: responseData,
          );

          print('🔐 AuthRepository: Social login successful');
          return Right(socialLoginResponse);
        } else {
          print(
            '🔐 AuthRepository: Social login failed: ${socialLoginResponse.message}',
          );
          return Left(socialLoginResponse.message);
        }
      } else {
        print(
          '🔐 AuthRepository: Social login failed with status: ${response.statusCode}',
        );
        return Left('Social login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('🔐 AuthRepository: Social login error: $e');
      if (e is DioException) {
        if (e.response != null) {
          print('🔐 AuthRepository: Server error: ${e.response!.statusCode}');
          print('🔐 AuthRepository: Server response: ${e.response!.data}');
          return Left('Server error: ${e.response!.statusCode}');
        }
      }
      return Left('Social login failed: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, CreateProfileResponse>> createProfile(
    CreateProfileRequest request,
  ) async {
    try {
      print(
        '🔐 AuthRepository: Create profile request for email: ${request.emailId}',
      );

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.createProfile}',
        data: request.toJson(),
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print(
        '🔐 AuthRepository: Create profile API response: ${response.statusCode}',
      );
      print('🔐 AuthRepository: Create profile API data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print(
          '🔐 AuthRepository: Response data type: ${responseData.runtimeType}',
        );

        final createProfileResponse = CreateProfileResponse.fromJson(
          responseData,
        );
        print(
          '🔐 AuthRepository: Create profile success: ${createProfileResponse.error}',
        );

        if (createProfileResponse.error == false) {
          // Store user data in SharedPreferences using the same method as OTP validation
          await _storeUserData(createProfileResponse.data);

          print('🔐 AuthRepository: Profile created successfully');
          return Right(createProfileResponse);
        } else {
          print(
            '🔐 AuthRepository: Create profile failed: ${createProfileResponse.message}',
          );
          return Left(createProfileResponse.message);
        }
      } else {
        print(
          '🔐 AuthRepository: Create profile failed with status: ${response.statusCode}',
        );
        return Left(
          'Create profile failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('🔐 AuthRepository: Create profile error: $e');
      if (e is DioException) {
        if (e.response != null) {
          print('🔐 AuthRepository: Server error: ${e.response!.statusCode}');
          print('🔐 AuthRepository: Server response: ${e.response!.data}');
          return Left('Server error: ${e.response!.statusCode}');
        }
      }
      return Left('Create profile failed: ${e.toString()}');
    }
  }
}
