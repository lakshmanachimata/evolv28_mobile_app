import 'package:dartz/dartz.dart';
import '../entities/social_login_request.dart';
import '../entities/social_login_response.dart';
import '../repositories/auth_repository.dart';

class SocialLoginUseCase {
  final AuthRepository _authRepository;

  SocialLoginUseCase(this._authRepository);

  Future<Either<String, SocialLoginResponse>> call(SocialLoginRequest request) async {
    return await _authRepository.socialLogin(request);
  }
}
