import 'package:dartz/dartz.dart';
import '../entities/otp_validation_response.dart';
import '../repositories/auth_repository.dart';

class GetUserDetailsUseCase {
  final AuthRepository repository;

  GetUserDetailsUseCase(this.repository);

  Future<Either<String, OtpValidationResponse>> call(int userId) async {
    return await repository.getUserDetails(userId);
  }
}
