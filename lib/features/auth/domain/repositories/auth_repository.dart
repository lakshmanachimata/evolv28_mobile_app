import 'package:dartz/dartz.dart';
import '../entities/auth_result.dart';

abstract class AuthRepository {
  Future<Either<String, AuthResult>> login(String email, String password, bool rememberMe);
  Future<void> logout();
  Future<bool> isLoggedIn();
}
