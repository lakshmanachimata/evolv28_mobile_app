import 'package:equatable/equatable.dart';
import 'user.dart';

class AuthResult extends Equatable {
  final User? user;
  final String? token;
  final String? error;

  const AuthResult({
    this.user,
    this.token,
    this.error,
  });

  bool get isSuccess => user != null && token != null && error == null;
  bool get isFailure => error != null;

  @override
  List<Object?> get props => [user, token, error];
}
