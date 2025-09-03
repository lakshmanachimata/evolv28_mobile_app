import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SharedPreferences sharedPreferences;

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
