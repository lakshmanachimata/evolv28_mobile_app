import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/otp_response.dart';
import '../../domain/entities/otp_validation_response.dart';
import '../../domain/entities/social_login_request.dart';
import '../../domain/entities/social_login_response.dart';
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

        // Save token if remember me is checked
        if (rememberMe) {
          await sharedPreferences.setString('auth_token', token);
          await sharedPreferences.setString('user_email', email);
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

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.sendOtp}',
        data: {'email_id': email},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );


      if (response.statusCode == 200) {
        final otpResponse = OtpResponse.fromJson(response.data);

        if (!otpResponse.error) {
            '📧 AuthRepository: OTP sent successfully: ${otpResponse.data.otp}',
          );
          return Right(otpResponse);
        } else {
            '📧 AuthRepository: OTP API returned error: ${otpResponse.message}',
          );
          return Left(otpResponse.message);
        }
      } else {
          '📧 AuthRepository: OTP API failed with status: ${response.statusCode}',
        );
        return Left('Failed to send OTP. Please try again.');
      }
    } catch (e) {
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

      // Get stored token for authorization
      final token = sharedPreferences.getString('user_token') ?? '';

      if (token.isEmpty) {
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

        '🔐 AuthRepository: Verify OTP API response: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        // Check if the response indicates success
        final responseData = response.data;
          '🔐 AuthRepository: Response data type: ${responseData.runtimeType}',
        );

        if (responseData is Map<String, dynamic>) {
          // Check the 'error' field - if error is false, it's success
          final hasError =
              responseData['error'] ??
              true; // Default to true (error) if field is missing

          if (!hasError) {
            return const Right(true);
          } else {
            final errorMessage =
                responseData['message'] ?? 'OTP verification failed';
            return Left(errorMessage);
          }
        } else if (responseData is String) {
          // Try to parse JSON string
          try {
            final Map<String, dynamic> parsedData = jsonDecode(responseData);
            final hasError = parsedData['error'] ?? true;

            if (!hasError) {
              return const Right(true);
            } else {
              final errorMessage =
                  parsedData['message'] ?? 'OTP verification failed';
                '🔐 AuthRepository: OTP verification failed: $errorMessage',
              );
              return Left(errorMessage);
            }
          } catch (e) {
            return const Left('Invalid response format from server');
          }
        } else {
          // If response is not a map or string, assume error for safety
            '🔐 AuthRepository: OTP verification failed - invalid response format',
          );
          return const Left('Invalid response format from server');
        }
      } else {
          '🔐 AuthRepository: Verify OTP API failed with status: ${response.statusCode}',
        );
        return Left('Failed to verify OTP. Please try again.');
      }
    } catch (e) {
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

      // Get stored token for authorization
      final token = sharedPreferences.getString('user_token') ?? '';

      if (token.isEmpty) {
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

        '🔐 AuthRepository: Get user details API response: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
          '🔐 AuthRepository: Response data type: ${responseData.runtimeType}',
        );

        if (responseData is Map<String, dynamic>) {
          // Check the 'error' field - if error is false, it's success
          final hasError =
              responseData['error'] ??
              true; // Default to true (error) if field is missing

          if (!hasError) {
            final otpValidationResponse = OtpValidationResponse.fromJson(
              responseData,
            );
            return Right(otpValidationResponse);
          } else {
            final errorMessage =
                responseData['message'] ?? 'Failed to get user details';
            return Left(errorMessage);
          }
        } else if (responseData is String) {
          // Try to parse JSON string
          try {
            final Map<String, dynamic> parsedData = jsonDecode(responseData);
            final hasError = parsedData['error'] ?? true;

            if (!hasError) {
              final otpValidationResponse = OtpValidationResponse.fromJson(
                parsedData,
              );
              return Right(otpValidationResponse);
            } else {
              final errorMessage =
                  parsedData['message'] ?? 'Failed to get user details';
                '🔐 AuthRepository: Get user details failed: $errorMessage',
              );
              return Left(errorMessage);
            }
          } catch (e) {
            return const Left('Invalid response format from server');
          }
        } else {
          // If response is not a map or string, assume error for safety
            '🔐 AuthRepository: Get user details failed - invalid response format',
          );
          return const Left('Invalid response format from server');
        }
      } else {
          '🔐 AuthRepository: Get user details API failed with status: ${response.statusCode}',
        );
        return Left('Failed to get user details. Please try again.');
      }
    } catch (e) {
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

      // Get stored token for authorization
      final token = sharedPreferences.getString('user_token') ?? '';

      if (token.isEmpty) {
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

        '🔐 AuthRepository: Get all music API response: ${response.statusCode}',
      );
        '🔐 AuthRepository: Response data type: ${response.data.runtimeType}',
      );

      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
          '🔐 AuthRepository: Get all music API failed with status: ${response.statusCode}',
        );
        return Left('Failed to retrieve music. Please try again.');
      }
    } catch (e) {
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
  Future<Either<String, OtpValidationResponse>> validateOtp(
    String email,
    String otp,
  ) async {
    try {

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.validateOtp}',
        data: {'email_id': email, 'otp': otp},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

        '🔐 AuthRepository: Response keys: ${response.data is Map ? (response.data as Map).keys.toList() : 'Not a Map'}',
      );

      // Debug the data structure more deeply
      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;

        if (responseMap.containsKey('data') && responseMap['data'] is Map) {
          final dataMap = responseMap['data'] as Map<String, dynamic>;
            '🔐 AuthRepository: Data section keys: ${dataMap.keys.toList()}',
          );
        }
      }

      if (response.statusCode == 200) {
        final otpValidationResponse = OtpValidationResponse.fromJson(
          response.data,
        );

        if (!otpValidationResponse.error) {

          // Check if userId and token are null (user doesn't exist)
          if (otpValidationResponse.data.userId == null ||
              otpValidationResponse.data.token == null) {
              '🔐 AuthRepository: User does not exist - userId and token are null',
            );
            return Left('User does not exist. Please register first.');
          }

          // Store user data in SharedPreferences
          await _storeUserData(otpValidationResponse.data);

          return Right(otpValidationResponse);
        } else {
            '🔐 AuthRepository: OTP validation failed: ${otpValidationResponse.message}',
          );
          return Left(otpValidationResponse.message);
        }
      } else {
          '🔐 AuthRepository: OTP validation API failed with status: ${response.statusCode}',
        );
        return Left('Failed to validate OTP. Please try again.');
      }
    } catch (e) {
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

  // Store user data in SharedPreferences
  Future<void> _storeUserData(OtpValidationData userData) async {
    try {

      // Store complete user data as JSON
      await sharedPreferences.setString(
        'user_data_json',
        jsonEncode(userData.toJson()),
      );

      // Store individual fields for easy access
      await sharedPreferences.setString('user_token', userData.token ?? '');
      await sharedPreferences.setString('user_id', userData.userId ?? '');
      await sharedPreferences.setString('user_log_id', userData.logId ?? '');
      await sharedPreferences.setString(
        'user_first_name',
        userData.fname ?? '',
      );
      await sharedPreferences.setString('user_last_name', userData.lname ?? '');
      await sharedPreferences.setString(
        'user_email_id',
        userData.emailId ?? '',
      );
      await sharedPreferences.setString('user_name', userData.userName ?? '');
      await sharedPreferences.setString('user_gender', userData.gender ?? '');
      await sharedPreferences.setString('user_country', userData.country ?? '');
      await sharedPreferences.setString('user_age', userData.age ?? '');
      await sharedPreferences.setString(
        'user_image_path',
        userData.imagePath ?? '',
      );
      await sharedPreferences.setString(
        'user_profile_pic_path',
        userData.profilepicpath ?? '',
      );

      // Store devices count
      await sharedPreferences.setInt(
        'user_devices_count',
        userData.devices.length,
      );

      // Verify what was actually stored
      final storedToken = sharedPreferences.getString('user_token');
      final storedUserId = sharedPreferences.getString('user_id');

    } catch (e) {
    }
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove('auth_token');
    await sharedPreferences.remove('user_email');
    await sharedPreferences.remove('user_data_json');
    await sharedPreferences.remove('user_token');
    await sharedPreferences.remove('user_id');
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
  }

  @override
  Future<Either<String, bool>> deleteUserAccount() async {
    try {
      // Get stored user data

      // Debug: List all stored keys
      final allKeys = sharedPreferences.getKeys();

      // Debug: Check what type of data is stored
      final userIdValue = sharedPreferences.get('user_id');
      final tokenValue = sharedPreferences.get('user_token');

        '🔐 AuthRepository: Raw userId type: ${userIdValue.runtimeType}, value: $userIdValue',
      );
        '🔐 AuthRepository: Raw token type: ${tokenValue.runtimeType}, value: $tokenValue',
      );

      // Convert to string safely
      final userId = userIdValue?.toString() ?? '';
      final token = tokenValue?.toString() ?? '';

        '🔐 AuthRepository: Converted token: ${token.isNotEmpty ? 'present' : 'empty'}',
      );

      if (userId.isEmpty || token.isEmpty) {

        // Clear any remaining local data
        await logout();

        return Right(true); // Return success since local cleanup is done
      }


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

        '🔐 AuthRepository: Delete user API response: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {

        // Clear all user data from SharedPreferences
        await logout();

        return Right(true);
      } else {
          '🔐 AuthRepository: Delete user API failed with status: ${response.statusCode}',
        );
        return Left('Failed to delete account. Please try again.');
      }
    } catch (e) {
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
    final firstName = sharedPreferences.getString('user_first_name') ?? '';
    final lastName = sharedPreferences.getString('user_last_name') ?? '';
    final devicesCount = sharedPreferences.getInt('user_devices_count') ?? 0;

      '🔐 AuthRepository: Profile check - FirstName: "$firstName", LastName: "$lastName", Devices: $devicesCount',
    );

    // User has complete profile if they have both first and last name AND have devices
    final hasCompleteProfile =
        firstName.isNotEmpty && lastName.isNotEmpty && devicesCount > 0;

    return hasCompleteProfile;
  }

  // Check if user has basic profile (firstname and lastname) but no devices
  Future<bool> hasBasicProfileButNoDevices() async {
    final firstName = sharedPreferences.getString('user_first_name') ?? '';
    final lastName = sharedPreferences.getString('user_last_name') ?? '';
    final devicesCount = sharedPreferences.getInt('user_devices_count') ?? 0;

      '🔐 AuthRepository: Basic profile check - FirstName: "$firstName", LastName: "$lastName", Devices: $devicesCount',
    );

    // User has basic profile but no devices if they have both first and last name BUT no devices
    final hasBasicProfileButNoDevices =
        firstName.isNotEmpty && lastName.isNotEmpty && devicesCount == 0;

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
  Future<Either<String, SocialLoginResponse>> socialLogin(SocialLoginRequest request) async {
    try {
      
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


      if (response.statusCode == 200) {
        final responseData = response.data;
        
        final socialLoginResponse = SocialLoginResponse.fromJson(responseData);
        
        if (!socialLoginResponse.error && socialLoginResponse.data != null) {
          // Store user data in SharedPreferences
          final userData = socialLoginResponse.data!;
          await sharedPreferences.setString('user_data_json', jsonEncode(responseData));
          await sharedPreferences.setString('user_token', userData.tokenid);
          await sharedPreferences.setString('user_id', userData.id);
          await sharedPreferences.setString('user_log_id', userData.logId ?? '');
          await sharedPreferences.setString('user_first_name', userData.fname);
          await sharedPreferences.setString('user_last_name', userData.lname);
          await sharedPreferences.setString('user_email_id', userData.emailid);
          
          return Right(socialLoginResponse);
        } else {
          return Left(socialLoginResponse.message);
        }
      } else {
        return Left('Social login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          return Left('Server error: ${e.response!.statusCode}');
        }
      }
      return Left('Social login failed: ${e.toString()}');
    }
  }
}
