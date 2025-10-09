import 'package:dartz/dartz.dart';
import '../entities/auth_result.dart';
import '../entities/otp_response.dart';
import '../entities/otp_validation_response.dart';
import '../entities/social_login_response.dart';
import '../entities/social_login_request.dart';
import '../entities/create_profile_request.dart';
import '../entities/create_profile_response.dart';

abstract class AuthRepository {
  Future<Either<String, AuthResult>> login(String email, String password, bool rememberMe);
  Future<Either<String, OtpResponse>> sendOtp(String email);
  Future<Either<String, dynamic>> validateOtp(String email, String otp);
  Future<Either<String, bool>> verifyOtp(String email, String otp);
  Future<Either<String, OtpValidationResponse>> getUserDetails(int userId);
  Future<Either<String, dynamic>> getAllMusic(int userId);
  Future<Either<String, SocialLoginResponse>> socialLogin(SocialLoginRequest request);
  Future<Either<String, CreateProfileResponse>> createProfile(CreateProfileRequest request);
  Future<void> logout();
  Future<Either<String, bool>> deleteUserAccount();
  Future<bool> isLoggedIn();
  Future<bool> hasCompleteProfile();
  Future<bool> hasBasicProfileButNoDevices();
  Future<Map<String, String>> getStoredUserData();
}
