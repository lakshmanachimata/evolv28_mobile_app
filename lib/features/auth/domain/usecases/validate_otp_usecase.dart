import 'package:dartz/dartz.dart';
import '../entities/otp_validation_response.dart';
import '../repositories/auth_repository.dart';

class ValidateOtpUseCase {
  final AuthRepository repository;

  ValidateOtpUseCase(this.repository);

  Future<Either<String, OtpValidationResponse>> call(String email, String otp) async {
    return await repository.validateOtp(email, otp);
  }
}
