import 'package:dartz/dartz.dart';
import '../entities/auth_result.dart';
import '../entities/otp_response.dart';
import '../entities/otp_validation_response.dart';

abstract class AuthRepository {
  Future<Either<String, AuthResult>> login(String email, String password, bool rememberMe);
  Future<Either<String, OtpResponse>> sendOtp(String email);
  Future<Either<String, OtpValidationResponse>> validateOtp(String email, String otp);
  Future<void> logout();
  Future<bool> isLoggedIn();
}
