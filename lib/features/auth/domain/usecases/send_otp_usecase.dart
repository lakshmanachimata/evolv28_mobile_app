import 'package:dartz/dartz.dart';
import '../entities/otp_response.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<Either<String, OtpResponse>> call(String email) async {
    return await repository.sendOtp(email);
  }
}
