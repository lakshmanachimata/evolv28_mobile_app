import 'package:dartz/dartz.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<String, AuthResult>> call(String email, String password, bool rememberMe) {
    return repository.login(email, password, rememberMe);
  }
}
