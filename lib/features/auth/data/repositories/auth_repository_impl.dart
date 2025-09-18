import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/otp_response.dart';
import '../../domain/entities/otp_validation_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SharedPreferences sharedPreferences;
  final Dio _dio = Dio();

  AuthRepositoryImpl({required this.sharedPreferences});

  @override
  Future<Either<String, AuthResult>> login(String email, String password, bool rememberMe) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock login logic - in real app, this would be an API call
      if (email == 'test@example.com' && password == 'password') {
        final user = User(
          id: '1',
          email: email,
          name: 'Test User',
        );
        
        final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        
        // Save token if remember me is checked
        if (rememberMe) {
          await sharedPreferences.setString('auth_token', token);
          await sharedPreferences.setString('user_email', email);
        }
        
        return Right(AuthResult(
          user: user,
          token: token,
        ));
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
        data: {
          'email_id': email,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📧 AuthRepository: OTP API response: ${response.data}');

      if (response.statusCode == 200) {
        final otpResponse = OtpResponse.fromJson(response.data);
        
        if (!otpResponse.error) {
          print('📧 AuthRepository: OTP sent successfully: ${otpResponse.data.otp}');
          return Right(otpResponse);
        } else {
          print('📧 AuthRepository: OTP API returned error: ${otpResponse.message}');
          return Left(otpResponse.message);
        }
      } else {
        print('📧 AuthRepository: OTP API failed with status: ${response.statusCode}');
        return Left('Failed to send OTP. Please try again.');
      }
    } catch (e) {
      print('📧 AuthRepository: OTP API error: $e');
      if (e is DioException) {
        if (e.response != null) {
          // Server responded with error status
          final errorMessage = e.response?.data?['message'] ?? 'Failed to send OTP. Please try again.';
          return Left(errorMessage);
        } else {
          // Network error
          return Left('Network error. Please check your connection and try again.');
        }
      }
      return Left('Failed to send OTP. Please try again.');
    }
  }

  @override
  Future<Either<String, OtpValidationResponse>> validateOtp(String email, String otp) async {
    try {
      print('🔐 AuthRepository: Validating OTP for email: $email');
      
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.validateOtp}',
        data: {
          'email_id': email,
          'otp': otp,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('🔐 AuthRepository: OTP validation API response: ${response.data}');
      print('🔐 AuthRepository: Response type: ${response.data.runtimeType}');
      print('🔐 AuthRepository: Response keys: ${response.data is Map ? (response.data as Map).keys.toList() : 'Not a Map'}');

      if (response.statusCode == 200) {
        final otpValidationResponse = OtpValidationResponse.fromJson(response.data);
        
        if (!otpValidationResponse.error) {
          print('🔐 AuthRepository: OTP validated successfully');
          return Right(otpValidationResponse);
        } else {
          print('🔐 AuthRepository: OTP validation failed: ${otpValidationResponse.message}');
          return Left(otpValidationResponse.message);
        }
      } else {
        print('🔐 AuthRepository: OTP validation API failed with status: ${response.statusCode}');
        return Left('Failed to validate OTP. Please try again.');
      }
    } catch (e) {
      print('🔐 AuthRepository: OTP validation API error: $e');
      if (e is DioException) {
        if (e.response != null) {
          // Server responded with error status
          final errorMessage = e.response?.data?['message'] ?? 'Failed to validate OTP. Please try again.';
          return Left(errorMessage);
        } else {
          // Network error
          return Left('Network error. Please check your connection and try again.');
        }
      }
      return Left('Failed to validate OTP. Please try again.');
    }
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove('auth_token');
    await sharedPreferences.remove('user_email');
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = sharedPreferences.getString('auth_token');
    return token != null && token.isNotEmpty;
  }
}
