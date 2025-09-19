import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<String, bool>> call(String email, String otp) async {
    return await repository.verifyOtp(email, otp);
  }
}
